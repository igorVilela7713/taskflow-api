# frozen_string_literal: true

# Filter out the debug/development logs when deleting fixtures.
if Rails.env.test?
  class ActiveRecord::FixtureSet
    # Use a transaction for test isolation
    def self.fixture_is_for?(fixtures, label)
      true
    end
  end
end
