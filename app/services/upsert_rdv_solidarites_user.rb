class UpsertRdvSolidaritesUser < BaseService
  def initialize(user:, organisation:, rdv_solidarites_session:)
    @user = user
    @organisation = organisation
    @rdv_solidarites_session = rdv_solidarites_session
  end

  def call
    upsert_rdv_solidarites_user
    result.rdv_solidarites_user_id = rdv_solidarites_user_id
  end

  private

  def rdv_solidarites_user_id
    @user.rdv_solidarites_user_id || user_id_from_email_taken_error || create_rdv_solidarites_user.user.id
  end

  def upsert_rdv_solidarites_user
    @user.rdv_solidarites_user_id.present? ? assign_to_org_and_update : create_or_update_rdv_solidarites_user
  end

  def create_or_update_rdv_solidarites_user
    return if create_rdv_solidarites_user.success?

    # If the user already exists in RDV-S, we check if he is in RDVI. If not we assign the user to the org
    # by creating the user profile and we then update the user.
    return assign_to_org_and_update if email_taken_error?

    result.errors += create_rdv_solidarites_user.errors
    fail!
  end

  def assign_to_org_and_update
    create_user_profile unless user_belongs_to_org?
    update_rdv_solidarites_user
  end

  def user_id_from_email_taken_error
    create_rdv_solidarites_user.error_details&.dig("email")&.first&.dig("id")
  end

  def email_taken_error?
    create_rdv_solidarites_user.error_details&.dig("email")&.any? { _1["error"] == "taken" }
  end

  def create_user_profile
    @create_user_profile ||= call_service!(
      RdvSolidaritesApi::CreateUserProfile,
      user_id: rdv_solidarites_user_id,
      organisation_id: @organisation.rdv_solidarites_organisation_id,
      rdv_solidarites_session: @rdv_solidarites_session
    )
  end

  def user_belongs_to_org?
    retrieve_organisation_user.user.present?
  end

  def retrieve_organisation_user
    @retrieve_organisation_user ||= RdvSolidaritesApi::RetrieveUser.call(
      rdv_solidarites_user_id: rdv_solidarites_user_id,
      rdv_solidarites_organisation_id: @organisation.rdv_solidarites_organisation_id,
      rdv_solidarites_session: @rdv_solidarites_session
    )
  end

  def create_rdv_solidarites_user
    @create_rdv_solidarites_user ||= RdvSolidaritesApi::CreateUser.call(
      user_attributes: rdv_solidarites_user_attributes.merge(organisation_ids: rdv_solidarites_organisation_ids),
      rdv_solidarites_session: @rdv_solidarites_session
    )
  end

  def rdv_solidarites_organisation_ids
    return @user.organisations.map(&:rdv_solidarites_organisation_id) if @user.organisations.present?

    [@organisation.rdv_solidarites_organisation_id]
  end

  def update_rdv_solidarites_user
    @update_rdv_solidarites_user ||= call_service!(
      RdvSolidaritesApi::UpdateUser,
      user_attributes: rdv_solidarites_user_attributes,
      rdv_solidarites_session: @rdv_solidarites_session,
      rdv_solidarites_user_id: rdv_solidarites_user_id
    )
  end

  def rdv_solidarites_user_attributes
    user_attributes = @user.attributes
                           .symbolize_keys
                           .slice(*User::SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES)
                           .transform_values(&:presence)
                           .compact
    user_attributes.delete(:email) if @user.conjoint?
    user_attributes
  end
end
