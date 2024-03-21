class FileConfiguration < ApplicationRecord
  has_many :category_configurations, dependent: :restrict_with_error

  validates :sheet_name, :last_name_column, :first_name_column, :title_column, presence: true
  validate :column_names_uniqueness

  # a hash with key-value pairs for all informed the column names of the file
  def column_attributes
    attributes.slice(*self.class.column_attributes_names).compact
  end

  def self.column_attributes_names
    attribute_names.select { |attribute_name| attribute_name.end_with?("column") }
  end

  private

  def column_names_uniqueness
    return if column_attributes.values.uniq.length == column_attributes.values.length

    errors.add(:base, "Chaque colonne doit avoir un nom différent")
  end
end
