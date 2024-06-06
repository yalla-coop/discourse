# frozen_string_literal: true

Fabricator(:user_password) do
  transient password: "myawesomefakepassword"

  user { Fabricate(:user) }
  password_salt { SecureRandom.hex(User::PASSWORD_SALT_LENGTH) }
  password_algorithm { User::TARGET_PASSWORD_ALGORITHM }

  after_build do |user_password, transients|
    user_password.password_hash =
      PasswordHasher.hash_password(
        password: transients[:password],
        salt: user_password.password_salt,
        algorithm: user_password.password_algorithm,
      )
  end
end

Fabricator(:expired_user_password, from: :user_password) { password_expired_at { 1.day.ago } }
