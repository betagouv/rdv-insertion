require "csv"

class CreateApplicantsCsvExport < BaseService
  def initialize(applicants:, structure:, motif_category:)
    @applicants = applicants
    @structure = structure
    @motif_category = motif_category
  end

  def call
    result.filename = filename
    result.csv = generate_csv
  end

  private

  def generate_csv
    csv = CSV.generate(write_headers: true, col_sep: ";", headers: headers, encoding: 'utf-8') do |row|
      @applicants
        .includes(:department).preload(:organisations, :rdvs, rdv_contexts: [:invitations])
        .each do |applicant|
        row << applicant_csv_row(applicant)
      end
    end
    # We add a BOM at the beginning of the file to enable a correct parsing of accented characters in Excel
    "\uFEFF#{csv}"
  end

  def headers
    [Applicant.human_attribute_name(:title),
     Applicant.human_attribute_name(:last_name),
     Applicant.human_attribute_name(:first_name),
     Applicant.human_attribute_name(:affiliation_number),
     Applicant.human_attribute_name(:department_internal_id),
     Applicant.human_attribute_name(:email),
     Applicant.human_attribute_name(:address),
     Applicant.human_attribute_name(:phone_number),
     Applicant.human_attribute_name(:birth_date),
     Applicant.human_attribute_name(:rights_opening_date),
     Applicant.human_attribute_name(:role),
     "Première invitation envoyée le",
     "Dernière invitation envoyée le",
     "Date du dernier RDV",
     Applicant.human_attribute_name(:status),
     "RDV honoré en - de 30 jours ?",
     "Date d'orientation",
     "Archivé ?",
     Applicant.human_attribute_name(:archiving_reason),
     "Numéro du département",
     "Nom du département",
     "Nombre d'organisations",
     "Nom des organisations"]
  end

  def applicant_csv_row(applicant) # rubocop:disable Metrics/AbcSize
    [applicant.title,
     applicant.last_name,
     applicant.first_name,
     applicant.affiliation_number,
     applicant.department_internal_id,
     applicant.email,
     applicant.address,
     applicant.phone_number,
     format_date(applicant.birth_date),
     format_date(applicant.rights_opening_date),
     applicant.role,
     display_invitation_date(applicant, first_invitation_date(applicant)),
     display_invitation_date(applicant, last_invitation_date(applicant)),
     last_rdv_date(applicant),
     human_rdv_context_status(applicant),
     I18n.t("boolean.#{applicant.seen_date.present?}"),
     format_date(applicant.seen_date),
     I18n.t("boolean.#{applicant.is_archived?}"),
     applicant.archiving_reason,
     applicant.department.number,
     applicant.department.name,
     applicant.organisations.to_a.count,
     applicant.organisations.collect(&:name).join(", ")]
  end

  def filename
    if @structure.nil?
      "Liste_beneficiaires.csv"
    else
      "Liste_beneficiaires_#{motif_category_title}_#{@structure.class.model_name.human.downcase}_" \
        "#{@structure.name.parameterize(separator: '_')}.csv"
    end
  end

  def motif_category_title
    @motif_category.presence || "autres"
  end

  def human_rdv_context_status(applicant)
    return "Non invité" if rdv_context(applicant)&.status.nil?

    I18n.t("activerecord.attributes.rdv_context.statuses.#{rdv_context(applicant).status}") +
      display_context_status_notice(rdv_context(applicant), number_of_days_before_action_required)
  end

  def number_of_days_before_action_required
    @number_of_days_before_action_required ||= @structure.configurations.find do |c|
      c.motif_category == @motif_category
    end.number_of_days_before_action_required
  end

  def display_context_status_notice(rdv_context, number_of_days_before_action_required)
    if rdv_context.invited_before_time_window?(number_of_days_before_action_required) && rdv_context.invitation_pending?
      " (Délai dépassé)"
    else
      ""
    end
  end

  def display_invitation_date(applicant, invitation_date)
    return "" if rdv_context(applicant)&.invitations.blank?

    format_date(invitation_date)
  end

  def first_invitation_date(applicant)
    rdv_context(applicant)&.first_invitation_sent_at
  end

  def last_invitation_date(applicant)
    rdv_context(applicant)&.last_invitation_sent_at
  end

  def last_rdv_date(applicant)
    return "" unless rdv_context(applicant)

    format_date(rdv_context(applicant).rdvs.last&.starts_at)
  end

  def rdv_context(applicant)
    applicant.rdv_context_for(@motif_category)
  end

  def format_date(date)
    date&.strftime("%d/%m/%Y")
  end
end
