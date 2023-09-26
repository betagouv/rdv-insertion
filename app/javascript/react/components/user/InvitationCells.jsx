import React from "react";
import Tippy from "@tippyjs/react";

import InvitationCell from "./InvitationCell";

export default function InvitationCells({ user, invitationsColspan, isDepartmentLevel }) {
  return (
    /* ----------------------------- Disabled invitations cases -------------------------- */
    user.isArchivedInCurrentDepartment() ? (
      <td colSpan={invitationsColspan}>
        Dossier archivé
        {user.archiveInCurrentDepartment().archiving_reason && (
          <>&nbsp;: {user.archiveInCurrentDepartment().archiving_reason}</>
        )}
      </td>
    ) : user.createdAt && isDepartmentLevel && !user.linkedToCurrentCategory() ? (
      <td colSpan={invitationsColspan}>
        L'usager n'appartient pas à une organisation qui gère ce type de rdv{" "}
        <Tippy
          content={
            <>
              Ajoutez l'usager à une organisation qui gère ces rdvs en appuyant sur le boutton
              "Ajouter à une organisation" sur sa fiche, puis rechargez le fichier
            </>
          }
        >
          <i className="fas fa-question-circle" />
        </Tippy>
      </td>
    ) : user.currentContextStatus === "rdv_pending" ? (
      <>
        <td colSpan={invitationsColspan}>{user.currentRdvContext.human_status}</td>
      </>
    ) : (
      /* ----------------------------- Enabled invitations cases --------------------------- */

      <>
        {/* --------------------------------- Invitations ------------------------------- */}
        <InvitationCell user={user} format="sms" />
        <InvitationCell user={user} format="email" />
        <InvitationCell user={user} format="postal" />
      </>
    )
  );
}