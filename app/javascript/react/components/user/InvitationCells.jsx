import React from "react";
import Tippy from "@tippyjs/react";

import InvitationCell from "./InvitationCell";

import { getFrenchFormatDateString } from "../../../lib/datesHelper";

export default function InvitationCells({ user }) {
  return (
    /* ----------------------------- Disabled invitations cases -------------------------- */
    user.isArchived() ? (
      <td colSpan={user.list.invitationsColSpan}>
        Dossier archivé
      </td>
    ) : user.createdAt && user.list.isDepartmentLevel && !user.linkedToCurrentCategory() ? (
      <td colSpan={user.list.invitationsColSpan}>
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
        <td colSpan={user.list.invitationsColSpan}>
          {user.currentFollowUp.human_status} (le {getFrenchFormatDateString(user.currentPendingRdv.starts_at)})
        </td>
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
