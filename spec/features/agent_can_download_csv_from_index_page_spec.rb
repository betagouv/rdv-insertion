require "csv"

describe "Agents can download csv from index page", :js do
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:organisation) { create(:organisation) }
  let!(:user) do
    create(
      :user,
      organisations: [organisation], email: "someemail@somecompany.com", phone_number: "0607070707"
    )
  end
  let!(:motif_category) { create(:motif_category, short_name: "rsa_follow_up") }
  let!(:motif_category2) { create(:motif_category, short_name: "rsa_insertion_offer") }
  let!(:rdv_solidarites_token) { "123456" }
  let!(:follow_up) { create(:follow_up, user: user, motif_category: motif_category, status: "rdv_seen") }
  let!(:follow_up2) { create(:follow_up, user: user, motif_category: motif_category2, status: "rdv_seen") }
  let!(:configuration) do
    create(
      :configuration,
      motif_category: motif_category, organisation: organisation, invitation_formats: %w[sms email]
    )
  end
  let!(:configuration2) do
    create(
      :configuration,
      motif_category: motif_category2, organisation: organisation, invitation_formats: %w[sms email]
    )
  end
  let!(:motif) { create(:motif, motif_category: motif_category, organisation: organisation) }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_invitation_requests(user.rdv_solidarites_user_id, rdv_solidarites_token)
    stub_geo_api_request(user.address)
  end

  shared_examples "triggering csv creation" do
    it "can trigger participation csv" do
      expect(Exporters::CreateUsersParticipationsCsvExportJob).to receive(:perform_async).once
      find_by_id("csvExportButton").click

      click_link("Export des rendez-vous des usagers")
    end

    it "can trigger users csv" do
      expect(Exporters::CreateUsersCsvExportJob).to receive(:perform_async).once
      find_by_id("csvExportButton").click

      click_link("Export des usagers")
    end
  end

  context "when viewing a specific org" do
    before do
      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
    end

    it_behaves_like "triggering csv creation"
  end

  context "when viewing the whole department" do
    before do
      visit department_users_path(organisation.department)
    end

    it_behaves_like "triggering csv creation"
  end

  context "when clicking on email link" do
    let!(:export) do
      create(:csv_export, agent:, structure: organisation, kind: "users_csv")
    end

    it "redirects to actual csv path" do
      visit csv_export_path(id: export.signed_id)

      wait_for_download
      expect(downloads.length).to eq(1)
      expect(download_content).not_to eq(nil)
    end

    context "when agent is not the creator of the export" do
      let!(:another_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:export) do
        create(:csv_export, agent: another_agent, structure: organisation, kind: "users_csv")
      end

      it "does not download the file" do
        visit csv_export_path(id: export.signed_id)

        expect(page).to have_current_path(organisation_users_path(organisation))
      end
    end

    context "when export is expired" do
      let!(:export) do
        create(:csv_export, agent:, structure: organisation, kind: "users_csv", created_at: 3.days.ago)
      end

      it "does not download the file" do
        visit csv_export_path(id: export.signed_id)

        expect(page).to have_current_path(organisation_users_path(organisation))
      end
    end
  end
end
