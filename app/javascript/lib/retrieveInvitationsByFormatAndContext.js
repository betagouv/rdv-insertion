const retrieveInvitationsByFormatAndContext = (invitations, format = null, context = null) => {
  if (format !== null) {
    invitations = invitations.filter((invitation) => invitation.format === format);
  }
  if (context !== null) {
    invitations = invitations.filter((invitation) => invitation.context === context);
  }
  const sentInvitations = invitations.filter((invitation) => !!invitation.sent_at);
  // Trier de la plus récente à la plus ancienne
  sentInvitations.sort((a, b) => new Date(b.sent_at) - new Date(a.sent_at));
  return sentInvitations;
};

export default retrieveInvitationsByFormatAndContext;
