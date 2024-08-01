module FollowUps
  class ClosingsController < ApplicationController
    wrap_parameters false
    before_action :set_follow_up, only: [:create, :destroy]

    def create
      authorize @follow_up, :close?
      if close_follow_up.success?
        redirect_to structure_user_follow_ups_path(user_id: @follow_up.user_id)
      else
        turbo_stream_display_error_modal(@follow_up.errors.full_messages)
      end
    end

    def destroy
      authorize @follow_up, :reopen?
      if @follow_up.update(closed_at: nil)
        redirect_to structure_user_follow_ups_path(user_id: @follow_up.user_id)
      else
        turbo_stream_display_error_modal(@follow_up.errors.full_messages)
      end
    end

    private

    def close_follow_up
      @close_follow_up ||= FollowUps::Close.call(follow_up: @follow_up)
    end

    def set_follow_up
      @follow_up = FollowUp.find(closing_params[:follow_up_id])
    end

    def closing_params
      params.permit(:follow_up_id)
    end
  end
end
