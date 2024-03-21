describe RdvContexts::ClosingsController do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:motif_category) { create(:motif_category) }
  let!(:category_configuration) { create(:category_configuration, motif_category: motif_category) }
  let!(:organisation) do
    create(:organisation, department: department, category_configurations: [category_configuration])
  end
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:rdv_context) { create(:rdv_context, user: user, motif_category: motif_category) }

  before do
    sign_in(agent)
  end

  describe "#create" do
    before do
      allow(RdvContexts::Close).to receive(:call)
        .with(rdv_context: rdv_context)
        .and_return(OpenStruct.new(success?: true))
    end

    let(:create_params) do
      { rdv_context_id: rdv_context.id, user_id: user.id, department_id: department.id }
    end

    it "calls the close rdv_context service" do
      expect(RdvContexts::Close).to receive(:call)
        .with(rdv_context: rdv_context)
      post :create, params: create_params
    end

    context "when the rdv_context is closed successfully" do
      it "redirects to user rdv_contexts" do
        post :create, params: create_params
        expect(response).to redirect_to(department_user_rdv_contexts_path(department_id: department.id,
                                                                          user_id: user.id))
      end
    end

    context "when not department_level" do
      let(:create_params) do
        { rdv_context_id: rdv_context.id, user_id: user.id,
          organisation_id: organisation.id }
      end

      context "when the rdv_context is closed successfully" do
        it "redirects to user show at organisation level" do
          post :create, params: create_params
          expect(response).to redirect_to(organisation_user_rdv_contexts_path(organisation_id: organisation.id,
                                                                              user_id: user.id))
        end
      end
    end
  end

  describe "#destroy" do
    let(:destroy_params) do
      { rdv_context_id: rdv_context.id, user_id: user.id,
        department_id: department.id }
    end
    let!(:rdv_context) do
      create(:rdv_context, user: user, motif_category: motif_category,
                           status: "closed", closed_at: Time.zone.now)
    end

    it "updates the rdv_context closed_at" do
      post :destroy, params: destroy_params
      expect(rdv_context.reload.closed_at).to eq(nil)
    end

    context "when the rdv_context is closed successfully" do
      it "redirects to user show" do
        post :destroy, params: destroy_params
        expect(response).to redirect_to(department_user_rdv_contexts_path(department_id: department.id,
                                                                          user_id: user.id))
      end
    end

    context "when not department_level" do
      let(:destroy_params) do
        { rdv_context_id: rdv_context.id, user_id: user.id,
          organisation_id: organisation.id }
      end

      context "when the rdv_context is closed successfully" do
        it "redirects to user show at organisation level" do
          post :destroy, params: destroy_params
          expect(response).to redirect_to(organisation_user_rdv_contexts_path(organisation_id: organisation.id,
                                                                              user_id: user.id))
        end
      end
    end
  end
end
