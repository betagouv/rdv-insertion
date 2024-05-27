describe "Agents can sort users on index page", :js do
  let!(:agent) { create(:agent, organisations: [organisation, organisation2]) }
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:organisation2) { create(:organisation, department: department) }
  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation") }
  let!(:motif_category2) { create(:motif_category, short_name: "rsa_accompagnement", name: "RSA accompagnement") }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: motif_category)
  end
  let!(:category_configuration2) do
    create(:category_configuration, organisation: organisation, motif_category: motif_category2)
  end
  let!(:user) { create(:user, organisations: [organisation, organisation2]) }
  let!(:follow_up) { create(:follow_up, user: user, motif_category: motif_category) }
  let!(:stat) { create(:stat, statable_type: "Department", statable_id: nil) }

  shared_examples "a page with an organisation navigation button" do
    it "shows the organisation navigation button in header" do
      visit(page_path)

      navigation_button = find_button("btn-organisation-navigation")
      expect(navigation_button).to have_content(current_structure.name)
      click_button("btn-organisation-navigation")

      within("#organisation-navigation") do
        within("#organisation-navigation-dropdown") do
          expect(page).to have_link(
            "#{department.name} - Toutes les organisations", href: department_users_path(department)
          )
          expect(page).to have_link(organisation.name, href: organisation_users_path(organisation))
          expect(page).to have_link(organisation2.name, href: organisation_users_path(organisation2))
        end
      end
    end
  end

  context "when agent is not logged in" do
    context "on welcome page" do
      it "does not show the organisation navigation button in header" do
        visit root_path

        expect(page).to have_no_css("button#btn-organisation-navigation")
      end
    end

    context "on stats page" do

      it "does not show the organisation navigation button in header" do
        visit stats_path

        expect(page).to have_no_css("button#btn-organisation-navigation")
      end
    end

    context "on login page" do
      it "does not show the organisation navigation button in header" do
        visit sign_in_path

        expect(page).to have_no_css("button#btn-organisation-navigation")
      end
    end
  end

  context "when agent is logged in" do
    before do
      setup_agent_session(agent)
    end

    context "on organisations index page" do
      it "does not show the organisation navigation button in header" do
        visit organisations_path

        expect(page).to have_no_css("button#btn-organisation-navigation")
      end
    end

    context "on department_level" do
      let!(:current_structure) { department }

      context "on users index page" do
        let!(:page_path) { department_users_path(department) }

        include_examples "a page with an organisation navigation button"
      end

      context "on users index page with motif_category_id" do
        let!(:page_path) { department_users_path(department, motif_category: motif_category) }

        include_examples "a page with an organisation navigation button"
      end

      context "on archived users index page" do
        let!(:page_path) { department_users_path(department, users_scope: "archived") }

        include_examples "a page with an organisation navigation button"
      end

      context "on new user page" do
        let!(:page_path) { new_department_user_path(department) }

        include_examples "a page with an organisation navigation button"
      end

      context "on upload users page" do
        let!(:page_path) { new_department_upload_path(department) }

        include_examples "a page with an organisation navigation button"
      end

      context "on upload users page with category selected" do
        let!(:page_path) { new_department_upload_path(department, category_configuration: motif_category.id) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user page" do
        let!(:page_path) { department_user_path(department, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user edit page" do
        let!(:page_path) { edit_department_user_path(department, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user follow-up page" do
        let!(:page_path) { department_user_follow_ups_path(department, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user parcours page" do
        let!(:page_path) { department_user_parcours_path(department, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on batch actions page" do
        let!(:page_path) { new_department_batch_action_path(department, motif_category_id: motif_category.id) }

        include_examples "a page with an organisation navigation button"
      end

      context "on stats page" do
        it "does not show the organisation navigation button in header" do
          visit stats_path

          expect(page).to have_no_css("button#btn-organisation-navigation")
        end
      end
    end

    context "on organisation level" do
      let!(:current_structure) { organisation }

      context "on users index page" do
        let!(:page_path) { organisation_users_path(organisation) }

        include_examples "a page with an organisation navigation button"
      end

      context "on users index page with motif_category_id" do
        let!(:page_path) { organisation_users_path(organisation, motif_category: motif_category) }

        include_examples "a page with an organisation navigation button"
      end

      context "on archived users index page" do
        let!(:page_path) { organisation_users_path(organisation, users_scope: "archived") }

        include_examples "a page with an organisation navigation button"
      end

      context "on new user page" do
        let!(:page_path) { new_organisation_user_path(organisation) }

        include_examples "a page with an organisation navigation button"
      end

      context "on upload users page" do
        let!(:page_path) { new_organisation_upload_path(organisation) }

        include_examples "a page with an organisation navigation button"
      end

      context "on upload users page with category selected" do
        let!(:page_path) { new_organisation_upload_path(organisation, category_configuration: motif_category.id) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user page" do
        let!(:page_path) { organisation_user_path(organisation, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user edit page" do
        let!(:page_path) { edit_organisation_user_path(organisation, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user follow-up page" do
        let!(:page_path) { organisation_user_follow_ups_path(organisation, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on user parcours page" do
        let!(:page_path) { organisation_user_parcours_path(organisation, user) }

        include_examples "a page with an organisation navigation button"
      end

      context "on batch actions page" do
        let!(:page_path) { new_organisation_batch_action_path(organisation, motif_category_id: motif_category.id) }

        include_examples "a page with an organisation navigation button"
      end

      context "on stats page" do
        it "does not show the organisation navigation button in header" do
          visit stats_path

          expect(page).to have_no_css("button#btn-organisation-navigation")
        end
      end
    end
  end
end
