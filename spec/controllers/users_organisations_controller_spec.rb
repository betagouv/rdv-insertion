describe UsersOrganisationsController do
  let!(:user_id) { 2222 }
  let!(:user) { create(:user, id: user_id, organisations: [organisation1]) }
  let!(:organisation1) { create(:organisation, name: "CD de DIE") }
  let(:organisation2) { create(:organisation, name: "CD de Valence") }
  let!(:department) { create(:department, organisations: [organisation1, organisation2]) }
  let!(:agent) { create(:agent, organisations: [organisation1]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#create" do
    subject do
      post :create, params: {
        department_id: department.id, users_organisation: {
          organisation_id: organisation2.id, user_id: user_id
        }, format: "turbo_stream"
      }
    end

    before do
      allow(Users::Save).to receive(:call)
        .with(user: user, organisation: organisation2)
        .and_return(OpenStruct.new(success?: true))
    end

    it "redirects with a success message" do
      subject

      expect(response).to redirect_to(department_user_path(department, user))
      expect(flash[:success]).to include("L'organisation a bien été ajoutée")
    end

    it "saves the user with the organisation" do
      expect(Users::Save).to receive(:call)
        .with(user: user, organisation: organisation2)
      subject
    end

    context "when the save fails" do
      before do
        allow(Users::Save).to receive(:call)
          .with(user: user, organisation: organisation2)
          .and_return(OpenStruct.new(success?: false, errors: ["something failed"]))
      end

      it "redirects with an error message" do
        subject

        expect(response.body).to match(/flashes/)
        expect(unescaped_response_body).to match(/something failed/)
      end
    end
  end

  describe "#destroy" do
    subject do
      delete :destroy, params: {
        department_id: department.id, users_organisation: {
          organisation_id: organisation1.id, user_id: user_id
        }, format: "turbo_stream"
      }
    end

    before do
      allow(Users::RemoveFromOrganisation).to receive(:call)
        .with(user: user, organisation: organisation1)
        .and_return(OpenStruct.new(success?: true))
    end

    it "shows with a success message" do
      subject

      expect(response).to be_successful
      expect(response.body).to match(/flashes/)
      expect(unescaped_response_body).to match(/L'organisation a bien été retirée/)
    end

    it "saves the user with the organisation" do
      expect(Users::RemoveFromOrganisation).to receive(:call)
        .with(user: user, organisation: organisation1)
      subject
    end

    context "when the save fails" do
      before do
        allow(Users::RemoveFromOrganisation).to receive(:call)
          .with(user: user, organisation: organisation1)
          .and_return(OpenStruct.new(success?: false, errors: ["something failed"]))
      end

      it "shows with an error message" do
        subject

        expect(response.body).to match(/flashes/)
        expect(unescaped_response_body).to match(/something failed/)
      end
    end

    context "when the user has no rdv_solidarites_user_id and the sync with rdvs fails" do
      let!(:user) { create(:user, id: user_id, organisations: [organisation1], rdv_solidarites_user_id: nil) }

      before do
        allow(Users::SyncWithRdvSolidarites).to receive(:call)
          .with(user: user)
          .and_return(OpenStruct.new(success?: false, errors: ["Something went wrong"]))
      end

      it "displays an error message" do
        subject

        expect(response).to be_successful
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Something went wrong/)
        expect(unescaped_response_body).to match(/L'utilisateur n'est plus lié à rdv-solidarités/)
      end
    end

  end
end
