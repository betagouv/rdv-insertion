describe FollowUpsController do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let(:user) { create(:user, organisations: [organisation]) }
  let!(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
  end
  let!(:configuration) do
    create(:configuration, motif_category: category_orientation, organisation: organisation)
  end
  let(:agent) { create(:agent, organisations: [organisation]) }
  let(:follow_up_params) do
    {
      follow_up: { user_id: user.id, motif_category_id: category_orientation.id },
      configuration_id: configuration.id,
      organisation_id: organisation.id
    }
  end
  let!(:follow_up_count_before) { FollowUp.count }

  describe "#create" do
    before do
      sign_in(agent)
    end

    it "creates a new follow_up" do
      post :create, params: follow_up_params
      expect(FollowUp.count).to eq(follow_up_count_before + 1)
      expect(FollowUp.last.user).to eq(user)
      expect(FollowUp.last.motif_category).to eq(category_orientation)
    end

    context "when not authorized" do
      let!(:another_organisation) { create(:organisation) }
      let(:user) { create(:user, organisations: [another_organisation]) }

      it "raises an error" do
        expect do
          post :create, params: follow_up_params
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when te creation fails" do
      let!(:follow_up) { create(:follow_up, motif_category: category_orientation, user: user) }

      it "opens an error modal" do
        post :create, params: follow_up_params

        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to match(/replace/)
        expect(response.body).to match(/remote_modal/)
      end
    end

    context "when html request" do
      it "redirects to the user show page with the right anchor" do
        post :create, params: follow_up_params, format: :html

        expect(response).to redirect_to(
          organisation_user_follow_ups_path(organisation_id: organisation.id, user_id: user.id,
                                            anchor: "follow_up_#{FollowUp.last.id}")
        )
      end

      context "when department level" do
        let(:follow_up_params) do
          {
            follow_up: { user_id: user.id, motif_category_id: category_orientation.id },
            configuration_id: configuration.id,
            department_id: department.id
          }
        end

        it "redirects to the right path" do
          post :create, params: follow_up_params, format: :html

          expect(response).to redirect_to(
            department_user_follow_ups_path(department_id: department.id, user_id: user.id,
                                            anchor: "follow_up_#{FollowUp.last.id}")
          )
        end
      end
    end

    context "when turbo request" do
      it "replace the create follow_up button" do
        post :create, params: follow_up_params, format: :turbo_stream

        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to match(/replace/)
        expect(response.body).to match(/target="user_#{user.id}_motif_category_#{category_orientation.id}"/)
      end
    end
  end
end
