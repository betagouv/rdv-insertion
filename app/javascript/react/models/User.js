import { makeAutoObservable } from "mobx";
import formatPhoneNumber from "../../lib/formatPhoneNumber";
import retrieveLastInvitationDate from "../../lib/retrieveLastInvitationDate";
import handleUserCreation from "../lib/handleUserCreation";
import retrieveRelevantOrganisation from "../../lib/retrieveRelevantOrganisation";
import handleUserInvitation from "../lib/handleUserInvitation";
import handleUserUpdate from "../lib/handleUserUpdate";
import { getFrenchFormatDateString } from "../../lib/datesHelper";

const ROLES = {
  usager: "demandeur",
  dem: "demandeur",
  cjt: "conjoint",
};

const TITLES = {
  m: "monsieur",
  mr: "monsieur",
  mme: "madame",
};

export default class User {
  constructor(
    attributes,
    department,
    organisation,
    currentConfiguration,
    currentAgent,
    list,
    availableTags = [],
    columnNames = null
  ) {
    const formattedAttributes = {};
    Object.keys(attributes).forEach((key) => {
      formattedAttributes[key] = attributes[key]?.toString()?.trim();
    });
    this.uniqueKey = Math.random().toString(36).substring(7);

    this._id = formattedAttributes.id;
    this._createdAt = formattedAttributes.createdAt;
    this._organisations = formattedAttributes.organisations || [];
    this.phoneNumberNew = null;
    this.rightsOpeningDateNew = null;
    this.emailNew = null;
    this.lastName = formattedAttributes.lastName;
    this.firstName = formattedAttributes.firstName;
    this.title = this.formatTitle(formattedAttributes.title);
    this.shortTitle = this.title ? (this.title === "monsieur" ? "M" : "Mme") : null;
    this.email = formattedAttributes.email;
    this.birthDate = formattedAttributes.birthDate;
    this.birthName = formattedAttributes.birthName;
    this.addressFirstField = formattedAttributes.addressFirstField;
    this.addressSecondField = formattedAttributes.addressSecondField;
    this.addressThirdField = formattedAttributes.addressThirdField;
    this.addressFourthField = formattedAttributes.addressFourthField;
    this.addressFifthField = formattedAttributes.addressFifthField;
    this.fullAddress = this.formatFullAddress();
    this.departmentInternalId = formattedAttributes.departmentInternalId;
    this.nir = formattedAttributes.nir;
    this.franceTravailId = formattedAttributes.franceTravailId;
    this.rightsOpeningDate = formattedAttributes.rightsOpeningDate;
    this.affiliationNumber = formattedAttributes.affiliationNumber;
    this.phoneNumber = formatPhoneNumber(formattedAttributes.phoneNumber);
    this.role = this.formatRole(formattedAttributes.role);
    this.shortRole = this.role ? (this.role === "demandeur" ? "DEM" : "CJT") : null;
    this.linkedOrganisationSearchTerms = formattedAttributes.linkedOrganisationSearchTerms;
    this.referentEmail = formattedAttributes.referentEmail || currentAgent?.email;
    this.tags = attributes.tags || [];

    this.department = department;
    this.departmentNumber = department.number;
    // when creating/inviting we always consider an user in the scope of only one organisation
    this.currentOrganisation = organisation;
    this.availableTags = availableTags;
    this.currentConfiguration = currentConfiguration;
    this.columnNames = columnNames;
    this.selected = formattedAttributes.selected || true;
    this.archives = [];
    this.list = list;

    this.resetErrors();

    this.triggers = {
      creation: false,
      unarchive: false,
      smsInvitation: false,
      emailInvitation: false,
      postalInvitation: false,
      referentAssignation: false,
      emailUpdate: false,
      phoneNumberUpdate: false,
      rightsOpeningDateUpdate: false,
      allAttributesUpdate: false,
      carnetCreation: false,
    };

    makeAutoObservable(this);
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

  async inviteBy(format, options = { raiseError: true }) {
    if (!this.createdAt || !this.belongsToCurrentOrg()) {
      const success = await this.createAccount(options);
      if (!success) return false;
    }

    if (format === "sms" && !this.phoneNumber) return false;
    if (format === "email" && !this.email) return false;
    if (format === "postal" && !this.fullAddress) return false;

    const actionType = `${format}Invitation`;
    this.triggers[actionType] = true;
    const invitationParams = [
      this.id,
      this.department.id,
      this.currentOrganisation.id,
      this.list.isDepartmentLevel,
      this.currentConfiguration.motif_category_id,
    ];
    const result = await handleUserInvitation(...invitationParams, format, {
      raiseError: options.raiseError,
    });
    if (result.success) {
      // dates are set as json to match the API format
      this.updateLastInvitationDate(format, new Date().toJSON());
    } else if (!options.raiseError) this.errors.push(actionType);
    this.triggers[actionType] = false;
    return true;
  }

  async createAccount(options = { raiseError: true }) {
    this.triggers.creation = true;

    if (!this.currentOrganisation) {
      this.currentOrganisation = await retrieveRelevantOrganisation(
        this.departmentNumber,
        this.linkedOrganisationSearchTerms,
        this.fullAddress,
        { raiseError: options.raiseError }
      );

      // If there is still no organisation it means the assignation was cancelled by agent
      if (!this.currentOrganisation) {
        this.triggers.creation = false;
        if (!options.raiseError) this.errors.push("createAccount");
        return false;
      }
    }
    const { success } = await handleUserCreation(this, this.currentOrganisation.id, {
      raiseError: options.raiseError,
    });

    if (!success && !options.raiseError) {
      this.errors = ["createAccount"];
    } else if (success) {
      this.resetErrors();
    }

    this.triggers.creation = false;

    return success;
  }

  resetErrors() {
    this.errors = [];
  }

  async updateAttribute(attribute, value) {
    if (value === this[attribute]) return true;

    const previousValue = this[attribute];
    this[attribute] = value;

    if (this.createdAt) {
      this.triggers[`${attribute}Update`] = true;
      const result = await handleUserUpdate(this.currentOrganisation.id, this, this.asJson());

      if (!result.success) {
        this[attribute] = previousValue;
      }

      this.triggers[`${attribute}Update`] = false;
      return result.success;
    }
    return true;
  }

  get isValid() {
    return !this.errors || this.errors.length === 0;
  }

  updateWith(upToDateUser) {
    this.resetErrors();
    this.createdAt = upToDateUser.created_at;
    this.id = upToDateUser.id;
    this.archives = upToDateUser.archives;
    this.organisations = upToDateUser.organisations;
    this.carnet_de_bord_carnet_id = upToDateUser.carnet_de_bord_carnet_id;
    // we assign a current organisation when we are in the context of a department
    this.currentOrganisation ||= upToDateUser.organisations.find(
      (o) =>
        o.department_number === this.departmentNumber &&
        // if we are in a specific context we choose an org that handles that category
        (!this.currentConfiguration ||
          o.motif_categories
            .map((motifCategory) => motifCategory.id)
            .includes(this.currentConfiguration.motif_category_id))
    );
    this.referents = upToDateUser.referents;
    // we update the attributes with the attributes in DB if the user is already created
    // and cannot be updated from the page
    if (this.belongsToCurrentOrg()) {
      this.firstName = upToDateUser.first_name;
      this.lastName = upToDateUser.last_name;
      this.email = upToDateUser.email;
      this.phoneNumber = formatPhoneNumber(upToDateUser.phone_number);
      this.fullAddress = upToDateUser.address;
      if (upToDateUser.rights_opening_date) {
        this.rightsOpeningDate = getFrenchFormatDateString(upToDateUser.rights_opening_date);
      }
      this.nir = upToDateUser.nir;
      this.affiliationNumber = upToDateUser.affiliation_number;
      this.role = upToDateUser.role;
      this.departmentInternalId = upToDateUser.department_internal_id;
    }
    this.tags = upToDateUser.tags.map((tag) => tag.value);
    if (this.currentConfiguration) {
      this.currentFollowUp = upToDateUser.follow_ups.find(
        (rc) => rc.motif_category_id === this.currentConfiguration.motif_category_id
      );
      this.currentFollowUpStatus = this.currentFollowUp && this.currentFollowUp.status;
      this.participations = this.currentFollowUp?.participations || [];
      this.lastSmsInvitationSentAt = retrieveLastInvitationDate(
        upToDateUser.invitations,
        "sms",
        this.currentConfiguration.motif_category_id
      );
      this.lastEmailInvitationSentAt = retrieveLastInvitationDate(
        upToDateUser.invitations,
        "email",
        this.currentConfiguration.motif_category_id
      );
      this.lastPostalInvitationSentAt = retrieveLastInvitationDate(
        upToDateUser.invitations,
        "postal",
        this.currentConfiguration.motif_category_id
      );
    }
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
      (this.addressFirstField ? `${this.addressFirstField} ` : "") +
      (this.addressSecondField ? `${this.addressSecondField} ` : "") +
      (this.addressThirdField ? `${this.addressThirdField} ` : "") +
      (this.addressFourthField ? `${this.addressFourthField} ` : "") +
      (this.addressFifthField ?? "")
    ).trim();
  }

  shouldDisplay(attribute) {
    return Object.keys(this.columnNames).includes(attribute);
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

  sortedParticipationsByRdvStartsAt() {
    return this.participations.sort((a, b) => new Date(a.starts_at) - new Date(b.starts_at));
  }

  lastParticipationRdvStartsAt() {
    return this.hasParticipations()
      ? this.sortedParticipationsByRdvStartsAt()[
          this.sortedParticipationsByRdvStartsAt().length - 1
        ].starts_at
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

  referentAlreadyAssigned() {
    return (
      this.referentEmail &&
      this.referents &&
      this.referents.some((referent) => referent.email === this.referentEmail)
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

  get tagsAsJson() {
    const matchingTags = this.availableTags.filter((tag) => this.tags.includes(tag.value));

    return matchingTags.map((tag) => ({ tag_id: tag.id }));
  }

  asJson() {
    return {
      ...(this.title && { title: this.title }),
      ...(this.lastName && { last_name: this.lastName }),
      ...(this.firstName && { first_name: this.firstName }),
      tag_users_attributes: this.tagsAsJson,
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
      ...(this.franceTravailId && { france_travail_id: this.franceTravailId }),
      ...(this.currentConfiguration && {
        follow_ups_attributes: [{ motif_category_id: this.currentConfiguration.motif_category_id }],
      }),
    };
  }
}
