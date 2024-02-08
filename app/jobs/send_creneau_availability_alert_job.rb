class SendCreneauAvailabilityAlertJob < ApplicationJob
  def perform
    return if staging_env?

    Department.all.each do |departement|
      departement.organisations.each do |organisation|
        NotifyUnavailableCreneauJob.perform_async(organisation.id)
      end
    end
  end
end
