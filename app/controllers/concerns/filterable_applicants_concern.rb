module FilterableApplicantsConcern
  def filter_applicants
    filter_applicants_by_search_query
    filter_applicants_by_action_required
    filter_applicants_by_status
    filter_applicants_by_page
  end

  def filter_applicants_by_status
    return if params[:status].blank?

    @applicants = @applicants.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.status(params[:status]))
  end

  def filter_applicants_by_action_required
    return unless params[:action_required] == "true"

    @applicants = @applicants.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.action_required)
  end

  def filter_applicants_by_search_query
    return if params[:search_query].blank?

    # with_pg_search_rank scope added to be compatible with distinct https://github.com/Casecommons/pg_search/issues/238
    @applicants = @applicants.search_by_text(params[:search_query]).with_pg_search_rank
  end

  def filter_applicants_by_page
    return if request.format == "csv"

    @applicants = @applicants.page(page)
  end
end
