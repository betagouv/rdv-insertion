module Invitations
  class AssignMailDeliveryStatusAndDate < AssignDeliveryStatusAndDateBase
    private

    def delivery_status
      @delivery_status ||= @webhook_params[:event]
    end

    def webhook_mismatch?
      return false if @invitation.email == @webhook_params[:email]

      Sentry.capture_message("Invitation email and webhook email do not match",
                             extra: { invitation: @invitation, webhook: @webhook_params })
    end
  end
end
