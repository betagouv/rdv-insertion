describe "Agents can convene user to rdv", :js do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department,
      # needed for the organisation users page
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id
    )
  end
  let!(:rdv_solidarites_organisation_id) { 444 }
  let!(:category_configuration) do
    create(
      :category_configuration,
      organisation: organisation,
      motif_category: motif_category,
      convene_user: true,
      number_of_days_before_action_required: 4
    )
  end
  let!(:motif_category) { create(:motif_category) }

  let!(:user) do
    create(
      :user,
      organisations: [organisation],
      rdv_solidarites_user_id: rdv_solidarites_user_id
    )
  end
  let!(:rdv_solidarites_user_id) { 555 }

  let!(:follow_up) do
    create(:follow_up, status: "invitation_pending", user: user, motif_category: motif_category)
  end
  let!(:invitation) { create(:invitation, follow_up: follow_up, created_at: 5.days.ago) }

  let!(:motif) do
    create(
      :motif,
      name: "Convocation au rdv",
      organisation: organisation,
      motif_category: motif_category
    )
  end

  before do
    setup_agent_session(agent)
  end

  describe "from #index" do
    it "can convene an user through a link" do
      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
      expect(page).to have_link("📅 Convoquer")
      new_window = window_opened_by { click_link("📅 Convoquer") }
      within_window new_window do
        expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
      end
    end

    context "when there is no convocation motifs" do
      before { motif.update! deleted_at: 2.days.ago }

      it "shows a message convocation is not possible" do
        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_link("📅 Convoquer")
        click_link("📅 Convoquer")
        expect(page).to have_content(
          "Aucun motif de convocation n'a été retrouvé pour cette catégorie sur RDV-Solidarités."
        )
      end
    end

    context "when there is a collectif motif" do
      let!(:collectif_motif) do
        create(:motif, collectif: true, motif_category:, organisation:)
      end

      let!(:collectif_rdv) do
        create(
          :rdv, starts_at: 2.days.from_now, motif: collectif_motif, max_participants_count: nil, organisation:
        )
      end

      it "can choose a collectif motif instead of an individuel one" do
        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_link("📅 Convoquer")
        click_link("📅 Convoquer")
        expect(page).to have_content(
          "S'agit-il d'un rdv individuel ou d'un rdv collectif ?"
        )
        expect(page).to have_link("Rdv individuel")
        expect(page).to have_link("Rdv collectif")

        new_window = window_opened_by { click_link("Rdv collectif") }
        within_window new_window do
          expect(page.current_url).to eq(collectif_rdv.add_user_url(rdv_solidarites_user_id))
        end
      end

      it "can still choose the individuel over the collectif" do
        visit organisation_users_path(organisation, motif_category_id: motif_category.id)
        expect(page).to have_link("📅 Convoquer")
        click_link("📅 Convoquer")

        expect(page).to have_content(
          "S'agit-il d'un rdv individuel ou d'un rdv collectif ?"
        )
        expect(page).to have_link("Rdv individuel")
        expect(page).to have_link("Rdv collectif")

        new_window = window_opened_by { click_link("Rdv individuel") }
        within_window new_window do
          expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
        end
      end

      context "when there is only the collectif motif" do
        before { motif.update! deleted_at: 2.days.ago }

        it "redirects directly to the collectif motif page" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
          new_window = window_opened_by { click_link("📅 Convoquer") }
          within_window new_window do
            expect(page.current_url).to eq(collectif_rdv.add_user_url(rdv_solidarites_user_id))
          end
        end

        context "when there is another collectif available before" do
          let!(:sooner_collectif_rdv) do
            create(
              :rdv, starts_at: 1.day.from_now, motif: collectif_motif, max_participants_count: nil, organisation:
            )
          end

          it "redirects directly to the first available rdv" do
            visit organisation_users_path(organisation, motif_category_id: motif_category.id)
            expect(page).to have_link("📅 Convoquer")
            new_window = window_opened_by { click_link("📅 Convoquer") }
            within_window new_window do
              expect(page.current_url).to eq(sooner_collectif_rdv.add_user_url(rdv_solidarites_user_id))
            end
          end
        end
      end

      context "when the collectif rdv is past" do
        let!(:collectif_rdv) do
          create(
            :rdv, starts_at: 2.days.ago, motif: collectif_motif, max_participants_count: nil, organisation:
          )
        end

        it "redirects to the individuel motif" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
          new_window = window_opened_by { click_link("📅 Convoquer") }
          within_window new_window do
            expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
          end
        end
      end

      context "when the collectif motif has no remaining seat" do
        let!(:collectif_rdv) do
          create(
            :rdv,
            starts_at: 2.days.from_now, motif: collectif_motif, max_participants_count: 2, organisation:,
            users_count: 2
          )
        end

        it "redirects to the individuel motif" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
          new_window = window_opened_by { click_link("📅 Convoquer") }
          within_window new_window do
            expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
          end
        end
      end
    end

    describe "button visbility" do
      context "when invitation is pending and the time to accept invitation has not exceeded" do
        let!(:invitation) { create(:invitation, follow_up: follow_up, created_at: 3.days.ago) }

        it "does not show a convocation button" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_no_content("📅 Convoquer")
        end
      end

      context "when there is a pending rdv" do
        let!(:participation) do
          create(:participation, follow_up: follow_up, user: user, created_at: 1.day.ago)
        end

        it "does not show a convocation button" do
          follow_up.set_status
          follow_up.save!
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_no_content("📅 Convoquer")
        end
      end

      context "when there is a noshow rdv" do
        let!(:follow_up) do
          create(:follow_up, status: "rdv_noshow", user: user, motif_category: motif_category)
        end

        it "shows a link to convene the user" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
        end
      end

      context "when there is an excused rdv" do
        let!(:follow_up) do
          create(:follow_up, status: "rdv_excused", user: user, motif_category: motif_category)
        end

        it "shows a link to convene the user" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
        end
      end

      context "when the category_configuration is not set to convene users" do
        before { category_configuration.update! convene_user: false }

        it "does not show a convocation button" do
          visit organisation_users_path(organisation, motif_category_id: motif_category.id)
          expect(page).to have_no_link("📅 Convoquer")
        end
      end

      context "from department level" do
        it "can also convene an user" do
          visit department_users_path(department, motif_category_id: motif_category.id)
          expect(page).to have_link("📅 Convoquer")
          new_window = window_opened_by { click_link("📅 Convoquer") }
          within_window new_window do
            expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
          end
        end
      end
    end
  end

  describe "from users#follow_ups" do
    it "can also convene an user" do
      visit organisation_user_follow_ups_path(organisation_id: organisation.id, user_id: user.id)
      expect(page).to have_link("📅 Convoquer")
      new_window = window_opened_by { click_link("📅 Convoquer") }
      within_window new_window do
        expect(page.current_url).to eq(motif.link_to_take_rdv_for(rdv_solidarites_user_id))
      end
    end
  end
end
