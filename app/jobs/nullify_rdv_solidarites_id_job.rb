class NullifyRdvSolidaritesIdJob < ApplicationJob
  def perform(class_name, id)
    resource = class_name.constantize.find_by(id: id)
    return if resource.blank? || resource.try(:deleted?)

    resource.update!("rdv_solidarites_#{class_name.downcase}_id": nil)
  end
end
