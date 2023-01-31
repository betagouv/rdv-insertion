class Motif < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [
    :name, :deleted_at, :location_type, :name, :reservable_online, :rdv_solidarites_service_id, :category, :collectif,
    :follow_up
  ].freeze

  enum location_type: { public_office: 0, phone: 1, home: 2 }

  belongs_to :organisation
  belongs_to :motif_category, optional: true
  has_many :rdvs, dependent: :nullify

  validates :rdv_solidarites_motif_id, uniqueness: true, presence: true
  validates :name, :location_type, presence: true

  def presential?
    location_type == "public_office"
  end

  def by_phone?
    location_type == "phone"
  end
end
