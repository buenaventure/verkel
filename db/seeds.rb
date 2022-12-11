# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Rake::Task['hunger_factor:import'].invoke
User.create!(email: 'admin@example.com', password: 'admin', role: :admin)

spaghetti = Ingredient.create!(name: 'Spaghetti', uses_hunger_factor: true)
pesto = Ingredient.create!(name: 'Pesto, grün')
recipe = Recipe.create!(name: 'Spaghetti mit Pesto', content: <<~CONTENT
  **125 g Spaghetti** in sprudelnd kochendes, gesalzenes Wasser geben.
  Nach circa 7 Minuten abgießen und mit **50 g Pesto, grün** anrichten.
CONTENT
)
meal = Meal.create!(recipe:, datetime: Time.zone.now.middle_of_day + 1.month)

packing_lane = PackingLane.create!(name: 'Tiere des Waldes')
group = Group.create!(name: 'Test-Kochgruppe', internal_name: 'Fuchs', packing_lane:)
p1 = Participant.create!(age: 12, group:)
p2 = Participant.create!(age: 14, group:)
GroupMealParticipation.create!(group:, meal:, participant: p1)
GroupMealParticipation.create!(group:, meal:, participant: p2)

supplier = Supplier.create!(name: 'Supermarkt')
Article.create!(ingredient: spaghetti, supplier:, quantity: 500, unit: 'g', packing_type: :piece)
Article.create!(ingredient: pesto, supplier:, quantity: 200, unit: 'g', packing_type: :piece)

Box.create!(datetime: Time.zone.now.middle_of_day - 3.hours + 1.month)
Order.create!(supplier:, coverage: (Time.zone.now.beginning_of_day + 3.weeks..Time.zone.now.end_of_day + 1.month))

GroupBoxIngredientUnitCache.refresh
ArticlePackingPlanner.new.run
