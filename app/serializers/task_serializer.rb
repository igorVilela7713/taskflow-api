# frozen_string_literal: true

class TaskSerializer
  def initialize(task)
    @task = task
  end

  def as_json
    {
      id: @task.id,
      title: @task.title,
      description: @task.description,
      status: @task.status,
      priority: @task.priority,
      due_date: @task.due_date,
      completed_at: @task.completed_at,
      created_at: @task.created_at,
      updated_at: @task.updated_at,
      user: {
        id: @task.user.id,
        email: @task.user.email,
        name: @task.user.name
      }
    }
  end
end
