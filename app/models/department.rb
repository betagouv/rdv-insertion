class Department < ApplicationRecord
  include HasLogo

  validates :name, :capital, :number, :pronoun, :region, :logo, presence: true

  has_many :organisations, dependent: :nullify
  has_many :invitations, dependent: :nullify
  has_many :archives, dependent: :restrict_with_error

  has_many :users, through: :organisations
  has_many :category_configurations, through: :organisations
  has_many :motif_categories, -> { distinct }, through: :category_configurations
  has_many :file_configurations, through: :category_configurations
  has_many :agents, through: :organisations
  has_many :rdvs, through: :organisations
  has_many :participations, through: :rdvs
  has_many :rdv_contexts, through: :users
  has_many :archived_users, through: :archives, source: :user
  has_many :tags, through: :organisations
  has_one :stat, as: :statable, dependent: :destroy

  scope :displayed_in_stats, -> { where(display_in_stats: true) }

  def name_with_region
    "#{name}, #{region}"
  end
end
