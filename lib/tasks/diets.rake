namespace :diets do
  desc 'imports diets.yml'
  task import: :environment do
    diets = SafeYAML.load_file('data/diets.yml')
    diets.each do |category, names|
      names.each do |name|
        diet = Diet.find_or_create_by(name:)
        diet.category = category
        diet.save!
      end
    end
  end
end
