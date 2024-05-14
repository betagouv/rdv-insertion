class BrevoSmsWebhooksController < ApplicationController
  skip_before_action :authenticate_agent!, :verify_authenticity_token

  def create
    byebug

    # Pour récupérer l'id de l'invitation dans le webhook lié au sms: params[:invitation_id]

    # Exemple d'un webhook Brevo SMS en erreur (soft_bounce), on recoit 2 webhooks pour un meme message:
    # {
    #   :to => "0033577777777",
    #   :status => "ok",
    #   :number_sent => 1,
    #   :sms_count => 1,
    #   :credits_used => 4.5,
    #   :remaining_credit => "197336.30",
    #   :reference => { "1" => "8htbv5x6an4a7ethjc" },
    #   :msg_status => "sent",
    #   :date => "2024-05-14 14:20:34",
    #   :messageId => 26_748_550_856_860,
    #   :tag => ""
    # }
    #
    # {
    #   :status => "OK",
    #   :msg_status => "soft_bounce",
    #   :errorCode => 7,
    #   :description => "Failed to deliver message for reasons unknown",
    #   :bounce_type => "soft_bounce",
    #   :to => "33577777777",
    #   :reference => { "1" => "8htbv5x6an4a7ethjc" },
    #   :ts_event => 1_715_689_234,
    #   :date => "2024-05-14 14:20:35",
    #   :messageId => 26_748_550_856_860,
    #   :tag => ""
    # }

    # Exemple de webhooks Brevo pour un SMS valide :
    #
    # {
    #   :status => "OK",
    #   :msg_status => "accepted",
    #   :description => "accepted",
    #   :to => "33677748967",
    #   :reference => { "1" => "a7rch8swpmdm7ethjc" },
    #   :ts_event => 1_715_689_794,
    #   :date => "2024-05-14 14:29:55",
    #   :messageId => 30_998_753_630_040,
    #   :tag => ""
    # }
    #
    # {
    #   :to=>"0033677748967",
    #   :status=>"ok",
    #   :number_sent=>1,
    #   :sms_count=>1,
    #   :credits_used=>4.5,
    #   :remaining_credit=>"197259.80",
    #   :reference=>{"1"=>"3s0hqamr9z7u7ethjc"},
    #   :msg_status=>"sent",
    #   :date=>"2024-05-14 14:30:58",
    #   :messageId=>11749852252618,
    #   :tag=>""
    #  }
    #
    # {
    #   :status => "OK",
    #   :msg_status => "delivered", <- C'est ce status qui nous interesse
    #   :description => "delivered",
    #   :to => "33677748967",
    #   :reference => { "1" => "januhxi6v5vu7ethjc" },
    #   :ts_event => 1_715_689_662,
    #   :date => "2024-05-14 14:27:42",
    #   :messageId => 59_665_259_812_778,
    #   :tag => ""
    # }
  end
end
