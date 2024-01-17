class CsvExportMailer < ApplicationMailer
  def internal_users_csv_export(email, csv, filename)
    attachments[filename] = { mime_type: "text/csv", content: csv }
    mail(
      to: email,
      subject: "Export csv d'usagers",
      body: ""
    )
  end

  def users_csv_export(email, file)
    send_csv("[RDV-Insertion] Export CSV des usagers", email, file)
  end

  def users_participations_csv_export(email, file)
    send_csv("[RDV-Insertion] Export CSV des rendez-vous", email, file)
  end

  private

  def send_csv(subject, email, file)
    attachments[file.filename] = { mime_type: file.mime_type, content: file.read }
    mail(to: email, subject:)
  rescue StandardError => e
    body = "Une erreur est survenue lors de la création de l'export CSV que vous avez demandé. \n" \
           "Veuillez réessayer ou nous contacter à l'adresse data.insertion@beta.gouv.fr.  \n" \
           "Merci de nous excuser pour la gêne occasionnée.  \n" \
           "L'équipe RDV-Insertion"

    mail(to: email, subject:, body:)
    Sentry.capture_message("Error when sending CSV export: #{e.message}")
  end
end
