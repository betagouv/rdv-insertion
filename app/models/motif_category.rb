class MotifCategory < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [
    :name, :short_name
  ].freeze

  has_many :configurations, dependent: :restrict_with_exception
  has_many :follow_ups, dependent: :restrict_with_exception
  has_many :motifs, dependent: :restrict_with_exception
  belongs_to :template

  validates :short_name, presence: true, uniqueness: true
  validates :name, presence: true
  validates :rdv_solidarites_motif_category_id, uniqueness: true, allow_nil: true

  delegate :model, to: :template, prefix: true
  delegate :atelier?, to: :template

  scope :optional_rdv_subscription, lambda { |optional_rdv_subscription = true|
    where(optional_rdv_subscription: optional_rdv_subscription)
  }
end
