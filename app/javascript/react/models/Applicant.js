import formatPhoneNumber from "../../lib/formatPhoneNumber";
import retrieveLastInvitationDate from "../../lib/retrieveLastInvitationDate";

const ROLES = {
  dem: "demandeur",
  cjt: "conjoint",
};

const TITLES = {
  mr: "monsieur",
  mme: "madame",
};

export default class Applicant {
  constructor(attributes, departmentNumber, organisation, organisationConfiguration) {
    const formattedAttributes = {};
    Object.keys(attributes).forEach((key) => {
      formattedAttributes[key] = attributes[key]?.toString()?.trim();
    });
    this.address = formattedAttributes.address;
    this.lastName = formattedAttributes.lastName;
    this.firstName = formattedAttributes.firstName;
    this.title =
      TITLES[formattedAttributes.title?.toLowerCase()] || formattedAttributes.title?.toLowerCase();
    this.shortTitle = this.title === "monsieur" ? "M" : "Mme";
    this.email = formattedAttributes.email;
    this.birthDate = formattedAttributes.birthDate;
    this.birthName = formattedAttributes.birthName;
    this.city = formattedAttributes.city;
    this.postalCode = formattedAttributes.postalCode;
    this.fullAddress = formattedAttributes.fullAddress || this.formatAddress();
    this.customId = formattedAttributes.customId;
    this.rightsOpeningDate = formattedAttributes.rightsOpeningDate;
    this.affiliationNumber = this.formatAffiliationNumber(formattedAttributes.affiliationNumber);
    this.phoneNumber = formatPhoneNumber(formattedAttributes.phoneNumber);
    // CONJOINT/CONCUBIN/PACSE => conjoint
    const formattedRole = formattedAttributes.role?.split("/")?.shift()?.toLowerCase();
    this.role = ROLES[formattedRole] || formattedRole;
    this.shortRole = this.role === "demandeur" ? "DEM" : "CJT";
    this.departmentNumber = departmentNumber;
    // when creating/inviting we always consider an applicant in the scope of only one organisation
    this.currentOrganisation = organisation;
    this.organisationConfiguration = organisationConfiguration;
  }

  get uid() {
    return this.generateUid();
  }

  get createdAt() {
    return this._createdAt;
  }

  get lastEmailInvitationSentAt() {
    return this._lastEmailInvitationSentAt;
  }

  get lastSmsInvitationSentAt() {
    return this._lastSmsInvitationSentAt;
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

  set lastEmailInvitationSentAt(lastEmailInvitationSentAt) {
    this._lastEmailInvitationSentAt = lastEmailInvitationSentAt;
  }

  set lastSmsInvitationSentAt(lastSmsInvitationSentAt) {
    this._lastSmsInvitationSentAt = lastSmsInvitationSentAt;
  }

  set organisations(organisations) {
    this._organisations = organisations;
  }

  formatAffiliationNumber(affiliationNumber) {
    if (affiliationNumber && [13, 15].includes(affiliationNumber.length)) {
      // This means it is a NIR, we replace it by a custom ID if present
      if (this.customId) {
        return `CUS-${this.customId}`;
      }
      return null;
    }
    return affiliationNumber;
  }

  updateWith(upToDateApplicant) {
    this.createdAt = upToDateApplicant.created_at;
    this.invitedAt = upToDateApplicant.invited_at;
    this.id = upToDateApplicant.id;
    this.organisations = upToDateApplicant.organisations;
    // we assign a current organisation when we are in the context of a department
    this.currentOrganisation ||= upToDateApplicant.organisations.find(
      (o) => o.department_number === this.departmentNumber
    );
    // we update the attributes with the attributes in DB if the applicant is already created
    // and cannot be updated from the page
    if (this.belongsToCurrentOrg()) {
      this.firstName = upToDateApplicant.first_name;
      this.lastName = upToDateApplicant.last_name;
      this.email = upToDateApplicant.email;
      this.phoneNumber = formatPhoneNumber(upToDateApplicant.phone_number);
      this.fullAddress = upToDateApplicant.address;
    }
    this.lastSmsInvitationSentAt = retrieveLastInvitationDate(upToDateApplicant.invitations, "sms");
    this.lastEmailInvitationSentAt = retrieveLastInvitationDate(
      upToDateApplicant.invitations,
      "email"
    );
  }

  formatAddress() {
    return (
      (this.address ?? "") +
      (this.postalCode ? ` ${this.postalCode}` : "") +
      (this.city ? ` ${this.city}` : "")
    );
  }

  shouldDisplay(attribute) {
    return (
      this.organisationConfiguration.column_names.required[attribute] ||
      (this.organisationConfiguration.column_names.optional &&
        this.organisationConfiguration.column_names.optional[attribute])
    );
  }

  shouldBeInvitedBySms() {
    return (
      this.organisationConfiguration.invitation_format === "sms" ||
      this.organisationConfiguration.invitation_format === "sms_and_email"
    );
  }

  shouldBeInvitedByEmail() {
    return (
      this.organisationConfiguration.invitation_format === "email" ||
      this.organisationConfiguration.invitation_format === "sms_and_email"
    );
  }

  belongsToCurrentOrg() {
    return (
      this.currentOrganisation &&
      this.organisations.map((o) => o.id).includes(this.currentOrganisation.id)
    );
  }

  hasMissingAttributes() {
    return [this.firstName, this.lastName, this.title].some((attribute) => !attribute);
  }

  generateUid() {
    // Base64 encoded "departmentNumber - affiliationNumber - role"

    const attributeIsMissing = [this.affiliationNumber, this.role].some((attribute) => !attribute);
    if (attributeIsMissing) {
      return null;
    }
    return btoa(`${this.departmentNumber} - ${this.affiliationNumber} - ${this.role}`);
  }

  asJson() {
    return {
      uid: this.generateUid(),
      address: this.fullAddress,
      title: this.title,
      last_name: this.lastName,
      first_name: this.firstName,
      role: this.role,
      affiliation_number: this.affiliationNumber,
      ...(this.phoneNumber && { phone_number: this.phoneNumber }),
      ...(this.email && this.email.includes("@") && { email: this.email }),
      ...(this.birthDate && { birth_date: this.birthDate }),
      ...(this.birthName && { birth_name: this.birthName }),
      ...(this.customId && { custom_id: this.customId }),
      ...(this.rightsOpeningDate && { rights_opening_date: this.rightsOpeningDate }),
    };
  }
}
