module Users::Sortable
  def order_users
    if archived_scope?
      archived_order
    elsif @current_motif_category
      order_by_follow_ups
    else
      order_by_created_at
    end
  end

  def archived_order
    @users = @users.order("archives.created_at desc")
  end

  def order_by_follow_ups
    @users = @users.select("users.*, follow_ups.created_at")
                   .order("follow_ups.created_at desc")
  end

  def order_by_created_at
    @users = @users.select("users.*, MIN(users_organisations.created_at) AS min_created_at")
                   .group("users.id")
                   .order("min_created_at DESC")
  end
end
