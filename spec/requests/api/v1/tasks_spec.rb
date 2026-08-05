# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JwtService.encode(user_id: user.id)}" } }

  describe "GET /api/v1/tasks" do
    before { create_list(:task, 5, user: user) }

    it "returns all tasks for the authenticated user" do
      get "/api/v1/tasks", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tasks"].length).to eq(5)
      expect(json["meta"]["total_count"]).to eq(5)
    end

    it "returns tasks filtered by status" do
      create(:task, user: user, status: :completed)
      get "/api/v1/tasks", params: { status: "completed" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tasks"].length).to eq(1)
    end

    it "returns tasks filtered by priority" do
      create(:task, user: user, priority: :high)
      get "/api/v1/tasks", params: { priority: "high" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tasks"].length).to eq(1)
    end

    it "returns paginated results" do
      get "/api/v1/tasks", params: { page: 1, per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tasks"].length).to eq(2)
      expect(json["meta"]["per_page"]).to eq(2)
      expect(json["meta"]["current_page"]).to eq(1)
    end

    it "returns 401 without authentication" do
      get "/api/v1/tasks"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/tasks" do
    let(:valid_params) do
      {
        task: {
          title: "Test Task",
          description: "Test Description",
          priority: "high",
          status: "pending"
        }
      }
    end

    it "creates a new task" do
      post "/api/v1/tasks", params: valid_params, headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["task"]["title"]).to eq("Test Task")
      expect(json["task"]["priority"]).to eq("high")
    end

    it "returns 422 with invalid params" do
      post "/api/v1/tasks", params: { task: { title: "" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]["message"]).to eq("Validation failed")
    end

    it "returns 401 without authentication" do
      post "/api/v1/tasks", params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/tasks/:id" do
    let(:task) { create(:task, user: user) }

    it "returns the task" do
      get "/api/v1/tasks/#{task.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["task"]["id"]).to eq(task.id)
    end

    it "returns 404 for non-existent task" do
      get "/api/v1/tasks/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without authentication" do
      get "/api/v1/tasks/#{task.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    let(:task) { create(:task, user: user) }

    it "updates the task" do
      patch "/api/v1/tasks/#{task.id}",
            params: { task: { title: "Updated Title" } },
            headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["task"]["title"]).to eq("Updated Title")
    end

    it "returns 422 with invalid params" do
      patch "/api/v1/tasks/#{task.id}",
            params: { task: { title: "" } },
            headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for non-existent task" do
      patch "/api/v1/tasks/999999",
            params: { task: { title: "Updated" } },
            headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    let!(:task) { create(:task, user: user) }

    it "deletes the task" do
      delete "/api/v1/tasks/#{task.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(Task.find_by(id: task.id)).to be_nil
    end

    it "returns 404 for non-existent task" do
      delete "/api/v1/tasks/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
