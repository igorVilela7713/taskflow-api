# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :tasks, dependent: :destroy

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 100 }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  # Callbacks
  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
