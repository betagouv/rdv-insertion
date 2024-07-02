describe NotifyUnavailableCreneauJob do
  subject do
    described_class.new.perform(organisation_id)
  end

  let!(:organisation) { create(:organisation) }
  let!(:organisation_id) { organisation.id }
  let!(:organisation_mail) { instance_double("organisation_mail") }
  let(:category_configuration) { create(:category_configuration) }

  let!(:grouped_invitation_params_by_category) do
    [
      {
        motif_category_name: "RSA Orientation",
        matching_category_configuration: category_configuration,
        city_code: %w[75001 75002 75003],
        referent_ids: ["1"],
        invitations_counter: 3
      },
      {
        motif_category_name: "RSA Accompagnement",
        city_code: ["75004"],
        matching_category_configuration: category_configuration,
        referent_ids: [],
        invitations_counter: 1
      }
    ]
  end

  before do
    allow(Invitations::VerifyOrganisationCreneauxAvailability).to receive(:call)
      .and_return(OpenStruct.new(success?: true,
                                 grouped_invitation_params_by_category: grouped_invitation_params_by_category))
    allow(OrganisationMailer).to receive(:creneau_unavailable).and_return(organisation_mail)
    allow(organisation_mail).to receive(:deliver_now)
  end

  it "send the email" do
    expect(OrganisationMailer).to receive(:creneau_unavailable)
      .with(organisation: organisation, grouped_invitation_params_by_category: grouped_invitation_params_by_category)
    expect(organisation_mail).to receive(:deliver_now)
    subject
  end

  it "send the message to mattermost" do
    expect(MattermostClient).to receive(:send_to_notif_channel)
      .with(
        "Créneaux indisponibles pour l'organisation #{organisation.name}" \
        " (Département: #{organisation.department.name})\n" \
        " Motif : #{grouped_invitation_params_by_category[0][:motif_category_name]}\n" \
        " Nombre d'invitations concernées : #{grouped_invitation_params_by_category[0][:invitations_counter]}\n" \
        " Référents (rdvsp_ids) : #{grouped_invitation_params_by_category[0][:referent_ids].join(', ')}\n" \
      )
    expect(MattermostClient).to receive(:send_to_notif_channel)
      .with(
        "Créneaux indisponibles pour l'organisation #{organisation.name}" \
        " (Département: #{organisation.department.name})\n" \
        " Motif : #{grouped_invitation_params_by_category[1][:motif_category_name]}\n" \
        " Nombre d'invitations concernées : #{grouped_invitation_params_by_category[1][:invitations_counter]}\n" \
      )
    subject
  end
end
