class BrevoMailWebhooksController < ApplicationController
  skip_before_action :authenticate_agent!, :verify_authenticity_token

  def create
    byebug

    # Exemple de webhooks de brevo pour un mail deliveré correctement :
    #   {
    #     :id => 1_050_528,
    #     :email => "emailvalide@gmail.com",
    #     :"message-id" =>
    # "<66435dc2760aa_15f7fe9ac24458@MacBook-Pro-de-Romain.local.mail>",
    #     :date => "2024-05-14 14:49:07",
    #     :tag => "",
    #     :event => "request",
    #     :"X-Mailin-custom" => "{\"invitation_id\":\"4464\"}",
    #     :subject =>
    # "[CANDIDATURE SIAE]: Votre entretien d'embauche dans le cadre de votre candidature SIAE",
    #     :sending_ip => "77.32.148.23",
    #     :ts_event => 1_715_690_947,
    #     :ts => 1_715_690_947,
    #     :reason => "sent",
    #     :ts_epoch => 1_715_690_947_211,
    #     :sender_email => "support-insertion@rdv-solidarites.fr"
    #   }

    # {
    #   :id => 1_050_528,
    #   :email => "emailvalide@gmail.com",
    #   :"message-id" =>
    #   "<66435dc2760aa_15f7fe9ac24458@MacBook-Pro-de-Romain.local.mail>",
    #   :date => "2024-05-14 14:49:19",
    #   :tag => "",
    #   :event => "delivered", <- C'est ce status qui nous intérésse
    #   :"X-Mailin-custom" => "{\"invitation_id\":\"4464\"}",
    #   :subject =>
    #   "[CANDIDATURE SIAE]: Votre entretien d'embauche dans le cadre de votre candidature SIAE",
    #   :sending_ip => "77.32.148.23",
    #   :ts_event => 1_715_690_959,
    #   :ts => 1_715_690_959,
    #   :reason => "sent",
    #   :ts_epoch => 1_715_690_959_000,
    #   :sender_email => "support-insertion@rdv-solidarites.fr"
    # }
    #
    # Exemple de hard bounce :
    #
    #     { :id => 1_050_528,
    #       :email =>
    #  "nimportequeoriqzdnbiquzhdgbqzkidgjkqzghd165168135441@gmail.com",
    #       :"message-id" =>
    #  "<66435fa8b40f_15f7fe98424717@MacBook-Pro-de-Romain.local.mail>",
    #       :date => "2024-05-14 14:57:12",
    #       :tag => "",
    #       :event => "request",
    #       :"X-Mailin-custom" => "{\"invitation_id\":\"4465\"}",
    #       :subject =>
    #  "[CANDIDATURE SIAE]: Votre entretien d'embauche dans le cadre de votre candidature SIAE",
    #       :sending_ip => "77.32.148.23",
    #       :ts_event => 1_715_691_432,
    #       :ts => 1_715_691_432,
    #       :reason => "sent",
    #       :ts_epoch => 1_715_691_432_713,
    #       :sender_email => "support-insertion@rdv-solidarites.fr" }
    #
    #
    #     { :id => 1_050_528,
    #       :email =>
    #  "nimportequeoriqzdnbiquzhdgbqzkidgjkqzghd165168135441@gmail.com",
    #       :"message-id" =>
    #  "<66435fa8b40f_15f7fe98424717@MacBook-Pro-de-Romain.local.mail>",
    #       :date => "2024-05-14 14:57:13",
    #       :tag => "",
    #       :event => "hard_bounce", <- C'est ce status qui nous intérésse, pas de delivered
    #       :"X-Mailin-custom" => "{\"invitation_id\":\"4465\"}",
    #       :subject =>
    #  "[CANDIDATURE SIAE]: Votre entretien d'embauche dans le cadre de votre candidature SIAE",
    #       :sending_ip => "77.32.148.23",
    #       :ts_event => 1_715_691_433,
    #       :ts => 1_715_691_433,
    #       :reason =>
    #  "550-5.1.1 The email account that you tried to reach does not exist. Please try\n   550-5.1.1 double-checking the recipient's email address for typos or\n   550-5.1.1 unnecessary spaces. For more information, go to\n   550 5.1.1  https://support.google.com/mail/?p=NoSuchUser ffacd0b85a97d-3502bd198ffsi6849051f8f.754 - gsmtp",
    #       :ts_epoch => 1_715_691_433_000,
    #       :sender_email => "support-insertion@rdv-solidarites.fr" }
  end
end
