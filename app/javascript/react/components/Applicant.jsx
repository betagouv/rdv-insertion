import React, { useState } from "react";
import Swal from "sweetalert2";
import Tippy from "@tippyjs/react";

import handleApplicantCreation from "../lib/handleApplicantCreation";
import handleApplicantInvitation from "../lib/handleApplicantInvitation";
import handleApplicantUpdate from "../lib/handleApplicantUpdate";
import retrieveRelevantOrganisation from "../../lib/retrieveRelevantOrganisation";
import getInvitationLetter from "../actions/getInvitationLetter";
import { todaysDateString } from "../../lib/datesHelper";
import camelToSnakeCase from "../../lib/stringHelper";

export default function Applicant({
  applicant,
  isDepartmentLevel,
  downloadInProgress,
  setDownloadInProgress,
}) {
  const [isLoading, setIsLoading] = useState({
    accountCreation: false,
    smsInvitation: false,
    emailInvitation: false,
    postalInvitation: false,
    organisationUpdate: false,
    emailUpdate: false,
    phoneNumberUpdate: false,
    rightsOpeningDateUpdate: false,
    allAttributesUpdate: false,
  });

  const handleUpdateContactsDataClick = async (attribute = null) => {
    setIsLoading({ ...isLoading, [`${attribute}Update`]: true });

    const attributes = {};
    if (attribute === "allAttributes") {
      attributes.email = applicant.emailNew;
      attributes.phone_number = applicant.phoneNumberNew;
      attributes.rights_opening_date = applicant.rightsOpeningDateNew;
    } else {
      attributes[`${camelToSnakeCase(attribute)}`] = applicant[`${attribute}New`];
    }

    const result = await handleApplicantUpdate(applicant, attributes);

    if (result.success) {
      if (attribute === "allAttributes") {
        applicant.markAttributeAsUpdated("email");
        applicant.markAttributeAsUpdated("phoneNumber");
        applicant.markAttributeAsUpdated("rightsOpeningDate");
      } else {
        applicant.markAttributeAsUpdated(`${attribute}`);
      }
    }

    setIsLoading({ ...isLoading, [`${attribute}Update`]: false });
  };

  const handleAddToOrganisationClick = async () => {
    setIsLoading({ ...isLoading, organisationUpdate: true });

    const result = await handleApplicantUpdate(applicant, applicant.toJson());

    if (result.success && result.applicant.organisations.length > 1) {
      Swal.fire(
        "Allocataire ajout??",
        "Cet allocataire existait d??j?? dans une autre organisation du d??partement. Il a ??t?? mis ?? jour et ajout?? ?? votre organisation",
        "info"
      );
    }
    setIsLoading({ ...isLoading, organisationUpdate: false });
  };

  const handleInvitationClick = async (format) => {
    setIsLoading({ ...isLoading, [`${format}Invitation`]: true });
    const invitationParams = [
      applicant.id,
      applicant.department.id,
      applicant.currentOrganisation.id,
      isDepartmentLevel,
      applicant.currentConfiguration.motif_category,
      applicant.currentOrganisation.phone_number,
    ];
    if (format === "sms") {
      const invitation = await handleApplicantInvitation(...invitationParams, "sms");
      applicant.lastSmsInvitationSentAt = invitation.sent_at;
    } else if (format === "email") {
      const invitation = await handleApplicantInvitation(...invitationParams, "email");
      applicant.lastEmailInvitationSentAt = invitation.sent_at;
    } else if (format === "postal") {
      setDownloadInProgress(true);
      const invitationLetter = await getInvitationLetter(...invitationParams);
      if (invitationLetter?.success) {
        applicant.lastPostalInvitationSentAt = todaysDateString();
      }
      setDownloadInProgress(false);
    }
    setIsLoading({ ...isLoading, [`${format}Invitation`]: false });
  };

  const handleCreationClick = async () => {
    setIsLoading({ ...isLoading, accountCreation: true });

    if (!applicant.currentOrganisation) {
      applicant.currentOrganisation = await retrieveRelevantOrganisation(
        applicant.departmentNumber,
        applicant.linkedOrganisationSearchTerms,
        applicant.fullAddress
      );

      // If there is still no organisation it means the assignation was cancelled by agent
      if (!applicant.currentOrganisation) {
        setIsLoading({ ...isLoading, accountCreation: false });
        return;
      }
    }
    await handleApplicantCreation(applicant, applicant.currentOrganisation.id);

    setIsLoading({ ...isLoading, accountCreation: false });
  };

  const computeColSpanForContactsUpdate = () =>
    applicant.displayedAttributes().length - applicant.attributesFromContactsDataFile().length;

  const computeColSpanForDisabledInvitations = () => {
    let colSpan = 0;
    if (applicant.shouldBeInvitedBySms()) colSpan += 1;
    if (applicant.shouldBeInvitedByEmail()) colSpan += 1;
    if (applicant.shouldBeInvitedByPostal()) colSpan += 1;
    return colSpan;
  };

  return (
    <>
      <tr className={applicant.isDuplicate || applicant.isArchived ? "table-danger" : ""}>
        <td>{applicant.affiliationNumber}</td>
        <td>{applicant.shortTitle}</td>
        <td>{applicant.firstName}</td>
        <td>{applicant.lastName}</td>
        <td>{applicant.shortRole}</td>
        {applicant.shouldDisplay("department_internal_id") && (
          <td>{applicant.departmentInternalId ?? " - "}</td>
        )}
        {applicant.shouldDisplay("birth_date") && <td>{applicant.birthDate ?? " - "}</td>}
        {applicant.shouldDisplay("email") && (
          <td className={applicant.emailUpdated ? "table-success" : ""}>
            {applicant.email ?? " - "}
          </td>
        )}
        {applicant.shouldDisplay("phone_number") && (
          <td className={applicant.phoneNumberUpdated ? "table-success" : ""}>
            {applicant.phoneNumber ?? " - "}
          </td>
        )}
        {applicant.shouldDisplay("rights_opening_date") && (
          <td className={applicant.rightsOpeningDateUpdated ? "table-success" : ""}>
            {applicant.rightsOpeningDate ?? " - "}
          </td>
        )}
        <td>
          {applicant.isArchived ? (
            <button type="submit" disabled className="btn btn-primary btn-blue">
              Dossier archiv??
            </button>
          ) : applicant.createdAt ? (
            applicant.belongsToCurrentOrg() ? (
              <i className="fas fa-check" />
            ) : (
              <Tippy
                content={
                  <span>
                    Cet allocataire est d??j?? pr??sent dans RDV-Insertion dans une autre organisation
                    que l&apos;organisation actuelle.
                    <br />
                    Appuyez sur ce bouton pour ajouter l&apos;allocataire ?? cette organisation et
                    mettre ?? jours ses informations.
                  </span>
                }
              >
                <button
                  type="submit"
                  disabled={isLoading.organisationUpdate}
                  className="btn btn-primary btn-blue"
                  onClick={() => handleAddToOrganisationClick()}
                >
                  {isLoading.organisationUpdate ? "En cours..." : "Ajouter ?? cette organisation"}
                </button>
              </Tippy>
            )
          ) : applicant.isDuplicate ? (
            <button type="submit" disabled className="btn btn-primary btn-blue">
              Cr??ation impossible
            </button>
          ) : (
            <button
              type="submit"
              disabled={isLoading.accountCreation}
              className="btn btn-primary btn-blue"
              onClick={() => handleCreationClick("accountCreation")}
            >
              {isLoading.accountCreation ? "Cr??ation..." : "Cr??er compte"}
            </button>
          )}
        </td>
        {applicant.isArchived ? (
          <td colSpan={computeColSpanForDisabledInvitations()} />
        ) : applicant.isDuplicate ? (
          <Tippy
            content={
              <span>
                <strong>Cet allocataire est un doublon.</strong> Les doublons sont identifi??s de 2
                fa??ons&nbsp;:
                <br />
                1) Son num??ro d&apos;ID ??diteur est identique ?? un autre allocataire pr??sent dans ce
                fichier.
                <br />
                2) Son num??ro d&apos;allocataire <strong>et</strong> son r??le sont identiques ?? ceux
                d&apos;un autre allocataire pr??sent dans ce fichier.
                <br />
                <br />
                Si cet allocataire a besoin d&apos;??tre cr????, merci de modifier votre fichier et de
                le charger ?? nouveau.
              </span>
            }
          >
            <td colSpan={computeColSpanForDisabledInvitations()}>
              <small className="d-inline-block mx-2">
                <i className="fas fa-exclamation-triangle" />
              </small>
            </td>
          </Tippy>
        ) : (
          <>
            {applicant.shouldBeInvitedBySms() && (
              <>
                <td>
                  {applicant.lastSmsInvitationSentAt ? (
                    <i className="fas fa-check" />
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
                      onClick={() => handleInvitationClick("sms")}
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
                    <i className="fas fa-check" />
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
                      onClick={() => handleInvitationClick("email")}
                    >
                      {isLoading.emailInvitation ? "Invitation..." : "Inviter par mail"}
                    </button>
                  )}
                </td>
              </>
            )}
            {applicant.shouldBeInvitedByPostal() && (
              <>
                <td>
                  {applicant.lastPostalInvitationSentAt ? (
                    <i className="fas fa-check" />
                  ) : (
                    <button
                      type="submit"
                      disabled={
                        isLoading.postalInvitation ||
                        downloadInProgress ||
                        !applicant.createdAt ||
                        !applicant.fullAddress ||
                        !applicant.belongsToCurrentOrg()
                      }
                      className="btn btn-primary btn-blue"
                      onClick={() => handleInvitationClick("postal")}
                    >
                      {isLoading.postalInvitation ? "Cr??ation en cours..." : "G??n??rer courrier"}
                    </button>
                  )}
                </td>
              </>
            )}
          </>
        )}
      </tr>
      {(applicant.phoneNumberNew || applicant.emailNew || applicant.rightsOpeningDateNew) && (
        <tr className="table-success">
          <td colSpan={computeColSpanForContactsUpdate()} className="text-align-right">
            <i className="fas fa-level-up-alt" />
            Nouvelles donn??es trouv??es pour {applicant.firstName} {applicant.lastName}
          </td>
          {["email", "phoneNumber", "rightsOpeningDate"].map(
            (attributeName) =>
              applicant.shouldDisplay(camelToSnakeCase(attributeName)) && (
                <td
                  className="update-box"
                  key={`${attributeName}${new Date().toISOString().slice(0, 19)}`}
                >
                  {applicant[`${attributeName}New`] && (
                    <>
                      {applicant[`${attributeName}New`]}
                      <br />
                      <button
                        type="submit"
                        className="btn btn-primary btn-blue btn-sm mt-2"
                        onClick={() => handleUpdateContactsDataClick(attributeName)}
                      >
                        {isLoading[`${attributeName}Update`] || isLoading.allAttributesUpdate
                          ? "En cours..."
                          : "Mettre ?? jour"}
                      </button>
                    </>
                  )}
                </td>
              )
          )}
          <td>
            {[applicant.emailNew, applicant.phoneNumberNew, applicant.rightsOpeningDateNew].filter(
              (e) => e != null
            ).length > 1 && (
              <button
                type="submit"
                className="btn btn-primary btn-blue"
                onClick={() => handleUpdateContactsDataClick("allAttributes")}
              >
                {isLoading.emailUpdate ||
                isLoading.phoneNumberUpdate ||
                isLoading.rightsOpeningDateUpdate ||
                isLoading.allAttributesUpdate
                  ? "En cours..."
                  : "Tout mettre ?? jour"}
              </button>
            )}
          </td>
          <td colSpan={computeColSpanForDisabledInvitations()} />
        </tr>
      )}
    </>
  );
}
