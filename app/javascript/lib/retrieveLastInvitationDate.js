import retrieveInvitationsByFormatAndContext from "./retrieveInvitationsByFormatAndContext";

const retrieveLastInvitationDate = (invitations, format = null, context = null) => {
  const sentInvitations = retrieveInvitationsByFormatAndContext(invitations, format, context)
  const [lastInvitation] = sentInvitations;

  return lastInvitation?.sent_at;
};

export default retrieveLastInvitationDate;
