describe ApplicantsController, type: :controller do
  let!(:organisation) { create(:organisation, rdv_solidarites_organisation_id: rdv_solidarites_organisation_id) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:rdv_solidarites_organisation_id) { 52 }
  let!(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession) }

  describe "#new" do
    render_views
    let!(:new_params) { { organisation_id: organisation.id } }

    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
    end

    it "renders the new applicant page" do
      get :new, params: new_params

      expect(response).to be_successful
      expect(response.body).to match(/Créer allocataire/)
    end
  end

  describe "#create" do
    render_views
    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
      allow(SaveApplicant).to receive(:call)
        .and_return(OpenStruct.new)
    end

    context "when html request" do
      let(:applicant_params) do
        {
          applicant: {
            first_name: "john", last_name: "doe", email: "johndoe@example.com",
            affiliation_number: "1234", role: "demandeur", title: "monsieur"
          },
          organisation_id: organisation.id,
          format: "html"
        }
      end

      it "calls the service" do
        expect(SaveApplicant).to receive(:call)
        post :create, params: applicant_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }

        it "does not call the service" do
          expect(SaveApplicant).not_to receive(:call)
          post :create, params: applicant_params.merge(organisation_id: another_organisation.id)
        end
      end

      context "when the creation succeeds" do
        let(:applicant) { create(:applicant, organisations: [organisation]) }

        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: true))
          allow(Applicant).to receive(:new)
            .and_return(applicant)
        end

        it "is a success" do
          post :create, params: applicant_params
          expect(response).to redirect_to(organisation_applicant_path(organisation, applicant))
        end
      end

      context "when the creation fails" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ['some error']))
        end

        it "renders the new page" do
          post :create, params: applicant_params
          expect(response).to be_successful
          expect(response.body).to match(/Créer allocataire/)
        end
      end
    end

    context "when json request" do
      let(:applicant_params) do
        {
          applicant: {
            uid: "123xz", first_name: "john", last_name: "doe", email: "johndoe@example.com",
            affiliation_number: "1234", role: "conjoint"
          },
          organisation_id: organisation.id,
          format: "json"
        }
      end

      it "calls the service" do
        expect(SaveApplicant).to receive(:call)
        post :create, params: applicant_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }

        it "renders forbidden in the response" do
          post :create, params: applicant_params.merge(organisation_id: another_organisation.id)
          expect(response).to have_http_status(:forbidden)
        end

        it "does not call the service" do
          expect(SaveApplicant).not_to receive(:call)
          post :create, params: applicant_params.merge(organisation_id: another_organisation.id)
        end
      end

      context "when the creation succeeds" do
        let!(:applicant) { create(:applicant) }

        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: true, applicant: applicant))
        end

        it "is a success" do
          post :create, params: applicant_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["success"]).to eq(true)
        end
      end

      context "when the creation fails" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ['some error']))
        end

        it "is not a success" do
          post :create, params: applicant_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["success"]).to eq(false)
        end

        it "renders the errors" do
          post :create, params: applicant_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["errors"]).to eq(['some error'])
        end
      end
    end
  end

  describe "#search" do
    let!(:search_params) { { applicants: { uids: ["23"] }, format: "json" } }
    let!(:applicant) { create(:applicant, organisations: [organisation], uid: "23", email: "borisjohnson@gov.uk") }

    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
    end

    context "policy scope" do
      let!(:another_organisation) { create(:organisation) }
      let!(:agent) { create(:agent, organisations: [another_organisation]) }
      let!(:another_applicant) { create(:applicant, uid: "0332", organisations: [another_organisation]) }
      let!(:search_params) { { applicants: { uids: %w[23 0332] }, format: "json" } }

      it "returns the policy scoped applicants" do
        post :search, params: search_params
        expect(response).to be_successful
        expect(JSON.parse(response.body)["applicants"].pluck("id")).to contain_exactly(another_applicant.id)
      end
    end

    it "is a success" do
      post :search, params: search_params
      expect(response).to be_successful
      expect(JSON.parse(response.body)["success"]).to eq(true)
    end

    it "renders the applicants" do
      post :search, params: search_params
      expect(response).to be_successful
      expect(JSON.parse(response.body)["applicants"].pluck("id")).to contain_exactly(applicant.id)
    end
  end

  describe "#show" do
    let!(:applicant) { create(:applicant, organisations: [organisation]) }
    let!(:show_params) { { id: applicant.id, organisation_id: organisation.id } }

    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
    end

    it "renders the applicant page" do
      get :show, params: show_params

      expect(response).to be_successful
    end
  end

  describe "#index" do
    let!(:applicants) { organisation.applicants }
    let!(:applicant) { create(:applicant, organisations: [organisation], last_name: "Chabat") }
    let!(:applicant2) { create(:applicant, organisations: [organisation], role: "demandeur") }
    let!(:index_params) { { organisation_id: organisation.id } }

    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
      allow(Applicant).to receive(:search_by_text)
        .and_return(applicants)
      allow(Applicant).to receive(:page)
        .and_return(applicants)
      allow(Applicant).to receive(:status)
        .and_return(applicants)
      allow(Applicant).to receive(:action_required)
        .and_return(applicants)
    end

    it "returns a list of applicants" do
      get :index, params: index_params

      expect(response).to be_successful
    end

    it "does not search applicants" do
      expect(Applicant).not_to receive(:search_by_text)

      get :index, params: index_params
    end

    context "when a page is specified" do
      let!(:index_params) { { organisation_id: organisation.id, page: 4 } }

      it "retrieves the applicants from that page" do
        expect(Applicant).to receive(:page).with("4")

        get :index, params: index_params.merge(page: 4)
      end
    end

    context "when a search query is specified" do
      let!(:index_params) { { organisation_id: organisation.id, search_query: "coco" } }

      it "searches the applicants" do
        expect(Applicant).to receive(:search_by_text).with("coco")

        get :index, params: index_params
      end
    end

    context "when a status is passed" do
      let!(:index_params) { { organisation_id: organisation.id, status: "rdv_pending" } }

      it "filters by status" do
        expect(Applicant).to receive(:status).with("rdv_pending")

        get :index, params: index_params
      end
    end

    context "when action_required is passed" do
      let!(:index_params) { { organisation_id: organisation.id, action_required: "true" } }

      it "filters by action required" do
        expect(Applicant).to receive(:action_required)

        get :index, params: index_params
      end
    end
  end

  describe "#update" do
    let!(:applicant) { create(:applicant, organisations: [organisation]) }
    let!(:update_params) { { id: applicant.id, organisation_id: organisation.id, applicant: { status: "resolved" } } }

    before do
      sign_in(agent)
      setup_rdv_solidarites_session(rdv_solidarites_session)
    end

    context "when json request" do
      let(:update_params) do
        {
          applicant: {
            status: "resolved"
          },
          id: applicant.id,
          organisation_id: organisation.id,
          format: "json"
        }
      end

      before do
        allow(SaveApplicant).to receive(:call)
          .and_return(OpenStruct.new)
      end

      it "calls the service" do
        expect(SaveApplicant).to receive(:call)
        post :update, params: update_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }
        let!(:another_agent) { create(:agent, organisations: [another_organisation]) }

        before do
          sign_in(another_agent)
          setup_rdv_solidarites_session(rdv_solidarites_session)
        end

        it "does not call the service" do
          post :update, params: update_params
          expect(SaveApplicant).not_to receive(:call)
        end
      end

      context "when the update succeeds" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: true, applicant: applicant))
        end

        it "is a success" do
          post :update, params: update_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["success"]).to eq(true)
        end
      end

      context "when the creation fails" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ['some error']))
        end

        it "is not a success" do
          post :update, params: update_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["success"]).to eq(false)
        end

        it "renders the errors" do
          post :update, params: update_params
          expect(response).to be_successful
          expect(JSON.parse(response.body)["errors"]).to eq(['some error'])
        end
      end
    end

    context "when html request" do
      let!(:update_params) do
        { id: applicant.id, organisation_id: organisation.id,
          applicant: { first_name: "Alain", last_name: "Deloin", phone_number: "0123456789" } }
      end

      before do
        sign_in(agent)
        setup_rdv_solidarites_session(rdv_solidarites_session)
        allow(SaveApplicant).to receive(:call)
          .and_return(OpenStruct.new)
      end

      it "calls the service" do
        expect(SaveApplicant).to receive(:call)
          .with(
            applicant: applicant,
            organisation: organisation,
            rdv_solidarites_session: rdv_solidarites_session
          )
        patch :update, params: update_params
      end

      context "when not authorized" do
        let!(:another_organisation) { create(:organisation) }
        let!(:another_agent) { create(:agent, organisations: [another_organisation]) }

        before do
          sign_in(another_agent)
          setup_rdv_solidarites_session(rdv_solidarites_session)
        end

        it "does not call the service" do
          expect(SaveApplicant).not_to receive(:call)
          patch :update, params: update_params
        end
      end

      context "when the update succeeds" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: true, applicant: applicant))
        end

        it "is redirects to the show page" do
          patch :update, params: update_params
          expect(response).to redirect_to(organisation_applicant_path(organisation, applicant))
        end
      end

      context "when the creation fails" do
        before do
          allow(SaveApplicant).to receive(:call)
            .and_return(OpenStruct.new(success?: false, errors: ['some error']))
        end

        it "is renders the edit page" do
          patch :update, params: update_params
          expect(response).to be_successful
        end
      end
    end
  end
end
