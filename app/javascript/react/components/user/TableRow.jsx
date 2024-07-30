import React from "react";
import { observer } from "mobx-react-lite";

import ContactInfosExtraLine from "./ContactInfosExtraLine";
import InvitationCells from "./InvitationCells";

function TableRow({ user }) {
  return (
    <>
      <tr className={user.isArchived() || (!user.isValid && !user.errorsMayNoLongerBeRelevant) ? "table-danger" : ""}>
        {user.list.columns.map((column) => {
          if (!column.visible || !column.content) return null

          return <td key={column.name} className={user[`${column.key}Updated`] ? "table-success" : ""} data-matomo-mask>{column.content({ user })}</td>
        })}

        {user.currentConfiguration && <InvitationCells user={user} />}
      </tr>

      {/* Contact infos extra line. It appears if the user contacts data when uploading the contacts file are different from the ones in DB */}

      {(user.belongsToCurrentOrg() && (user.phoneNumberNew || user.emailNew || user.rightsOpeningDateNew)) && (
        <ContactInfosExtraLine user={user} />
      )}
    </>
  );
}

export default observer(TableRow);

