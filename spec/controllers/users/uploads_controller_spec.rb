describe Users::UploadsController do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }

  describe "GET #new" do
    before do
      sign_in(agent)
    end

    context "at organisation level" do
      context "when organisation does not exist" do
        it "returns an error" do
          expect do
            get :new, params: { organisation_id: "i-do-not-exist" }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when agent does not belong to the organisation" do
        let(:other_organisation) { create(:organisation) }
        let(:agent) { create(:agent, organisations: [other_organisation]) }

        it "redirects the agent" do
          get :new, params: { organisation_id: organisation.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include("Votre compte ne vous permet pas d'effectuer cette action")
        end
      end

      context "when agent is authorized" do
        context "when no category_configuration is specified" do
          it "redirects to category selection" do
            get :new, params: { organisation_id: organisation.id }
            expect(response).to redirect_to(uploads_category_selection_organisation_users_path(organisation))
          end
        end
      end
    end

    context "at department level" do
      context "when department does not exist" do
        it "returns an error" do
          expect do
            get :new, params: { department_id: "i-do-not-exist" }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when agent does not belong to the department" do
        let!(:another_department) { create(:department) }
        let(:other_organisation) { create(:organisation, department: another_department) }
        let(:agent) { create(:agent, organisations: [other_organisation]) }

        it "redirects the agent" do
          get :new, params: { department_id: department.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include("Votre compte ne vous permet pas d'effectuer cette action")
        end
      end

      context "when agent is authorized" do
        context "when no category_configuration is specified" do
          it "redirects to category selection" do
            get :new, params: { department_id: department.id }
            expect(response).to redirect_to(uploads_category_selection_department_users_path(department))
          end
        end
      end
    end
  end
end
