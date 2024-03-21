describe "Agents can reorder categories from index page", :js do
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
  let!(:rdv_context) { create(:rdv_context, user: user, motif_category: motif_category, status: "rdv_seen") }
  let!(:rdv_context2) { create(:rdv_context, user: user, motif_category: motif_category2, status: "rdv_seen") }
  let!(:category_configuration) do
    create(
      :category_configuration,
      motif_category: motif_category, organisation: organisation, invitation_formats: %w[sms email]
    )
  end
  let!(:category_configuration2) do
    create(
      :category_configuration,
      motif_category: motif_category2, organisation: organisation, invitation_formats: %w[sms email]
    )
  end
  let!(:motif) { create(:motif, motif_category: motif_category, organisation: organisation) }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_invitation_requests(user.rdv_solidarites_user_id, rdv_solidarites_token)
    stub_geo_api_request(user.address)
  end

  shared_examples "a working reordering" do
    it "can drag n drop to reorder" do
      first_configuration = find(".draggable li:first-child")
      last_configuration = find(".draggable li:last-child")

      first_configuration_text = first_configuration.text
      last_configuration_text = last_configuration.text

      first_configuration.drag_to(last_configuration)

      visit current_path

      # Ensure that the category_configuration order has changed even after a page refresh
      expect(find(".draggable li:last-child").text).to eq(first_configuration_text)
      expect(find(".draggable li:first-child").text).to eq(last_configuration_text)
    end
  end

  context "when viewing a specific org" do
    before do
      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
    end

    it_behaves_like "a working reordering"
  end

  context "when viewing the whole department" do
    before do
      visit department_users_path(organisation.department)
    end

    it_behaves_like "a working reordering"
  end
end
