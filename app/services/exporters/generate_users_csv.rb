# rubocop:disable Metrics/ClassLength
module Exporters
  class GenerateUsersCsv < Csv
    attr_reader :agent

    def initialize(user_ids:, agent:, structure: nil, motif_category_id: nil)
      @user_ids = user_ids
      @structure = structure
      @motif_category = motif_category_id.present? ? MotifCategory.find(motif_category_id) : nil
      @agent = agent
    end

    protected

    def department_level?
      @structure.instance_of?(Department)
    end

    def department_id
      department_level? ? @structure.id : @structure.department_id
    end

    def filename
      if @structure.present?
        "Export_#{resource_human_name}_#{@motif_category.present? ? "#{@motif_category.short_name}_" : ''}" \
          "#{@structure.class.model_name.human.downcase}_" \
          "#{@structure.name.parameterize(separator: '_')}.csv"
      else
        "Export_#{resource_human_name}_#{Time.zone.now.to_i}.csv"
      end
    end

    def resource_human_name
      "usagers"
    end

    def each_element(&)
      @users.each(&)
    end

    def preload_associations
      @users =
        if @motif_category
          User.preload(
            :archives, :organisations, :tags, :referents, :rdvs, :address_geocoding,
            participations: [:organisation, :follow_up],
            follow_ups: [:invitations, :motif_category, :notifications, { rdvs: [:motif, :participations, :users] }],
            orientations: [:orientation_type, :organisation]
          ).find(@user_ids)
        else
          User.preload(
            :invitations, :notifications, :archives, :organisations, :tags, :referents, :address_geocoding,
            follow_ups: [:motif_category, :participations, :rdvs],
            participations: [:organisation, :rdv, { follow_up: :motif_category }],
            rdvs: [:motif, :participations],
            orientations: [:orientation_type, :organisation]
          ).find(@user_ids)
        end
    end

    def headers # rubocop:disable Metrics/AbcSize
      [User.human_attribute_name(:title),
       User.human_attribute_name(:last_name),
       User.human_attribute_name(:first_name),
       User.human_attribute_name(:affiliation_number),
       User.human_attribute_name(:department_internal_id),
       User.human_attribute_name(:france_travail_id),
       User.human_attribute_name(:email),
       User.human_attribute_name(:address),
       User.human_attribute_name(:post_code),
       User.human_attribute_name(:city),
       User.human_attribute_name(:phone_number),
       User.human_attribute_name(:birth_date),
       User.human_attribute_name(:created_at),
       User.human_attribute_name(:rights_opening_date),
       User.human_attribute_name(:role),
       "Première invitation envoyée le",
       "Dernière invitation envoyée le",
       "Dernière convocation envoyée le",
       "Date du dernier RDV",
       "Heure du dernier RDV",
       "Motif du dernier RDV",
       "Nature du dernier RDV",
       "Dernier RDV pris en autonomie ?",
       "Dernier RDV pris le",
       Rdv.human_attribute_name(:status),
       *(FollowUp.human_attribute_name(:status) if @motif_category),
       "Rendez-vous d'orientation (RSA) honoré en - moins de 30 jours?",
       "Rendez-vous d'orientation (RSA) honoré en - moins de 15 jours?",
       "Date d'orientation",
       "Type d'orientation",
       "Date de début d'accompagnement",
       "Date de fin d'accompagnement",
       "Structure d'orientation",
       User.human_attribute_name(:referents),
       "Nombre d'organisations",
       "Nom des organisations",
       User.human_attribute_name(:tags),
       *(Archive.human_attribute_name(:created_at) unless department_level?),
       *(Archive.human_attribute_name(:archiving_reason) unless department_level?)]
    end

    def csv_row(user) # rubocop:disable Metrics/AbcSize
      [user.title,
       user.last_name,
       user.first_name,
       user.affiliation_number,
       user.department_internal_id,
       user.france_travail_id,
       user.email,
       user.address,
       user.geocoded_post_code,
       user.geocoded_city,
       user.phone_number,
       display_date(user.birth_date),
       display_date(user.created_at),
       display_date(user.rights_opening_date),
       user.role,
       display_date(first_invitation_date(user)),
       display_date(last_invitation_date(user)),
       display_date(last_notification_date(user)),
       display_date(last_rdv_starts_at(user)),
       display_time(last_rdv_starts_at(user)),
       last_rdv_motif(user),
       last_rdv_type(user),
       rdv_taken_in_autonomy?(user),
       display_date(last_participation_created_at(user)),
       human_last_participation_status(user),
       *(human_follow_up_status(user) if @motif_category),
       oriented_in_less_than_n_days?(user, 30),
       oriented_in_less_than_n_days?(user, 15),
       orientation_date(user),
       orientation_type(user),
       display_date(orientation_starts_at(user)),
       display_date(orientation_ends_at(user)),
       orientation_structure(user),
       user.referents.map(&:email).join(", "),
       user.organisations.to_a.count,
       display_organisation_names(user.organisations),
       scoped_user_tags(user.tags).pluck(:value).join(", "),
       *(display_date(user.organisation_archive(@structure)&.created_at) unless department_level?),
       *(user.organisation_archive(@structure)&.archiving_reason unless department_level?)]
    end

    def human_last_participation_status(user)
      return "" if last_participation(user).blank?

      last_participation(user).human_status
    end

    def human_follow_up_status(user)
      return "" if @motif_category.nil? || follow_up_for_export(user).nil?

      follow_up_for_export(user).human_status + display_follow_up_status_notice(follow_up_for_export(user))
    end

    def display_follow_up_status_notice(follow_up)
      if @structure.present? && follow_up.invited_before_time_window?(number_of_days_before_action_required) &&
         follow_up.invitation_pending?
        " (Délai dépassé)"
      else
        ""
      end
    end

    def number_of_days_before_action_required
      @number_of_days_before_action_required ||=
        @structure.category_configurations.includes(:motif_category).find do |c|
          c.motif_category == @motif_category
        end.number_of_days_before_action_required
    end

    def display_date(date)
      date&.strftime("%d/%m/%Y")
    end

    def display_time(datetime)
      datetime&.strftime("%kh%M")
    end

    def first_invitation_date(user)
      if @motif_category.present?
        follow_up_for_export(user)&.first_invitation_created_at
      else
        user.first_invitation_created_at
      end
    end

    def last_invitation_date(user)
      if @motif_category.present?
        follow_up_for_export(user)&.last_invitation_created_at
      else
        user.last_invitation_created_at
      end
    end

    def last_notification_date(user)
      return follow_up_for_export(user)&.last_convocation_created_at if @motif_category.present?

      user.last_convocation_created_at
    end

    def last_rdv_starts_at(user)
      last_rdv(user)&.starts_at
    end

    def last_participation_created_at(user)
      last_participation(user)&.created_at
    end

    def last_rdv(user)
      rdvs = @motif_category.present? ? follow_up_for_export(user)&.rdvs : user.rdvs
      return if rdvs.blank?

      rdvs.select { |rdv| Pundit.policy!(agent, rdv).show? }.max_by(&:starts_at)
    end

    def last_participation(user)
      last_rdv(user)&.participation_for(user)
    end

    def last_rdv_motif(user)
      last_rdv(user).present? ? last_rdv(user).motif.name : ""
    end

    def last_rdv_type(user)
      return "" if last_rdv(user).blank?

      last_rdv(user).collectif? ? "collectif" : "individuel"
    end

    def display_organisation_names(organisations)
      organisations.map do |organisation|
        display_organisation_name(organisation)
      end.join(", ")
    end

    def display_organisation_name(organisation)
      if organisation.department_id == department_id
        organisation.name
      else
        "#{organisation.name} (Organisation d'un autre départment : " \
          "#{organisation.department.number} - #{organisation.department.name})"
      end
    end

    def scoped_user_tags(tags)
      if department_level?
        tags.joins(:organisations).where(organisations: { id: @agent.organisation_ids, department_id: })
      else
        tags.joins(:organisations).where(organisations: @structure)
      end
    end

    def orientation_date(user)
      orientation = user.participations.select do |participation|
        participation.seen? && participation.orientation? && participation.department_id == department_id
      end.min_by(&:starts_at)

      display_date(orientation&.starts_at)
    end

    def orientation(user)
      user.orientations.to_a.find(&:active?)
    end

    def orientation_type(user)
      orientation(user)&.orientation_type&.name
    end

    def orientation_starts_at(user)
      orientation(user)&.starts_at
    end

    def orientation_ends_at(user)
      orientation(user)&.ends_at
    end

    def orientation_structure(user)
      orientation(user)&.organisation&.name
    end

    def rdv_taken_in_autonomy?(user)
      return "" if last_participation(user).blank?

      I18n.t("boolean.#{last_participation(user).created_by_user?}")
    end

    def oriented_in_less_than_n_days?(user, number_of_days)
      return "Non calculable" if user.in_many_departments?

      follow_up = user.first_orientation_follow_up
      result = follow_up.present? && follow_up.rdv_seen_delay_in_days.present? &&
               follow_up.rdv_seen_delay_in_days < number_of_days
      I18n.t("boolean.#{result}")
    end

    def follow_up_for_export(user)
      user.follow_up_for(@motif_category)
    end
  end
end
# rubocop: enable Metrics/ClassLength
