RSpec.describe InvitationMailer do
  include_context "with all existing categories"

  let!(:department) { create(:department, name: "Drôme", pronoun: "la") }
  let!(:help_phone_number) { "0139393939" }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:messages_configuration) do
    create(:messages_configuration, organisation: organisation, display_department_logo: true,
                                    display_europe_logos: true, display_france_travail_logo: true)
  end
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "Valjean", title: "monsieur")
  end
  let!(:invitation) do
    create(
      :invitation,
      follow_up: follow_up, user: user, department: department,
      format: "email", help_phone_number: help_phone_number,
      organisations: [organisation]
    )
  end
  let!(:follow_up) { build(:follow_up) }

  describe "#standard_invitation" do
    subject do
      described_class.with(invitation: invitation, user: user).standard_invitation
    end

    context "for rsa_orientation" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("[RSA]: Votre rendez-vous d'orientation dans le cadre de votre RSA")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
          "à un rendez-vous d'orientation afin de démarrer un parcours d'accompagnement"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end

      context "when the signature is configured" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
        end

        it "renders the mail with the right signature" do
          expect(subject.body.encoded).to match(/Fabienne Bouchet/)
        end
      end

      context "when template attributes are overriden by category_configuration attributes" do
        let!(:category_configuration) do
          create(
            :category_configuration,
            motif_category: category_rsa_orientation, organisation:,
            template_rdv_title_override: "nouveau type de rendez-vous",
            template_rdv_purpose_override: "tester une nouvelle fonctionnalité"
          )
        end

        it "renders the subject" do
          email_subject = unescape_html(subject.subject)
          expect(email_subject).to eq("[RSA]: Votre nouveau type de rendez-vous dans le cadre de votre RSA")
        end

        it "renders the body" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).to match("Bonjour Jean VALJEAN")
          expect(body_string).to match("Le département de la Drôme.")
          expect(body_string).to match("01 39 39 39 39")
          expect(body_string).to match(
            "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer à un" \
            " nouveau type de rendez-vous afin de tester une nouvelle fonctionnalité."
          )
          expect(body_string).to match("Ce RDV est obligatoire.")
          expect(body_string).not_to match(
            "votre RSA pourra être suspendu ou réduit."
          )
          expect(body_string).to match("/i/r/#{invitation.uuid}")
          expect(body_string).to match("dans un délai de 3 jours")
          expect(body_string).to match("Logo du département")
          expect(body_string).to match("Logo de l'Union européene")
          expect(body_string).to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_accompagnement" do
      let!(:follow_up) { build(:follow_up) }

      %w[category_rsa_accompagnement category_rsa_accompagnement_social category_rsa_accompagnement_sociopro]
        .each do |motif_category|
        before { follow_up.motif_category = send(motif_category) }

        it "renders the headers" do
          expecting_mail_to_have_correct_headers
        end

        it "renders the subject" do
          email_subject = unescape_html(subject.subject)
          expect(email_subject).to eq("[RSA]: Votre rendez-vous d'accompagnement dans le cadre de votre RSA")
        end

        it "renders the body" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).to match("Bonjour Jean VALJEAN")
          expect(body_string).to match("Le département de la Drôme.")
          expect(body_string).to match("01 39 39 39 39")
          expect(body_string).to match(
            "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
            "à un rendez-vous d'accompagnement afin de démarrer un parcours d'accompagnement"
          )
          expect(body_string).to match("Ce RDV est obligatoire.")
          expect(body_string).to match(
            "votre RSA pourra être suspendu ou réduit."
          )
          expect(body_string).to match("/i/r/#{invitation.uuid}")
          expect(body_string).to match("dans un délai de 3 jours")
          expect(body_string).to match("Logo du département")
          expect(body_string).to match("Logo de l'Union européene")
          expect(body_string).to match("Logo de France Travail")
        end

        context "when the display logos options are disabled" do
          let!(:messages_configuration) do
            create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                            display_europe_logos: false, display_france_travail_logo: false)
          end

          it "does not display the different optional logos" do
            body_string = unescape_html(subject.body.encoded)
            expect(body_string).not_to match("Logo du département")
            expect(body_string).not_to match("Logo de l'Union européene")
            expect(body_string).not_to match("Logo de France Travail")
          end
        end
      end
    end

    context "for rsa_cer_signature" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_cer_signature)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[RSA]: Votre rendez-vous de signature de CER" \
          " dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer à un " \
          "rendez-vous de signature de CER afin de construire et signer votre Contrat d'Engagement Réciproque"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_follow_up" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_follow_up) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[RSA]: Votre rendez-vous de suivi" \
          " dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
          "à un rendez-vous de suivi afin de faire un point avec votre référent de parcours"
        )
        expect(body_string).not_to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_main_tendue" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_main_tendue) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[RSA]: Votre entretien de main tendue" \
          " dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
          "à un entretien de main tendue afin de faire le point sur votre situation"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_atelier_collectif_mandatory" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_atelier_collectif_mandatory)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[RSA]: Votre atelier collectif" \
          " dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
          "à un atelier collectif afin de vous aider dans votre parcours d'insertion"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_spie" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_spie)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to(
          eq("[DEMANDE D'EMPLOI]: Votre rendez-vous d'accompagnement dans le cadre de votre demande d'emploi")
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes demandeur d'emploi et à ce titre vous êtes invité à participer à un " \
          "rendez-vous d'accompagnement afin de démarrer un parcours d'accompagnement"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa integration information" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_integration_information)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("[RSA]: Votre rendez-vous d'information dans le cadre de votre RSA")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous êtes bénéficiaire du RSA et à ce titre vous êtes invité à participer " \
          "à un rendez-vous d'information afin de vous renseigner sur vos droits et vos devoirs"
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for siae_interview" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_interview) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[CANDIDATURE SIAE]: Votre entretien d'embauche dans le cadre de votre candidature SIAE"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to include(
          "Vous êtes candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)" \
          " et à ce titre vous êtes invité à participer à un entretien d'embauche " \
          "afin de poursuivre le processus de recrutement"
        )
        expect(body_string).not_to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for siae_collective_information" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_collective_information) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[CANDIDATURE SIAE]: Votre rendez-vous collectif d'information dans le cadre de votre candidature SIAE"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to include(
          "Vous êtes candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)" \
          " et à ce titre vous êtes invité à participer à " \
          "un rendez-vous collectif d'information afin de découvrir cette structure"
        )
        expect(body_string).not_to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
      end
    end

    context "for siae_follow_up" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_follow_up) }

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[SUIVI SIAE]: Votre rendez-vous de suivi dans le cadre de votre suivi SIAE"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to include(
          "Vous êtes salarié.e au sein de notre structure" \
          " et à ce titre vous êtes invité à participer à un rendez-vous de suivi " \
          "afin de faire un point avec votre référent"
        )
        expect(body_string).not_to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("dans un délai de 3 jours")
      end
    end

    context "for rsa_orientation_france_travail" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_orientation_france_travail)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[RSA]: Votre rendez-vous d'orientation dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match("Dans le cadre du projet 'France Travail'")
        expect(body_string).to match("afin de démarrer un parcours d'accompagnement.")
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end
  end

  describe "#invitation_for_rsa_orientation_on_phone_platform" do
    subject do
      described_class
        .with(invitation: invitation, user: user)
        .phone_platform_invitation
    end

    let!(:follow_up) do
      build(:follow_up, motif_category: category_rsa_orientation_on_phone_platform)
    end

    it "renders the headers" do
      expecting_mail_to_have_correct_headers
    end

    it "renders the subject" do
      expect(subject.subject).to eq("[RSA]: Votre rendez-vous d'orientation téléphonique dans le cadre de votre RSA")
    end

    it "renders the body" do
      body_string = unescape_html(subject.body.encoded)
      expect(body_string).to match("Bonjour Jean VALJEAN")
      expect(body_string).to match("Le département de la Drôme.")
      expect(body_string).to match("01 39 39 39 39")
      expect(body_string).to match(
        "En tant que bénéficiaire du RSA vous devez contacter la plateforme départementale" \
        " afin de démarrer un parcours d'accompagnement"
      )
      expect(body_string).not_to match("/invitations/redirect")
      expect(body_string).to match("dans un délai de 3 jours")
      expect(body_string).to match("Logo du département")
      expect(body_string).to match("Logo de l'Union européene")
      expect(body_string).to match("Logo de France Travail")
    end

    context "when the display logos options are disabled" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                        display_europe_logos: false, display_france_travail_logo: false)
      end

      it "does not display the different optional logos" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).not_to match("Logo du département")
        expect(body_string).not_to match("Logo de l'Union européene")
        expect(body_string).not_to match("Logo de France Travail")
      end
    end

    context "when the signature is configured" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end
  end

  describe "#atelier_invitation" do
    subject do
      described_class
        .with(invitation: invitation, user: user)
        .atelier_invitation
    end

    let!(:follow_up) do
      build(:follow_up, motif_category: category_rsa_atelier_rencontres_pro)
    end

    it "renders the headers" do
      expecting_mail_to_have_correct_headers
    end

    it "renders the subject" do
      email_subject = unescape_html(subject.subject)
      expect(email_subject).to eq(
        "[RSA]: Participer à un atelier dans le cadre de votre parcours"
      )
    end

    it "renders the body" do
      body_string = unescape_html(subject.body.encoded)
      expect(body_string).to match("Bonjour Jean VALJEAN")
      expect(body_string).to match("Le département de la Drôme.")
      expect(body_string).to match("01 39 39 39 39")
      expect(body_string).to match(
        "Vous êtes bénéficiaire du RSA et bénéficiez d'un accompagnement. " \
        "En cliquant sur le bouton suivant, vous pouvez <span class=\"font-weight-bold\">consulter le\\(s\\) " \
        "atelier\\(s\\) et formation\\(s\\) proposé\\(s\\)</span> sur la plateforme " \
        "RDV-Solidarités et vous y inscrire directement et librement, dans la limite des places disponibles."
      )
      expect(body_string).to match("/i/r/#{invitation.uuid}")
      expect(body_string).not_to match("dans un délai de 3 jours")
      expect(body_string).to match("Logo du département")
      expect(body_string).to match("Logo de l'Union européene")
      expect(body_string).to match("Logo de France Travail")
    end

    context "when the display logos options are disabled" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                        display_europe_logos: false, display_france_travail_logo: false)
      end

      it "does not display the different optional logos" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).not_to match("Logo du département")
        expect(body_string).not_to match("Logo de l'Union européene")
        expect(body_string).not_to match("Logo de France Travail")
      end
    end

    context "when the signature is configured" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end
  end

  describe "#short_invitation" do
    subject do
      described_class
        .with(invitation: invitation, user: user)
        .short_invitation
    end

    context "for psychologue" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_psychologue)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("Votre rendez-vous de suivi psychologue")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match("Vous êtes invité à participer à un rendez-vous de suivi psychologue.")
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end
  end

  describe "#atelier_enfants_ados" do
    subject do
      described_class
        .with(invitation: invitation, user: user)
        .atelier_enfants_ados_invitation
    end

    context "for atelier_enfants_ados" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_atelier_enfants_ados)
      end

      it "renders the headers" do
        expecting_mail_to_have_correct_headers
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("Invitation à un atelier destiné aux jeunes de ton âge")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match("Tu es invité à participer à un atelier organisé par le Département.")
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end
  end

  describe "#short_invitation_reminder" do
    subject do
      described_class.with(invitation: invitation, user: user).short_invitation_reminder
    end

    context "for psychologue" do
      let!(:follow_up) { build(:follow_up, motif_category: category_psychologue) }

      it "renders the headers" do
        expect(subject.to).to eq([user.email])
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("[Rappel]: Votre rendez-vous de suivi psychologue")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Vous avez reçu un premier mail il y a 3 jours vous invitant à prendre un rendez-vous de suivi psychologue."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match(
          "Il ne vous reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
          " jours</span> pour prendre rendez-vous"
        )
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "when the signature is configured" do
      let!(:follow_up) { build(:follow_up, motif_category: category_psychologue) }
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end
  end

  describe "#standard_invitation_reminder" do
    subject do
      described_class.with(invitation: invitation, user: user).standard_invitation_reminder
    end

    context "for rsa_orientation" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation) }

      it "renders the headers" do
        expect(subject.to).to eq([user.email])
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("[Rappel]: Votre rendez-vous d'orientation dans le cadre de votre RSA")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "En tant que bénéficiaire du RSA, vous avez reçu un premier mail il y a 3 jours " \
          "vous invitant à prendre rendez-vous afin de démarrer un parcours d'accompagnement."
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match(
          "Il ne vous reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
          " jours</span> pour prendre rendez-vous"
        )
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "when the signature is configured" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation) }
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end

    context "for rsa_accompagnement" do
      %w[category_rsa_accompagnement category_rsa_accompagnement_social category_rsa_accompagnement_sociopro]
        .each do |motif_category|
        before { follow_up.motif_category = send(motif_category) }

        it "renders the headers" do
          expect(subject.to).to eq([user.email])
        end

        it "renders the subject" do
          email_subject = unescape_html(subject.subject)
          expect(email_subject).to eq("[Rappel]: Votre rendez-vous d'accompagnement dans le cadre de votre RSA")
        end

        it "renders the body" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).to match("Bonjour Jean VALJEAN")
          expect(body_string).to match("Le département de la Drôme.")
          expect(body_string).to match("01 39 39 39 39")
          expect(body_string).to match(
            "En tant que bénéficiaire du RSA, vous avez reçu un premier mail il y a 3 jours " \
            "vous invitant à prendre rendez-vous afin de démarrer un parcours d'accompagnement."
          )
          expect(body_string).to match("Ce RDV est obligatoire.")
          expect(body_string).to match(
            "votre RSA pourra être suspendu ou réduit."
          )
          expect(body_string).to match("/i/r/#{invitation.uuid}")
          expect(body_string).to match(
            "Il ne vous reste plus que <span class=\"font-weight-bold\">" \
            "#{invitation.number_of_days_before_expiration}" \
            " jours</span> pour prendre rendez-vous"
          )
          expect(body_string).to match("Logo du département")
          expect(body_string).to match("Logo de l'Union européene")
          expect(body_string).to match("Logo de France Travail")
        end

        context "when the display logos options are disabled" do
          let!(:messages_configuration) do
            create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                            display_europe_logos: false, display_france_travail_logo: false)
          end

          it "does not display the different optional logos" do
            body_string = unescape_html(subject.body.encoded)
            expect(body_string).not_to match("Logo du département")
            expect(body_string).not_to match("Logo de l'Union européene")
            expect(body_string).not_to match("Logo de France Travail")
          end
        end
      end
    end

    context "for rsa_cer_signature" do
      let!(:follow_up) do
        build(:follow_up, motif_category: category_rsa_cer_signature)
      end

      it "renders the headers" do
        expect(subject.to).to eq([user.email])
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[Rappel]: Votre rendez-vous de signature de CER " \
          "dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "En tant que bénéficiaire du RSA, vous avez reçu un premier mail il y a 3 jours " \
          "vous invitant à prendre rendez-vous afin de construire et signer votre Contrat d'Engagement Réciproque."
        )
        expect(body_string).to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match(
          "Il ne vous reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
          " jours</span> pour prendre rendez-vous"
        )
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "for rsa_follow_up" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_follow_up) }

      it "renders the headers" do
        expect(subject.to).to eq([user.email])
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq(
          "[Rappel]: Votre rendez-vous de suivi " \
          "dans le cadre de votre RSA"
        )
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "En tant que bénéficiaire du RSA, vous avez reçu un premier mail il y a 3 jours " \
          "vous invitant à prendre rendez-vous afin de faire un point avec votre référent de parcours."
        )
        expect(body_string).not_to match("Ce RDV est obligatoire.")
        expect(body_string).not_to match(
          "votre RSA pourra être suspendu ou réduit."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match(
          "Il ne vous reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
          " jours</span> pour prendre rendez-vous"
        )
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end
  end

  describe "#phone_platform_reminder" do
    subject do
      described_class
        .with(invitation: invitation, user: user)
        .phone_platform_invitation_reminder
    end

    let!(:follow_up) do
      build(:follow_up, motif_category: category_rsa_orientation_on_phone_platform)
    end

    it "renders the headers" do
      expect(subject.to).to eq([user.email])
    end

    it "renders the subject" do
      expect(subject.subject).to eq("[Rappel]: Votre rendez-vous d'orientation téléphonique dans le cadre de votre RSA")
    end

    it "renders the body" do
      body_string = unescape_html(subject.body.encoded)
      expect(body_string).to match("Bonjour Jean VALJEAN")
      expect(body_string).to match("Le département de la Drôme.")
      expect(body_string).to match(
        "En tant que bénéficiaire du RSA, vous avez reçu un premier mail il y a 3 jours vous invitant à contacter" \
        " la plateforme départementale afin de démarrer un parcours d'accompagnement."
      )
      expect(body_string).not_to match("/invitations/redirect")
      expect(body_string).not_to match("uuid=#{invitation.uuid}")
      expect(body_string).to match(
        "Il ne vous reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
        " jours</span> pour appeler le <span class=\"font-weight-bold\">01 39 39 39 39</span>."
      )
      expect(body_string).to match("Logo du département")
      expect(body_string).to match("Logo de l'Union européene")
      expect(body_string).to match("Logo de France Travail")
    end

    context "when the display logos options are disabled" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                        display_europe_logos: false, display_france_travail_logo: false)
      end

      it "does not display the different optional logos" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).not_to match("Logo du département")
        expect(body_string).not_to match("Logo de l'Union européene")
        expect(body_string).not_to match("Logo de France Travail")
      end
    end

    context "when the signature is configured" do
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end
  end

  describe "#atelier_enfants_ados_invitation_reminder" do
    subject do
      described_class.with(invitation: invitation, user: user).atelier_enfants_ados_invitation_reminder
    end

    context "for atelier_enfants_ados" do
      let!(:follow_up) { build(:follow_up, motif_category: category_atelier_enfants_ados) }

      it "renders the headers" do
        expect(subject.to).to eq([user.email])
      end

      it "renders the subject" do
        email_subject = unescape_html(subject.subject)
        expect(email_subject).to eq("[Rappel]: Invitation à un atelier destiné aux jeunes de ton âge")
      end

      it "renders the body" do
        body_string = unescape_html(subject.body.encoded)
        expect(body_string).to match("Bonjour Jean VALJEAN")
        expect(body_string).to match("Le département de la Drôme.")
        expect(body_string).to match("01 39 39 39 39")
        expect(body_string).to match(
          "Tu as reçu un premier mail il y a 3 jours t'invitant à un atelier destiné aux jeunes de ton âge."
        )
        expect(body_string).to match("/i/r/#{invitation.uuid}")
        expect(body_string).to match(
          "Il ne te reste plus que <span class=\"font-weight-bold\">#{invitation.number_of_days_before_expiration}" \
          " jours</span> pour prendre rendez-vous à la date et l'horaire de ton choix en cliquant" \
          " sur le bouton suivant."
        )
        expect(body_string).to match("Logo du département")
        expect(body_string).to match("Logo de l'Union européene")
        expect(body_string).to match("Logo de France Travail")
      end

      context "when the display logos options are disabled" do
        let!(:messages_configuration) do
          create(:messages_configuration, organisation: organisation, display_department_logo: false,
                                          display_europe_logos: false, display_france_travail_logo: false)
        end

        it "does not display the different optional logos" do
          body_string = unescape_html(subject.body.encoded)
          expect(body_string).not_to match("Logo du département")
          expect(body_string).not_to match("Logo de l'Union européene")
          expect(body_string).not_to match("Logo de France Travail")
        end
      end
    end

    context "when the signature is configured" do
      let!(:follow_up) { build(:follow_up, motif_category: category_psychologue) }
      let!(:messages_configuration) do
        create(:messages_configuration, organisation: organisation, signature_lines: ["Fabienne Bouchet"])
      end

      it "renders the mail with the right signature" do
        expect(subject.body.encoded).to match(/Fabienne Bouchet/)
      end
    end
  end

  def expecting_mail_to_have_correct_headers
    expect(subject.to).to eq([user.email])
    expect(subject.header["X-Mailin-custom"].value).to eq({ record_identifier: invitation.record_identifier }.to_json)
  end
end
