# rubocop:disable Metrics/ClassLength
module Exporters
  class GenerateUsersCsv < Csv
    attr_reader :agent

    def initialize(user_ids:, agent:, structure: nil, motif_category: nil)
      @user_ids = user_ids
      @structure = structure
      @motif_category = motif_category
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
            :archives, :organisations, :tags, :referents, :rdvs,
            participations: [:organisation, :rdv_context],
            rdv_contexts: [:invitations, :motif_category, :notifications, { rdvs: [:motif, :participations, :users] }]
          ).find(@user_ids)
        else
          User.preload(
            :invitations, :notifications, :archives, :organisations, :tags, :referents,
            rdv_contexts: [:motif_category, :participations, :rdvs],
            participations: [:organisation, :rdv, { rdv_context: :motif_category }],
            rdvs: [:motif, :participations]
          ).find(@user_ids)
        end
    end

    def headers # rubocop:disable Metrics/AbcSize
      [User.human_attribute_name(:title),
       User.human_attribute_name(:last_name),
       User.human_attribute_name(:first_name),
       User.human_attribute_name(:affiliation_number),
       User.human_attribute_name(:department_internal_id),
       User.human_attribute_name(:nir),
       User.human_attribute_name(:france_travail_id),
       User.human_attribute_name(:email),
       User.human_attribute_name(:address),
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
       Rdv.human_attribute_name(:status),
       *(RdvContext.human_attribute_name(:status) if @motif_category),
       "Rendez-vous d'orientation (RSA) honoré en - moins de 30 jours?",
       "Rendez-vous d'orientation (RSA) honoré en - moins de 15 jours?",
       "Date d'orientation",
       Archive.human_attribute_name(:created_at),
       Archive.human_attribute_name(:archiving_reason),
       User.human_attribute_name(:referents),
       "Nombre d'organisations",
       "Nom des organisations",
       User.human_attribute_name(:tags)]
    end

    def csv_row(user) # rubocop:disable Metrics/AbcSize
      [user.title,
       user.last_name,
       user.first_name,
       user.affiliation_number,
       user.department_internal_id,
       user.nir,
       user.france_travail_id,
       user.email,
       user.address,
       user.phone_number,
       display_date(user.birth_date),
       display_date(user.created_at),
       display_date(user.rights_opening_date),
       user.role,
       display_date(first_invitation_date(user)),
       display_date(last_invitation_date(user)),
       display_date(last_notification_date(user)),
       display_date(last_rdv_date(user)),
       display_time(last_rdv_date(user)),
       last_rdv_motif(user),
       last_rdv_type(user),
       rdv_taken_in_autonomy?(user),
       human_last_participation_status(user),
       *(human_rdv_context_status(user) if @motif_category),
       oriented_in_less_than_n_days?(user, 30),
       oriented_in_less_than_n_days?(user, 15),
       orientation_date(user),
       display_date(user.archive_for(department_id)&.created_at),
       user.archive_for(department_id)&.archiving_reason,
       user.referents.map(&:email).join(", "),
       user.organisations.to_a.count,
       user.organisations.map(&:name).join(", "),
       user.tags.pluck(:value).join(", ")]
    end

    def human_last_participation_status(user)
      return "" if last_participation(user).blank?

      last_participation(user).human_status
    end

    def human_rdv_context_status(user)
      return "" if @motif_category.nil? || rdv_context_for_export(user).nil?

      rdv_context_for_export(user).human_status + display_context_status_notice(rdv_context_for_export(user))
    end

    def display_context_status_notice(rdv_context)
      if @structure.present? && rdv_context.invited_before_time_window?(number_of_days_before_action_required) &&
         rdv_context.invitation_pending?
        " (Délai dépassé)"
      else
        ""
      end
    end

    def number_of_days_before_action_required
      @number_of_days_before_action_required ||= @structure.configurations.includes(:motif_category).find do |c|
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
        rdv_context_for_export(user)&.first_invitation_created_at
      else
        user.first_invitation_created_at
      end
    end

    def last_invitation_date(user)
      if @motif_category.present?
        rdv_context_for_export(user)&.last_invitation_created_at
      else
        user.last_invitation_created_at
      end
    end

    def last_notification_date(user)
      return rdv_context_for_export(user)&.last_convocation_created_at if @motif_category.present?

      user.last_convocation_created_at
    end

    def last_rdv_date(user)
      last_rdv(user)&.starts_at
    end

    def last_rdv(user)
      rdvs = @motif_category.present? ? rdv_context_for_export(user)&.rdvs : user.rdvs
      return if rdvs.blank?

      rdvs.select { |rdv| Pundit.policy!(agent, rdv).show? }.max_by(&:starts_at)
    end

    def last_participation(user)
      last_rdv(user).present? ? last_rdv(user).participation_for(user) : ""
    end

    def last_rdv_motif(user)
      last_rdv(user).present? ? last_rdv(user).motif.name : ""
    end

    def last_rdv_type(user)
      return "" if last_rdv(user).blank?

      last_rdv(user).collectif? ? "collectif" : "individuel"
    end

    def orientation_date(user)
      orientation = user.participations.select do |participation|
        participation.seen? && participation.orientation? && participation.department_id == department_id
      end.min_by(&:starts_at)

      display_date(orientation&.starts_at)
    end

    def rdv_taken_in_autonomy?(user)
      return "" if last_participation(user).blank?

      I18n.t("boolean.#{last_participation(user).created_by_user?}")
    end

    def oriented_in_less_than_n_days?(user, number_of_days)
      return "Non calculable" if user.in_many_departments?

      rdv_context = user.first_orientation_rdv_context
      result = rdv_context.present? && rdv_context.rdv_seen_delay_in_days.present? &&
               rdv_context.rdv_seen_delay_in_days < number_of_days
      I18n.t("boolean.#{result}")
    end

    def rdv_context_for_export(user)
      user.rdv_context_for(@motif_category)
    end
  end
end
# rubocop: enable Metrics/ClassLength
