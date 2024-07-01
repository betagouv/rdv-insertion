describe Invitations::SendSms, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  include_context "with all existing categories"

  let!(:help_phone_number) { "0147200001" }
  let!(:phone_number) { "+33782605941" }
  let!(:user) do
    create(
      :user,
      phone_number: phone_number,
      first_name: "john", last_name: "doe", title: "monsieur"
    )
  end
  let!(:department) do
    create(
      :department,
      number: "26",
      name: "Drôme",
      region: "Auvergne-Rhône-Alpes"
    )
  end
  let!(:organisation) { create(:organisation, department: department) }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: category_rsa_orientation)
  end
  let!(:sms_sender_name) { "provider" }

  let!(:invitation) do
    create(
      :invitation,
      user: user, department: department, rdv_solidarites_token: "123", help_phone_number: help_phone_number,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/lieux?invitation_token=123", format: "sms", follow_up: follow_up
    )
  end

  let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation) }
  let!(:content) do
    "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
      " à un rendez-vous d'orientation. " \
      "Pour choisir la date du RDV, cliquez sur ce lien " \
      "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
      "Ce RDV est obligatoire. En cas de problème, contactez le 0147200001."
  end

  describe "#call" do
    before do
      allow(SendTransactionalSms).to receive(:call).and_return(OpenStruct.new(success?: true))
      allow(invitation).to receive(:sms_sender_name).and_return(sms_sender_name)
      ENV["RDV_SOLIDARITES_URL"] = "www.rdv-solidarites.fr"
    end

    it("is a success") { is_a_success }

    it "calls the send sms service with the right content" do
      expect(SendTransactionalSms).to receive(:call)
        .with(
          phone_number: phone_number, content: content,
          sender_name: sms_sender_name
        )
      subject
    end

    context "when the phone number is nil" do
      let!(:phone_number) { nil }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Le téléphone doit être renseigné"])
      end
    end

    context "when the phone number is not a mobile" do
      let!(:phone_number) { "0142249062" }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Le numéro de téléphone doit être un mobile"])
      end
    end

    context "when the invitation format is not sms" do
      before { invitation.format = "email" }

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Envoi de SMS alors que le format est email"])
      end
    end

    context "when it is a reminder" do
      let!(:content) do
        "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours vous " \
          "invitant à prendre RDV au créneau de votre choix afin de démarrer un parcours d'accompagnement. " \
          "Ce lien de prise de RDV expire dans 5 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. En cas de problème, contactez le 0147200001."
      end

      before do
        invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
      end

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "when the template attributes are overriden by the category_configuration" do
      before do
        category_configuration.update!(
          template_rdv_title_override: "nouveau type de rendez-vous",
          template_user_designation_override: "nouveau"
        )
      end

      let!(:content) do
        "M. John DOE,\nVous êtes nouveau et êtes #{user.conjugate('invité')} à participer" \
          " à un nouveau type de rendez-vous. " \
          "Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. En cas de problème, contactez le 0147200001."
      end

      it "sends the content with the overriden attributes" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa accompagnement" do
      let!(:follow_up) { build(:follow_up) }
      let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à " \
          "participer à un rendez-vous d'accompagnement." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. En l'absence d'action de votre part, " \
          "votre RSA pourra être suspendu ou réduit. " \
          "En cas de problème, contactez le 0147200001."
      end

      %w[category_rsa_accompagnement category_rsa_accompagnement_social category_rsa_accompagnement_sociopro]
        .each do |motif_category|
        before do
          follow_up.motif_category = send(motif_category)
          category_configuration.motif_category = send(motif_category)
        end

        it("is a success") { is_a_success }

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end

        context "when it is a reminder" do
          let!(:content) do
            "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours vous " \
              "invitant à prendre RDV au créneau de votre choix afin de démarrer un parcours d'accompagnement. " \
              "Ce lien de prise de RDV expire dans 5 jours: " \
              "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
              "Ce RDV est obligatoire. En l'absence d'action de votre part, " \
              "votre RSA pourra être suspendu ou réduit. En cas de problème, contactez le " \
              "0147200001."
          end

          before do
            invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
          end

          it "calls the send transactional service with the right content" do
            expect(SendTransactionalSms).to receive(:call)
              .with(
                phone_number: phone_number, content: content,
                sender_name: sms_sender_name
              )
            subject
          end
        end
      end
    end

    context "for rsa orientation on phone platform" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation_on_phone_platform) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation,
                                        motif_category: category_rsa_orientation_on_phone_platform)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et devez contacter la plateforme départementale " \
          "afin de démarrer un parcours d'accompagnement. Pour cela, merci d'appeler le " \
          "0147200001 dans les 3 jours. " \
          "Cet appel est obligatoire pour le traitement de votre dossier. "
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours vous " \
            "invitant à contacter la plateforme départementale afin de démarrer un parcours d'accompagnement. " \
            "Il vous reste 5 jours pour appeler le " \
            "0147200001. Cet appel est obligatoire pour le traitement de votre dossier. "
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for rsa cer signature" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_cer_signature) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_cer_signature)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
          " à un rendez-vous de signature de CER." \
          " Pour choisir la date du RDV, cliquez sur ce lien dans les " \
          "3 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours " \
            "vous invitant à prendre RDV au créneau de votre choix afin de construire et signer " \
            "votre Contrat d'Engagement Réciproque. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "Ce RDV est obligatoire. En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for rsa_main_tendue" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_main_tendue) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_main_tendue)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
          " à un entretien de main tendue." \
          " Pour choisir la date du RDV, cliquez sur ce lien dans les " \
          "3 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours " \
            "vous invitant à prendre RDV au créneau de votre choix afin de faire le point sur votre situation." \
            " Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "Ce RDV est obligatoire. En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for rsa_atelier_collectif_mandatory" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_atelier_collectif_mandatory) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation,
                                        motif_category: category_rsa_atelier_collectif_mandatory)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
          " à un atelier collectif. Pour choisir la date du RDV, cliquez sur ce lien dans les " \
          "3 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours " \
            "vous invitant à prendre RDV au créneau de votre choix afin de vous aider dans votre parcours d'insertion" \
            ". Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "Ce RDV est obligatoire. En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for rsa_spie" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_spie) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_spie)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes demandeur d'emploi et êtes #{user.conjugate('invité')} à participer" \
          " à un rendez-vous d'accompagnement." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. En l'absence d'action de votre part, " \
          "votre RSA pourra être suspendu ou réduit. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que demandeur d'emploi, vous avez reçu un message il y a 3 jours vous " \
            "invitant à prendre RDV au créneau de votre choix afin de démarrer un parcours d'accompagnement. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "Ce RDV est obligatoire. En l'absence d'action de votre part, " \
            "votre RSA pourra être suspendu ou réduit. En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for siae_interview" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_interview) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_siae_interview)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)" \
          " et êtes #{user.conjugate('invité')} à participer à un entretien d'embauche." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que candidat.e dans une Structure d’Insertion par l’Activité Economique " \
            "(SIAE), vous avez reçu un message il y a 3 jours vous " \
            "invitant à prendre RDV au créneau de votre choix afin de poursuivre le processus de recrutement. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for siae_collective_information" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_collective_information) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation,
                                        motif_category: category_siae_collective_information)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes candidat.e dans une Structure d’Insertion par l’Activité Economique (SIAE)" \
          " et êtes #{user.conjugate('invité')} à participer à un rendez-vous collectif d'information." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que candidat.e dans une Structure d’Insertion par l’Activité Economique " \
            "(SIAE), vous avez reçu un message il y a 3 jours vous " \
            "invitant à prendre RDV au créneau de votre choix afin de découvrir cette structure. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for siae_follow_up" do
      let!(:follow_up) { build(:follow_up, motif_category: category_siae_follow_up) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_siae_follow_up)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes salarié.e au sein de notre structure" \
          " et êtes #{user.conjugate('invité')} à participer à un rendez-vous de suivi." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que salarié.e au sein de notre structure, " \
            "vous avez reçu un message il y a 3 jours vous " \
            "invitant à prendre RDV au créneau de votre choix afin de faire un point avec votre référent. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for psychologue" do
      let!(:follow_up) { build(:follow_up, motif_category: category_psychologue) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_psychologue)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes invité à prendre un rendez-vous de suivi psychologue." \
          " Pour choisir la date du RDV, cliquez sur ce lien: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa_orientation_france_travail" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_orientation_france_travail) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation,
                                        motif_category: category_rsa_orientation_france_travail)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes invité à participer à " \
          "un rendez-vous d'orientation." \
          " Pour choisir la date du RDV, cliquez sur ce lien dans les " \
          "3 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for atelier_enfants_ados" do
      let!(:follow_up) { build(:follow_up, motif_category: category_atelier_enfants_ados) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_atelier_enfants_ados)
      end
      let!(:content) do
        "John Doe,\nTu es invité à participer à un atelier organisé par le département. " \
          "Nous te proposons de cliquer ci-dessous pour découvrir le programme. " \
          "Si tu es intéressé pour participer, tu n’auras qu’à cliquer et t’inscrire en ligne avec le lien suivant: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, tu peux contacter le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa_integration_information" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_integration_information) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation,
                                        motif_category: category_rsa_integration_information)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
          " à un rendez-vous d'information." \
          " Pour choisir la date du RDV, cliquez sur ce lien " \
          "dans les 3 jours: rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "Ce RDV est obligatoire. " \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours vous " \
            "invitant à prendre RDV au créneau de votre choix afin de vous renseigner sur vos droits et vos devoirs. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "Ce RDV est obligatoire. En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end

    context "for rsa insertion offer" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_insertion_offer) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_insertion_offer)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et bénéficiez d'un accompagnement. " \
          "Vous pouvez consulter le(s) atelier(s) et formation(s) proposé(s) et vous y inscrire directement et " \
          "librement, dans la limite des places disponibles, en cliquant sur ce lien: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa_atelier_competences" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_atelier_competences) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_atelier_competences)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et bénéficiez d'un accompagnement. " \
          "Vous pouvez consulter le(s) atelier(s) et formation(s) proposé(s) et vous y inscrire directement et " \
          "librement, dans la limite des places disponibles, en cliquant sur ce lien: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa_atelier_rencontres_pro" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_atelier_rencontres_pro) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_atelier_rencontres_pro)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et bénéficiez d'un accompagnement. " \
          "Vous pouvez consulter le(s) atelier(s) et formation(s) proposé(s) et vous y inscrire directement et " \
          "librement, dans la limite des places disponibles, en cliquant sur ce lien: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end
    end

    context "for rsa follow up" do
      let!(:follow_up) { build(:follow_up, motif_category: category_rsa_follow_up) }
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_rsa_follow_up)
      end
      let!(:content) do
        "M. John DOE,\nVous êtes bénéficiaire du RSA et êtes #{user.conjugate('invité')} à participer" \
          " à un rendez-vous de suivi. " \
          "Pour choisir la date du RDV, cliquez sur ce lien dans les " \
          "3 jours: " \
          "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
          "En cas de problème, contactez le 0147200001."
      end

      it("is a success") { is_a_success }

      it "calls the send transactional service with the right content" do
        expect(SendTransactionalSms).to receive(:call)
          .with(
            phone_number: phone_number, content: content,
            sender_name: sms_sender_name
          )
        subject
      end

      context "when it is a reminder" do
        let!(:content) do
          "M. John DOE,\nEn tant que bénéficiaire du RSA, vous avez reçu un message il y a 3 jours " \
            "vous invitant à prendre RDV au créneau de votre choix afin de faire un point avec votre référent" \
            " de parcours. " \
            "Ce lien de prise de RDV expire dans 5 jours: " \
            "rdv-solidarites.fr/i/r/#{invitation.uuid}\n" \
            "En cas de problème, contactez le " \
            "0147200001."
        end

        before do
          invitation.update!(trigger: "reminder", valid_until: 5.days.from_now)
        end

        it "calls the send transactional service with the right content" do
          expect(SendTransactionalSms).to receive(:call)
            .with(
              phone_number: phone_number, content: content,
              sender_name: sms_sender_name
            )
          subject
        end
      end
    end
  end
end
