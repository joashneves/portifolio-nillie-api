puts "Criando usuario admin..."

admin = User.find_or_create_by!(username: "admin") do |u|
  u.password = "admin123"
  u.password_confirmation = "admin123"
  u.admin = true
end

puts "Admin criado com sucesso!"
puts "  Username: admin"
puts "  Password: admin123"
