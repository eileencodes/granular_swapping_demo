class MealsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    default: { writing: :meals_default, reading: :meals_default_replica },
    one: { writing: :meals_one, reading: :meals_one_replica },
    two: { writing: :meals_two, reading: :meals_two_replica }
  }
end
