module Users
  class ReferentAssignationsController < ApplicationController
    before_action :set_department, :set_user, :set_agents, only: [:index, :create, :destroy]
    before_action :verify_user_is_sync_with_rdv_solidarites, :set_agent, only: [:create, :destroy]
    before_action :set_user_referents, only: [:index]

    def index; end

    def create
      if assign_referent.success?
        respond_to do |format|
          format.turbo_stream { redirect_to request.referer }
          format.json { render json: { success: true, user: @user } }
        end
      else
        respond_to do |format|
          format.turbo_stream { turbo_stream_display_error_modal(assign_referent.errors) }
          format.json { render json: { success: false }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      if remove_referent.success?
        redirect_to(request.referer)
      else
        turbo_stream_display_error_modal(remove_referent.errors)
      end
    end

    private

    def referent_assignation_params
      params.require(:referent_assignation).permit(:agent_email, :agent_id)
    end

    def agent_id
      params[:agent_id] || referent_assignation_params[:agent_id]
    end

    def agent_email
      referent_assignation_params[:agent_email]
    end

    def set_user
      @user = policy_scope(User).includes(:referents).find(params[:user_id])
    end

    def set_user_referents
      @user_referents = policy_scope(@user.referents).distinct
    end

    def verify_user_is_sync_with_rdv_solidarites
      sync_user_with_rdv_solidarites(@user) if @user.rdv_solidarites_user_id.nil?
    end

    def set_department
      @department = current_department
    end

    def set_agents
      @agents = Agent.joins(:organisations).where(
        organisations: @user.organisations.where(department: @department)
      ).with_last_name.distinct.order(:email)
      @agents = @agents.not_betagouv if production_env?
    end

    def assign_referent
      @assign_referent ||= Users::AssignReferent.call(user: @user, agent: @agent)
    end

    def remove_referent
      @remove_referent ||= Users::RemoveReferent.call(user: @user, agent: @agent)
    end

    def set_agent
      @agent =
        if agent_id.present?
          @agents.find(agent_id)
        elsif agent_email.present?
          @agents.find_by!(email: agent_email)
        else
          raise ActiveRecord::RecordNotFound
        end
    end
  end
end
