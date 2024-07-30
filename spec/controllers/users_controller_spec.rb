describe UsersController do
  let!(:department) { create(:department) }
  let!(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
  end
  let!(:category_accompagnement) do
    create(:motif_category, short_name: "rsa_accompagnement", name: "RSA accompagnement")
  end
  let!(:category_configuration) do
    create(
      :category_configuration,
      motif_category: category_orientation,
      number_of_days_before_action_required: number_of_days_before_action_required
    )
  end
  let!(:number_of_days_before_action_required) { 6 }
  let!(:organisation) do
    create(:organisation, rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
                          department_id: department.id, category_configurations: [category_configuration])
  end
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:rdv_solidarites_organisation_id) { 888 }
  let(:user) { create(:user, organisations: [organisation]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#new" do
    let!(:new_params) { { organisation_id: organisation.id } }

    it "renders the new user page" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(response.body).to match(/Prénom/)
      expect(response.body).to match(/Enregistrer/)
    end
  end

  describe "#create" do
    before do
      allow(Users::FindOrInitialize).to receive(:call)
        .and_return(OpenStruct.new(success?: true, user: user))
      allow(User).to receive(:new)
        .and_return(user)
      allow(user).to receive(:assign_attributes)
      allow(Users::Save).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    let(:user_params) do
      {
        user: {
          uid: "123xz", first_name: "john", last_name: "doe", email: "johndoe@example.com",
          affiliation_number: "1234", role: "conjoint"
        },
        organisation_id: organisation.id
      }
    end

    it "calls the Users::FindOrInitialize service" do
      expect(Users::FindOrInitialize).to receive(:call)
      post :create, params: user_params
    end

    it "assigns the attributes" do
      expect(user).to receive(:assign_attributes)
      post :create, params: user_params
    end

    it "calls the Users::Save service" do
      expect(Users::Save).to receive(:call)
      post :create, params: user_params
    end

    context "when html request" do
      let(:user_params) do
        {
          user: {
            first_name: "john", last_name: "doe", email: "johndoe@example.com",
            affiliation_number: "1234", role: "demandeur", title: "monsieur"
          },
          organisation_id: organisation.id,
          format: "html"
        }
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }

        it "redirects the agent" do
          post :create, params: user_params.merge(organisation_id: another_organisation.id)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include("Votre compte ne vous permet pas d'effectuer cette action")
        end
      end

      context "when the creation succeeds" do
        it "is a success" do
          post :create, params: user_params
          expect(response).to redirect_to(organisation_user_path(organisation, user))
        end
      end

      context "when the creation fails" do
        before do
          allow(Users::Save).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
        end

        it "renders the new page" do
          post :create, params: user_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Prénom/)
          expect(response.body).to match(/Enregistrer/)
        end
      end
    end

    context "when json request" do
      before { request.accept = "application/json" }

      let(:user_params) do
        {
          user: {
            uid: "123xz", first_name: "john", last_name: "doe", email: "johndoe@example.com",
            affiliation_number: "1234", role: "conjoint"
          },
          organisation_id: organisation.id
        }
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }

        it "renders the errors" do
          post :create, params: user_params.merge(organisation_id: another_organisation.id)
          expect(response).not_to be_successful
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body["errors"]).to eq(["Votre compte ne vous permet pas d'effectuer cette action"])
        end
      end

      context "when the creation succeeds" do
        let!(:user) { create(:user, organisations: [organisation]) }

        it "is a success" do
          post :create, params: user_params
          expect(response).to be_successful
          expect(response.parsed_body["success"]).to eq(true)
        end

        it "renders the user" do
          post :create, params: user_params
          expect(response).to be_successful
          expect(response.parsed_body["user"]["id"]).to eq(user.id)
        end
      end

      context "when the creation fails" do
        before do
          allow(Users::Save).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
        end

        it "is not a success" do
          post :create, params: user_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to eq(false)
        end

        it "renders the errors" do
          post :create, params: user_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["errors"]).to eq(["some error"])
        end
      end
    end
  end

  describe "#show" do
    let!(:user) do
      create(
        :user, first_name: "Andreas", last_name: "Kopke", organisations: [organisation]
      )
    end
    let!(:show_params) { { id: user.id, organisation_id: organisation.id } }

    context "when organisation_level" do
      it "renders the user page" do
        get :show, params: show_params

        expect(response).to be_successful
        expect(response.body).to match(/Andreas/)
        expect(response.body).to match(/Kopke/)
      end
    end

    context "when user is archived" do
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:archive) { create(:archive, user: user, organisation: organisation) }
      let!(:show_params) { { id: user.id, organisation_id: organisation.id } }

      it "the user is displayed as archived" do
        get :show, params: show_params

        expect(response).to be_successful
        expect(response.body).to match(/Dossier archivé/)
        expect(response.body).to match(
          "span class=\"badge badge-tag justify-content-between text-dark-blue me-2 mb-2 " \
          "d-flex text-truncate background-warning"
        )
      end
    end

    context "when department_level" do
      let!(:show_params) { { id: user.id, department_id: department.id } }

      it "renders the user page" do
        get :show, params: show_params

        expect(response).to be_successful
        expect(response.body).to match(/Andreas/)
        expect(response.body).to match(/Kopke/)
      end

      context "when user is archived" do
        let!(:other_organisation) { create(:organisation, department:) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, other_organisation]) }
        let!(:user) { create(:user, organisations: [organisation, other_organisation]) }
        let!(:archive) { create(:archive, user: user, organisation: organisation) }
        let!(:archive2) { create(:archive, user: user, organisation: other_organisation) }

        it "the user is displayed as archived" do
          get :show, params: show_params

          expect(response).to be_successful
          expect(response.body).to match(/Dossier archivé/)
          matches = response.body.scan(
            "span class=\"badge badge-tag justify-content-between text-dark-blue me-2 mb-2 " \
            "d-flex text-truncate background-warning"
          )
          expect(matches.size).to eq(2)
        end
      end

      context "when user is partially archived" do
        let!(:other_organisation) { create(:organisation, department:) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, other_organisation]) }
        let!(:user) { create(:user, organisations: [organisation, other_organisation]) }
        let!(:archive) { create(:archive, user: user, organisation: organisation) }

        it "the user is not displayed as archived" do
          get :show, params: show_params

          expect(response).to be_successful
          expect(response.body).not_to match(/Dossier archivé/)
          matches = response.body.scan(
            "span class=\"badge badge-tag justify-content-between text-dark-blue me-2 mb-2 " \
            "d-flex text-truncate background-warning"
          )
          expect(matches.size).to eq(1)
        end
      end
    end
  end

  describe "#default_list" do
    context "when department_level" do
      let!(:index_params) { { department_id: department.id } }

      context "when department has no motif_categories" do
        let!(:organisation) { create(:organisation, department: department, category_configurations: []) }

        it "redirects to the department_users_paths with no params" do
          get :default_list, params: index_params

          expect(response).to redirect_to(department_users_path(department))
        end
      end

      context "when department has one motif_category" do
        let!(:category_orientation) do
          create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
        end
        let!(:category_configuration) { create(:category_configuration, motif_category: category_orientation) }
        let!(:organisation) do
          create(:organisation, department: department, category_configurations: [category_configuration])
        end

        it "redirects to the motif_category index" do
          get :default_list, params: index_params

          expect(response).to redirect_to(
            department_users_path(department, motif_category_id: category_orientation.id)
          )
        end
      end

      context "when department has multiple motif_categories" do
        let!(:category_orientation) do
          create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
        end
        let!(:category_accompagnement) do
          create(:motif_category, short_name: "rsa_accompagnement", name: "RSA accompagnement")
        end
        let!(:category_configuration) { create(:category_configuration, motif_category: category_orientation) }
        let!(:category_configuration2) { create(:category_configuration, motif_category: category_accompagnement) }
        let!(:organisation) do
          create(:organisation, department: department,
                                category_configurations: [category_configuration, category_configuration2])
        end

        it "redirects to the department_users_paths with no params" do
          get :default_list, params: index_params

          expect(response).to redirect_to(department_users_path(department))
        end
      end
    end

    context "when organisation level" do
      let!(:index_params) { { organisation_id: organisation.id } }

      context "when organisation has no motif_categories" do
        let!(:organisation) { create(:organisation, department: department, category_configurations: []) }

        it "redirects to the organisation_users_paths with no params" do
          get :default_list, params: index_params

          expect(response).to redirect_to(organisation_users_path(organisation))
        end
      end

      context "when organisation has one motif_category" do
        let!(:category_orientation) do
          create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
        end
        let!(:category_configuration) { create(:category_configuration, motif_category: category_orientation) }
        let!(:organisation) do
          create(:organisation, department: department, category_configurations: [category_configuration])
        end

        it "redirects to the motif_category index" do
          get :default_list, params: index_params

          expect(response).to redirect_to(
            organisation_users_path(organisation, motif_category_id: category_orientation.id)
          )
        end
      end

      context "when organisation has multiple motif_categories" do
        let!(:category_orientation) do
          create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
        end
        let!(:category_accompagnement) do
          create(:motif_category, short_name: "rsa_accompagnement", name: "RSA accompagnement")
        end
        let!(:category_configuration) { create(:category_configuration, motif_category: category_orientation) }
        let!(:category_configuration2) { create(:category_configuration, motif_category: category_accompagnement) }
        let!(:organisation) do
          create(:organisation, department: department,
                                category_configurations: [category_configuration, category_configuration2])
        end

        it "redirects to the organisation_users_paths with no params" do
          get :default_list, params: index_params

          expect(response).to redirect_to(organisation_users_path(organisation))
        end
      end
    end
  end

  describe "#index" do
    let!(:user) do
      create(
        :user,
        created_at: Time.zone.parse("2023-03-10 12:30"),
        organisations: [organisation], last_name: "Chabat", follow_ups: [follow_up1]
      )
    end
    let!(:follow_up1) { build(:follow_up, motif_category: category_orientation, status: "rdv_seen") }

    let!(:user2) do
      create(
        :user,
        created_at: Time.zone.parse("2023-04-10 12:30"),
        organisations: [organisation], last_name: "Baer", follow_ups: [follow_up2]
      )
    end
    let!(:follow_up2) { build(:follow_up, motif_category: category_orientation, status: "invitation_pending") }

    let!(:user3) do
      create(
        :user,
        created_at: Time.zone.parse("2023-05-10 12:30"),
        organisations: [organisation], last_name: "Darmon", follow_ups: [follow_up3]
      )
    end
    let!(:follow_up3) { build(:follow_up, motif_category: category_accompagnement, status: "invitation_pending") }
    let!(:category_configuration2) { create(:category_configuration, motif_category: category_accompagnement) }

    let!(:archived_user) do
      create(
        :user,
        organisations: [organisation], last_name: "Barthelemy", follow_ups: [follow_up4]
      )
    end
    let!(:archive) { create(:archive, user: archived_user, organisation: organisation) }
    let!(:follow_up4) { build(:follow_up, motif_category: category_orientation, status: "invitation_pending") }

    let!(:other_organisation) { create(:organisation, department:) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, other_organisation]) }
    let!(:partially_archived_user) do
      create(:user, organisations: [organisation, other_organisation], follow_ups: [follow_up5], last_name: "Rouve")
    end
    # user is archived in only one of his organisations
    let!(:archive2) { create(:archive, user: partially_archived_user, organisation: other_organisation) }
    let!(:follow_up5) { build(:follow_up, motif_category: category_orientation, status: "invitation_pending") }

    let!(:index_params) { { organisation_id: organisation.id, motif_category_id: category_orientation.id } }

    it "returns a list of users in the current context" do
      get :index, params: index_params

      expect(response).to be_successful
      expect(response.body).to match(/Chabat/)
      expect(response.body).to match(/Baer/)
      expect(response.body).not_to match(/Darmon/)
      expect(response.body).not_to match(/Barthelemy/)
      expect(response.body).to match(/Rouve/)
    end

    it "does not display the configure organisation option" do
      get :index, params: index_params

      expect(response.body).not_to match(/Configurer l'organisation/)
    end

    context "when there is all types of follow_ups statuses" do
      before do
        FollowUp.statuses.each_key do |status|
          create(:follow_up, motif_category: category_orientation,
                             status: status,
                             user: create(:user, organisations: [organisation]))
        end
      end

      it "displays all statuses in the filter list except closed" do
        get :index, params: index_params.merge(motif_category_id: category_orientation.id)
        FollowUp.statuses.each_key do |status|
          if status == "closed"
            expect(response.body).not_to match(/"#{status}"/)
          else
            expect(response.body).to match(/"#{status}"/)
          end
        end
      end
    end

    context "when the agent is admin" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      before do
        sign_in(agent)
      end

      it "displays the configure organisation option" do
        get :index, params: index_params

        expect(response.body).to match(/Configurer l'organisation/)
      end
    end

    context "when no context is specified" do
      let!(:index_params) { { organisation_id: organisation.id } }

      it "returns the list of all users" do
        get :index, params: index_params

        expect(response).to be_successful
        expect(response.body).to match(/Chabat/)
        expect(response.body).to match(/Baer/)
        expect(response.body).to match(/Darmon/)
        expect(response.body).to match(/Barthelemy/)
        expect(response.body).to match(/Rouve/)
      end

      it "displays the users creation date and the corresponding filter" do
        get :index, params: index_params

        expect(response.body).to match(/Date de création/)
        expect(response.body).to match(/Filtrer par date de création/)
      end

      it "displays the archived users as archived" do
        get :index, params: index_params

        matches = response.body.scan("table-archived")
        expect(matches.size).to eq(1)
      end
    end

    context "when archived users only" do
      let!(:index_params) { { organisation_id: organisation.id, users_scope: "archived" } }

      it "returns the list of archived users" do
        get :index, params: index_params

        expect(response).to be_successful
        expect(response.body).not_to match(/Chabat/)
        expect(response.body).not_to match(/Baer/)
        expect(response.body).to match(/Barthelemy/)
      end

      it "displays the users creation date and the corresponding filter" do
        get :index, params: index_params

        expect(response.body).to match(/Date de création/)
        expect(response.body).to match(/Filtrer par date de création/)
      end

      context "when department level" do
        let!(:index_params) { { department_id: department.id, users_scope: "archived" } }

        it "returns the list of archived users" do
          get :index, params: index_params

          expect(response).to be_successful
          expect(response.body).not_to match(/Chabat/)
          expect(response.body).not_to match(/Baer/)
          expect(response.body).to match(/Barthelemy/)
          expect(response.body).not_to match(/Rouve/)
        end
      end
    end

    context "when a search query is specified" do
      let!(:index_params) do
        { organisation_id: organisation.id, search_query: "chabat", motif_category_id: category_orientation.id }
      end

      it "searches the users" do
        get :index, params: index_params
        expect(response.body).to match(/Chabat/)
        expect(response.body).not_to match(/Baer/)
      end
    end

    context "when a status is passed" do
      let!(:index_params) do
        { organisation_id: organisation.id, status: "invitation_pending", motif_category_id: category_orientation.id }
      end

      it "filters by status" do
        get :index, params: index_params
        expect(response.body).to match(/Baer/)
        expect(response.body).not_to match(/Chabat/)
      end
    end

    context "when creation dates are passed" do
      let!(:index_params) do
        { organisation_id: organisation.id, creation_date_after: "01-04-2023", creation_date_before: "30-04-2023" }
      end

      it "filters by creation dates" do
        get :index, params: index_params
        expect(response.body).to match(/Baer/)
        expect(response.body).not_to match(/Chabat/)
        expect(response.body).not_to match(/Darmon/)
      end
    end

    context "when tags filters are passed" do
      let!(:tags) do
        [
          create(:tag, value: "tag1"),
          create(:tag, value: "tag2"),
          create(:tag, value: "tag3")
        ]
      end

      let!(:user) do
        create(
          :user,
          organisations: [organisation],
          first_name: "Michael",
          tag_users_attributes: [{ tag_id: tags[0].id }]
        )
      end

      let!(:user2) do
        create(:user, organisations: [organisation], first_name: "Marie",
                      tag_users_attributes: [{ tag_id: tags[0].id }, { tag_id: tags[1].id }])
      end

      let!(:user3) do
        create(:user, organisations: [organisation], first_name: "Oliva",
                      tag_users_attributes: [{ tag_id: tags[2].id }])
      end

      let!(:index_params) do
        { organisation_id: organisation.id, tag_ids: [tags[0].id, tags[1].id] }
      end

      it "filters by tag" do
        get :index, params: index_params
        expect(response.body).not_to match(/Michael/)
        expect(response.body).to match(/Marie/)
        expect(response.body).not_to match(/Oliva/)
      end

      context "when a single tag is given as string" do
        let!(:index_params) do
          { organisation_id: organisation.id, tag_ids: tags[2].id }
        end

        it "filters by this tag" do
          get :index, params: index_params
          expect(response.body).to match(/Oliva/)
          expect(response.body).not_to match(/Michael/)
          expect(response.body).not_to match(/Marie/)
        end
      end
    end

    context "when invitations dates are passed" do
      let!(:invitation1) do
        create(
          :invitation, created_at: Time.zone.parse("2022-06-01 12:00"), follow_up: follow_up1,
                       user: user
        )
      end
      let!(:invitation2) do
        create(
          :invitation, created_at: Time.zone.parse("2022-06-08 12:00"), follow_up: follow_up2, user: user2
        )
      end
      let!(:invitation3) do
        create(
          :invitation, created_at: Time.zone.parse("2022-06-15 12:00"), follow_up: follow_up3, user: user3
        )
      end

      context "for first invitations" do
        let!(:index_params) do
          { organisation_id: organisation.id, motif_category_id: category_orientation.id,
            first_invitation_date_after: "05-06-2022", first_invitation_date_before: "10-06-2022" }
        end

        it "filters by first invitations dates" do
          get :index, params: index_params
          expect(response.body).to match(/Baer/)
          expect(response.body).not_to match(/Chabat/)
          expect(response.body).not_to match(/Darmon/)
        end
      end

      context "for last invitations" do
        let!(:invitation4) do
          create(:invitation, created_at: Time.zone.parse("2022-06-19 12:00"),
                              follow_up: follow_up1, user: user)
        end
        let!(:invitation5) do
          create(:invitation, created_at: Time.zone.parse("2022-06-16 12:00"),
                              follow_up: follow_up2, user: user2)
        end
        let!(:invitation6) do
          create(:invitation, created_at: Time.zone.parse("2022-06-17 12:00"),
                              follow_up: follow_up3, user: user3)
        end

        let!(:index_params) do
          { organisation_id: organisation.id, motif_category: category_orientation,
            last_invitation_date_after: "17-06-2022", last_invitation_date_before: "17-06-2022" }
        end

        it "filters by last invitations dates" do
          get :index, params: index_params
          expect(response.body).not_to match(/Baer/)
          expect(response.body).not_to match(/Chabat/)
          expect(response.body).to match(/Darmon/)
        end
      end
    end

    context "when action_required is passed" do
      let!(:index_params) do
        { organisation_id: organisation.id, action_required: "true", motif_category_id: category_orientation.id }
      end
      let!(:number_of_days_before_action_required) { 6 }

      context "when the invitation has been sent before the number of days before action required" do
        let!(:invitation) { create(:invitation, user: user2, follow_up: follow_up2, created_at: 7.days.ago) }

        it "filters by action required" do
          get :index, params: index_params
          expect(response.body).to match(/Baer/)
          expect(response.body).not_to match(/Chabat/)
        end
      end

      context "when the invitation has been sent after the number of days defined in the category_configuration" do
        let!(:invitation) { create(:invitation, user: user2, follow_up: follow_up2, created_at: 3.days.ago) }

        it "filters by action required" do
          get :index, params: index_params
          expect(response.body).not_to match(/Baer/)
          expect(response.body).not_to match(/Chabat/)
        end
      end
    end

    context "when referent_id is passed" do
      let!(:index_params) do
        {
          organisation_id: organisation.id,
          referent_id: agent.id,
          motif_category_id: category_orientation.id
        }
      end

      before { user.referents = [agent] }

      it "filters on the users assigned to the agent" do
        get :index, params: index_params
        expect(response.body).to match(/Chabat/)
        expect(response.body).not_to match(/Baer/)
        expect(response.body).not_to match(/Darmon/)
      end
    end

    context "when the organisation convene users" do
      before do
        category_configuration.update!(convene_user: true)
        follow_up2.update!(motif_category: category_accompagnement)
      end

      let!(:rdv) { create(:rdv) }
      let!(:participation) do
        create(
          :participation,
          rdv: rdv,
          user: user,
          status: "unknown",
          follow_up: follow_up1
        )
      end
      let!(:rdv2) { create(:rdv) }
      let!(:participation2) do
        create(
          :participation,
          rdv: rdv2,
          user: user,
          status: "unknown",
          follow_up: follow_up2
        )
      end
      let!(:notification) do
        create(
          :notification,
          participation: participation, event: "participation_created", created_at: Time.zone.parse("20/12/2021 12:00")
        )
      end
      let!(:notification2) do
        create(
          :notification,
          participation: participation, event: "participation_updated", created_at: Time.zone.parse("21/12/2021 12:00")
        )
      end
      let!(:notification3) do
        create(
          :notification,
          participation: participation2, event: "participation_created", created_at: Time.zone.parse("25/12/2021 12:00")
        )
      end

      it "shows the last sent convocation on the current motif category" do
        get :index, params: index_params

        expect(response.body).to include("Dernière convocation envoyée le")
        expect(response.body).to include("20/12/2021")
        expect(response.body).not_to include("21/12/2021")
        expect(response.body).not_to include("25/12/2021")
      end
    end

    context "when department level" do
      let!(:index_params) { { department_id: department.id, motif_category_id: category_orientation.id } }

      it "renders the index page" do
        get :index, params: index_params

        expect(response.body).to match(/Chabat/)
        expect(response.body).to match(/Baer/)
      end

      it "does not display the configure organisation option" do
        get :index, params: index_params

        expect(response.body).not_to match(/Configurer une organisation/)
      end

      context "ordering" do
        context "without motif_category" do
          let!(:index_params) do
            { department_id: department.id }
          end

          before do
            UsersOrganisation.find_by(user: user2, organisation: organisation)
                             .update!(created_at: 1.year.ago)
          end

          it "orders by date of affectation to the department organisations" do
            get :index, params: index_params

            ordered_table = Nokogiri::XML(response.body).css("td").map(&:text)
            ordered_first_names = ordered_table & [user.first_name, user2.first_name]

            expect(ordered_first_names).to eq([user.first_name, user2.first_name])
          end

          context "when there are several organisations linked to a user" do
            let!(:other_org) { create(:organisation, department:, users: [user], agents: [agent]) }

            before do
              UsersOrganisation.find_by(user: user, organisation: other_org)
                               .update!(created_at: 2.years.ago)
            end

            it "orders by date of affectation to the department organisations" do
              get :index, params: index_params

              ordered_table = Nokogiri::XML(response.body).css("td").map(&:text)
              ordered_first_names = ordered_table & [user.first_name, user2.first_name]

              expect(ordered_first_names).to eq([user2.first_name, user.first_name])
            end

            context "at organisation level" do
              it "orders by date of affectation to the organisation" do
                get :index, params: { organisation_id: organisation.id }

                ordered_table = Nokogiri::XML(response.body).css("td").map(&:text)
                ordered_first_names = ordered_table & [user.first_name, user2.first_name]

                expect(ordered_first_names).to eq([user.first_name, user2.first_name])
              end
            end
          end
        end

        context "with motif_category" do
          let!(:index_params) { { department_id: department.id, motif_category_id: category_orientation.id } }

          before do
            user.follow_ups.first.update!(motif_category: category_orientation, created_at: 1.year.ago)
          end

          it "orders by follow_up creation" do
            get :index, params: index_params

            ordered_table = Nokogiri::XML(response.body).css("td").map(&:text)
            ordered_first_names = ordered_table & [user.first_name, user2.first_name]

            expect(ordered_first_names).to eq([user2.first_name, user.first_name])
          end
        end
      end

      context "when the agent is admin" do
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        before do
          sign_in(agent)
        end

        it "displays the configure organisation option" do
          get :index, params: index_params

          expect(response.body).to match(/Configurer une organisation/)
        end
      end
    end

    context "when csv request" do
      before do
        allow(Exporters::CreateUsersCsvExportJob).to receive(:perform_async)
      end

      context "at department level" do
        let!(:index_params) { { department_id: department.id, format: :csv } }
        let!(:other_organisation) { create(:organisation, department:) }
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation, other_organisation]) }

        it "calls the service" do
          expect(Exporters::CreateUsersCsvExportJob).to receive(:perform_async)
          get :index, params: index_params
        end

        it "redirects to users page" do
          get :index, params: index_params
          expect(response).to redirect_to(department_users_path(department))
        end

        context "when not admin in all organisations" do
          let!(:agent) do
            create(
              :agent, admin_role_in_organisations: [organisation], basic_role_in_organisations: [other_organisation]
            )
          end

          it "does not call the service" do
            expect(Exporters::CreateUsersCsvExportJob).not_to receive(:perform_async)

            get :index, params: index_params
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq("Votre compte ne vous permet pas d'effectuer cette action")
          end
        end
      end

      context "at organisation level" do
        let!(:index_params) { { organisation_id: organisation.id, format: :csv } }
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        it "calls the service" do
          expect(Exporters::CreateUsersCsvExportJob).to receive(:perform_async)
          get :index, params: index_params
        end

        it "redirects to users page" do
          get :index, params: index_params
          expect(response).to redirect_to(organisation_users_path(organisation))
        end

        context "when the agent is not admin in the org" do
          let!(:agent) do
            create(:agent, basic_role_in_organisations: [organisation])
          end

          it "does not call the service" do
            expect(Exporters::CreateUsersCsvExportJob).not_to receive(:perform_async)

            get :index, params: index_params
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq("Votre compte ne vous permet pas d'effectuer cette action")
          end
        end
      end
    end
  end

  describe "#edit" do
    let!(:user) { create(:user, organisations: [organisation]) }

    context "when organisation_level" do
      let!(:edit_params) { { id: user.id, organisation_id: organisation.id } }

      it "renders the edit user page" do
        get :edit, params: edit_params

        expect(response).to be_successful
        expect(response.body).to match(/Prénom/)
        expect(response.body).to match(/"#{user.first_name}"/)
        expect(response.body).to match(/Enregistrer/)
      end
    end

    context "when department_level" do
      let!(:edit_params) { { id: user.id, department_id: department.id } }

      it "renders the edit user page" do
        get :edit, params: edit_params

        expect(response.body).to match(/Prénom/)
        expect(response.body).to match(/"#{user.first_name}"/)
        expect(response.body).to match(/Enregistrer/)
      end
    end
  end

  describe "#update" do
    let!(:user) { create(:user, organisations: [organisation]) }
    let!(:update_params) do
      { id: user.id, organisation_id: organisation.id, user: { birth_date: "20/12/1988" } }
    end

    before do
      sign_in(agent)
    end

    context "when json request" do
      let(:update_params) do
        {
          user: {
            birth_date: "20/12/1988"
          },
          id: user.id,
          organisation_id: organisation.id,
          format: "json"
        }
      end

      before do
        allow(Users::Save).to receive(:call)
          .and_return(OpenStruct.new)
      end

      it "calls the service" do
        expect(Users::Save).to receive(:call)
        post :update, params: update_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }
        let!(:another_agent) { create(:agent, organisations: [another_organisation]) }

        before do
          sign_in(another_agent)
        end

        it "does not call the service" do
          expect do
            post :update, params: update_params
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the update succeeds" do
        before do
          allow(Users::Save).to receive(:call)
            .and_return(OpenStruct.new(success?: true, user: user))
        end

        it "is a success" do
          post :update, params: update_params
          expect(response).to be_successful
          expect(response.parsed_body["success"]).to eq(true)
        end
      end

      context "with tags" do
        let(:tag) { create(:tag) }
        let(:update_params) do
          {
            user: {
              tag_users_attributes: [{ tag_id: tag.id }]
            },
            id: user.id,
            organisation_id: organisation.id,
            format: "json"
          }
        end
        let!(:existing_tag) { create(:tag, value: "lol") }

        before do
          allow(Users::Save).to receive(:call).and_call_original
          allow_any_instance_of(Users::Save).to receive(:sync_with_rdv_solidarites)
            .and_return true
          organisation.tags << tag
          organisation.tags << existing_tag
          user.tags << existing_tag
        end

        it "updates the tags" do
          post :update, params: update_params
          expect(user.reload.tags.size).to eq(1)
          expect(user.reload.tags.first.id).to eq(tag.id)
        end

        context "with empty tags" do
          let(:update_params) do
            {
              user: {
                birth_date: "20/12/1988",
                tag_users_attributes: []
              },
              id: user.id,
              organisation_id: organisation.id,
              format: "json"
            }
          end

          before do
            # This is unfortunately required because without it Rspec removes all params
            # that return false to .present? and tag_users_attributes
            # being an empty array, the controller doesn't receive it
            allow_any_instance_of(described_class).to receive(:params).and_return(
              ActionController::Parameters.new(update_params)
            )
          end

          it "removes all existing tags" do
            post :update, params: update_params
            expect(user.reload.tags.size).to eq(0)
          end

          context "with tags on other organisations" do
            let(:other_organisation) { create(:organisation) }
            let(:other_tag) { create(:tag, value: "ok") }

            before do
              other_organisation.tags << other_tag
              user.tags << other_tag
            end

            it "removes only correct tags" do
              post :update, params: update_params
              expect(user.reload.tags.first).to eq(other_tag)
              expect(user.reload.tags.size).to eq(1)
            end
          end
        end

        context "without tags given" do
          let(:update_params) do
            {
              user: {
                birth_date: "20/12/1988",
                tag_users_attributes: nil
              },
              id: user.id,
              organisation_id: organisation.id,
              format: "json"
            }
          end

          before do
            allow_any_instance_of(described_class).to receive(:params).and_return(
              ActionController::Parameters.new(update_params)
            )
          end

          it "does not remove existing tags" do
            post :update, params: update_params
            expect(user.reload.tags.first).to eq(existing_tag)
          end
        end
      end

      context "when the creation fails" do
        before do
          allow(Users::Save).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
        end

        it "is not a success" do
          post :update, params: update_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to eq(false)
        end

        it "renders the errors" do
          post :update, params: update_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["errors"]).to eq(["some error"])
        end
      end
    end

    context "when html request" do
      let!(:update_params) do
        { id: user.id, organisation_id: organisation.id,
          user: { first_name: "Alain", last_name: "Deloin", phone_number: "0123456789" } }
      end

      before do
        sign_in(agent)
        allow(Users::Save).to receive(:call)
          .and_return(OpenStruct.new(success?: true))
      end

      it "calls the service" do
        expect(Users::Save).to receive(:call)
          .with(
            user: user,
            organisation: organisation
          )
        patch :update, params: update_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }
        let!(:another_agent) { create(:agent, organisations: [another_organisation]) }

        before do
          sign_in(another_agent)
        end

        it "does not call the service" do
          expect do
            patch :update, params: update_params
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the update succeeds" do
        context "when organisation level" do
          it "redirects to the show page" do
            patch :update, params: update_params
            expect(response).to redirect_to(organisation_user_path(organisation, user))
          end
        end

        context "when department level" do
          let!(:update_params) do
            { id: user.id, department_id: department.id,
              user: { first_name: "Alain", last_name: "Deloin", phone_number: "0123456789" } }
          end

          it "redirects to the show page" do
            patch :update, params: update_params
            expect(response).to redirect_to(department_user_path(department, user))
          end
        end
      end

      context "when the creation fails" do
        before do
          allow(Users::Save).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
        end

        it "renders the edit page" do
          patch :update, params: update_params
          expect(response).not_to be_successful
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
