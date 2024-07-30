import appFetch from "../../lib/appFetch";

const deleteArchive = async (archiveId, organisationId) => appFetch(`/organisations/${organisationId}/archives/${archiveId}`, "DELETE");

export default deleteArchive;
