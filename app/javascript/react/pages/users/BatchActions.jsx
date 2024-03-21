import React, { useEffect } from "react";
import { observer } from "mobx-react-lite";

import UsersList from "../../components/users/UsersList";
import BatchActionsButtons from "../../components/users/BatchActionsButtons";
import DisplayReferentsColumnButton from "../../components/users/DisplayReferentsColumnButton";

import { formatDateInput } from "../../../lib/datesHelper";

import User from "../../models/User";
import usersStore from "../../models/Users";

const UsersBatchActions = observer(
  ({
    users,
    usersFromApp,
    organisation,
    categoryConfiguration,
    department,
    currentAgent,
    backToUsersListUrl
  }) => {
    useEffect(() => {
      setUsersFromApp();
    }, [usersFromApp]);

    const redirectToUsersList = () => {
      window.location.href = backToUsersListUrl;
    };

    const setUsersFromApp = () => {
      users.setUsers([]);
      users.showReferentColumn = categoryConfiguration?.rdv_with_referents;
      users.categoryConfiguration = categoryConfiguration;
      users.isDepartmentLevel = !organisation;
      users.sourcePage = "batchActions";

      usersFromApp.forEach((userFromApp) => {
        const user = new User(
          {
            lastName: userFromApp.last_name,
            firstName: userFromApp.first_name,
            affiliationNumber: userFromApp.affiliation_number,
            tags: userFromApp.tags,
            nir: userFromApp.nir,
            poleEmploiId: userFromApp.pole_emploi_id,
            role: userFromApp.role,
            title: userFromApp.title,
            fullAddress: userFromApp.address,
            email: userFromApp.email,
            phoneNumber: userFromApp.phone_number,
            birthDate: formatDateInput(userFromApp.birth_date),
            birthName: userFromApp.birth_name,
            departmentInternalId: userFromApp.department_internal_id,
            rightsOpeningDate: formatDateInput(userFromApp.rights_opening_date),
            referentEmail: userFromApp.referent_email
          },
          department,
          organisation,
          categoryConfiguration,
          currentAgent,
          users
        );
        user.updateWith(userFromApp);

        users.addUser(user);
      });
    };

    return (
      <>
        <div className="container mt-5 mb-3">
          <div className="row card-white justify-content-center">
            <div className="col-4 text-center d-flex align-items-center justify-content-start">
                <button
                  type="submit"
                  className="btn btn-secondary btn-blue-out"
                  onClick={redirectToUsersList}
                >
                  Retour au suivi
                </button>
            </div>
            <div className="col-4 text-center">
              <h2 className="text-center new-users-title">Envoyer des invitations aux usagers non-invités</h2>
            </div>
            <div className="col-4" />
          </div>
          <div className="row my-3" style={{ height: 50 }}>
            <div className="d-flex justify-content-end align-items-center">
              <BatchActionsButtons users={users} />
              <DisplayReferentsColumnButton users={users} />
            </div>
          </div>
        </div>
        {users.list.length > 0 && !users.loading && (
          <UsersList users={users} />
        )}
      </>
    );
  }
);

export default (props) => <UsersBatchActions users={usersStore} {...props} />;
