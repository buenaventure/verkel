namespace :testdata do
  desc 'generates testdata'
  task :generate, %i[num_groups participants_per_group offset] => :environment do |_t, args|
    raise 'Missing num_groups argument' unless args.num_groups
    raise 'Missing participants_per_group argument' unless args.participants_per_group

    offset = args.offset.to_i || 0
    Participant.insert_all(
      Group.insert_all(
        (1..args.num_groups.to_i).map { { name: format('Kochgruppe #%02d', it + offset) } },
        unique_by: :name, returning: :id
      ).map do |g|
        group_id = g['id']
        (1..args.participants_per_group.to_i).map { { group_id:, age: 12 } } # at this age factor is 1
      end.flatten
    )
  end

  desc 'clean'
  task clean: :environment do
    Participant.delete_all
    Group.delete_all
  end
end
