module Users
  class Save < BaseService
    def initialize(user:, organisation:, rdv_solidarites_session:)
      @user = user
      @organisation = organisation
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      User.transaction do
        assign_organisation
        validate_user!
        save_record!(@user)
        upsert_rdv_solidarites_user
        if @user.rdv_solidarites_user_id.nil?
          assign_rdv_solidarites_user_id
          assign_referents if @user.referents.present?
        end
      end
    end

    private

    def assign_organisation
      @user.organisations = (@user.organisations.to_a + [@organisation]).uniq
    end

    def upsert_rdv_solidarites_user
      @upsert_rdv_solidarites_user ||= call_service!(
        UpsertRdvSolidaritesUser,
        user: @user,
        organisation: @organisation,
        rdv_solidarites_session: @rdv_solidarites_session
      )
    end

    def rdv_solidarites_organisation_ids
      return [@organisation.rdv_solidarites_organisation_id] if @organisation

      @user.organisations.map(&:rdv_solidarites_organisation_id)
    end

    def validate_user!
      call_service!(
        Users::Validate,
        user: @user
      )
    end

    def assign_rdv_solidarites_user_id
      @user.rdv_solidarites_user_id = upsert_rdv_solidarites_user.rdv_solidarites_user_id
      save_record!(@user)
    end

    def assign_referents
      @user.referents.each do |referent|
        call_service!(
          Users::AssignReferent,
          user: @user,
          agent: referent,
          rdv_solidarites_session: @rdv_solidarites_session
        )
      end
    end
  end
end
