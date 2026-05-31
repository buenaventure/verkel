# frozen_string_literal: true

require_relative 'seeds/helpers'
include Seeds::Helpers

Rake::Task['hunger_factor:import'].invoke

find_or_create_user!(email: 'admin@example.com', password: 'admin', role: :admin)
find_or_create_user!(email: 'buero@example.com', password: 'buero', role: :office)

spaghetti = Ingredient.create!(name: 'Spaghetti', uses_hunger_factor: true)
pesto = Ingredient.create!(name: 'Pesto, grün')
recipe = Recipe.create!(name: 'Spaghetti mit Pesto', content: <<~CONTENT)
  **125 g Spaghetti** in sprudelnd kochendes, gesalzenes Wasser geben.
  Nach circa 7 Minuten abgießen und mit **50 g Pesto, grün** anrichten.
CONTENT
meal = Meal.create!(recipe:, datetime: Time.zone.now.middle_of_day + 1.month)

packing_lane = PackingLane.create!(name: 'Tiere des Waldes')
group_fuchs = Group.create!(name: 'Test-Kochgruppe', internal_name: 'Fuchs', packing_lane:)
create_group_participants!(group: group_fuchs, meal:, ages: [12, 14])

group_hase = Group.create!(name: 'Test-Kochgruppe 2', internal_name: 'Hase', packing_lane:)
group_uhu = Group.create!(name: 'Test-Kochgruppe 3', internal_name: 'Uhu', packing_lane:)

supplier = Supplier.create!(name: 'Supermarkt', email: 'super.markt@example.com', phone: '0123456789')
upsert_article!(ingredient: spaghetti, supplier:, quantity: 500, unit: 'g', packing_type: :piece, price: 1.89)
upsert_article!(ingredient: pesto, supplier:, quantity: 200, unit: 'g', packing_type: :piece, price: 2.49)

rice = find_or_create_ingredient!(name: 'Reis, Langkorn')
tomato = find_or_create_ingredient!(name: 'Tomaten, passiert')
upsert_article!(ingredient: rice, supplier:, quantity: 1, unit: 'kg', packing_type: :piece, price: 3.20)
upsert_article!(ingredient: tomato, supplier:, quantity: 500, unit: 'g', packing_type: :piece, price: 1.15)

create_group_participants!(group: group_hase, meal:, ages: [10, 12])
create_group_participants!(group: group_uhu, meal:, ages: [9, 11])

curry = Recipe.create!(name: 'Gemüsecurry mit Reis', content: <<~CONTENT)
  **200 g Reis, Langkorn** kochen.
  Mit **400 g Tomaten, passiert** und Gewürzen zu einem Curry verrühren.
CONTENT
curry_meal = Meal.create!(recipe: curry, datetime: meal.datetime + 2.days)
[group_hase, group_uhu].each do |group|
  GroupMealParticipation.create!(group:, meal: curry_meal, participant: group.participants.first!)
end

Box.create!(datetime: meal.datetime - 3.hours)
Box.create!(datetime: meal.datetime - 2.days)
Box.create!(datetime: meal.datetime - 1.day)
Box.create!(datetime: meal.datetime + 1.day)
Order.create!(supplier:, coverage: (Time.zone.now.beginning_of_day + 3.weeks..Time.zone.now.end_of_day + 1.month))

recalculate!

Box.order(:datetime).first!.update!(status: :packed)
