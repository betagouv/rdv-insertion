module Users
  class Upsert < BaseService
    def initialize(user_attributes:, organisation:, rdv_solidarites_session:)
      @user_attributes = user_attributes
      @organisation = organisation
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      @user = find_or_initialize_user.user
      result.user = @user
      @user.assign_attributes(**@user_attributes.compact_blank)
      save_user!
    end

    private

    def find_or_initialize_user
      @find_or_initialize_user ||= call_service!(
        Users::FindOrInitialize,
        attributes: @user_attributes,
        department_id: @organisation.department_id
      )
    end

    def save_user!
      call_service!(
        Users::Save,
        user: @user,
        organisation: @organisation,
        rdv_solidarites_session: @rdv_solidarites_session
      )
    end
  end
end
