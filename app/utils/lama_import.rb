class ImportError < RuntimeError
end

module LamaImport
  def self.lama
    LamaApi.new(Rails.application.config.lama_api[:event_id])
  end

  def self.info(msg)
    @output ||= ''
    puts msg
    @output += "#{msg}\n"
  end

  def self.output
    result = @output
    @output = nil
    result
  end

  def self.diets
    diets = lama.restrictions.map do |restriction|
      {
        name: restriction['name'],
        category: restriction['category'],
        lama_uuid: restriction['id']
      }
    end
    Diet.upsert_all(diets, unique_by: :name)
    # delete all diets which once have been imported from lama, but are not included now
    deleted_diets = Diet.where.not(lama_uuid: [nil] + diets.map { |d| d[:lama_uuid] }).delete_all
    info "Imported #{diets.size} Diets, deleted #{deleted_diets}"
    output
  end

  def self.participants
    attendees = lama.attendees
    participants = attendees.map do |attendee|
      {
        lama_uuid: attendee['id'],
        comment: attendee['restrictionsComment'],
        age: attendee['age']
      }
    end
    participant_id_map = Participant.upsert_all(participants, unique_by: :lama_uuid, returning: %w[lama_uuid id]).rows.to_h
    # delete all participants which once have been imported from lama, but are not included now
    deleted_participants = Participant.where.not(lama_uuid: [nil] + participant_id_map.keys).delete_all
    info "Imported #{participant_id_map.size} Participants, deleted #{deleted_participants}"

    restriction_uuids = attendees.map{ |a| a['restrictions'] }.flatten.uniq
    diet_id_map = Diet.where(lama_uuid: restriction_uuids).pluck(:lama_uuid, :id).to_h
    deleted_participant_diets = DietParticipant.where(participant: participant_id_map.values).delete_all
    diet_participants = attendees.map do |attendee|
      attendee['restrictions'].map do |restriction|
        {
          diet_id: diet_id_map[restriction],
          participant_id: participant_id_map[attendee['id']]
        }
      end
    end.flatten
    DietParticipant.insert_all(diet_participants)
    info "Imported #{diet_participants.size} DietParticipants, "\
      "#{deleted_participant_diets} before, #{diet_id_map.size} unique"
    output
  end

  def self.recipes
    meals = lama.meals
    recipes = meals.map do |meal|
      {
        lama_uuid: meal['id'],
        name: meal['name']
      }
    end
    created = 0
    updated = 0
    recipes.each do |recipe|
      next if Recipe.where(lama_uuid: recipe[:lama_uuid]).exists?

      if (existing_recipe = Recipe.find_by(name: recipe[:name], lama_uuid: nil))
        existing_recipe.lama_uuid = recipe[:lama_uuid]
        existing_recipe.save!
        updated += 1
      else
        Recipe.create(name: "#{recipe[:name]} LAMA", lama_uuid: recipe[:lama_uuid])
        created += 1
      end
    end
    # delete all recipes which once have been imported from lama, but are not included now
    deleted_recipes = Recipe.where.not(lama_uuid: [nil] + recipes.map { |m| m[:lama_uuid] }).delete_all
    info "Imported #{recipes.size} Recipes, created #{created}, updated #{updated}, deleted #{deleted_recipes}"
    output
  end

  def self.groups_slots
    deleted_group_meal_participations = GroupMealParticipation.where(lama_imported: true).delete_all

    slots = lama.slots.map { |slot| [slot['id'], slot] }.to_h
    lama_groups = lama.groups

    # Import Groups
    group_names = Set[]
    groups = lama_groups.map do |group|
      name = group['name']
      unless group_names.add?(name)
        count = 1
        count += 1 until group_names.add?("#{name} (#{count})")
        name = "#{name} (#{count})"
      end
      {
        lama_uuid: group['id'],
        name: name
      }
    end
    group_id_map = Group.upsert_all(groups, unique_by: :lama_uuid, returning: %w[lama_uuid id]).rows.to_h
    # delete all groups which once have been imported from lama, but are not included now
    deleted_groups = Group.where.not(lama_uuid: [nil] + group_id_map.keys).delete_all
    info "Imported #{group_id_map.size} Groups, deleted #{deleted_groups}"

    # Generate and import Meals from Slots and Recipes(Meal in Lama)
    # our meals are a combination of recipe and datetime of the slot
    meals_uuid = Set[]
    lama_groups.map do |group|
      group['slots'].map do |slot|
        slot['mealIds'].map do |meal|
          meals_uuid.add([slot['slotId'], meal])
        end
      end
    end
    recipe_id_map = Recipe.where(lama_uuid: meals_uuid.map { |m| m[1] }).pluck(:lama_uuid, :id).to_h
    unknown_meals = Set[]
    meals = meals_uuid.map do |slot_id, meal_id|
      slot = slots[slot_id]
      if recipe_id_map.include?(meal_id)
        # lama talks utc but means local time
        # this assumes we have configured the correct local time
        t = Time.iso8601(slot['startsAt'])
        {
          lama_slot_uuid: slot['id'],
          recipe_id: recipe_id_map.fetch(meal_id),
          name: slot['name'],
          datetime: Time.new(t.year, t.month, t.day, t.hour, t.min, t.sec),
          optional: true
        }
      else
        unknown_meals.add(meal_id)
      end
    end
    abort("\e[0;31mUnknown Meals: #{unknown_meals}. Try lama:import_meals\e[0m") unless unknown_meals.empty?
    meal_id_map = Meal.upsert_all(
      meals,
      unique_by: %i[lama_slot_uuid recipe_id],
      returning: %w[lama_slot_uuid recipe_id id]
    ).rows.map do |row|
      [[row[0], row[1]], row[2]]
    end.to_h
    # delete all meals which once have been imported from lama, but are not included now
    values = meal_id_map.keys.map { |slot_uuid, recipe_id| "(uuid('#{slot_uuid}'), #{recipe_id})" }
    deleted_meals = Meal \
                    .where.not(lama_slot_uuid: nil) \
                    .where("(lama_slot_uuid, recipe_id) NOT IN (VALUES #{values.join(', ')})").delete_all
    info "Imported #{meal_id_map.size} Meals, deleted #{deleted_meals}"

    # Import GroupMealParticipations
    attendees = lama_groups.map do |group|
      group['slots'].map do |slot|
        slot['attendees']
      end
    end.flatten
    participant_id_map = Participant.where(lama_uuid: attendees).pluck(:lama_uuid, :id).to_h

    group_meal_participations = lama_groups.map do |group|
      group_id = group_id_map[group['id']]
      group['slots'].map do |slot|
        slot['mealIds'].map do |meal|
          recipe_id = recipe_id_map[meal]
          meal_id = meal_id_map[[slot['slotId'], recipe_id]]
          slot['attendees'].map do |attendee|
            raise ImportError, "unknown attendee #{attendee}" unless participant_id_map.include? attendee

            {
              group_id:,
              meal_id:,
              participant_id: participant_id_map[attendee],
              lama_imported: true
            }
          end
        end
      end
    end.flatten
    group_meal_participations.each_slice(50_000) do |group_meal_participation_slice|
      GroupMealParticipation.upsert_all(group_meal_participation_slice, unique_by: %i[group_id meal_id participant_id])
    end
    info "Imported #{group_meal_participations.size} GroupMealParticipations, "\
      "deleted #{deleted_group_meal_participations}"
    output
  end

  def self.all
    ActiveRecord::Base.transaction do
      diets +
        participants +
        recipes +
        groups_slots
    end
  rescue LamaError => e
    e
  rescue ImportError => e
    e
  end
end
