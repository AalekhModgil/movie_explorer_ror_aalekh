AdminUser.delete_all
User.delete_all

AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?

User.create!(
  name: 'Test User',
  email: 'user@example.com',
  password: 'password',
  mobile_number: '1234567890',
  role: 'user'
)

User.create!(
  name: 'Test Supervisor',
  email: 'supervisor@example.com',
  password: 'password',
  mobile_number: '0987654321',
  role: 'supervisor'
)