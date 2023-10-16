import React from "react";
import { makeAutoObservable } from "mobx";

import CreationCell from "../components/user/CreationCell";
import ReferentAssignationCell from "../components/user/ReferentAssignationCell";
import CarnetCreationCell from "../components/user/CarnetCreationCell";
import EditableCell from "../components/user/EditableCell";

class Users {
  constructor() {
    this.list = [];
    this.sortBy = null;
    this.sortDirection = "asc";
    this.loading = false;
    this.fileColumnNames = [];
    this.showCarnetColumn = false
    this.configuration = null
    this.showReferentColumn = false
    this.isDepartmentLevel = false
    makeAutoObservable(this);
  }

  get columns() {
    return [
      {
        name: "Séléction",
        attributes: { className: "text-center", scope: "col" },
        content: ({ user }) => (
            <input
              type="checkbox"
              className="form-check-input"
              checked={user.selected}
              onChange={(event) => {
                user.selected = event.target.checked;
              }}
            />
        )
      },
      {
        name: "Civilité",
        sortable: true,
        key: "title",
        content: ({ user }) => (
          <EditableCell
            type="select"
            user={user}
            cell="title"
            values={[
              { key: "M", value: "monsieur" },
              { key: "Mme", value: "madame" },
            ]}
          />
        )
      },
      {
        name: "Prénom",
        sortable: true,
        key: "firstName",
        content: ({ user }) => <EditableCell type="text" user={user} cell="firstName" />
      },
      {
        name: "Nom",
        sortable: true,
        key: "lastName",
        content: ({ user }) => <EditableCell type="text" user={user} cell="lastName" />
      },
      {
        name: "Numéro CAF", 
        visible: this.fileColumnNames.affiliation_number_column,
        content: ({ user }) => <EditableCell type="text" user={user} cell="affiliationNumber" />
      },
      {
        name: "Rôle",
        sortable: true,
        key: "role",
        visible: this.fileColumnNames.role_column,
        content: ({ user }) => (
          <EditableCell
            user={user}
            cell="role"
            type="select"
            values={[
              { key: "DEM", value: "demandeur" },
              { key: "CJT", value: "conjoint" },
            ]}
          />
        )
      },
      {
        name: "ID Editeur",
        visible: this.fileColumnNames.department_internal_id_column,
        content: ({ user }) => <EditableCell user={user} cell="departmentInternalId" />
      },
      {
        name: "NIR",
        visible: this.fileColumnNames.nir_column,
        content: ({ user }) => user.nir ?? " - "
      },
      {
        name: "ID PE",
        visible: this.fileColumnNames.pole_emploi_id_column,
        content: ({ user }) => user.poleEmploiId ?? " - "
      },
      {
        name: "Email",
        key: "email",
        isInContactFile: true,
        visible: this.fileColumnNames.email_column,
        content: ({ user }) => <EditableCell user={user} cell="email" />
      },
      {
        name: "Téléphone",
        key: "phoneNumber",
        isInContactFile: true,
        visible: this.fileColumnNames.phone_number_column,
        content: ({ user }) => <EditableCell user={user} cell="phoneNumber" />
      },
      {
        name: "Tags",
        visible: this.fileColumnNames.tags_column,
        content: ({ user }) => (
          <EditableCell
            user={user}
            cell="tags"
            type="tags"
            values={user.availableTags.map((tag) => tag.value)}
          />
        )
      },
      {
        name:  "Date d&apos;entrée flux",
        key: "rightsOpeningDate",
        isInContactFile: true,
        visible: this.fileColumnNames.rights_opening_date_column,
        content: ({ user }) => <EditableCell user={user} cell="rightsOpeningDate" />
      },
      {
        name: "Création compte",
        attributes: { style: { whiteSpace: "nowrap" }, scope: "col" },
        content: ({ user }) => <CreationCell user={user} />
      },
      {
        name: "Création carnet",
        attributes: { style: { whiteSpace: "nowrap" }, scope: "col" },
        visible: this.showCarnetColumn,
        content: ({ user }) => <CarnetCreationCell user={user} />
      },
      {
        name: "Référent",
        attributes: { scope: "col-3" },
        visible: this.showReferentColumn,
        content: ({ user }) => <ReferentAssignationCell user={user} />
      },
      {
        name: "Invitation SMS",
        visible: this.configuration?.invitation_formats?.includes("sms"),
        attributes: { scope: "col-3" }
      },
      {
        name: "Invitation mail",
        visible: this.configuration?.invitation_formats?.includes("email"),
        attributes: { scope: "col-3" }
      },
      {
        name: "Invitation courrier",
        visible: this.configuration?.invitation_formats?.includes("postal"),
        attributes: { scope: "col-3" }
      }
    ].map(column => ({
      attributes: { scope: "col" },
      visible: true,
      ...column
    }))
  }

  get numberOfColumnsBeforeContactListUpdate() {
    let offset = 0;
    // eslint-disable-next-line no-restricted-syntax
    for (const column of this.columns) {
      if (column.isInContactFile) break
      if (column.visible) offset += 1;
    }
    return offset
  }

  get columnsAfterFirstContactListUpdate() {
    return this.columns.filter(column => column.visible).slice(this.numberOfColumnsBeforeContactListUpdate)
  }

  addUser(user) {
    this.list.push(user);
  }

  setUsers(users) {
    this.list = users;
  }

  setLoading(loading) {
    this.loading = loading;
  }

  get selectedUsers() {
    return this.list.filter((user) => user.selected);
  }

  sort(column) {
    if (this.sortBy === column) {
      // Everytime we click on the same column,
      // we go to the next sorting (asc, then desc, then back to no sorting)
      const sortings = ["up", "down", null]
      const index = sortings.indexOf(this.sortDirection)
      this.sortDirection = sortings[(index + 1) % sortings.length]
    } else {
      this.sortBy = column;
      this.sortDirection = "up";
    }
  }

  get sorted() {
    if (this.sortBy && this.sortDirection) {
      return this.list.slice().sort((a, b) => {
        if (a[this.sortBy] < b[this.sortBy]) {
          return this.sortDirection === "up" ? -1 : 1;
        }
        if (a[this.sortBy] > b[this.sortBy]) {
          return this.sortDirection === "up" ? 1 : -1;
        }

        return 0;
      });
    }
    return this.invalidFirsts;
  }

  get invalidFirsts() {
    return this.list.slice().sort((a, b) => {
      if (a.isValid !== b.isValid) {
        return a.isValid ? 1 : -1;
      }
      return null;
    });
  }

  get invitationsColSpan() {
    let colSpan = 0;
    if (this.canBeInvitedBy("sms")) colSpan += 1;
    if (this.canBeInvitedBy("email")) colSpan += 1;
    if (this.canBeInvitedBy("postal")) colSpan += 1;
    return colSpan;
  }

  canBeInvitedBy(format) {
    if (!this.configuration) return false;
    return this.configuration.invitation_formats.includes(format);
  }
}

export default new Users();