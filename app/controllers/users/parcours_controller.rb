module Users
  class ParcoursController < ApplicationController
    before_action :set_user, :set_department, :set_back_to_users_list_url, only: [:show]

    include BackToListConcern

    def show
      @orientations = @user.orientations.includes(:agent, :organisation).order(starts_at: :asc)
    end

    private

    def set_department
      @department = policy_scope(Department).find(current_department_id)
      authorize(@department, :parcours?)
    end

    def set_user
      @user = policy_scope(User).preload(:archives).find(params[:user_id])
    end
  end
end
