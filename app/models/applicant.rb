class Applicant < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [
    :first_name, :last_name, :birth_date, :email, :phone_number, :address, :affiliation_number, :birth_name
  ].freeze
  RDV_SOLIDARITES_CLASS_NAME = "User".freeze

  include SearchableConcern
  include NotificableConcern
  include HasPhoneNumberConcern
  include InvitableConcern
  include HasRdvsConcern

  before_validation :generate_uid

  has_and_belongs_to_many :organisations
  has_many :invitations, dependent: :destroy
  has_many :rdv_contexts, dependent: :destroy
  has_and_belongs_to_many :rdvs
  belongs_to :department

  validates :uid, uniqueness: true, allow_nil: true
  validates :rdv_solidarites_user_id, uniqueness: true, allow_nil: true
  validates :department_internal_id, uniqueness: { scope: :department_id }, allow_nil: true
  validates :last_name, :first_name, :title, presence: true
  validates :email, allow_blank: true, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ }
  validate :birth_date_validity, :uid_or_department_internal_id_presence

  delegate :name, :number, to: :department, prefix: true

  enum role: { demandeur: 0, conjoint: 1 }
  enum title: { monsieur: 0, madame: 1 }

  scope :active, -> { where(deleted_at: nil) }
  scope :archived, ->(archived = true) { where(is_archived: archived) }
  scope :without_rdv_contexts, lambda { |motif_categories|
    where.not(id: joins(:rdv_contexts).where(rdv_contexts: { motif_category: motif_categories }).ids)
  }

  def rdv_seen_delay_in_days
    return if first_seen_rdv_starts_at.blank?

    first_seen_rdv_starts_at.to_datetime.mjd - created_at.to_datetime.mjd
  end

  def full_name
    "#{title.capitalize} #{first_name.capitalize} #{last_name.upcase}"
  end

  def short_title
    title == "monsieur" ? "M" : "Mme"
  end

  def street_address
    split_address.present? ? split_address[1].strip.gsub(/-$/, '').gsub(/,$/, '').gsub(/\.$/, '') : nil
  end

  def zipcode_and_city
    split_address.present? ? split_address[2].strip : nil
  end

  def organisations_with_rdvs
    organisations.where(id: rdvs.pluck(:organisation_id))
  end

  def delete_organisation(organisation)
    organisations.delete(organisation)
    save!
  end

  def rdv_context_for(motif_category)
    rdv_contexts.find { |rc| rc.motif_category == motif_category }
  end

  def deleted?
    deleted_at.present?
  end

  def inactive?
    is_archived? || deleted?
  end

  def motif_categories
    rdv_contexts.map(&:motif_category)
  end

  def as_json(_opts = {})
    super.merge(
      created_at: created_at,
      invitations: invitations,
      organisations: organisations
    )
  end

  private

  def generate_uid
    # Base64 encoded "department_number - affiliation_number - role"
    return if deleted?
    return if department_id.blank? || affiliation_number.blank? || role.blank?

    self.uid = Base64.strict_encode64("#{department.number} - #{affiliation_number} - #{role}")
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Time.zone.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "n'est pas valide")
  end

  def uid_or_department_internal_id_presence
    return if deleted?
    return if department_internal_id.present? || (affiliation_number.present? && role.present?)

    errors.add(:base, "le couple num??ro d'allocataire + r??le ou l'ID interne au d??partement doivent ??tre pr??sents.")
  end

  def split_address
    address&.match(/^(.+) (\d{5}.*)$/m)
  end
end
