# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    status { :pending }
    priority { :medium }
    due_date { Faker::Date.forward(days: 30) }
    user
  end
end
