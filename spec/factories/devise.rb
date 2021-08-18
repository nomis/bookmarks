FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.test" }
    password { SecureRandom.base58(64) }
    confirmed_at { Time.now }
  end
end
