import React, { useState } from "react";

import retrieveInvitationsByFormatAndContext from "../../lib/retrieveInvitationsByFormatAndContext";
import retrieveLastInvitationDate from "../../lib/retrieveLastInvitationDate";
import handleApplicantInvitation from "../lib/handleApplicantInvitation";
import getInvitationLetter from "../actions/getInvitationLetter";
import { getFrenchFormatDateString, todaysDateString } from "../../lib/datesHelper";

export default function InvitationBlock({
  applicant,
  invitations,
  organisation,
  department,
  context,
  isDepartmentLevel,
  invitationFormats,
  numberOfDaysToAcceptInvitation,
  status,
}) {
  const [isLoading, setIsLoading] = useState({
    smsInvitation: false,
    emailInvitation: false,
    postalInvitation: false,
  });
  const [lastSmsInvitationSentAt, setLastSmsInvitationSentAt] = useState(
    retrieveLastInvitationDate(invitations, "sms")
  );
  const [lastEmailInvitationSentAt, setLastEmailInvitationSentAt] = useState(
    retrieveLastInvitationDate(invitations, "email")
  );
  const [lastPostalInvitationSentAt, setLastPostalInvitationSentAt] = useState(
    retrieveLastInvitationDate(invitations, "postal")
  );
  const [smsInvitations, setSmsInvitations] = useState(retrieveInvitationsByFormatAndContext(invitations, "sms"));
  const [emailInvitations, setEmailInvitations] = useState(retrieveInvitationsByFormatAndContext(invitations, "email"));
  const [postalInvitations, setPostalInvitations] = useState(retrieveInvitationsByFormatAndContext(invitations, "postal"));
  const [showInvitationsHistory, setShowInvitationsHistory] = useState(false);

  const showInvitation = (format) => invitationFormats.includes(format);

  const updateStatusBlock = () => {
    const statusBlock = document.getElementById(`js-block-status-${context}`);
    if (statusBlock) {
      statusBlock.textContent = "Invitation en attente de réponse";
      statusBlock.className = "p-4";
    }
  };

  const handleClick = async (action) => {
    setIsLoading({ ...isLoading, [action]: true });
    const applicantParams = [
      applicant,
      department.id,
      organisation,
      isDepartmentLevel,
      context,
      numberOfDaysToAcceptInvitation,
    ];
    if (action === "smsInvitation") {
      const invitation = await handleApplicantInvitation(...applicantParams, "sms");
      setLastSmsInvitationSentAt(invitation?.sent_at);
      invitations.push(invitation);
      setSmsInvitations(invitations);
    } else if (action === "emailInvitation") {
      const invitation = await handleApplicantInvitation(...applicantParams, "email");
      setLastEmailInvitationSentAt(invitation?.sent_at);
    } else {
      const invitationLetter = await getInvitationLetter(...applicantParams, "postal");
      if (invitationLetter?.success) {
        setLastPostalInvitationSentAt(todaysDateString());
      }
    }
    updateStatusBlock();
    setIsLoading({ ...isLoading, [action]: false });
  };

  const toggleInvitationsHistory = (value) => {
    setShowInvitationsHistory(value)
  }

  return (
    <div className="d-flex justify-content-center">
      <table className="block-white text-center align-middle mb-4 mx-4">
        <thead>
          <tr>
            {showInvitation("sms") && (
              <th className="px-4 py-2">
                <h4>Invitation SMS</h4>
              </th>
            )}
            {showInvitation("email") && (
              <th className="px-4 py-2">
                <h4>Invitation mail</h4>
              </th>
            )}
            {showInvitation("postal") && (
              <th className="px-4 py-2">
                <h4>Invitation courrier</h4>
              </th>
            )}
          </tr>
        </thead>
        <tbody>
          {!showInvitationsHistory &&
            <tr>
              {showInvitation("sms") && (
                <td className="px-4 py-2">
                  {lastSmsInvitationSentAt ? getFrenchFormatDateString(lastSmsInvitationSentAt) : "-"}
                </td>
              )}
              {showInvitation("email") && (
                <td className="px-4 py-2">
                  {lastEmailInvitationSentAt
                    ? getFrenchFormatDateString(lastEmailInvitationSentAt)
                    : "-"}
                </td>
              )}
              {showInvitation("postal") && (
                <td className="px-4 py-2">
                  {lastPostalInvitationSentAt
                    ? getFrenchFormatDateString(lastPostalInvitationSentAt)
                    : "-"}
                </td>
              )}
            </tr>
          }
          {showInvitationsHistory &&
            <tr>
              {showInvitation("sms") && (
                smsInvitations.map(invitation =>
                  <td className="px-4 py-2">
                    {invitation.sent_at}
                  </td>
                )
              )}
              {showInvitation("email") && (
                emailInvitations.map(invitation =>
                  <td className="px-4 py-2">
                    {invitation.sent_at}
                  </td>
                )
              )}
              {showInvitation("postal") && (
                postalInvitations.map(invitation =>
                  <td className="px-4 py-2">
                    {invitation.sent_at}
                  </td>
                )
              )}
            </tr>
          }
          <tr>
            {showInvitation("sms") && (
              <td className="px-4 py-2">
                <button
                  type="button"
                  disabled={
                    isLoading.smsInvitation ||
                    !applicant.phone_number ||
                    applicant.is_archived === true ||
                    status === "rdv_pending"
                  }
                  className="btn btn-blue"
                  onClick={() => handleClick("smsInvitation")}
                >
                  {isLoading.smsInvitation && "Invitation..."}
                  {!isLoading.smsInvitation && lastSmsInvitationSentAt && "Relancer"}
                  {!isLoading.smsInvitation && !lastSmsInvitationSentAt && "Inviter"}
                </button>
              </td>
            )}
            {showInvitation("email") && (
              <td className="px-4 py-2">
                <button
                  type="button"
                  disabled={
                    isLoading.emailInvitation ||
                    !applicant.email ||
                    applicant.is_archived === true ||
                    status === "rdv_pending"
                  }
                  className="btn btn-blue"
                  onClick={() => handleClick("emailInvitation")}
                >
                  {isLoading.emailInvitation && "Invitation..."}
                  {!isLoading.emailInvitation && lastEmailInvitationSentAt && "Relancer"}
                  {!isLoading.emailInvitation && !lastEmailInvitationSentAt && "Inviter"}
                </button>
              </td>
            )}
            {showInvitation("postal") && (
              <td className="px-4 py-2">
                <button
                  type="button"
                  disabled={
                    isLoading.postalInvitation ||
                    !applicant.address ||
                    applicant.is_archived === true ||
                    status === "rdv_pending"
                  }
                  className="btn btn-blue"
                  onClick={() => handleClick("postalInvitation")}
                >
                  {isLoading.postalInvitation && "Invitation..."}
                  {!isLoading.postalInvitation && lastPostalInvitationSentAt && "Recréer"}
                  {!isLoading.postalInvitation && !lastPostalInvitationSentAt && "Inviter"}
                </button>
              </td>
            )}
          </tr>
          {!showInvitationsHistory &&
            <tr>
              <td
                className="px-4 py-2"
                colSpan={3}
                style={{ cursor: "pointer" }}
              >
                <a onClick={() => toggleInvitationsHistory(true)}>
                  <i className="fas fa-angle-down" /> Voir l'historique <i className="fas fa-angle-down" />
                </a>

              </td>
            </tr>
          }
          {showInvitationsHistory &&
            <tr>
              <td
                className="px-4 py-2"
                colSpan={3}
                style={{ cursor: "pointer" }}
              >
                <a onClick={() => toggleInvitationsHistory(false)}>
                  <i className="fas fa-angle-up" /> Voir moins <i className="fas fa-angle-up" />
                </a>
              </td>
            </tr>
          }

        </tbody>
      </table>
    </div>
  );
}
