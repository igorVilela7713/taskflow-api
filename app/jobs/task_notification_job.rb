# frozen_string_literal: true

class TaskNotificationJob
  include Sidekiq::Job

  sidekiq_options queue: :notifications, retry: 3, backtrace: true

  # Perform the notification job
  # @param task_id [Integer] the task ID
  # @param action [String] the action that triggered the notification
  def perform(task_id, action)
    task = Task.find(task_id)
    user = task.user

    # TODO: Implement actual notification logic
    # - Send email notification
    # - Send push notification
    # - Send webhook to external services

    Rails.logger.info(
      "[TaskNotificationJob] Task #{task_id} (#{task.title}) - Action: #{action} - User: #{user.email}"
    )

    case action
    when "created"
      notify_task_created(task, user)
    when "updated"
      notify_task_updated(task, user)
    when "status_changed"
      notify_status_changed(task, user)
    else
      Rails.logger.warn("[TaskNotificationJob] Unknown action: #{action}")
    end
  end

  private

  def notify_task_created(task, user)
    # TODO: Send "task created" notification
    Rails.logger.info("[TaskNotification] Sending 'task created' notification for task #{task.id} to #{user.email}")
  end

  def notify_task_updated(task, user)
    # TODO: Send "task updated" notification
    Rails.logger.info("[TaskNotification] Sending 'task updated' notification for task #{task.id} to #{user.email}")
  end

  def notify_status_changed(task, user)
    # TODO: Send "status changed" notification
    Rails.logger.info("[TaskNotification] Sending 'status changed' notification for task #{task.id} to #{user.email}")
  end
end
