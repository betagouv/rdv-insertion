describe "Agents can upload documents for users", js: true do
  let!(:agent) { create(:agent) }
  let!(:department) { create(:department, number: "26") }
  let!(:organisation) do
    create(:organisation, name: "CD 26", agents: organisation_agents, department: department)
  end
  let!(:user) do
    create(:user, organisations: [organisation])
  end
  let!(:organisation_agents) do
    [agent, create(:agent, first_name: "Kad", last_name: "Merad"),
     create(:agent, first_name: "Olivier", last_name: "Barroux")]
  end

  let!(:other_organisation) do
    create(:organisation, name: "Asso 26", agents: other_organisation_agents, department:)
  end

  let!(:other_organisation_agents) { [create(:agent, first_name: "Jean-Paul", last_name: "Rouve")] }

  before { setup_agent_session(agent) }

  context "when on a user profile" do
    it "can upload a file" do
      visit organisation_user_path(organisation_id: organisation.id, id: user.id)
      expect(page).to have_content("Parcours")

      click_link("Parcours")

      expect(page).to have_content("Aucun diagnostic renseigné.")

      find_by_id("file-input-diagnostic").set(Rails.root.join("spec/fixtures/dummy.pdf"))
      click_button("Ajouter un diagnostic")

      expect(page).not_to have_content("Aucun diagnostic renseigné.")
      expect(page).to have_content("dummy.pdf")
      expect(page).to have_selector(".document-link", count: 1)
      expect(user.diagnostics.first.file.filename).to eq("dummy.pdf")

      find_by_id("file-input-contract").set(Rails.root.join("spec/fixtures/dummy.pdf"))
      click_button("Ajouter un contrat")

      expect(page).not_to have_content("Aucun contrat renseigné.")
      expect(page).to have_content("dummy.pdf")
      expect(page).to have_selector(".document-link", count: 2)
      expect(user.contracts.first.file.filename).to eq("dummy.pdf")

      accept_alert do
        find_by_id("delete-button-#{user.contracts.first.id}").click
      end

      accept_alert do
        find_by_id("delete-button-#{user.diagnostics.first.id}").click
      end

      expect(page).not_to have_selector(".document-link")

      expect(user.contracts.count).to eq(0)
      expect(user.diagnostics.count).to eq(0)
    end
  end
end
