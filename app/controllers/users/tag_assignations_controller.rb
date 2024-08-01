module Users
  class TagAssignationsController < ApplicationController
    include Users::Taggable

    before_action :set_available_tags, :set_user, :set_user_tags

    def index; end

    def create
      @user.tags << @available_tags.where(id: tag_assignation_params[:tag_ids])
      redirect_to structure_user_path(@user.id)
    end

    def destroy
      @user.tags.delete(tag)
      redirect_to structure_user_path(@user.id)
    end

    private

    def set_available_tags
      @available_tags =
        if department_level?
          policy_scope(department.tags).order(Arel.sql("LOWER(tags.value)")).group("tags.id")
        else
          organisation.tags.order(Arel.sql("LOWER(tags.value)"))
        end
    end

    def set_user
      @user = policy_scope(User).includes(:tags).find(params[:user_id])
    end

    def tag_assignation_params
      params.require(:tag_assignation).permit(tag_ids: [])
    end

    def department
      @department ||= current_department
    end

    def organisation
      @organisation ||= current_organisation
    end

    def tag
      @available_tags.find(params[:tag_id])
    end
  end
end
