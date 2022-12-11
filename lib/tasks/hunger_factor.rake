namespace :hunger_factor do
  desc 'imports hunger factors from huf.csv'
  task import: :environment do
    hunger_factors = CSV.read('data/huf.csv', headers: true).map do |huf|
      {
        age: huf['age'],
        factor: huf['avg']
      }
    end
    HungerFactor.upsert_all(hunger_factors, unique_by: :age)
    puts "Imported #{hunger_factors.size} HungerFactors"
  end
end
