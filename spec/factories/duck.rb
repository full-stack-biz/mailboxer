# frozen_string_literal: true

FactoryGirl.define do
  factory :duck do
    sequence :name do |n|
      "Duck #{n}"
    end
    sequence :email do |n|
      "duck#{n}@duck.com"
    end
  end
end
