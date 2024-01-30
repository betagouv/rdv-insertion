import React, { useState } from "react";
import Swal from "sweetalert2";
import Tippy from "@tippyjs/react";
import { observer } from "mobx-react-lite";

import FileHandler from "../components/FileHandler";
import EnrichWithContactFile from "../components/EnrichWithContactFile";
import UserBatchActions from "../components/UserBatchActions";
import UserRow from "../components/User";

import retrieveUpToDateUsers from "../lib/retrieveUpToDateUsers";
import parseContactsData from "../lib/parseContactsData";
import updateUserContactsData from "../lib/updateUserContactsData";
import retrieveContactsData from "../lib/retrieveContactsData";
import { formatDateInput } from "../../lib/datesHelper";
import { parameterizeObjectValues } from "../../lib/parameterize";

import User from "../models/User";
import usersStore from "../models/Users";
import uploadFile from "../lib/uploadFile";

const UsersUpload = observer(
  ({
    users,
    organisation,
    configuration,
    columnNames,
    tags,
    sheetName,
    department,
    motifCategoryName,
    currentAgent,
  }) => {
    const parameterizedColumnNames = parameterizeObjectValues({ ...columnNames });

    const isDepartmentLevel = !organisation;
    const [fileSize, setFileSize] = useState(0);
    const [showEnrichWithContactFile, setShowEnrichWithContactFile] = useState(false);

    const redirectToUserList = () => {
      const scope = isDepartmentLevel ? "departments" : "organisations";
      const url = `/${scope}/${(organisation || department).id}/users`;
      const queryParams = configuration
        ? `?motif_category_id=${configuration.motif_category_id}`
        : "";

      window.location.href = url + queryParams;
    };

    const retrieveUsersFromList = async (file) => {
      users.fileColumnNames = parameterizedColumnNames;
      users.showCarnetColumn = !!department.carnet_de_bord_deploiement_id;
      users.showReferentColumn = configuration?.rdv_with_referents;
      users.configuration = configuration;
      users.isDepartmentLevel = isDepartmentLevel;

      const rows = await uploadFile(file, sheetName, columnNames);
      if (typeof(rows) === "undefined") return;

      rows.forEach((row) => {
        const user = new User(
          {
            lastName: row[parameterizedColumnNames.last_name_column],
            firstName: row[parameterizedColumnNames.first_name_column],
            affiliationNumber: row[parameterizedColumnNames.affiliation_number_column],
            tags:
              row[parameterizedColumnNames.tags_column]
                ?.toString()
                .split(",")
                .map((tag) => tag.trim()) || [],
            nir: row[parameterizedColumnNames.nir_column],
            poleEmploiId: row[parameterizedColumnNames.pole_emploi_id_column],
            role: row[parameterizedColumnNames.role_column],
            title: row[parameterizedColumnNames.title_column],
            addressFirstField: row[parameterizedColumnNames.address_first_field_column],
            addressSecondField: row[parameterizedColumnNames.address_second_field_column],
            addressThirdField: row[parameterizedColumnNames.address_third_field_column],
            addressFourthField: row[parameterizedColumnNames.address_fourth_field_column],
            addressFifthField: row[parameterizedColumnNames.address_fifth_field_column],
            email: row[parameterizedColumnNames.email_column],
            phoneNumber: row[parameterizedColumnNames.phone_number_column],
            birthDate: formatDateInput(row[parameterizedColumnNames.birth_date_column]),
            birthName: row[parameterizedColumnNames.birth_name_column],
            departmentInternalId: row[parameterizedColumnNames.department_internal_id_column],
            rightsOpeningDate: formatDateInput(
              row[parameterizedColumnNames.rights_opening_date_column]
            ),
            linkedOrganisationSearchTerms:
              row[parameterizedColumnNames.organisation_search_terms_column],
            referentEmail: row[parameterizedColumnNames.referent_email_column],
          },
          department,
          organisation,
          tags,
          configuration,
          columnNames,
          currentAgent,
          users
        );

        users.addUser(user);
      });
    };

    const displayFormatErrorMessage = (acceptedFormats) => {
      Swal.fire({
        title: `Le fichier doit être au format ${acceptedFormats.map((format) => ` ${format}`)}`,
        icon: "error",
      });
    };

    const isFormatValid = (file, acceptedFormats) =>
      acceptedFormats.some((format) => file.name.endsWith(format));

    const handleUsersFile = async (file) => {
      const acceptedFormats = [".csv", ".xls", ".xlsx", ".ods"];
      if (!isFormatValid(file, acceptedFormats)) {
        displayFormatErrorMessage(acceptedFormats);
        return;
      }

      setFileSize(file.size);
      users.setUsers([]);
      await retrieveUsersFromList(file);

      if (users.list.length === 0) return;

      users.setUsers(await retrieveUpToDateUsers(users.list, department.id));
    };

    const handleContactsFile = async (file) => {
      const acceptedFormats = [".csv", ".txt"];
      if (!isFormatValid(file, acceptedFormats)) {
        displayFormatErrorMessage(acceptedFormats);
        return;
      }

      setFileSize(file.size);
      const contactsData = await retrieveContactsData(file);
      if (contactsData.length === 0) return;

      await Promise.all(
        users.list.map(async (user) => {
          const userContactsData = contactsData.find(
            (contactRow) =>
              // padStart is used because sometimes affiliation numbers are fetched with less than 7 letters
              contactRow.MATRICULE.toString()?.padStart(7, "0") ===
              user.affiliationNumber?.padStart(7, "0")
          );
          if (userContactsData) {
            const parsedUserContactsData = await parseContactsData(userContactsData);
            user = await updateUserContactsData(user, parsedUserContactsData);
          }
        })
      );
    };

    return (
      <>
        <div className="container mt-5 mb-8">
          <div className="row card-white justify-content-center">
            <div className="col-4 text-center d-flex align-items-center justify-content-start">
              <button
                type="submit"
                className="btn btn-secondary btn-blue-out"
                onClick={redirectToUserList}
              >
                Retour au suivi
              </button>
            </div>
            <div className="col-4 text-center d-flex flex-column align-items-center">
              <h3 className="new-users-title">
                Ajout {isDepartmentLevel ? "au niveau du territoire" : "usagers"}
              </h3>
              {configuration && (
                <h6>
                  ({motifCategoryName}
                  {configuration.rdv_with_referents && " avec réferents"})
                </h6>
              )}

              <FileHandler
                handleFile={handleUsersFile}
                loading={(loading) => users.setLoading(loading)}
                fileSize={fileSize}
                name="users-list-upload"
                accept="text/plain, .csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel, application/vnd.oasis.opendocument.spreadsheet"
                multiple={false}
                uploadMessage={<span>Choisissez un fichier d'usagers</span>}
                pendingMessage="Récupération des informations, merci de patienter"
              />
            </div>
            <div className="col-4 d-flex align-items-center justify-content-end">
              <a
                target="blank"
                href="https://rdv-insertion.gitbook.io/guide-dutilisation-rdv-insertion/"
              >
                <button type="button" className="btn btn-blue-out">
                  Guide d&apos;utilisation
                  <i className="fas fa-external-link-alt icon-sm" />
                </button>
              </a>
            </div>
          </div>
          {!showEnrichWithContactFile && users.list.length > 0 && (
            <div className="my-4 text-center">
              <button
                type="button"
                className="btn btn-blue-out"
                onClick={() => setShowEnrichWithContactFile(true)}
              >
                Enrichir avec des données de contacts CNAF
              </button>
            </div>
          )}
          {showEnrichWithContactFile && users.list.length > 0 && (
            <EnrichWithContactFile handleContactsFile={handleContactsFile} fileSize={fileSize} />
          )}
          {users.list.length > 0 && (
            <>
              <div className="row my-1" style={{ height: 50 }}>
                <div className="d-flex justify-content-end align-items-center">
                  <UserBatchActions users={users} />
                  <i className="fas fa-user" />
                  {users.showReferentColumn ? (
                    <Tippy content="Cacher colonne référent">
                      <button
                        type="button"
                        onClick={() => {
                          users.showReferentColumn = false;
                        }}
                      >
                        <i className="fas fa-minus" />
                      </button>
                    </Tippy>
                  ) : (
                    <Tippy content="Montrer colonne référent">
                      <button
                        type="button"
                        onClick={() => {
                          users.showReferentColumn = true;
                        }}
                      >
                        <i className="fas fa-plus" />
                      </button>
                    </Tippy>
                  )}
                </div>
              </div>
            </>
          )}
        </div>
        {users.list.length > 0 && !users.loading && (
          <>
            <div className="my-5 px-4" style={{ overflow: "scroll" }}>
              <table className="table table-hover text-center align-middle table-striped table-bordered">
                <thead className="align-middle dark-blue">
                  <tr>
                    {users.columns.map((column) => {
                      if (!column.visible) return null;

                      return (
                        <th {...column.attributes} key={column.name}>
                          {column.header({ column, users })}
                        </th>
                      );
                    })}
                  </tr>
                </thead>
                <tbody>
                  {users.sorted.map((user) => (
                    <UserRow user={user} key={user.uniqueKey} />
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </>
    );
  }
);

export default (props) => <UsersUpload users={usersStore} {...props} />;
