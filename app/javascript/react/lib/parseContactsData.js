import retrieveContactPhoneNumber from "../../lib/retrieveContactPhoneNumber";

const parseContactsData = async (applicantContactsData) => {
  const phoneNumber = retrieveContactPhoneNumber(applicantContactsData);
  const email = applicantContactsData["ADRESSE ELECTRONIQUE DOSSIER"];
  const rightsOpeningDate = applicantContactsData["DATE DEBUT DROITS - DEVOIRS"];

  return { phoneNumber, email, rightsOpeningDate };
};

export default parseContactsData;
