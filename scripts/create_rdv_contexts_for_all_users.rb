# rails runner scripts/create_follow_ups_for_all_users.rb

puts "Assigning contexts..."
puts "-----"
puts
User.find_each do |user|
  puts "Assigning to user #{user.id}..."
  motif_categories = user.organisations.flat_map(&:motif_categories).uniq
  motif_categories.each do |motif_category|
    FollowUp.find_or_create_by!(user: user, motif_category: motif_category)
  end
end
puts "-----"
puts
puts "Contexts assigned!"
