class TagsController < ApplicationController
  before_action :set_organisation

  def create
    tag = Tag.joins(:tag_organisations).find_by(
      tag_organisations: { organisation_id: @organisation.department.organisation_ids },
      value: tag_params[:value]
    ) || Tag.create!(tag_params)

    @organisation.tags << tag

    render turbo_stream: turbo_stream.append("tags", partial: "tags/tag", locals: { tag: tag })
  end

  def destroy
    TagOrganisation.find_by(
      organisation_id: @organisation.id,
      tag_id: params[:id]
    ).destroy!

    Tag.find(params[:id]).destroy! unless @organisation.department.tags.exists?(id: params[:id])

    render turbo_stream: turbo_stream.remove("tag_#{params[:id]}")
  end

  private

  def set_organisation
    return if department_level?

    @organisation = policy_scope(Organisation).find(params[:organisation_id])
  end

  def tag_params
    params.require(:tag).permit(:value)
  end
end
