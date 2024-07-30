class UsersOrganisationsController < ApplicationController
  before_action :set_user, :set_department, :set_organisations, :set_user_archives,
                only: [:index, :create, :destroy]
  before_action :set_user_organisations, only: [:index]
  before_action :set_organisation_to_add, :assign_motif_category, only: [:create]
  before_action :set_organisation_to_remove, :verify_user_is_sync_with_rdv_solidarites, only: [:destroy]

  def index
    @assignable_organisations = @organisations.where.not(id: @user.organisations.ids)
  end

  def create
    if save_user.success?
      flash.now[:success] = "L'organisation a bien été ajoutée"
    else
      flash.now[:error] = "Une erreur s'est produite lors de l'ajout de l'organisation: #{save_user.errors}"
    end
  end

  def destroy
    if remove_user_from_org.success?
      flash.now[:success] = "L'organisation a bien été retirée"

      if user_deleted_or_removed_from_current_org?
        turbo_stream_redirect(session[:back_to_users_list_url] || structure_users_path)
      else
        redirect_to(structure_user_path(@user.id), status: :see_other)
      end
    else
      turbo_stream_display_error_modal(remove_user_from_org.errors)
    end
  end

  private

  def users_organisation_params
    params.require(:users_organisation).permit(:organisation_id, :user_id)
  end

  def user_id
    params[:user_id] || users_organisation_params[:user_id]
  end

  def set_user
    @user = policy_scope(User).preload(:archives).find(user_id)
  end

  def set_department
    @department = current_department
  end

  def set_organisation_to_add
    @organisation_to_add = @department.organisations.find(users_organisation_params[:organisation_id])
  end

  def set_organisation_to_remove
    @organisation_to_remove = @department.organisations.find(users_organisation_params[:organisation_id])
  end

  def set_organisations
    @organisations = @department.organisations.includes(:motif_categories)
  end

  def set_user_organisations
    @user_organisations = @user.reload.organisations
  end

  def redirect_to_department_user_path
    redirect_to(
      department_user_path(@department, @user),
      flash: { success: "L'organisation a bien été ajoutée" }
    )
  end

  def user_deleted_or_removed_from_current_org?
    @user.deleted? || @organisation_to_remove.id == current_organisation_id
  end

  def assign_motif_category
    return if params[:users_organisation]["motif_category_id_#{@organisation_to_add.id}"].blank?

    @user.assign_motif_category(params[:users_organisation]["motif_category_id_#{@organisation_to_add.id}"])
  end

  def verify_user_is_sync_with_rdv_solidarites
    sync_user_with_rdv_solidarites(@user) if @user.rdv_solidarites_user_id.nil?
  end

  def save_user
    @save_user ||= Users::Save.call(
      user: @user,
      organisation: @organisation_to_add
    )
  end

  def remove_user_from_org
    @remove_user_from_org ||= Users::RemoveFromOrganisation.call(
      user: @user,
      organisation: @organisation_to_remove
    )
  end

  def set_user_archives
    @user_archives = @user.archives
  end
end
