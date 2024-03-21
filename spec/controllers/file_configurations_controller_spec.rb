describe FileConfigurationsController do
  let!(:organisation) { create(:organisation) }
  let!(:another_organisation) { create(:organisation) }
  let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let!(:file_configuration) { create(:file_configuration, category_configurations: [category_configuration]) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:unauthorized_agent) { create(:agent, admin_role_in_organisations: [another_organisation]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#show" do
    let!(:show_params) { { organisation_id: organisation.id, id: file_configuration.id } }

    it "displays the file_configuration" do
      get :show, params: show_params

      expect(response).to be_successful
      expect(unescaped_response_body).to match(/Nom de l'onglet Excel/)
      expect(unescaped_response_body).to match(/#{file_configuration.sheet_name}/)
      expect(unescaped_response_body).to match(/Colonnes obligatoires/)
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

    it "displays the new form for file_configuration" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(unescaped_response_body).to match(/Créer fichier d'import/)
      expect(unescaped_response_body).to match(/new_file_configuration/)
      expect(unescaped_response_body).to match(/Information collectée/)
      expect(unescaped_response_body).to match(/Nom de la colonne dans le fichier/)
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
    let!(:edit_params) { { organisation_id: organisation.id, id: file_configuration.id } }

    it "displays the edit form for file_configuration" do
      get :edit, params: edit_params

      expect(response).to be_successful
      expect(unescaped_response_body).to match(/Modifier fichier d'import/)
      expect(unescaped_response_body).to match(/edit_file_configuration/)
      expect(unescaped_response_body).to match(/Information collectée/)
      expect(unescaped_response_body).to match(/Nom de la colonne dans le fichier/)
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
        file_configuration: {
          sheet_name: "INDEX BENEFICIAIRES", title_column: "Civilité", first_name_column: "Prénom",
          last_name_column: "Nom", role_column: "Rôle", email_column: "Adresses mail"
        },
        organisation_id: organisation.id
      }
    end

    it "creates the file category_configuration" do
      expect { post :create, params: create_params, format: :turbo_stream }.to change(FileConfiguration, :count).by(1)
    end

    it "assigns the corrects attributes" do
      post :create, params: create_params, format: :turbo_stream
      expect(FileConfiguration.last.reload.sheet_name).to eq("INDEX BENEFICIAIRES")
      expect(FileConfiguration.last.reload.title_column).to eq("Civilité")
      expect(FileConfiguration.last.reload.first_name_column).to eq("Prénom")
      expect(FileConfiguration.last.reload.last_name_column).to eq("Nom")
      expect(FileConfiguration.last.reload.role_column).to eq("Rôle")
      expect(FileConfiguration.last.reload.email_column).to eq("Adresses mail")
    end

    context "when the creation succeeds" do
      it "is a success" do
        post :create, params: create_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Le fichier d'import a été créé avec succès/)
      end

      it "adds the file_configuration to the category_configuration form" do
        post :create, params: create_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/Nouvelle category_configuration/)
      end
    end

    context "when the creation fails" do
      let!(:create_params) do
        {
          file_configuration: {
            sheet_name: "INDEX BENEFICIAIRES"
          },
          organisation_id: organisation.id
        }
      end

      it "renders the new form" do
        post :create, params: create_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/Créer fichier d'import/)
        expect(unescaped_response_body).to match(/new_file_configuration/)
        expect(unescaped_response_body).to match(/Information collectée/)
        expect(unescaped_response_body).to match(/Nom de la colonne dans le fichier/)
        expect(unescaped_response_body).to match(/Civilité doit être rempli/)
        expect(unescaped_response_body).to match(/Prénom doit être rempli/)
        expect(unescaped_response_body).to match(/Nom de famille doit être rempli/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        post :create, params: create_params, format: :turbo_stream

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authorized because not admin in the right organisation" do
      before do
        sign_in(unauthorized_agent)
      end

      it "raises an error" do
        expect do
          post :create, params: create_params, format: :turbo_stream
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#update" do
    let!(:update_params) do
      {
        file_configuration: {
          sheet_name: "INDEX BENEFICIAIRES", title_column: "monsieurmadame", first_name_column: "Prénom",
          last_name_column: "Nom", role_column: "Rôle benef", email_column: "Adresses mail"
        },
        organisation_id: organisation.id, id: file_configuration.id
      }
    end

    it "updates the category_configuration" do
      patch :update, params: update_params, format: :turbo_stream
      expect(file_configuration.reload.sheet_name).to eq("INDEX BENEFICIAIRES")
      expect(file_configuration.reload.title_column).to eq("monsieurmadame")
      expect(file_configuration.reload.first_name_column).to eq("Prénom")
      expect(file_configuration.reload.last_name_column).to eq("Nom")
      expect(file_configuration.reload.role_column).to eq("Rôle benef")
      expect(file_configuration.reload.email_column).to eq("Adresses mail")
    end

    context "when the update succeeds" do
      it "is a success" do
        patch :update, params: update_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Le fichier d'import a été modifié avec succès/)
      end
    end

    context "when the update fails" do
      let!(:update_params) do
        {
          file_configuration: {
            first_name_column: "", last_name_column: "", title_column: ""
          },
          organisation_id: organisation.id, id: file_configuration.id
        }
      end

      it "renders the edit page" do
        patch :update, params: update_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/Modifier fichier d'import/)
        expect(unescaped_response_body).to match(/edit_file_configuration/)
        expect(unescaped_response_body).to match(/Information collectée/)
        expect(unescaped_response_body).to match(/Nom de la colonne dans le fichier/)
        expect(unescaped_response_body).to match(/Civilité doit être rempli/)
        expect(unescaped_response_body).to match(/Prénom doit être rempli/)
        expect(unescaped_response_body).to match(/Nom de famille doit être rempli/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        patch :update, params: update_params, format: :turbo_stream

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
          patch :update, params: update_params, format: :turbo_stream
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#confirm_update" do
    let!(:update_params) do
      {
        file_configuration: {
          sheet_name: "INDEX BENEFICIAIRES", title_column: "monsieurmadame", first_name_column: "Prénom",
          last_name_column: "Nom", role_column: "Rôle benef", email_column: "Adresses mail"
        },
        organisation_id: organisation.id, file_configuration_id: file_configuration.id
      }
    end

    context "when the file_configuration is linked to many category_configurations" do
      let!(:organisation2) { create(:organisation) }
      let!(:category_configuration2) { create(:category_configuration, organisation: organisation2) }
      let!(:file_configuration) do
        create(:file_configuration, category_configurations: [category_configuration, category_configuration2])
      end

      it "opens a confirm modal" do
        patch :confirm_update, params: update_params, format: :turbo_stream
        expect(unescaped_response_body).to match(/Ce fichier est utilisé par d'autres organisations/)
        expect(unescaped_response_body).to match(/Modifier pour toutes/)
        expect(unescaped_response_body).to match(/Dupliquer et sauvegarder/)
      end
    end
  end
end
