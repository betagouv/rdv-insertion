import React from "react";
import Tippy from "@tippyjs/react";

import InvitationCell from "./InvitationCell";

export default function InvitationCells({ user }) {
  return (
    /* ----------------------------- Disabled invitations cases -------------------------- */
    user.isArchivedInCurrentDepartment() ? (
      <td colSpan={user.list.invitationsColspan}>
        Dossier archivé
        {user.archiveInCurrentDepartment().archiving_reason && (
          <>&nbsp;: {user.archiveInCurrentDepartment().archiving_reason}</>
        )}
      </td>
    ) : user.createdAt && user.list.isDepartmentLevel && !user.linkedToCurrentCategory() ? (
      <td colSpan={user.list.invitationsColspan}>
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
    ) : user.currentFollowUpStatus === "rdv_pending" ? (
      <>
        <td colSpan={user.list.invitationsColspan}>{user.currentFollowUp.human_status}</td>
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
