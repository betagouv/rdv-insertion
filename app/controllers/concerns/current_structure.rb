module CurrentStructure
  extend ActiveSupport::Concern

  included do
    helper_method :current_structure_type, :department_level?,
                  :current_structure, :current_structure_name, :current_structure_id,
                  :current_department, :current_department_name, :current_department_id,
                  :current_organisation, :current_organisation_id,
                  :current_agent_department_organisations

    delegate :name, to: :current_structure, prefix: true
    delegate :name, to: :current_department, prefix: true
  end

  def current_structure_type
    @current_structure_type ||=
      if params[:department_id].nil? && params[:organisation_id].nil?
        nil
      elsif params[:organisation_id].present?
        "organisation"
      else
        "department"
      end
  end

  def department_level?
    current_structure_type == "department"
  end

  def current_organisation_id
    @current_organisation_id ||= params[:organisation_id].to_i if current_structure_type == "organisation"
  end

  def current_department_id
    @current_department_id ||= department_level? ? params[:department_id].to_i : current_department&.id
  end

  def current_structure_id = current_organisation_id || current_department_id

  def current_structure
    return unless params[:department_id] || params[:organisation_id]

    @current_structure ||=
      department_level? ? Department.find(current_department_id) : Organisation.find(current_organisation_id)

    authorize @current_structure, :access?
  end

  def current_department
    return unless current_structure

    @current_department ||=
      department_level? ? current_structure : current_structure.department
  end

  def current_organisation
    return if department_level?

    @current_organisation ||= current_structure
  end

  def current_agent_department_organisations
    return unless current_agent && current_department

    @current_agent_department_organisations ||= current_agent.department_organisations(current_department_id)
  end

  def current_organisation_ids
    @current_organisation_ids ||=
      department_level? ? current_department.organisation_ids : [current_organisation_id]
  end

  def current_organisations_filter
    if department_level?
      { organisations: { department_id: current_department_id } }
    else
      { organisations: [current_organisation_id] }
    end
  end

  def current_organisation_filter
    if department_level?
      { organisation: { department_id: current_department_id } }
    else
      { organisation_id: current_organisation_id }
    end
  end
end
