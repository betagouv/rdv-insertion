# For france travail the webhooks are specific, we have to adapt to FT specs as they could not
# implement a system integrating our webhooks, so we separated the two webhooks logic.
module Rdv::FranceTravailWebhooks
  extend ActiveSupport::Concern

  included do
    after_commit on: :create, if: -> { organisation.france_travail? } do
      send_france_travail_webhook(:created)
    end

    after_commit on: :update, if: -> { organisation.france_travail? } do
      send_france_travail_webhook(:updated)
    end

    around_destroy :send_france_travail_webhook_on_destroy, if: -> { organisation.france_travail? }
  end

  private

  def send_france_travail_webhook(event)
    OutgoingWebhooks::SendFranceTravailWebhookJob.perform_async(
      generate_france_travail_payload(event), updated_at
    )
  end

  def send_france_travail_webhook_on_destroy
    payload = generate_france_travail_payload(:destroyed)

    yield if block_given?

    OutgoingWebhooks::SendFranceTravailWebhookJob.perform_async(payload, updated_at)
  end

  # rubocop:disable Metrics/AbcSize
  def generate_france_travail_payload(event)
    {
      "idOrigine" => id,
      "libelleStructure" => organisation.name,
      "codeSafir" => organisation.safir_code,
      "objet" => motif.name,
      "nombrePlaces" => max_participants_count,
      "idModalite" => france_travail_id_modalite,
      "typeReception" => collectif? ? "Collectif" : "Individuel",
      "dateRendezvous" => starts_at.to_datetime,
      "duree" => duration_in_min,
      "initiateur" => created_by,
      "address" => lieu&.address,
      "conseiller" => agents.map do |agent|
                        {
                          "email" => agent.email,
                          "nom" => agent.last_name,
                          "prenom" => agent.first_name
                        }
                      end,
      "participants" => users.map do |user|
                          {
                            "nir" => user.nir,
                            "nom" => user.last_name,
                            "prenom" => user.first_name,
                            "civilite" => user.title,
                            "email" => user.email,
                            "telephone" => user.phone_number,
                            "dateNaissance" => user.birth_date
                          }
                        end,
      "information" => motif.instruction_for_rdv,
      "dateAnnulation" => cancelled_at,
      "dateFinRendezvous" => ends_at.to_datetime,
      "mode" => france_travail_event_mapping[event]
    }
  end
  # rubocop:enable Metrics/AbcSize

  def france_travail_event_mapping
    {
      created: "création",
      updated: "modification",
      destroyed: "suppression"
    }
  end

  def france_travail_id_modalite
    motif.phone? ? 1 : 3
  end
end
