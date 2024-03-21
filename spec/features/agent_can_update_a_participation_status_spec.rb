describe "Agents can update a participation status", :js do
  let(:department) { create(:department) }
  let(:organisation) { create(:organisation, department: department) }
  let(:agent) { create(:agent, organisations: [organisation]) }
  let(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation",
                            category_configurations: [category_configuration])
  end
  let(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let(:user) do
    create(:user, organisations: [organisation])
  end
  let(:rdv) do
    create(:rdv, organisation: organisation)
  end

  let(:rdv_context) do
    create(:rdv_context, status: "rdv_seen", user: user, motif_category: category_orientation)
  end

  let(:participation) do
    create(:participation, rdv_context: rdv_context, user: user, rdv: rdv, status: "seen")
  end

  let(:rdvs_participation_id) { participation.rdv_solidarites_participation_id }

  before do
    setup_agent_session(agent)
    stub_request(:patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/participations/#{rdvs_participation_id}")
      .to_return(status: 200, body: "{}")
  end

  context "when user has rdvs" do
    context "rdv is in the past" do
      it "can edit a participation status" do
        visit organisation_user_rdv_contexts_path(organisation_id: organisation.id, user_id: user.id)
        page.execute_script("window.scrollBy(0, 500)")
        status_update_button = find_by_id("toggle-rdv-status")
        expect(status_update_button).to have_content("Rendez-vous honoré")

        status_update_button.click
        find("a[data-value=revoked]").click

        expect(status_update_button).to have_content("Annulé (par le service)")
        expect(participation.reload.status).to eq("revoked")
      end
    end

    context "when rdv_solidarites_rdv_id is nil" do
      let(:rdv) do
        create(:rdv, organisation: organisation, rdv_solidarites_rdv_id: nil)
      end

      it "does not display the toggle button" do
        visit organisation_user_rdv_contexts_path(organisation_id: organisation.id, user_id: user.id)
        page.execute_script("window.scrollBy(0, 500)")
        expect(page).to have_content("RDV honoré")

        expect(page).to have_no_css("#toggle-rdv-status")
      end
    end
  end
end
