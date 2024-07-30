import Swal from "sweetalert2";
import deleteArchive from "../actions/deleteArchive";

const handleArchiveDelete = async (user, options = { raiseError: true }) => {
  const archiveToDelete = user.archiveInCurrentOrganisation();
  const result = await deleteArchive(archiveToDelete.id, archiveToDelete.organisation_id);
  if (result.success) {
    user.archives = user.archives.filter((archive) => archive.id !== archiveToDelete.id);
    if (options.raiseError) {
      Swal.fire("Dossier de l'usager rouvert avec succès", "", "info");
    }
  } else if (!result.success && options.raiseError) {
    Swal.fire("Impossible de rouvrir le dossier du bénéficiaire'", result.errors[0], "error");
  }
  return result;
};

export default handleArchiveDelete;
