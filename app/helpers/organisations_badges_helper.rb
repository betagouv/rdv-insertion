module OrganisationsBadgesHelper
  def css_classes_for_organisation_badge(archive)
    html_escape(
      "badge badge-tag justify-content-between text-dark-blue me-2 mb-2 d-flex text-truncate"
        .concat(archive.nil? ? " background-blue-light" : " background-warning")
    )
  end

  def tooltip_for_organisation_badge(archive)
    return if archive.nil?

    html_escape(
      "data-controller=tooltip " \
      "data-action=mouseover->tooltip#organisationArchiveInformations " \
      "data-archive-creation-date=#{format_date(archive.created_at)} " \
      "data-archive-reason=#{archive.archiving_reason} " \
      "data-show-archiving-reason=#{policy(archive).show?}"
    )
  end
end
