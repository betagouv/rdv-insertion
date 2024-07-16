class NotifyParticipationToExternalOrganisationEmailJob < ApplicationJob
  def perform(participation_id, event)
    @participation = Participation.find(participation_id)
    @category_configuration = @participation.current_category_configuration
    @event = event

    return if !@category_configuration.notify_rdv_changes? || already_notified?

    OrganisationMailer.notify_rdv_changes(
      to: @category_configuration.email_to_notify_rdv_changes,
      organisation: @participation.organisation,
      participation: @participation,
      event:
    ).deliver_now
  end

  private

  def already_notified?
    cache_key = "notify_rdv_changes_#{@participation.id}_#{@event}"
    return true if Rails.cache.read(cache_key)

    Rails.cache.write(cache_key, true, expires_in: 1.hour)
    false
  end
end
