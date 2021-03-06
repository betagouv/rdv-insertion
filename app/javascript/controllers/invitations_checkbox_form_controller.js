import { Controller } from "@hotwired/stimulus";
import { navigator } from "@hotwired/turbo";
import tippy from "tippy.js";
import getInvitationLetter from "../react/actions/getInvitationLetter";

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
    this.element.parentElement.classList.add("spinner-border", "spinner-border-sm");
    navigator.submitForm(this.element.closest("form"));
  }

  async submitStart(event) {
    // For postal invitations, we have to use JSON instead of Turbostream as I found no
    // way to send_data as a turbo stream
    const body = Object.fromEntries(event.detail.formSubmission.fetchRequest.entries);
    if (body.invitation_format === "postal") {
      event.detail.formSubmission.stop();
      const { applicantId, departmentId, organisationId } = this.element.dataset;

      const isDepartmentLevel = !organisationId;

      const result = await getInvitationLetter(
        applicantId,
        departmentId,
        organisationId,
        isDepartmentLevel,
        body.motif_category,
        body.help_phone_number
      );

      const checkbox = this.element.querySelector("input[type=checkbox]");

      checkbox.hidden = false;
      checkbox.parentElement.classList.remove("spinner-border", "spinner-border-sm");
      if (result.success) {
        checkbox.disabled = true;
      } else {
        checkbox.checked = false;
      }
    }
  }
}
