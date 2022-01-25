import React, { useEffect, useState } from "react";
import Swal from "sweetalert2";
import Tippy from "@tippyjs/react";

import retrievePhoneNumber from "../../lib/retrievePhoneNumber";
import handleApplicantCreation from "../lib/handleApplicantCreation";
import handleApplicantInvitation from "../lib/handleApplicantInvitation";
import updateApplicant from "../actions/updateApplicant";
import retrieveRelevantOrganisation from "../../lib/retrieveRelevantOrganisation";

export default function Applicant({ applicant, dispatchApplicants, contactsData, isDepartmentLevel }) {
  const [isLoading, setIsLoading] = useState({
    updateContacts: false,
    accountCreation: false,
    smsInvitation: false,
    emailInvitation: false,
    addToOrganisation: false,
  });

  const updateApplicantContacts = async (applicantContactsData) => {
    setIsLoading({ ...isLoading, updateContacts: true });
    // first, we update the contact infos of the js model if necessary
    let phoneNumberUpdated = false;
    let emailUpdated = false;

    if (applicant.phoneNumber == null) {
      applicant.updatePhoneNumber(retrievePhoneNumber(applicantContactsData));
      phoneNumberUpdated = true;
    }
    if (applicant.email == null) {
      applicant.updateEmail(applicantContactsData["ADRESSE ELECTRONIQUE DOSSIER"]);
      emailUpdated = true;
    }

    // if the applicant exists in DB, we update the record to allow invitations on this page
    if (applicant.createdAt) {
      const result = await updateApplicant(
        applicant.currentOrganisation.id,
        applicant.id,
        applicant.asJson()
      );
      // if the update fails, we don't notify the agent, but remove the unusable contacts infos
      if (!result.success) {
        if (phoneNumberUpdated && result.errors[0].includes("Téléphone")) applicant.updatePhoneNumber(undefined);
        if (emailUpdated && result.errors[0].includes("Email")) applicant.updateEmail(undefined);
      }
    }
    setIsLoading({ ...isLoading, updateContacts: false });
  }

  useEffect(() => {
    if (contactsData.length > 0 && (applicant.phoneNumber == null || applicant.email == null)) {
      const applicantContactsData = contactsData.find((a) =>
        a.MATRICULE.toString() === applicant.affiliationNumber
      );
      if (applicantContactsData) updateApplicantContacts(applicantContactsData);
    }
  }, [contactsData]);

  const handleClick = async (action) => {
    setIsLoading({ ...isLoading, [action]: true });
    if (action === "accountCreation") {
      if (!applicant.currentOrganisation) {
        applicant.currentOrganisation = await retrieveRelevantOrganisation(
          applicant.departmentNumber,
          applicant.fullAddress
        );
        // If there is still no organisation it means the assignation was cancelled by agent
        if (!applicant.currentOrganisation) {
          setIsLoading({ ...isLoading, [action]: false });
          return;
        }
      }
      await handleApplicantCreation(applicant, applicant.currentOrganisation.id);
    } else if (action === "addToOrganisation") {
      const result = await updateApplicant(
        applicant.currentOrganisation.id,
        applicant.id,
        applicant.asJson()
      );
      if (result.success) {
        applicant.updateWith(result.applicant);
      } else {
        Swal.fire("Impossible d'assigner à l'orrganisation", result.errors[0], "error");
      }
    } else if (action === "smsInvitation") {
      const invitation = await handleApplicantInvitation(
        applicant.id,
        applicant.department.id,
        applicant.currentOrganisation,
        isDepartmentLevel,
        "sms"
      );
      applicant.lastSmsInvitationSentAt = invitation.sent_at;
    } else if (action === "emailInvitation") {
      const invitation = await handleApplicantInvitation(
        applicant.id,
        applicant.department.id,
        applicant.currentOrganisation,
        isDepartmentLevel,
        "email"
      );
      applicant.lastEmailInvitationSentAt = invitation.sent_at;
    }

    dispatchApplicants({
      type: "update",
      item: {
        seed: applicant.uid,
        applicant,
      },
    });
    setIsLoading({ ...isLoading, [action]: false });
  };

  return (
    <tr key={applicant.uid}>
      <td>{applicant.affiliationNumber}</td>
      <td>{applicant.shortTitle}</td>
      <td>{applicant.firstName}</td>
      <td>{applicant.lastName}</td>
      <td>{applicant.shortRole}</td>
      {applicant.shouldDisplay("birth_date") && <td>{applicant.birthDate ?? " - "}</td>}
      {applicant.shouldDisplay("email") && <td>{applicant.email ?? " - "}</td>}
      {applicant.shouldDisplay("phone_number") && <td>{applicant.phoneNumber ?? " - "}</td>}
      {applicant.shouldDisplay("department_internal_id") && (
        <td>{applicant.departmentInternalId ?? " - "}</td>
      )}
      {applicant.shouldDisplay("rights_opening_date") && (
        <td>{applicant.rightsOpeningDate ?? " - "}</td>
      )}
      <td>
        {applicant.createdAt ? (
          applicant.belongsToCurrentOrg() ? (
            <i className="fas fa-check green-check" />
          ) : (
            <Tippy
              content={
                <span>
                  Cet allocataire est déjà présent dans RDV-Insertion dans une autre organisation
                  que l&apos;organisation actuelle.
                  <br />
                  Appuyez sur ce bouton pour ajouter l&apos;allocataire à cette organisation et
                  mettre à jours ses informations.
                </span>
              }
            >
              <button
                type="submit"
                disabled={isLoading.addToOrganisation}
                className="btn btn-primary btn-blue"
                onClick={() => handleClick("addToOrganisation")}
              >
                {isLoading.addToOrganisation ? "En cours..." : "Ajouter à cette organisation"}
              </button>
            </Tippy>
          )
        ) : (
          <button
            type="submit"
            disabled={isLoading.accountCreation}
            className="btn btn-primary btn-blue"
            onClick={() => handleClick("accountCreation")}
          >
            {isLoading.accountCreation ? "Création..." : "Créer compte"}
          </button>
        )}
      </td>
      {applicant.shouldBeInvitedBySms() && (
        <>
          <td>
            {applicant.lastSmsInvitationSentAt ? (
              <i className="fas fa-check green-check" />
            ) : (
              <button
                type="submit"
                disabled={
                  isLoading.smsInvitation ||
                  !applicant.createdAt ||
                  !applicant.phoneNumber ||
                  !applicant.belongsToCurrentOrg()
                }
                className="btn btn-primary btn-blue"
                onClick={() => handleClick("smsInvitation")}
              >
                {isLoading.smsInvitation ? "Invitation..." : "Inviter par SMS"}
              </button>
            )}
          </td>
        </>
      )}
      {applicant.shouldBeInvitedByEmail() && (
        <>
          <td>
            {applicant.lastEmailInvitationSentAt ? (
              <i className="fas fa-check green-check" />
            ) : (
              <button
                type="submit"
                disabled={
                  isLoading.emailInvitation ||
                  !applicant.createdAt ||
                  !applicant.email ||
                  !applicant.belongsToCurrentOrg()
                }
                className="btn btn-primary btn-blue"
                onClick={() => handleClick("emailInvitation")}
              >
                {isLoading.emailInvitation ? "Invitation..." : "Inviter par mail"}
              </button>
            )}
          </td>
        </>
      )}
    </tr>
  );
}
