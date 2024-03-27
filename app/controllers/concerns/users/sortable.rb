module Users::Sortable
  private

  def order_users
    if sort_by && sort_direction
      custom_order
    else
      default_order
    end
  end

  def custom_order
    return default_order unless sort_direction.in?(%w[asc desc]) && sort_by.in?(%w[first_name last_name])

    @users = @users.order("#{sort_by} #{sort_direction}")
  end

  def default_order
    if archived_scope?
      archived_order
    elsif @current_motif_category
      order_by_rdv_contexts
    else
      order_by_created_at
    end
  end

  def sort_direction
    params[:sort_direction]
  end

  def sort_by
    params[:sort_by]
  end

  def archived_order
    @users = @users.order("archives.created_at desc")
  end

  def order_by_rdv_contexts
    @users = @users.select("users.*, rdv_contexts.created_at")
                   .order("rdv_contexts.created_at desc")
  end

  def order_by_created_at
    @users = @users.select("users.*, MIN(users_organisations.created_at) AS min_created_at")
                   .group("users.id")
                   .order("min_created_at DESC")
  end
end
