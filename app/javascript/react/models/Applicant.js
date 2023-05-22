import formatPhoneNumber from "../../lib/formatPhoneNumber";
import retrieveLastInvitationDate from "../../lib/retrieveLastInvitationDate";
import { getFrenchFormatDateString } from "../../lib/datesHelper";

const ROLES = {
  allocataire: "demandeur",
  dem: "demandeur",
  cjt: "conjoint",
};

const TITLES = {
  mr: "monsieur",
  mme: "madame",
};

export default class Applicant {
  constructor(
    attributes,
    department,
    organisation,
    currentConfiguration,
    columnNames,
    currentAgent
  ) {
    const formattedAttributes = {};
    Object.keys(attributes).forEach((key) => {
      formattedAttributes[key] = attributes[key]?.toString()?.trim();
    });
    this.lastName = formattedAttributes.lastName;
    this.firstName = formattedAttributes.firstName;
    this.title = this.formatTitle(formattedAttributes.title);
    this.shortTitle = this.title ? (this.title === "monsieur" ? "M" : "Mme") : null;
    this.email = formattedAttributes.email;
    this.birthDate = formattedAttributes.birthDate;
    this.birthName = formattedAttributes.birthName;
    // address is street name and street number
    this.address = formattedAttributes.address;
    // sometimes street number is separated from address
    this.streetNumber = formattedAttributes.streetNumber;
    this.streetType = formattedAttributes.streetType;
    this.city = formattedAttributes.city;
    this.postalCode = formattedAttributes.postalCode;
    this.fullAddress = formattedAttributes.fullAddress || this.formatFullAddress();
    this.departmentInternalId = formattedAttributes.departmentInternalId;
    this.nir = formattedAttributes.nir;
    this.poleEmploiId = formattedAttributes.poleEmploiId;
    this.rightsOpeningDate = formattedAttributes.rightsOpeningDate;
    this.affiliationNumber = formattedAttributes.affiliationNumber;
    this.phoneNumber = formatPhoneNumber(formattedAttributes.phoneNumber);
    this.role = this.formatRole(formattedAttributes.role);
    this.shortRole = this.role ? (this.role === "demandeur" ? "DEM" : "CJT") : null;
    this.linkedOrganisationSearchTerms = formattedAttributes.linkedOrganisationSearchTerms;
    this.referentEmail = formattedAttributes.referentEmail || currentAgent?.email;

    this.department = department;
    this.departmentNumber = department.number;
    // when creating/inviting we always consider an applicant in the scope of only one organisation
    this.currentOrganisation = organisation;
    this.currentConfiguration = currentConfiguration;
    this.columnNames = columnNames;
    this.isDuplicate = false;
  }

  get uid() {
    return this.generateUid();
  }

  get createdAt() {
    return this._createdAt;
  }

  get id() {
    return this._id;
  }

  get organisations() {
    return this._organisations;
  }

  set createdAt(createdAt) {
    this._createdAt = createdAt;
  }

  set id(id) {
    this._id = id;
  }

  set organisations(organisations) {
    this._organisations = organisations;
  }

  formatTitle(title) {
    title = title?.toLowerCase();
    title = TITLES[title] || title;
    if (!Object.values(TITLES).includes(title)) return null;
    return title;
  }

  formatRole(role) {
    // CONJOINT/CONCUBIN/PACSE => conjoint
    // CONJOINT(E) => conjoint
    role = role?.split("/")?.shift()?.split("(")?.shift()?.toLowerCase();
    role = ROLES[role] || role;
    if (!Object.values(ROLES).includes(role)) return null;
    return role;
  }

  updateWith(upToDateApplicant) {
    this.createdAt = upToDateApplicant.created_at;
    this.invitedAt = upToDateApplicant.invited_at;
    this.id = upToDateApplicant.id;
    this.archives = upToDateApplicant.archives;
    this.organisations = upToDateApplicant.organisations;
    // we assign a current organisation when we are in the context of a department
    this.currentOrganisation ||= upToDateApplicant.organisations.find(
      (o) =>
        o.department_number === this.departmentNumber &&
        o.motif_categories
          .map((motifCategory) => motifCategory.id)
          .includes(this.currentConfiguration.motif_category_id)
    );
    // we update the attributes with the attributes in DB if the applicant is already created
    // and cannot be updated from the page
    if (this.belongsToCurrentOrg()) {
      this.firstName = upToDateApplicant.first_name;
      this.lastName = upToDateApplicant.last_name;
      this.email = upToDateApplicant.email;
      this.phoneNumber = formatPhoneNumber(upToDateApplicant.phone_number);
      this.fullAddress = upToDateApplicant.address;
      if (upToDateApplicant.rights_opening_date) {
        this.rightsOpeningDate = getFrenchFormatDateString(upToDateApplicant.rights_opening_date);
      }
    }
    this.currentRdvContext = upToDateApplicant.rdv_contexts.find(
      (rc) => rc.motif_category_id === this.currentConfiguration.motif_category_id
    );
    this.currentContextStatus = this.currentRdvContext && this.currentRdvContext.status;
    this.participations = this.currentRdvContext?.participations || [];
    this.lastSmsInvitationSentAt = retrieveLastInvitationDate(
      upToDateApplicant.invitations,
      "sms",
      this.currentConfiguration.motif_category_id
    );
    this.lastEmailInvitationSentAt = retrieveLastInvitationDate(
      upToDateApplicant.invitations,
      "email",
      this.currentConfiguration.motif_category_id
    );
    this.lastPostalInvitationSentAt = retrieveLastInvitationDate(
      upToDateApplicant.invitations,
      "postal",
      this.currentConfiguration.motif_category_id
    );
    this.agents = upToDateApplicant.agents;
  }

  updatePhoneNumber(phoneNumber) {
    this.phoneNumber = formatPhoneNumber(phoneNumber);
  }

  markAttributeAsUpdated(attribute) {
    this[`${attribute}New`] = null;
    this[`${attribute}Updated`] = true;
  }

  formatFullAddress() {
    return (
      (this.streetNumber ? `${this.streetNumber} ` : "") +
      (this.streetType ? `${this.streetType} ` : "") +
      (this.address ?? "") +
      (this.postalCode ? ` ${this.postalCode}` : "") +
      (this.city ? ` ${this.city}` : "")
    );
  }

  displayedAttributes() {
    const attributes = [
      this.affiliationNumber,
      this.shortTitle,
      this.firstName,
      this.lastName,
      this.shortRole,
    ];
    if (this.shouldDisplay("department_internal_id_column"))
      attributes.push(this.departmentInternalId);
    if (this.shouldDisplay("email_column")) attributes.push(this.email);
    if (this.shouldDisplay("phone_number_column")) attributes.push(this.phoneNumber);
    if (this.shouldDisplay("rights_opening_date_column")) attributes.push(this.rightsOpeningDate);
    return attributes;
  }

  attributesFromContactsDataFile() {
    const attributes = [];
    if (this.shouldDisplay("email_column")) attributes.push(this.email);
    if (this.shouldDisplay("phone_number_column")) attributes.push(this.phoneNumber);
    if (this.shouldDisplay("rights_opening_date_column")) attributes.push(this.rightsOpeningDate);
    return attributes;
  }

  shouldDisplay(attribute) {
    return Object.keys(this.columnNames).includes(attribute);
  }

  canBeInvitedBy(format) {
    return this.currentConfiguration.invitation_formats.includes(format);
  }

  belongsToCurrentOrg() {
    return (
      this.currentOrganisation &&
      this.organisations.map((o) => o.id).includes(this.currentOrganisation.id)
    );
  }

  linkedToCurrentCategory() {
    return this.organisations.some((organisation) =>
      organisation.motif_categories
        .map((motifCategory) => motifCategory.id)
        .includes(this.currentConfiguration.motif_category_id)
    );
  }

  hasParticipations() {
    return this.participations && this.participations.length > 0;
  }

  sortedParticipationsByCreationDate() {
    return this.participations.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  }

  lastParticipationCreatedAt() {
    return this.hasParticipations()
      ? this.sortedParticipationsByCreationDate()[
          this.sortedParticipationsByCreationDate().length - 1
        ].created_at
      : null;
  }

  requiredAttributeToInviteBy(format) {
    switch (format) {
      case "sms":
        return this.phoneNumber;
      case "email":
        return this.email;
      case "postal":
        return this.fullAddress;
      default:
        return null;
    }
  }

  lastInvitationDate(format) {
    switch (format) {
      case "sms":
        return this.lastSmsInvitationSentAt;
      case "email":
        return this.lastEmailInvitationSentAt;
      case "postal":
        return this.lastPostalInvitationSentAt;
      default:
        return null;
    }
  }

  updateLastInvitationDate(format, date) {
    switch (format) {
      case "sms":
        this.lastSmsInvitationSentAt = date;
        return null;
      case "email":
        this.lastEmailInvitationSentAt = date;
        return null;
      case "postal":
        this.lastPostalInvitationSentAt = date;
        return null;
      default:
        return null;
    }
  }

  markAsAlreadyInvitedBy(format) {
    // We cannot re-invite if the applicant is invited in this format and if the applicant has no rdvs yet,
    // or if he has been reinvted after the last rdv
    const lastInvitationDate = this.lastInvitationDate(format);
    return (
      lastInvitationDate &&
      (!this.hasParticipations() ||
        new Date(lastInvitationDate) > new Date(this.lastParticipationCreatedAt()))
    );
  }

  referentAlreadyAssigned() {
    return (
      this.referentEmail &&
      this.agents &&
      this.agents.some((agent) => agent.email === this.referentEmail)
    );
  }

  archiveInCurrentDepartment() {
    return this.archives.find((archive) => archive.department_id === this.department.id);
  }

  isArchivedInCurrentDepartment() {
    return this.archives && this.archiveInCurrentDepartment();
  }

  generateUid() {
    // Base64 encoded "departmentNumber - affiliationNumber - role"

    const attributeIsMissing = [this.affiliationNumber, this.role].some((attribute) => !attribute);
    if (attributeIsMissing) {
      return null;
    }
    return btoa(`${this.affiliationNumber} - ${this.role}`);
  }

  asJson() {
    return {
      title: this.title,
      last_name: this.lastName,
      first_name: this.firstName,
      ...(this.fullAddress && { address: this.fullAddress }),
      ...(this.role && { role: this.role }),
      ...(this.affiliationNumber && { affiliation_number: this.affiliationNumber }),
      ...(this.phoneNumber && { phone_number: this.phoneNumber }),
      ...(this.email && this.email.includes("@") && { email: this.email }),
      ...(this.birthDate && { birth_date: this.birthDate }),
      ...(this.birthName && { birth_name: this.birthName }),
      ...(this.departmentInternalId && { department_internal_id: this.departmentInternalId }),
      ...(this.rightsOpeningDate && { rights_opening_date: this.rightsOpeningDate }),
      ...(this.nir && { nir: this.nir }),
      ...(this.poleEmploiId && { pole_emploi_id: this.poleEmploiId }),
    };
  }
}
