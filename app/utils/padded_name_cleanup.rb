# frozen_string_literal: true

# Strips the surrounding whitespace that recipe parsing used to leave in
# ingredient and diet names (`**5 g Mandeln (+vegan)**` created "Mandeln ").
#
# A padded record is renamed when its stripped name is free. If the stripped
# name is already taken, the padded record is merged into that one, but only
# when nothing besides recipes refers to it; anything else (articles, weights,
# participants, ...) needs a human to decide and is reported as skipped.
class PaddedNameCleanup
  MERGEABLE = {
    Ingredient => %i[recipe_ingredients],
    Diet => %i[positive_diet_ingredients negative_diet_ingredients]
  }.freeze

  BLOCKING = {
    Ingredient => %i[articles ingredient_weights extra_ingredients ingredient_alternatives
                     ingredient_substitutions diets missing_ingredients],
    Diet => %i[ingredients diet_participants]
  }.freeze

  def initialize(apply:, log: $stdout)
    @apply = apply
    @log = log
  end

  def call
    ApplicationRecord.transaction do
      MERGEABLE.each_key { |model| clean(model) }
      raise ActiveRecord::Rollback unless @apply
    end
  end

  private

  def clean(model)
    padded(model).each do |record|
      label = "#{model.model_name.human} ##{record.id} #{record.name.inspect}"
      report(label, clean_record(model, record))
    end
  end

  def clean_record(model, record)
    twin = model.find_by(name: record.name.strip)
    if twin.nil?
      record.update!(name: record.name.strip)
      'umbenannt'
    elsif (blockers = blocking_references(model, record)).any?
      "übersprungen, wird noch verwendet von: #{blockers.join(', ')}"
    else
      merge(model, record, twin)
      "zusammengeführt mit ##{twin.id}"
    end
  end

  def padded(model)
    model.where("name <> btrim(name, E' \\t\\r\\n')").order(:id)
  end

  def blocking_references(model, record)
    BLOCKING[model].select { |association| record.public_send(association).exists? }
  end

  def merge(model, record, twin)
    MERGEABLE[model].each do |association|
      references = record.public_send(association)
      foreign_key = record.association(association).reflection.foreign_key
      changes = { foreign_key => twin.id }
      # Calculatable caches notice changes through updated_at.
      changes[:updated_at] = Time.current if references.klass.column_names.include?('updated_at')
      references.update_all(changes) # rubocop:disable Rails/SkipsModelValidations
    end
    record.reload.destroy!
  end

  def report(label, outcome)
    @log.puts "#{'[Probelauf] ' unless @apply}#{label}: #{outcome}"
  end
end
