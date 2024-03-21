describe MessagesConfigurationsController do
  let!(:organisation) { create(:organisation) }
  let!(:another_organisation) { create(:organisation) }
  let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let!(:messages_configuration) do
    create(:messages_configuration, organisation: organisation,
                                    direction_names: ["DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX"],
                                    signature_lines: ["Antoine Dupont, ministre de l'Intérieur"],
                                    sender_city: "Toulouse",
                                    letter_sender_name: "le CD rose",
                                    sms_sender_name: "Toulouse31")
  end
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#show" do
    let!(:show_params) { { organisation_id: organisation.id, id: messages_configuration.id } }

    it "displays the messages_configuration" do
      get :show, params: show_params

      expect(response).to be_successful
      expect(response.body).to match(/Courrier/)
      expect(response.body).to match(/En-têtes/)
      expect(response.body).to match(/DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX/)
      expect(response.body).to match(/Signature/)
      expect(response.body).to match(/Antoine Dupont, ministre de l&#39;Intérieur/)
      expect(response.body).to match(/Ville d&#39;expédition/)
      expect(response.body).to match(/Toulouse/)
      expect(response.body).to match(/Nom de l&#39;expéditeur/)
      expect(response.body).to match(/le CD rose/)
      expect(response.body).to match(/Afficher les logos européens/)
      expect(response.body).to match(/Afficher le logo du département/)
      expect(response.body).to match(/Adresse d&#39;accueil/)
      expect(response.body).to match(/SMS/)
      expect(response.body).to match(/Toulouse31/)
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        get :show, params: show_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authorized because not admin in the right organisation" do
      let!(:unauthorized_agent) { create(:agent, admin_role_in_organisations: [another_organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "raises an error" do
        expect do
          get :show, params: show_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#new" do
    let!(:new_params) { { organisation_id: organisation.id } }

    it "displays the messages_configuration" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(response.body).to match(/Courrier/)
      expect(response.body).to match(/En-têtes/)
      expect(response.body).to match(/Signature/)
      expect(response.body).to match(/Ville d&#39;expédition/)
      expect(response.body).to match(/Nom de l&#39;expéditeur/)
      expect(response.body).to match(/Afficher les logos européens/)
      expect(response.body).to match(/Afficher le logo du département/)
      expect(response.body).to match(/Adresse d&#39;accueil/)
      expect(response.body).to match(/SMS/)
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        get :new, params: new_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authorized because not admin in the right organisation" do
      let!(:unauthorized_agent) { create(:agent, admin_role_in_organisations: [another_organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "raises an error" do
        expect do
          get :new, params: new_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#edit" do
    let!(:edit_params) { { organisation_id: organisation.id, id: messages_configuration.id } }

    it "displays the messages_configuration" do
      get :edit, params: edit_params

      expect(response).to be_successful
      expect(response.body).to match(/Courrier/)
      expect(response.body).to match(/En-têtes/)
      expect(response.body).to match(/DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX/)
      expect(response.body).to match(/Signature/)
      expect(response.body).to match(/Antoine Dupont, ministre de l&#39;Intérieur/)
      expect(response.body).to match(/Ville d&#39;expédition/)
      expect(response.body).to match(/Toulouse/)
      expect(response.body).to match(/Nom de l&#39;expéditeur/)
      expect(response.body).to match(/le CD rose/)
      expect(response.body).to match(/Afficher les logos européens/)
      expect(response.body).to match(/Afficher le logo du département/)
      expect(response.body).to match(/Adresse d&#39;accueil/)
      expect(response.body).to match(/SMS/)
      expect(response.body).to match(/Toulouse31/)
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        get :edit, params: edit_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authorized because not admin in the right organisation" do
      let!(:unauthorized_agent) { create(:agent, admin_role_in_organisations: [another_organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "raises an error" do
        expect do
          get :edit, params: edit_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#create" do
    let!(:create_params) do
      {
        messages_configuration: {
          direction_names: ["Sous-direction à l'insertion"], sender_city: "Marseille",
          letter_sender_name: "la SDI de Marseille", signature_lines: ["Payet, aucun trophée"],
          help_address: "sur la Canebière", display_europe_logos: true, sms_sender_name: "Marseille13",
          display_department_logo: false, display_france_travail_logo: true
        },
        organisation_id: organisation.id
      }
    end

    it "creates the messages_configuration" do
      expect { post :create, params: create_params }.to change(MessagesConfiguration, :count).by(1)
    end

    it "assigns the correct attributes" do
      post :create, params: create_params

      expect(MessagesConfiguration.last.direction_names).to eq(["Sous-direction à l'insertion"])
      expect(MessagesConfiguration.last.sender_city).to eq("Marseille")
      expect(MessagesConfiguration.last.letter_sender_name).to eq("la SDI de Marseille")
      expect(MessagesConfiguration.last.signature_lines).to eq(["Payet, aucun trophée"])
      expect(MessagesConfiguration.last.help_address).to eq("sur la Canebière")
      expect(MessagesConfiguration.last.display_europe_logos).to eq(true)
      expect(MessagesConfiguration.last.display_france_travail_logo).to eq(true)
      expect(MessagesConfiguration.last.sms_sender_name).to eq("Marseille13")
      expect(MessagesConfiguration.last.display_department_logo).to eq(false)
    end

    context "when letter_sender_name and sender_city are blank" do
      let!(:create_params) do
        { messages_configuration: { sender_city: "  ", letter_sender_name: "" }, organisation_id: organisation.id }
      end

      it "saves thoses attributes as nil values" do
        post :create, params: create_params

        expect(MessagesConfiguration.last.sender_city).to eq(nil)
        expect(MessagesConfiguration.last.letter_sender_name).to eq(nil)
      end
    end

    context "when the create succeeds" do
      it "is a success" do
        post :create, params: create_params
        expect(response).to redirect_to(organisation_category_configurations_path(organisation))
        expect(response.body).not_to match(/input/)
      end
    end

    context "when the create fails" do
      let!(:create_params) do
        {
          messages_configuration: {
            sms_sender_name: "leCDdeMarseille13"
          },
          organisation_id: organisation.id
        }
      end

      it "renders the new page" do
        post :create, params: create_params

        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/Courrier/)
        expect(response.body).to match(/En-têtes/)
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/ne doit pas dépasser 11 caractères/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        patch :create, params: create_params

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#update" do
    let!(:update_params) do
      {
        messages_configuration: {
          direction_names: ["Sous-direction à l'insertion"], sender_city: "Marseille",
          letter_sender_name: "la SDI de Marseille", signature_lines: ["Payet, aucun trophée"],
          help_address: "sur la Canebière", display_europe_logos: true, sms_sender_name: "Marseille13",
          display_department_logo: false, display_france_travail_logo: true
        },
        organisation_id: organisation.id, id: messages_configuration.id
      }
    end

    it "updates the category_configuration" do
      patch :update, params: update_params

      expect(messages_configuration.reload.direction_names).to eq(["Sous-direction à l'insertion"])
      expect(messages_configuration.reload.sender_city).to eq("Marseille")
      expect(messages_configuration.reload.letter_sender_name).to eq("la SDI de Marseille")
      expect(messages_configuration.reload.signature_lines).to eq(["Payet, aucun trophée"])
      expect(messages_configuration.reload.help_address).to eq("sur la Canebière")
      expect(messages_configuration.reload.display_europe_logos).to eq(true)
      expect(messages_configuration.reload.display_france_travail_logo).to eq(true)
      expect(messages_configuration.reload.sms_sender_name).to eq("Marseille13")
      expect(messages_configuration.reload.display_department_logo).to eq(false)
    end

    context "when the update succeeds" do
      it "is a success" do
        patch :update, params: update_params
        expect(response).to be_successful
        expect(response.body).not_to match(/input/)
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Les réglages ont été modifiés avec succès/)
      end
    end

    context "when the update fails" do
      let!(:update_params) do
        {
          messages_configuration: {
            sms_sender_name: "leCDdeMarseille13"
          },
          organisation_id: organisation.id, id: messages_configuration.id
        }
      end

      it "renders the edit page" do
        patch :update, params: update_params

        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/Courrier/)
        expect(response.body).to match(/En-têtes/)
        expect(response.body).to match(/DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX/)
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/ne doit pas dépasser 11 caractères/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        patch :update, params: update_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authorized because not admin in the right organisation" do
      let!(:unauthorized_agent) { create(:agent, admin_role_in_organisations: [another_organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "raises an error" do
        expect do
          patch :update, params: update_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
