class StatsController < ApplicationController
  skip_before_action :authenticate_agent!, only: [:index, :show, :deployment_map]
  before_action :set_organisation, :set_department, :set_stat, :set_display_all_stats, only: [:show]

  def index
    @department_count = Department.displayed_in_stats.count
    @stat = Stat.find_by(statable_type: "Department", statable_id: nil)
    @scope = Department.new
  end

  def show
    @scope = @organisation || @department
  end

  def deployment_map; end

  private

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id]) if params[:organisation_id]
  end

  def set_department
    @department = @organisation&.department || Department.find(params[:department_id])
  end

  def set_stat
    @stat = Stat.find_by(statable: @organisation || @department)
  end

  def set_display_all_stats
    @display_all_stats = @department.configurations.none? { |configuration| configuration.invitation_formats.blank? }
  end
end
