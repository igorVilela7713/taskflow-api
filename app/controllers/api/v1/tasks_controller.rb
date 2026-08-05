# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      def index
        tasks = current_user.tasks

        tasks = apply_filters(tasks)
        tasks = apply_sorting(tasks)

        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 20).to_i, 100].min

        total = tasks.count
        tasks = tasks.offset((page - 1) * per_page).limit(per_page)

        render json: {
          tasks: tasks.map { |task| TaskSerializer.new(task).as_json },
          meta: {
            current_page: page,
            per_page: per_page,
            total_count: total,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end

      def create
        task = current_user.tasks.build(task_params)

        if task.save
          TaskNotificationJob.perform_async(task.id, "created")
          render json: TaskSerializer.new(task).as_json, status: :created
        else
          render json: {
            error: {
              code: "UNPROCESSABLE_ENTITY",
              message: "Validation failed",
              details: task.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      def show
        task = current_user.tasks.find(params[:id])
        render json: TaskSerializer.new(task).as_json
      end

      def update
        task = current_user.tasks.find(params[:id])

        if task.update(task_params)
          TaskNotificationJob.perform_async(task.id, "updated")
          render json: TaskSerializer.new(task).as_json
        else
          render json: {
            error: {
              code: "UNPROCESSABLE_ENTITY",
              message: "Validation failed",
              details: task.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        task = current_user.tasks.find(params[:id])
        task.destroy!

        render json: { message: "Task deleted successfully" }, status: :ok
      end

      private

      def task_params
        params.require(:task).permit(:title, :description, :status, :priority, :due_date)
      end

      def apply_filters(tasks)
        tasks = tasks.where(status: params[:status]) if params[:status].present?
        tasks = tasks.where(priority: params[:priority]) if params[:priority].present?
        tasks = tasks.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        tasks = tasks.where("due_date >= ?", params[:due_after]) if params[:due_after].present?
        tasks = tasks.where("due_date <= ?", params[:due_before]) if params[:due_before].present?
        tasks
      end

      def apply_sorting(tasks)
        sort_field = %w[created_at updated_at priority due_date title].include?(params[:sort]) ? params[:sort] : "created_at"
        order = params[:order] == "asc" ? :asc : :desc

        tasks.order(sort_field => order)
      end
    end
  end
end
