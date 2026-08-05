# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :user

  # Enums
  enum status: { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :priority, presence: true, inclusion: { in: priorities.keys }
  validates :due_date, comparison: { greater_than: -> { Date.current } }, allow_nil: true

  # Scopes
  scope :active, -> { where.not(status: %w[completed cancelled]) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :overdue, -> { where("due_date < ? AND status != ?", Date.current, statuses[:completed]) }
  scope :due_soon, ->(days = 3) { where("due_date <= ? AND due_date >= ? AND status != ?", Date.current + days, Date.current, statuses[:completed]) }

  # Callbacks
  after_save :set_completed_at, if: -> { saved_change_to_status? && completed? }

  private

  def set_completed_at
    update_column(:completed_at, Time.current)
  end
end
