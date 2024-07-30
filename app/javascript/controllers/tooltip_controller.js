import { Controller } from "@hotwired/stimulus";
import tippy from "tippy.js";

export default class extends Controller {
  actionRequired() {
    tippy(this.element, {
      content(reference) {
        const { numberOfDaysBeforeActionRequired } = reference.dataset;
        return (
          "Une intervention est nécessaire quand: " +
          `<ul><li>L'invitation a été envoyée depuis + de ${numberOfDaysBeforeActionRequired} jours sans réponse</li>` +
          "<li>Le RDV a été annulé par l'un des partis ou l'usager ne s'est pas présenté au RDV</li>" +
          "<li>L'issue du RDV n'a pas été renseignée sur RDV-Solidarités</li></ul>"
        );
      },
      allowHTML: true,
    });
  }

  organisationArchiveInformations() {
    tippy(this.element, {
      content(reference) {
        const { archiveCreationDate, archiveReason, showArchivingReason } = reference.dataset;
        const displayedArchivingReason = showArchivingReason === "true" ? `Motif: ${archiveReason || "Aucun motif renseigné"}` : ""

        return (
          `Archivé le ${archiveCreationDate}<br/>${displayedArchivingReason}`
        );
      },
      allowHTML: true,
    });
  }

  tagCreationDate() {
    tippy(this.element, {
      content(reference) {
        const { tagCreationDate } = reference.dataset;
        return (`Tag ajouté le ${tagCreationDate}`);
      },
      allowHTML: true,
    });
  }

  csvExportUsers() {
    tippy(this.element, {
      content: "Les usagers correspondant aux filtres actuels seront exportés",
      placement: "bottom",
    });
  }

  csvExportParticipations() {
    tippy(this.element, {
      content: "Les RDVs des usagers correspondant aux filtres actuels seront exportés",
      placement: "bottom",
    });
  }

  organisationDetails() {
    tippy(this.element, {
      content:
        "Les modifications du nom, de l'email et du téléphone seront répercutées sur RDV-Solidarités",
      placement: "bottom",
    });
  }

  slugAttribute() {
    tippy(this.element, {
      content:
        "Si l'assignation des usagers à l'organisation se fait via une colonne du fichier d'import " +
        "des usagers, les cases de cette colonne devront faire référence à la valeur définie ici.",
    });
  }

  senderCityAttribute() {
    tippy(this.element, {
      content:
        "Si aucune ville n'est définie, c'est la préfecture du département qui sera utilisée.",
    });
  }

  directionNamesAttribute() {
    tippy(this.element, {
      content:
        "Si aucun en-tête n'est défini, c'est le nom de l'organisation qui sera utilisé en haut à gauche du courrier.",
    });
  }

  letterSenderNameAttribute() {
    tippy(this.element, {
      content() {
        return (
          "Dans les courriers d'invitation, permet de personnaliser la phrase :<br/>" +
          "<i>Pour faciliter votre prise de rendez-vous, le Conseil départemental a mis en place.<br/><br/></i>" +
          "Si cette option est définie, la valeur renseignée remplacera <i>le Conseil départemental</i> dans cette phrase."
        );
      },
      allowHTML: true,
    });
  }

  safirCodeAttribute() {
    tippy(this.element, {
      content() {
        return "Il ne concerne que les agences France Travail";
      },
      allowHTML: true,
    });
  }

  departmentInternalIdAttribute() {
    tippy(this.element, {
      content: "ID dans l'éditeur logiciel (IODAS, SOLIS...) ou dans le SI du département",
    });
  }

  closeFollowUpButton() {
    tippy(this.element, {
      content:
        "Le statut du bénéficiaire pour cette catégorie passera en «Dossier traité» et ses invitations seront désactivées. Il n'apparaîtra plus dans la liste de suivi de cette catégorie, mais restera visible dans l'onglet «Tous les contacts».",
      placement: "bottom",
    });
  }

  reopenFollowUpButton() {
    tippy(this.element, {
      content: "Le bénéficiaire pourra de nouveau être invité et suivi dans ce contexte",
      placement: "bottom",
    });
  }

  helpAddressAttribute() {
    tippy(this.element, {
      content() {
        return (
          "Les courriers d'invitation se terminent par la phrase suivante :<br/>" +
          "<i>Si vous rencontrez une difficulté pour accéder à internet, veuillez téléphoner dès réception de ce courrier au XXXXXXXX.<br/><br/></i>" +
          "Si cette option est renseignée, la phrase se poursuivra de la manière suivante : veuillez téléphoner dès réception de ce courrier au XXXXXXXXXX ou vous rendre <i>texte défini avec cette option</i>."
        );
      },
      allowHTML: true,
    });
  }

  smsSenderNameAttribute() {
    tippy(this.element, {
      content() {
        return (
          "Par défaut, le nom de l'expéditeur des SMS reçus par les usagers est : Dept17 (le numéro change en fonction " +
          "du département). Vous pouvez modifier l'expéditeur affiché ici. Attention, le nom ne doit pas dépasser " +
          "11 caractères et ne comporter aucun espace.<br/><br/>" +
          "<b>Nous vous recommandons de ne pas modifier cette option.</b>"
        );
      },
      allowHTML: true,
    });
  }

  archivingDisabled() {
    // the button is in a wrapper because we cannot set a tooltip on a disabled element
    const archiveButton = document.getElementById("archive-button");
    if (archiveButton.classList.contains("disabled")) {
      tippy(this.element, {
        content:
          "L'usager est archivé dans toutes vos organisations. Pour rouvrir son dossier, naviguez au sein d'une organisation où il est archivé.",
      });
    }
  }

  noCategorySelected() {
    tippy(this.element, {
      content:
        "L'usager apparaitra dans l'onglet 'Tous les contacts' seulement. " +
        "En choisissant cette option vous ne pourrez pas inviter l'usager à prendre rdv à l'upload du fichier " +
        "(mais vous pourrez le faire ultérieurement en accédant à sa fiche).",
    });
  }

  reOrderCategories() {
    tippy(this.element, {
      content:
        "Vous pouvez réorganiser l'ordre d'affichage des catégories en les faisant glisser-déposer.",
    });
  }

  reinviteButton() {
    tippy(this.element, {
      content:
       "Réinviter remettra les compteurs à 0 vis à vis des délais",
      placement: "bottom",
    });
  }

  invitationNotDelivered() {
    tippy(this.element, {
      content(reference) {
        const { invitationFormat } = reference.dataset;
        if (invitationFormat === "sms") {
          return "Le SMS n'a pas pu être délivré. Causes possibles : numéro incorrect, problème de l'opérateur, etc. Nous vous invitons à vérifier le format du numéro et à le modifier si nécessaire.";
        }
        return "L’email n'a pas pu être remis. Causes possibles : boîte de réception pleine ou indisponible, adresse email incorrecte ou inexistante, filtre anti-spams, etc. Nous vous invitons à vérifier le format de l’adresse email et de réessayer d'envoyer l'invitation.";
      },
      placement: "top",
    });
  }
}
