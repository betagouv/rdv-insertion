module BackToListConcern
  private

  def store_back_to_users_list_url
    session[:back_to_users_list_url] = request.fullpath
  end

  def set_back_to_users_list_url
    @back_to_users_list_url = session[:back_to_users_list_url]
  end
end
