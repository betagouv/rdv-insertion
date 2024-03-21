describe "Agents can create a rdv_context", :js do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
  end
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: category_orientation)
  end
  let!(:user) do
    create(:user, organisations: [organisation])
  end
  let!(:rdv_context_count_before) { RdvContext.count }

  before do
    setup_agent_session(agent)
    allow_any_instance_of(RdvContext).to receive(:status).and_return("not_invited")
  end

  context "from users index page" do
    context "at department level" do
      it "can create a rdv_context" do
        visit department_users_path(department)
        expect(page).to have_content("Ajouter")

        click_button("Ajouter")

        expect(page).to have_content("Non invité")
        expect(RdvContext.count).to eq(rdv_context_count_before + 1)
        expect(RdvContext.last.status).to eq("not_invited")
        expect(RdvContext.last.motif_category).to eq(category_orientation)
        expect(RdvContext.last.user).to eq(user)
        expect(page).to have_current_path(department_users_path(department))
      end
    end

    context "at organisation level" do
      it "can create a rdv_context" do
        visit organisation_users_path(organisation)
        expect(page).to have_content("Ajouter")

        click_button("Ajouter")

        expect(page).to have_content("Non invité")
        expect(RdvContext.count).to eq(rdv_context_count_before + 1)
        expect(RdvContext.last.status).to eq("not_invited")
        expect(RdvContext.last.motif_category).to eq(category_orientation)
        expect(RdvContext.last.user).to eq(user)
        expect(page).to have_current_path(organisation_users_path(organisation))
      end
    end
  end

  context "from user rdv_contexts page" do
    context "at department level" do
      it "can create a rdv_context" do
        visit department_user_rdv_contexts_path(department_id: department.id, user_id: user.id)
        expect(page).to have_content("Ouvrir un suivi")

        click_button("Ouvrir un suivi")

        expect(page).to have_content("Non invité")
        expect(RdvContext.count).to eq(rdv_context_count_before + 1)
        expect(RdvContext.last.status).to eq("not_invited")
        expect(RdvContext.last.motif_category).to eq(category_orientation)
        expect(RdvContext.last.user).to eq(user)
        expect(page).to have_current_path(department_user_rdv_contexts_path(department_id: department.id,
                                                                            user_id: user.id))
      end
    end

    context "at organisation level" do
      it "can create a rdv_context" do
        visit organisation_user_rdv_contexts_path(organisation_id: organisation.id, user_id: user.id)
        expect(page).to have_content("Ouvrir un suivi")

        click_button("Ouvrir un suivi")

        expect(page).to have_content("Non invité")
        expect(RdvContext.count).to eq(rdv_context_count_before + 1)
        expect(RdvContext.last.status).to eq("not_invited")
        expect(RdvContext.last.motif_category).to eq(category_orientation)
        expect(RdvContext.last.user).to eq(user)
        expect(page).to have_current_path(organisation_user_rdv_contexts_path(organisation_id: organisation.id,
                                                                              user_id: user.id))
      end
    end
  end
end
