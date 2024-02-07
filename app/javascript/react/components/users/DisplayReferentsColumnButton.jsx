import React from "react";
import Tippy from "@tippyjs/react";
import { observer } from "mobx-react-lite";

export default observer(({ users }) => (
  <Tippy content={users.showReferentColumn ? "Cacher colonne référent" : "Montrer colonne référent"}>
    <button
      type="button"
      className={users.showReferentColumn ? "btn btn-blue sm" : "btn btn-blue-out"}
      style={{ cursor: "pointer" }}
      onClick={() => { users.showReferentColumn = !users.showReferentColumn } }
    >
      <i className="fas fa-user" />
      <i className={users.showReferentColumn ? "fas fa-minus" : "fas fa-plus"} />
    </button>
  </Tippy>
));
