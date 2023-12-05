module NavigationHelper
  def structure_id_param
    department_level? ? { department_id: Current.department_id } : { organisation_id: Current.organisation_id }
  end

  def structure_users_path(**params)
    send(:"#{structure_type}_users_path", { **structure_id_param, **params.compact_blank })
  end

  def structure_configurations_positions_update_path
    send(:"#{structure_type}_configurations_positions_update_path", structure_id_param)
  end

  def edit_structure_user_path(user_id)
    send(:"edit_#{structure_type}_user_path", { id: user_id, **structure_id_param })
  end

  def structure_user_path(user_id, **params)
    send(:"#{structure_type}_user_path", { id: user_id, **structure_id_param, **params })
  end

  def new_structure_user_path
    send(:"new_#{structure_type}_user_path")
  end

  def new_structure_upload_path(**params)
    send(:"new_#{structure_type}_upload_path", **params)
  end

  def uploads_category_selection_structure_users_path(**params)
    send(:"uploads_category_selection_#{structure_type}_users_path", **params)
  end

  def structure_user_invitations_path(user_id)
    send(:"#{structure_type}_user_invitations_path", { user_id: })
  end

  def structure_user_tag_assignations_path(user_id)
    send(:"#{structure_type}_user_tag_assignations_path", { user_id: })
  end
end
