import React, { useEffect, useCallback } from "react";
import { observer } from "mobx-react-lite";

import EditableTags from "./EditableTags";

import User from "../../models/User";

const EditTags = observer(({ user: userProp,  availableTagsInScope, affectedTagsInScope, organisation, department }) => {
  const [isEditingTags, setIsEditingTags] = React.useState(false);
  const [user, setUser] = React.useState(null);

  useEffect(() => {
    setUser(
      new User(
        {
          id: userProp.id,
          createdAt: userProp.created_at,
          tags: affectedTagsInScope.map((tag) => tag.value),
        },
        department,
        organisation,
        availableTagsInScope
      )
    );
  }, []);

  return (
    <>
      {isEditingTags && (
        <EditableTags
          scope="show"
          user={user}
          cell="tags"
          values={availableTagsInScope.map((tag) => tag.value)}
          setIsEditingTags={() => window.location.reload()}
        />
      )}
      <button
        type="button"
        className="btn btn-primary mb-3"
        onClick={useCallback(() => setIsEditingTags(true))}
      >
        <i className="fas fa-pen" /> Modifier les tags
      </button>
    </>
  );
});

export default (props) => <EditTags {...props} />;
