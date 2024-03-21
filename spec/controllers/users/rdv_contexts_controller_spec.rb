describe Users::RdvContextsController do
  render_views

  describe "#index" do
    context "it shows the different contexts" do
      let!(:department) { create(:department) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:rdv_solidarites_organisation_id) { 888 }
      let!(:category_configuration2) do
        create(:category_configuration, motif_category: category_accompagnement,
                                        invitation_formats: %w[sms email postal])
      end
      let!(:organisation) do
        create(:organisation, rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
                              category_configurations: [category_configuration, category_configuration2],
                              department_id: department.id)
      end
      let!(:rdv_context) do
        create(:rdv_context, status: "rdv_seen", user: user, motif_category: category_orientation)
      end
      let!(:invitation_orientation) do
        create(:invitation, created_at: "2021-10-20", format: "sms", rdv_context: rdv_context)
      end
      let!(:motif) { create(:motif, name: "RSA Orientation sur site") }
      let!(:rdv_orientation1) do
        create(
          :rdv,
          starts_at: "2021-10-22", motif: motif,
          organisation: organisation
        )
      end
      let!(:participation) do
        create(
          :participation,
          rdv: rdv_orientation1, rdv_context: rdv_context, user: user, status: "noshow",
          created_at: "2021-10-21"
        )
      end
      let!(:rdv_orientation2) do
        create(
          :rdv,
          starts_at: "2021-10-24", motif: motif, organisation: organisation
        )
      end
      let!(:participation2) do
        create(
          :participation,
          rdv_context: rdv_context, rdv: rdv_orientation2, user: user, status: "seen",
          created_at: "2021-10-23"
        )
      end
      let!(:rdv_context2) do
        create(
          :rdv_context, status: "invitation_pending", user: user, motif_category: category_accompagnement
        )
      end
      let!(:invitation_accompagnement) do
        create(:invitation, created_at: "2021-11-20", format: "sms", rdv_context: rdv_context2, user:)
      end
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
          number_of_days_before_action_required: 10
        )
      end
      let!(:user) do
        create(
          :user, first_name: "Andreas", last_name: "Kopke", organisations: [organisation]
        )
      end
      let!(:index_params) { { user_id: user.id, organisation_id: organisation.id } }

      before { sign_in(agent) }

      it "shows all the contexts" do
        get :index, params: index_params

        expect(response).to be_successful
        expect(response.body).to match(/RSA orientation/)
        expect(response.body).to match(/RSA accompagnement/)
        expect(response.body).to match(/RDV honoré/)
        expect(response.body).to match(/RDV pris le/)
        expect(response.body).to match(/Date du RDV/)
        expect(response.body).to match(/Statut RDV/)
        expect(response.body).to include("21/10/2021")
        expect(response.body).to include("22/10/2021")
        expect(response.body).to include("23/10/2021")
        expect(response.body).to include("24/10/2021")
        expect(response.body).to match(/Absence non excusée/)
        expect(response.body).to match(/Rendez-vous honoré/)
        expect(response.body).to match(/Statut RDV/)
        expect(response.body).to match(/Invitation en attente de réponse/)
        expect(response.body).to match(/RSA Orientation sur site/)
        expect(response.body).not_to match(/Convoqué par/)
      end

      context "when a rdv_context is not open" do
        let!(:rdv_context2) { nil }
        let!(:invitation_accompagnement) { nil }

        it "show the open rdv_context button" do
          get :index, params: index_params

          expect(unescaped_response_body).to match("class=\"simple_form rdv_context\"")
          expect(unescaped_response_body).to match("input value=\"#{user.id}\"")
          expect(unescaped_response_body).to match("input value=\"#{category_accompagnement.id}\"")
          expect(unescaped_response_body).to match(/Ouvrir un suivi/)
        end
      end

      context "when one rdv is a convocation" do
        before { participation.update!(convocable: true) }

        let!(:notification) do
          create(
            :notification,
            participation: participation, event: "participation_created", format: "sms",
            created_at: 2.days.ago
          )
        end

        it "shows the convocation formats" do
          get :index, params: index_params

          expect(response.body).to match(/Convoqué par/)
          expect(response.body).to include("SMS 📱")
          expect(response.body).not_to include("Email 📧")
        end

        context "when the rdv is pending" do
          before do
            rdv_orientation1.update! starts_at: 2.days.from_now
            participation.update! status: "unknown"
          end

          it "shows the courrier generation button" do
            get :index, params: index_params

            expect(response.body).to include("<i class=\"fas fa-file-pdf\"></i> Courrier")
          end
        end

        context "when the rdv is passed" do
          it "does not show the courrier generation button" do
            get :index, params: index_params

            expect(response.body).not_to include("<i class=\"fas fa-file-pdf\"></i> Courrier")
          end
        end

        context "when the user has no title" do
          before { user.update! title: nil }

          it "does not show the courrier generation button" do
            get :index, params: index_params

            expect(response.body).not_to include("<i class=\"fas fa-file-pdf\"></i> Courrier")
          end
        end
      end

      context "when there is no matching category_configuration for a rdv_context" do
        let!(:organisation) do
          create(:organisation, rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
                                department_id: department.id, category_configurations: [category_configuration2])
        end

        let!(:rdv_context) do
          create(:rdv_context, status: "rdv_seen", user: user, motif_category: category_orientation)
        end

        it "does not display the context" do
          get :index, params: index_params

          expect(response).to be_successful
          expect(response.body).to match(/InvitationBlock/)
          expect(response.body).not_to match(/RSA orientation/)
        end
      end
    end
  end
end
