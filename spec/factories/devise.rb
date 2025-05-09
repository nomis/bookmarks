FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.test" }
    password { SecureRandom.base58(64) }
    confirmed_at { Time.now }
  end

  factory :public_user, parent: :user do
    visibility { :public }
  end

  factory :private_user, parent: :user do
    visibility { :private }
  end

  factory :secret_user, parent: :user do
    visibility { :secret }
  end
end
