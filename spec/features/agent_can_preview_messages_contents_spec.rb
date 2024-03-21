describe "Agents can preview messages contents", :js do
  include_context "with all existing categories"

  let!(:agent) { create(:agent) }
  let!(:organisation) { create(:organisation, department: create(:department, number: "26")) }
  let!(:agent_role) { create(:agent_role, agent:, organisation:, access_level: "admin") }
  let!(:category_configuration) do
    create(:category_configuration, motif_category: category_rsa_orientation, organisation:)
  end

  before { setup_agent_session(agent) }

  it "can preview and edit messages contents" do
    visit organisation_category_configuration_path(organisation, category_configuration)

    expect(page).to have_button("Convocations")
    expect(page).to have_button("Invitations")

    click_button("Invitations")

    expect(page).to have_css("span.text-purple", text: "rendez-vous d'orientation", wait: 20)
    expect(page).to have_css("span.text-purple", text: "bénéficiaire du RSA")
    expect(page).to have_css("span.text-purple", text: "démarrer un parcours d'accompagnement")

    find("button.btn-close").click

    expect(page).to have_button("Convocations")
    expect(page).to have_button("Invitations")

    click_button("Convocations")

    expect(page).to have_css("span.text-purple", text: "rendez-vous d'orientation téléphonique", wait: 20)
    expect(page).to have_css("span.text-purple", text: "rendez-vous d'orientation")
    expect(page).to have_css("span.text-purple", text: "bénéficiaire du RSA")
    expect(page).to have_css("span.text-purple", text: "démarrer un parcours d'accompagnement")

    expect(page).to have_css("button.btn-close")
    find("button.btn-close").click

    expect(page).to have_button("Modifier")

    click_button("Modifier")

    page.fill_in "category_configuration_template_rdv_title_override", with: "nouveau type de rendez-vous"
    page.fill_in "category_configuration_template_rdv_title_by_phone_override", with: "nouveau coup de téléphone"
    page.fill_in "category_configuration_template_user_designation_override", with: "une personne remarquable"
    page.fill_in "category_configuration_template_rdv_purpose_override", with: "vous rencontrer"

    click_button("Enregistrer")

    expect(page).to have_button("Invitations")

    click_button("Invitations")

    expect(page).to have_css("span.text-purple", text: "nouveau type de rendez-vous", wait: 20)
    expect(page).to have_css("span.text-purple", text: "une personne remarquable")
    expect(page).to have_css("span.text-purple", text: "vous rencontrer")

    expect(page).to have_no_css("span.text-purple", text: "rendez-vous d'orientation")
    expect(page).to have_no_css("span.text-purple", text: "bénéficiaire du RSA")
    expect(page).to have_no_css("span.text-purple", text: "démarrer un parcours d'accompagnement")

    find("button.btn-close").click

    expect(page).to have_button("Convocations")

    click_button("Convocations")

    expect(page).to have_css("span.text-purple", text: "nouveau type de rendez-vous", wait: 20)
    expect(page).to have_css("span.text-purple", text: "nouveau coup de téléphone")
    expect(page).to have_css("span.text-purple", text: "une personne remarquable")
    expect(page).to have_css("span.text-purple", text: "vous rencontrer")

    expect(page).to have_no_css("span.text-purple", text: "rendez-vous d'orientation téléphonique")
    expect(page).to have_no_css("span.text-purple", text: "rendez-vous d'orientation")
    expect(page).to have_no_css("span.text-purple", text: "bénéficiaire du RSA")
    expect(page).to have_no_css("span.text-purple", text: "démarrer un parcours d'accompagnement")
  end

  context "when the category does not require all the template variables and has no reminder" do
    let!(:category_configuration) do
      create(:category_configuration, motif_category: category_rsa_insertion_offer, organisation:)
    end

    it "still can preview contents" do
      visit organisation_category_configuration_path(organisation, category_configuration)

      expect(page).to have_button("Convocations")
      expect(page).to have_button("Invitations")

      click_button("Invitations")

      expect(page).to have_css("span.text-purple", text: "bénéficiaire du RSA", wait: 20)
      expect(page).to have_content("atelier")

      find("button.btn-close").click

      expect(page).to have_button("Convocations")
      expect(page).to have_button("Invitations")

      click_button("Convocations")

      expect(page).to have_css("span.text-purple", text: "atelier", wait: 20)
      expect(page).to have_css("span.text-purple", text: "atelier téléphonique")
      expect(page).to have_css("span.text-purple", text: "bénéficiaire du RSA")
    end
  end
end
