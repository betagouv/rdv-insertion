describe ConfigurationsController do
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(:organisation, name: "PIE Pantin", slug: "pie-pantin", email: "pie@pantin.fr", phone_number: "0102030405",
                          independent_from_cd: true, department: department)
  end
  let!(:another_organisation) { create(:organisation, department: department) }
  let!(:file_configuration) { create(:file_configuration) }
  let!(:configuration) do
    create(:configuration, organisation: organisation, file_configuration: file_configuration)
  end
  let!(:another_configuration) { create(:configuration, organisation: another_organisation) }
  let!(:config_of_other_dep) { create(:configuration, organisation: create(:organisation)) }
  let!(:messages_configuration) { create(:messages_configuration, organisation: organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#index" do
    let!(:index_params) { { organisation_id: organisation.id } }

    it "renders the index page" do
      get :index, params: index_params

      expect(response).to be_successful
      expect(response.body).to match(/Détails de l'organisation/)
      expect(response.body).to match(/Catégories de motifs configurés/)
      expect(response.body).to match(/Configuration des messages/)
    end

    it "displays the organisation" do
      get :index, params: index_params

      expect(response.body).to match(/Nom/)
      expect(response.body).to match(/PIE Pantin/)
      expect(response.body).to match(/Email/)
      expect(response.body).to match(/pie@pantin.fr/)
      expect(response.body).to match(/Numéro de téléphone/)
      expect(response.body).to match(/0102030405/)
      expect(response.body).to match(/Indépendante du CD/)
      expect(response.body).to match(/Oui/)
      expect(response.body).to match(/Logo/)
      expect(response.body).to match(/Désignation dans le fichier usagers/)
      expect(response.body).to match(/pie-pantin/)
    end

    it "displays the configurations of the organisation" do
      get :index, params: index_params

      expect(response.body).to match(/turbo-frame id="configuration_#{configuration.id}"/)
      expect(response.body).not_to match(/turbo-frame id="configuration_#{another_configuration.id}"/)
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        get :index, params: index_params

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
          get :index, params: index_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#show" do
    let!(:show_params) { { id: configuration.id, organisation_id: organisation.id } }

    it "renders the configuration page" do
      get :show, params: show_params

      expect(response).to be_successful
      expect(response.body).to match(/Contexte/)
      expect(response.body).to match(/Formats d&#39;invitations/)
      expect(response.body).to match(/Fichier d'import/)
    end

    it "displays the file_configuration details of the configuration" do
      get :show, params: show_params

      expect(response.body).to match(/#{configuration.file_configuration.sheet_name}/)
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
    let!(:new_configuration) { build(:configuration, organisation: organisation) }
    let!(:new_params) { { organisation_id: organisation.id } }

    it "renders the new user page" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(response.body).to match(/Créer configuration/)
    end

    it "displays the file_configurations of the department" do
      get :new, params: new_params

      expect(response.body).to match("configuration_file_configuration_#{configuration.file_configuration.id}")
      expect(response.body).to match("configuration_file_configuration_#{another_configuration.file_configuration.id}")
      expect(response.body).not_to match(
        "configuration_file_configuration_#{config_of_other_dep.file_configuration.id}"
      )
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
    let!(:edit_params) { { organisation_id: organisation.id, id: configuration.id } }

    it "renders the edit user page" do
      get :edit, params: edit_params

      expect(response).to be_successful
      expect(unescaped_response_body).to include("Modifier \"#{configuration.motif_category_name}\"")
    end

    it "displays the file_configurations of the department" do
      get :edit, params: edit_params

      expect(response.body).to match("configuration_file_configuration_#{configuration.file_configuration.id}")
      expect(response.body).to match("configuration_file_configuration_#{another_configuration.file_configuration.id}")
      expect(response.body).not_to match(
        "configuration_file_configuration_#{config_of_other_dep.file_configuration.id}"
      )
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
    let!(:motif_category) { create(:motif_category) }
    let!(:create_params) { { configuration: configuration_attributes, organisation_id: organisation.id } }
    let!(:configuration_attributes) do
      {
        invitation_formats: %w[sms email postal], convene_user: false,
        rdv_with_referents: true, invite_to_user_organisations_only: true,
        number_of_days_before_action_required: 12,
        motif_category_id: motif_category.id, file_configuration_id: file_configuration.id,
        number_of_days_between_periodic_invites: 15
      }
    end
    let!(:configuration) { create(:configuration, **configuration_attributes, organisation: organisation) }

    before do
      allow(Configurations::Create).to receive(:call)
        .and_return(OpenStruct.new(success?: true, configuration: configuration))
      allow(Configuration).to receive(:new).and_return(configuration)
    end

    it "tries to create the configuration" do
      expect(Configurations::Create).to receive(:call)
        .with(configuration: configuration)
      post :create, params: create_params
    end

    context "when the creation succeeds" do
      it "is a success" do
        post :create, params: create_params
        expect(response).to redirect_to(organisation_configuration_path(organisation, configuration))
      end
    end

    context "when the creation fails" do
      let!(:configuration) { build(:configuration, **configuration_attributes, organisation: organisation) }

      before do
        allow(Configurations::Create).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors:
            ["Catégorie de motifs doit exister"]))
      end

      it "renders the new page" do
        post :create, params: create_params
        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/Créer configuration/)
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Catégorie de motifs doit exister/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        post :create, params: create_params

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
          post :create, params: create_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#update" do
    let!(:update_params) do
      {
        configuration: {
          invitation_formats: %w[sms email postal], convene_user: false,
          rdv_with_referents: true, invite_to_user_organisations_only: true,
          number_of_days_before_action_required: 12,
          day_of_the_month_periodic_invites: 5
        },
        organisation_id: organisation.id, id: configuration.id
      }
    end

    it "updates the configuration" do
      patch :update, params: update_params
      expect(configuration.reload.invitation_formats).to eq(%w[sms email postal])
      expect(configuration.reload.convene_user).to eq(false)
      expect(configuration.reload.rdv_with_referents).to eq(true)
      expect(configuration.reload.invite_to_user_organisations_only).to eq(true)
      expect(configuration.reload.number_of_days_before_action_required).to eq(12)
      expect(configuration.reload.day_of_the_month_periodic_invites).to eq(5)
    end

    context "when the update succeeds" do
      it "is a success" do
        patch :update, params: update_params
        expect(response).to redirect_to(organisation_configuration_path(organisation, configuration))
      end
    end

    context "when the update fails" do
      let!(:update_params) do
        {
          configuration: {
            number_of_days_before_action_required: 2
          },
          organisation_id: organisation.id, id: configuration.id
        }
      end

      it "renders the edit page" do
        patch :update, params: update_params
        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(unescaped_response_body).to include("Modifier \"#{configuration.motif_category_name}\"")
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Le délai d'expiration de l'invtation doit être supérieur à 3 jours/)
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

  describe "#destroy" do
    let!(:destroy_params) do
      { organisation_id: organisation.id, id: configuration.id, format: "text/html" }
    end

    it "destroys the configuration" do
      expect do
        delete :destroy, params: destroy_params
        Configuration.find(configuration.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the destroy succeeds" do
      it "is a success" do
        delete :destroy, params: destroy_params
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/La configuration a été supprimée avec succès/)
      end
    end

    context "when not authorized because not admin" do
      let!(:unauthorized_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        sign_in(unauthorized_agent)
      end

      it "redirects to the homepage" do
        delete :destroy, params: destroy_params

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
          delete :destroy, params: destroy_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
