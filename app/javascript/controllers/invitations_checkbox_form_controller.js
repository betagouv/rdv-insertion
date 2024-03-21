import { Controller } from "@hotwired/stimulus";
import { navigator } from "@hotwired/turbo";
import tippy from "tippy.js";
import handleUserInvitation from "../react/lib/handleUserInvitation";
import { getFrenchFormatDateString, todaysDateString } from "../lib/datesHelper";

export default class extends Controller {
  connect() {
    const checkbox = this.element.querySelector("input[type=checkbox]");
    const { invitationFormat } = this.element.dataset;
    if (!checkbox) return null;

    if (invitationFormat === "postal") {
      return tippy(checkbox, {
        content: "Générer courrier d'invitation",
      });
    }

    return tippy(checkbox, {
      content: `Envoyer ${invitationFormat} d'invitation`,
    });
  }

  submit() {
    this.element.hidden = true;
    if (this.element.labels[0]) {
      this.element.labels[0].hidden = true;
    }
    this.element.parentElement.classList.add("spinner-border", "spinner-border-sm");
    navigator.submitForm(this.element.closest("form"));
  }

  async submitStart(event) {
    // We have to use JSON instead of Turbostream because postal invitation return raw data as pdfs
    const body = Object.fromEntries(event.detail.formSubmission.fetchRequest.entries);
    event.detail.formSubmission.stop();
    const { userId, departmentId, organisationId, followUpId } = this.element.dataset;

    const isDepartmentLevel = !organisationId;
    const result = await handleUserInvitation(
      userId,
      departmentId,
      organisationId,
      isDepartmentLevel,
      body.motif_category_id,
      body.invitation_format
    );

    const checkbox = this.element.querySelector("input[type=checkbox]");

    checkbox.hidden = false;
    checkbox.parentElement.classList.remove("spinner-border", "spinner-border-sm");
    if (result.success) {
      checkbox.disabled = true;
      checkbox.classList = "";
      this.updateFirstInvitationDate(followUpId);
      this.updateLastInvitationDate(followUpId);
      this.updateStatus(followUpId);
    } else {
      checkbox.checked = false;
      if (checkbox.labels[0]) {
        checkbox.labels[0].hidden = false;
      }
    }
  }

  updateFirstInvitationDate(followUpId) {
    const firstInvitationDate = document.getElementById(`first-invitation-date-${followUpId}`);
    if (firstInvitationDate.innerHTML === " - ") {
      firstInvitationDate.innerHTML = getFrenchFormatDateString(todaysDateString());
    }
  }

  updateLastInvitationDate(followUpId) {
    const lastInvitationDate = document.getElementById(`last-invitation-date-${followUpId}`);
    lastInvitationDate.innerHTML = getFrenchFormatDateString(todaysDateString());
  }

  updateStatus(followUpId) {
    const status = document.getElementById(`follow-up-status-${followUpId}`);
    status.classList = [];
    status.innerHTML = "Invitation en attente de réponse";
  }
}
