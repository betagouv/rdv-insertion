describe "Agents can preview messages contents", js: true do
  include_context "with all existing categories"

  let!(:agent) { create(:agent) }
  let!(:organisation) { create(:organisation) }
  let!(:agent_role) { create(:agent_role, agent:, organisation:, access_level: "admin") }
  let!(:configuration) { create(:configuration, motif_category: category_rsa_orientation, organisation:) }

  before { setup_agent_session(agent) }

  it "can preview and edit messages contents" do
    visit organisation_configuration_path(organisation, configuration)

    expect(page).to have_button("Notification")
    expect(page).to have_button("Invitation")

    click_button("Invitation")

    expect(page).to have_css("span.text-success", text: "rendez-vous d'orientation", wait: 10)
    expect(page).to have_css("span.text-success", text: "bénéficiaire du RSA")
    expect(page).to have_css("span.text-success", text: "démarrer un parcours d'accompagnement")

    find("button.btn-close").click

    expect(page).to have_button("Notification")
    expect(page).to have_button("Invitation")

    click_button("Notification")

    expect(page).to have_css("span.text-success", text: "rendez-vous d'orientation téléphonique", wait: 10)
    expect(page).to have_css("span.text-success", text: "rendez-vous d'orientation")
    expect(page).to have_css("span.text-success", text: "bénéficiaire du RSA")
    expect(page).to have_css("span.text-success", text: "démarrer un parcours d'accompagnement")

    expect(page).to have_css("button.btn-close")
    find("button.btn-close").click

    expect(page).to have_button("Modifier")

    click_button("Modifier")

    page.fill_in "configuration_template_rdv_title_override", with: "nouveau type de rendez-vous"
    page.fill_in "configuration_template_rdv_title_by_phone_override", with: "nouveau coup de téléphone"
    page.fill_in "configuration_template_applicant_designation_override", with: "une personne remarquable"
    page.fill_in "configuration_template_rdv_purpose_override", with: "vous rencontrer"

    click_button("Enregistrer")

    expect(page).to have_button("Invitation")

    click_button("Invitation")

    expect(page).to have_css("span.text-success", text: "nouveau type de rendez-vous", wait: 10)
    expect(page).to have_css("span.text-success", text: "une personne remarquable")
    expect(page).to have_css("span.text-success", text: "vous rencontrer")

    expect(page).not_to have_css("span.text-success", text: "rendez-vous d'orientation")
    expect(page).not_to have_css("span.text-success", text: "bénéficiaire du RSA")
    expect(page).not_to have_css("span.text-success", text: "démarrer un parcours d'accompagnement")

    find("button.btn-close").click

    expect(page).to have_button("Notification")

    click_button("Notification")

    expect(page).to have_css("span.text-success", text: "nouveau type de rendez-vous", wait: 10)
    expect(page).to have_css("span.text-success", text: "nouveau coup de téléphone")
    expect(page).to have_css("span.text-success", text: "une personne remarquable")
    expect(page).to have_css("span.text-success", text: "vous rencontrer")

    expect(page).not_to have_css("span.text-success", text: "rendez-vous d'orientation téléphonique")
    expect(page).not_to have_css("span.text-success", text: "rendez-vous d'orientation")
    expect(page).not_to have_css("span.text-success", text: "bénéficiaire du RSA")
    expect(page).not_to have_css("span.text-success", text: "démarrer un parcours d'accompagnement")
  end
end
