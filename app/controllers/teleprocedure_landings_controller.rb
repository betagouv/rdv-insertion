# Where the bRSA lands after his teleprocedure online

class TeleprocedureLandingsController < ApplicationController
  skip_before_action :authenticate_agent!

  def show
    @department = Department.find_by!(number: params[:department_number])
  end
end
