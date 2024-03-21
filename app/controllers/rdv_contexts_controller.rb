class RdvContextsController < ApplicationController
  PERMITTED_PARAMS = [:user_id, :motif_category_id].freeze

  before_action :set_user, only: [:create]

  def create
    @rdv_context = RdvContext.new(**rdv_context_params)
    authorize @rdv_context
    if save_rdv_context.success?
      respond_to do |format|
        # html is used for the show page
        format.html do
          redirect_to(structure_user_rdv_contexts_path(@user.id, anchor:))
        end
        format.turbo_stream { replace_new_button_cell_by_rdv_context_status_cell } # turbo is used for index page
      end
    else
      turbo_stream_display_error_modal(save_rdv_context.errors)
    end
  end

  private

  def rdv_context_params
    params.require(:rdv_context).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def set_user
    @user = policy_scope(User).preload(:archives).find(rdv_context_params[:user_id])
  end

  def save_rdv_context
    @save_rdv_context ||= RdvContexts::Save.call(rdv_context: @rdv_context)
  end

  def replace_new_button_cell_by_rdv_context_status_cell
    turbo_stream_replace(
      "user_#{@user.id}_motif_category_#{rdv_context_params[:motif_category_id]}",
      "rdv_context_status_cell",
      { rdv_context: @rdv_context, category_configuration: nil }
    )
  end

  def anchor
    "rdv_context_#{@rdv_context.id}"
  end
end
