class InviteUser < BaseService
  def initialize(
    user:, organisations:, invitation_attributes:, motif_category_attributes:, check_creneaux_availability: true
  )
    @user = user
    @organisations = organisations
    @invitation_attributes = invitation_attributes
    @motif_category_attributes = motif_category_attributes
    @check_creneaux_availability = check_creneaux_availability
  end

  def call
    set_current_configuration
    find_or_create_follow_up
    set_invitation_organisations
    set_invitation
    result.invitation = @invitation
    save_and_send_invitation!
  end

  private

  def set_invitation
    @invitation = Invitation.new(
      user: @user,
      department: department,
      organisations: @invitation_organisations,
      follow_up: @follow_up,
      # the validity of an invitation is equal to the number of days before an action is required,
      # then the organisation usually convene the user
      valid_until: @current_configuration.number_of_days_before_action_required.days.from_now,
      help_phone_number: @current_configuration.phone_number,
      rdv_with_referents: @current_configuration.rdv_with_referents,
      **@invitation_attributes
    )
  end

  def department
    @department ||= @organisations.first.department
  end

  def set_invitation_organisations
    @invitation_organisations =
      if @current_configuration.invite_to_user_organisations_only?
        @organisations & @user.unarchived_organisations
      else
        @organisations
      end
  end

  def find_or_create_follow_up
    FollowUp.with_advisory_lock "setting_follow_up_for_user_#{@user.id}" do
      @follow_up = FollowUp.find_or_create_by!(motif_category: @current_configuration.motif_category, user: @user)
    end
  end

  def motif_category
    @motif_category_attributes.present? ? MotifCategory.find_by!(@motif_category_attributes) : nil
  end

  def all_configurations
    @all_configurations ||= CategoryConfiguration.where(organisation: @organisations & @user.organisations).to_a
  end

  def set_current_configuration
    @current_configuration =
      if motif_category.nil?

        if all_configurations.length != 1
          fail!("Plusieurs catégories de motifs disponibles et aucune n'a été choisie")
          return
        end

        all_configurations.first
      else
        all_configurations.find { |c| c.motif_category_id == motif_category.id }
      end
  end

  def save_and_send_invitation!
    call_service!(
      Invitations::SaveAndSend,
      invitation: @invitation,
      check_creneaux_availability: @check_creneaux_availability
    )
  end
end
