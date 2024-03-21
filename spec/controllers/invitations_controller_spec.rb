describe InvitationsController do
  describe "#create" do
    let!(:user_id) { "24213123" }
    let!(:organisation_id) { "22232" }
    let!(:department) { create(:department) }
    let!(:organisation) { create(:organisation, id: organisation_id, department: department) }
    let!(:other_org) { create(:organisation, department: department) }

    let!(:organisations) { Organisation.where(id: organisation.id) }
    let!(:agent) { create(:agent, organisations: organisations) }
    let!(:user) do
      create(
        :user,
        first_name: "JANE", last_name: "DOE", title: "madame",
        id: user_id, organisations: organisations
      )
    end
    let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation") }

    let!(:create_params) do
      {
        organisation_id: organisation.id,
        user_id: user_id,
        invitation: {
          format: "sms",
          motif_category: motif_category_attributes
        },
        format: "json"
      }
    end

    let!(:invitation_attributes) do
      { format: "sms" }
    end

    let!(:motif_category_attributes) { { id: motif_category.id.to_s } }
    let!(:invitation) { create(:invitation) }

    before do
      sign_in(agent)
      travel_to(Time.zone.parse("2022-05-04 12:30"))
      allow(InviteUser).to receive(:call)
        .with(user:, organisations:, invitation_attributes:, motif_category_attributes:)
        .and_return(OpenStruct.new(success?: true, invitation:))
    end

    context "organisation level" do
      it "calls the invite user service" do
        expect(InviteUser).to receive(:call)
          .with(user:, organisations:, invitation_attributes:, motif_category_attributes:)
        post :create, params: create_params
      end
    end

    context "department level" do
      let!(:organisations) { Organisation.where(id: [organisation.id, other_org.id]) }
      let!(:create_params) do
        {
          department_id: department.id,
          user_id: user_id,
          invitation: {
            format: "email",
            motif_category: motif_category_attributes,
            rdv_solidarites_lieu_id: "3929"
          },
          format: "json"
        }
      end
      let!(:invitation_attributes) do
        { format: "email", rdv_solidarites_lieu_id: "3929" }
      end

      it "calls the service" do
        expect(InviteUser).to receive(:call)
          .with(user:, organisations:, invitation_attributes:, motif_category_attributes:)
        post :create, params: create_params
      end
    end

    context "when the service succeeds" do
      context "when sms or email invitation" do
        it "is a success" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.parsed_body["success"]).to eq(true)
        end

        it "renders the invitation" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.parsed_body["invitation"]["id"]).to eq(invitation.id)
        end
      end

      context "when postal invitation" do
        let!(:create_params) do
          {
            organisation_id: organisation.id,
            user_id: user_id,
            invitation: {
              format: "postal",
              motif_category: motif_category_attributes
            },
            format: "pdf"
          }
        end

        let!(:invitation_attributes) do
          { format: "postal" }
        end

        before do
          allow(WickedPdf).to receive_message_chain(:new, :pdf_from_string)
          allow(invitation).to receive(:content).and_return("some content")
        end

        it "is a success" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.headers["Content-Type"]).to eq("application/pdf")
        end

        it "renders the invitation" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.headers["Content-Disposition"]).to start_with("attachment; filename=")
          first_name = user.first_name
          last_name = user.last_name
          expect(response.headers["Content-Disposition"]).to end_with("_#{last_name}_#{first_name}.pdf")
        end
      end
    end

    context "when the service fails" do
      before do
        allow(InviteUser).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
      end

      it "is not a success" do
        post :create, params: create_params
        expect(response).not_to be_successful
        expect(response.parsed_body["success"]).to eq(false)
      end

      it "renders the errors" do
        post :create, params: create_params
        expect(response).not_to be_successful
        expect(response.parsed_body["errors"]).to eq(["some error"])
      end
    end
  end

  describe "GET #invitation_code" do
    render_views

    it "returns a success response" do
      get :invitation_code
      expect(response).to be_successful
      expect(response.body).to match(/Je prends rendez-vous/)
    end
  end

  describe "#redirect_shortcut" do
    subject { get :redirect_shortcut, params: { uuid: invitation.uuid } }

    let!(:invitation) { create(:invitation, format: "sms") }

    it "redirects to the invitation link" do
      subject
      expect(response).to redirect_to(
        Rails.application.routes.url_helpers.redirect_invitations_path(params: { uuid: invitation.uuid })
      )
    end
  end

  describe "#redirect" do
    subject { get :redirect, params: invite_params }

    let!(:user_id) { "24" }
    let!(:invitation) { create(:invitation, format: "sms") }
    let!(:invitation2) { create(:invitation, format: "email") }

    context "when uuid is passed" do
      let!(:invite_params) { { uuid: invitation2.uuid } }

      it "redirects to the invitation link" do
        subject
        expect(response).to redirect_to invitation2.link
      end

      context "when the invitation is no longer valid" do
        render_views
        before { invitation2.update!(valid_until: 2.days.ago) }

        it "says the invitation is invalid" do
          subject
          expect(response.body.encode).to include("Désolé, votre invitation n'est plus valide !")
          expect(response.body.encode).to include(invitation.help_phone_number)
        end
      end

      context "when the uuid cannot be found" do
        let!(:invite_params) { { uuid: "some_wrong_uuid" } }

        it "redirects back to the invitation page" do
          subject
          expect(response).to redirect_to :invitation_landing
        end

        it "displays an error message" do
          subject
          expect(flash[:error]).not_to be_nil
        end
      end
    end
  end
end
