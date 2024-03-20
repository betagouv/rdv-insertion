import React from "react";
import { observer } from "mobx-react-lite";

export default observer(({ users }) => {
  const toggle = () => {
    const dropdown = document.getElementById("batch-actions");
    dropdown.classList.toggle("show");
  };

  const deleteAll = () => {
    toggle();
    users.setUsers(users.list.filter((user) => !user.selected));
  };

  const batchActions = async (actionName, actionArguments = []) => {
    toggle();
    // We need a synchronous loop with await here to avoid sending too many requests at the same time
    // eslint-disable-next-line no-restricted-syntax
    for (const user of users.selectedUsers) {
      // eslint-disable-next-line no-await-in-loop
      await user[actionName](...actionArguments, { raiseError: false });
    }
  }

  const createAccounts = async () => {
    toggle();
    // We need a synchronous loop with await here to avoid sending too many requests at the same time
    // eslint-disable-next-line no-restricted-syntax
    for (const user of users.selectedUsers) {
      if (user.isArchivedInCurrentDepartment()) {
        // eslint-disable-next-line no-await-in-loop
        await user.unarchive({ raiseError: false });
      } else {
        // eslint-disable-next-line no-await-in-loop
        await user.createAccount({ raiseError: false });
      }
    }
  }

  const noUserSelected = !users.list.some((user) => user.selected);

  return (
    <div style={{ marginRight: 20, position: "relative" }}>
      <button
        type="button"
        className="btn btn-primary dropdown-toggle"
        onClick={toggle}
        disabled={noUserSelected}
      >
        Actions pour toute la sélection
      </button>
      <div className="dropdown-menu" id="batch-actions">
        {users.sourcePage === "upload" && (
          <button
            type="button"
            className="dropdown-item d-flex justify-content-between align-items-center"
            onClick={createAccounts}
          >
            <span>Créer comptes</span>
            <i className="fas fa-user" />
          </button>
        )}
        {users.showReferentColumn && (
          <button
            type="button"
            className="dropdown-item d-flex justify-content-between align-items-center"
            onClick={() => batchActions("assignReferent")}
          >
            <span>Assigner référent</span>
            <i className="fas fa-user-friends" />
          </button>
        )}
        {users.canBeInvitedBy("sms") && (
          <button
            type="button"
            className="dropdown-item d-flex justify-content-between align-items-center"
            onClick={() => batchActions("inviteBy", ["sms"])}
          >
            <span>Inviter par sms</span>
            <i className="fas fa-comment" />
          </button>
        )}
        {users.canBeInvitedBy("email") && (
          <button
            type="button"
            className="dropdown-item d-flex justify-content-between align-items-center"
            onClick={() => batchActions("inviteBy", ["email"])}
          >
            <span>Inviter par mail</span>
            <i className="fas fa-inbox" />
          </button>
        )}
        {users.canBeInvitedBy("postal") && (
          <button
            type="button"
            className="dropdown-item d-flex justify-content-between align-items-center"
            onClick={() => batchActions("inviteBy", ["postal"])}
          >
            <span>Inviter par courrier &nbsp;</span>
            <i className="fas fa-envelope" />
          </button>
        )}
        <button
          type="button"
          className="dropdown-item d-flex justify-content-between align-items-center"
          onClick={deleteAll}
        >
          <span>Cacher la sélection</span>
          <i className="fas fa-eye-slash" />
        </button>
      </div>
    </div>
  );
});
