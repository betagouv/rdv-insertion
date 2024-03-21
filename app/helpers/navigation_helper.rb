module NavigationHelper
  def structure_id_param
    department_level? ? { department_id: Current.department_id } : { organisation_id: Current.organisation_id }
  end

  def structure_users_path(**params)
    send(:"#{Current.structure_type}_users_path", { **structure_id_param, **params.compact_blank })
  end

  def structure_category_configurations_positions_update_path
    send(:"#{Current.structure_type}_category_configurations_positions_update_path", structure_id_param)
  end

  def edit_structure_user_path(user_id)
    send(:"edit_#{Current.structure_type}_user_path", { id: user_id, **structure_id_param })
  end

  def structure_user_path(user_id, **params)
    send(:"#{Current.structure_type}_user_path", { id: user_id, **structure_id_param, **params })
  end

  def new_structure_user_path
    send(:"new_#{Current.structure_type}_user_path", **structure_id_param)
  end

  def new_structure_upload_path(**params)
    send(:"new_#{Current.structure_type}_upload_path", { **structure_id_param, **params })
  end

  def uploads_category_selection_structure_users_path(**params)
    send(:"uploads_category_selection_#{Current.structure_type}_users_path", { **structure_id_param, **params })
  end

  def structure_user_invitations_path(user_id)
    send(:"#{Current.structure_type}_user_invitations_path", { user_id:, **structure_id_param })
  end

  def structure_user_tag_assignations_path(user_id)
    send(:"#{Current.structure_type}_user_tag_assignations_path", { user_id:, **structure_id_param })
  end

  def structure_user_rdv_contexts_path(user_id, **params)
    send(:"#{Current.structure_type}_user_rdv_contexts_path", { user_id:, **structure_id_param, **params })
  end

  def new_structure_batch_action_path(motif_category_id)
    send(:"new_#{Current.structure_type}_batch_action_path", { **structure_id_param, motif_category_id: })
  end
end
