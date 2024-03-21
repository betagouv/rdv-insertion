describe "Agents can invite from index page", :js do
  let!(:agent) { create(:agent) }
  let!(:organisation) { create(:organisation, agents: [agent]) }
  let!(:user) do
    create(
      :user,
      organisations: [organisation], email: "someemail@somecompany.com", phone_number: "0607070707"
    )
  end
  let!(:motif_category) { create(:motif_category, short_name: "rsa_follow_up") }
  let!(:rdv_solidarites_token) { "123456" }
  let!(:follow_up) { create(:follow_up, user: user, motif_category: motif_category) }
  let!(:configuration) do
    create(
      :configuration,
      motif_category: motif_category, organisation: organisation, invitation_formats: %w[sms email]
    )
  end
  let!(:motif) { create(:motif, motif_category: motif_category, organisation: organisation) }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_invitation_requests(user.rdv_solidarites_user_id, rdv_solidarites_token)
    stub_geo_api_request(user.address)
    stub_brevo
    stub_request(
      :get,
      /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
    ).to_return(status: 200, body: { "creneau_availability" => true }.to_json, headers: {})
  end

  context "when no invitations is sent" do
    it "can invite the user" do
      follow_up.set_status
      follow_up.save!

      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
      expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: false, disabled: false)
      expect(page).to have_field("email_invite_for_user_#{user.id}", checked: false, disabled: false)
      expect(page).to have_content("Non invité")

      check("email_invite_for_user_#{user.id}")

      expect(page).to have_field("email_invite_for_user_#{user.id}", checked: true, disabled: true)
      expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: false, disabled: false)
      expect(page).to have_content("Invitation en attente de réponse")
    end

    context "when there is no creneau available" do
      before do
        stub_request(
          :get,
          /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
        ).to_return(status: 200, body: { "creneau_availability" => false }.to_json, headers: {})
      end

      it "cannot invite the user" do
        follow_up.set_status
        follow_up.save!

        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        check("email_invite_for_user_#{user.id}")
        expect(page).to have_content("Impossible d'inviter l'utilisateur")
        expect(page).to have_content(
          "Il n'y a plus de créneaux disponibles pour inviter cet utilisateur.\n\n" \
          "Nous vous invitons à créer de nouvelles plages d'ouverture ou augmenter le délai de prise de rdv depuis " \
          "RDV-Solidarités pour pouvoir à nouveau envoyer des invitations.\n\nPlus d'informations sur notre guide"
        )
      end
    end
  end

  context "when an invitation has been sent" do
    let!(:sms_invitation) do
      create(
        :invitation,
        format: "sms", user: user, follow_up: follow_up, rdv_solidarites_token: rdv_solidarites_token,
        created_at: 2.days.ago
      )
    end

    it "can invite in the format where invitation has not been sent" do
      follow_up.set_status
      follow_up.save!

      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
      expect(page).to have_field("email_invite_for_user_#{user.id}", checked: false, disabled: false)

      check("email_invite_for_user_#{user.id}")

      expect(page).to have_field("email_invite_for_user_#{user.id}", checked: true, disabled: true)
    end

    it "can re-invite in the format where invitation has been sent" do
      follow_up.set_status
      follow_up.save!

      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
      expect(page).to have_no_field("sms_invite_for_user_#{user.id}")
      expect(page).to have_css("label[for=\"sms_invite_for_user_#{user.id}\"]")

      find("label[for=\"sms_invite_for_user_#{user.id}\"]").click

      expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: true, disabled: true)
    end
  end

  context "when there are rdvs" do
    let!(:rdv) { create(:rdv) }
    let!(:participation) do
      create(
        :participation,
        rdv: rdv, user: user, follow_up: follow_up, status: "seen", created_at: 4.days.ago
      )
    end

    context "when the user has been invited prior to the rdv" do
      let!(:sms_invitation) do
        create(
          :invitation,
          format: "sms", user: user, follow_up: follow_up, created_at: 6.days.ago,
          rdv_solidarites_token: rdv_solidarites_token
        )
      end

      it "can invite the user in all format" do
        follow_up.set_status
        follow_up.save!

        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: false, disabled: false)
        expect(page).to have_field("email_invite_for_user_#{user.id}", checked: false, disabled: false)
        expect(page).to have_content("RDV honoré")

        check("email_invite_for_user_#{user.id}")

        expect(page).to have_field("email_invite_for_user_#{user.id}", checked: true, disabled: true)
        expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: false, disabled: false)
        expect(page).to have_content("Invitation en attente de réponse")
      end

      context "when there is no creneau available" do
        before do
          stub_request(
            :get,
            /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
          ).to_return(status: 200, body: { "creneau_availability" => false }.to_json, headers: {})
        end

        it "cannot invite the user" do
          follow_up.set_status
          follow_up.save!

          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          check("email_invite_for_user_#{user.id}")
          expect(page).to have_content("Impossible d'inviter l'utilisateur")
          expect(page).to have_content(
            "Il n'y a plus de créneaux disponibles pour inviter cet utilisateur.\n\n" \
            "Nous vous invitons à créer de nouvelles plages d'ouverture ou augmenter le délai de prise de rdv depuis " \
            "RDV-Solidarités pour pouvoir à nouveau envoyer des invitations.\n\nPlus d'informations sur notre guide"
          )
        end
      end
    end

    context "when the invitation has been sent after the rdv" do
      let!(:sms_invitation) do
        create(
          :invitation,
          format: "sms", user: user, follow_up: follow_up, created_at: 2.days.ago,
          rdv_solidarites_token: rdv_solidarites_token
        )
      end

      it "can invite in the format where invitation has not been sent" do
        follow_up.set_status
        follow_up.save!

        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_field("email_invite_for_user_#{user.id}", checked: false, disabled: false)

        check("email_invite_for_user_#{user.id}")

        expect(page).to have_field("email_invite_for_user_#{user.id}", checked: true, disabled: true)
      end

      it "can re-invite in the format where invitation has been sent" do
        follow_up.set_status
        follow_up.save!

        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_no_field("sms_invite_for_user_#{user.id}")
        expect(page).to have_css("label[for=\"sms_invite_for_user_#{user.id}\"]")

        find("label[for=\"sms_invite_for_user_#{user.id}\"]").click

        expect(page).to have_field("sms_invite_for_user_#{user.id}", checked: true, disabled: true)
      end
    end

    context "when the rdv is pending" do
      let!(:rdv) { create(:rdv, starts_at: 2.days.from_now) }
      let!(:participation) do
        create(
          :participation,
          rdv: rdv, user: user, follow_up: follow_up, status: "unknown", created_at: 4.days.ago
        )
      end

      let!(:sms_invitation) do
        create(
          :invitation,
          format: "sms", user: user, follow_up: follow_up, created_at: 2.days.ago,
          rdv_solidarites_token: rdv_solidarites_token
        )
      end

      it "cannot invite in any format and do not show the invitation fields" do
        follow_up.set_status
        follow_up.save!

        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_no_field("sms_invite_for_user_#{user.id}")
        expect(page).to have_no_field("email_invite_for_user_#{user.id}")
        expect(page).to have_content("RDV à venir")
      end
    end
  end
end
