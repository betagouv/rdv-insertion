describe CategoryConfigurationsController do
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(:organisation, name: "PIE Pantin", slug: "pie-pantin", email: "pie@pantin.fr", phone_number: "0102030405",
                          independent_from_cd: true, department: department)
  end
  let!(:another_organisation) { create(:organisation, department: department) }
  let!(:file_configuration) { create(:file_configuration) }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, file_configuration: file_configuration)
  end
  let!(:another_configuration) { create(:category_configuration, organisation: another_organisation) }
  let!(:config_of_other_dep) { create(:category_configuration, organisation: create(:organisation)) }
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

    it "displays the category_configurations of the organisation" do
      get :index, params: index_params

      expect(response.body).to match(/turbo-frame id="category_configuration_#{category_configuration.id}"/)
      expect(response.body).not_to match(/turbo-frame id="category_configuration_#{another_configuration.id}"/)
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
    let!(:show_params) { { id: category_configuration.id, organisation_id: organisation.id } }

    it "renders the category_configuration page" do
      get :show, params: show_params

      expect(response).to be_successful
      expect(response.body).to match(/Contexte/)
      expect(response.body).to match(/Formats d&#39;invitations/)
      expect(response.body).to match(/Fichier d'import/)
    end

    it "displays the file_configuration details of the category_configuration" do
      get :show, params: show_params

      expect(response.body).to match(/#{category_configuration.file_configuration.sheet_name}/)
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
    let!(:new_configuration) { build(:category_configuration, organisation: organisation) }
    let!(:new_params) { { organisation_id: organisation.id } }

    it "renders the new user page" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(response.body).to match(/Créer configuration/)
    end

    it "displays the file_configurations of the department" do
      get :new, params: new_params

      expect(response.body).to match(
        "category_configuration_file_configuration_#{category_configuration.file_configuration.id}"
      )
      expect(response.body).to match(
        "category_configuration_file_configuration_#{another_configuration.file_configuration.id}"
      )
      expect(response.body).not_to match(
        "category_configuration_file_configuration_#{config_of_other_dep.file_configuration.id}"
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
    let!(:edit_params) { { organisation_id: organisation.id, id: category_configuration.id } }

    it "renders the edit user page" do
      get :edit, params: edit_params

      expect(response).to be_successful
      expect(unescaped_response_body).to include("Modifier \"#{category_configuration.motif_category_name}\"")
    end

    it "displays the file_configurations of the department" do
      get :edit, params: edit_params

      expect(response.body).to match(
        "category_configuration_file_configuration_#{category_configuration.file_configuration.id}"
      )
      expect(response.body).to match(
        "category_configuration_file_configuration_#{another_configuration.file_configuration.id}"
      )
      expect(response.body).not_to match(
        "category_configuration_file_configuration_#{config_of_other_dep.file_configuration.id}"
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
    let!(:create_params) do
      { category_configuration: category_configuration_attributes, organisation_id: organisation.id }
    end
    let!(:category_configuration_attributes) do
      {
        invitation_formats: %w[sms email postal], convene_user: false,
        rdv_with_referents: true, invite_to_user_organisations_only: true,
        number_of_days_before_action_required: 12,
        motif_category_id: motif_category.id, file_configuration_id: file_configuration.id,
        number_of_days_between_periodic_invites: 15
      }
    end
    let!(:category_configuration) do
      create(:category_configuration, **category_configuration_attributes, organisation: organisation)
    end

    before do
      allow(CategoryConfigurations::Create).to receive(:call)
        .and_return(OpenStruct.new(success?: true, category_configuration: category_configuration))
      allow(CategoryConfiguration).to receive(:new).and_return(category_configuration)
    end

    it "tries to create the category_configuration" do
      expect(CategoryConfigurations::Create).to receive(:call)
        .with(category_configuration: category_configuration)
      post :create, params: create_params
    end

    context "when the creation succeeds" do
      it "is a success" do
        post :create, params: create_params
        expect(response).to redirect_to(organisation_category_configuration_path(organisation, category_configuration))
      end
    end

    context "when the creation fails" do
      let!(:category_configuration) do
        build(:category_configuration, **category_configuration_attributes, organisation: organisation)
      end

      before do
        allow(CategoryConfigurations::Create).to receive(:call)
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
        category_configuration: {
          invitation_formats: %w[sms email postal], convene_user: false,
          rdv_with_referents: true, invite_to_user_organisations_only: true,
          number_of_days_before_action_required: 12,
          day_of_the_month_periodic_invites: 5
        },
        organisation_id: organisation.id, id: category_configuration.id
      }
    end

    it "updates the category_configuration" do
      patch :update, params: update_params
      expect(category_configuration.reload.invitation_formats).to eq(%w[sms email postal])
      expect(category_configuration.reload.convene_user).to eq(false)
      expect(category_configuration.reload.rdv_with_referents).to eq(true)
      expect(category_configuration.reload.invite_to_user_organisations_only).to eq(true)
      expect(category_configuration.reload.number_of_days_before_action_required).to eq(12)
      expect(category_configuration.reload.day_of_the_month_periodic_invites).to eq(5)
    end

    context "when the update succeeds" do
      it "is a success" do
        patch :update, params: update_params
        expect(response).to redirect_to(organisation_category_configuration_path(organisation, category_configuration))
      end
    end

    context "when the update fails" do
      let!(:update_params) do
        {
          category_configuration: {
            number_of_days_before_action_required: 2
          },
          organisation_id: organisation.id, id: category_configuration.id
        }
      end

      it "renders the edit page" do
        patch :update, params: update_params
        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(unescaped_response_body).to include("Modifier \"#{category_configuration.motif_category_name}\"")
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
      { organisation_id: organisation.id, id: category_configuration.id, format: "text/html" }
    end

    it "destroys the category_configuration" do
      expect do
        delete :destroy, params: destroy_params
        CategoryConfiguration.find(category_configuration.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the destroy succeeds" do
      it "is a success" do
        delete :destroy, params: destroy_params
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Le contexte a été supprimé avec succès/)
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
