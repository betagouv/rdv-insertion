module Users::Archivable
  private

  def archived_user_ids_in_organisations(organisations)
    users_with_archives_in_all_their_organisations_in_list(organisations).map(&:id)
  end

  def users_with_archives_in_all_their_organisations_in_list(organisations)
    organisation_ids = organisations.map(&:id)
    user_organisation_count_subquery = user_organisation_count_subquery(organisation_ids)

    User.joins(:archives)
        .where(archives: { organisation_id: organisation_ids })
        .group("users.id")
        .having(
          "COUNT(DISTINCT archives.organisation_id) = " \
          "(SELECT organisation_count FROM (#{user_organisation_count_subquery.to_sql}) " \
          "AS user_organisation_counts WHERE user_organisation_counts.user_id = users.id)"
        )
  end

  def user_organisation_count_subquery(organisation_ids)
    Organisation.joins(:users)
                .where(id: organisation_ids)
                .select("users.id AS user_id", "COUNT(DISTINCT organisations.id) AS organisation_count")
                .group("users.id")
  end
end
