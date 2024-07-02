module TagsHelper
  def user_tag_creation_date(tag, user)
    user.tag_users.find { |tag_user| tag_user.tag_id == tag.id }
        .created_at.strftime("%d/%m/%Y")
  end
end
