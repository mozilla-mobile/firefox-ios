/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 * Central registry describing the data types Form Autofill can detect and
 * classify (address, credit card, ...).
 */
class AutofillDataTypeRegistry {
  // Canonical data-type identifiers. Exposed on the instance below (e.g.
  // `AutofillDataTypes.ADDRESS`) so callers reference a named constant, and
  // used as the descriptor `id`s.
  static ADDRESS = "address";
  static CREDIT_CARD = "creditCard";
  static PASSPORT = "passport";

  /** @type {Map<string, AutofillDataType>} */
  #byId;

  /** Maps a field sub-category to the id of the type that owns it. */
  #subCategoryToTypeId;

  /**
   * @param {AutofillDataType[]} descriptors
   */
  constructor(descriptors) {
    this.all = Object.freeze(
      descriptors.map(type =>
        Object.freeze({
          ...type,
          fields: Object.freeze(type.fields),
          // Derived from `fields` so each field name and its owning
          // sub-category are declared in exactly one place.
          subCategories: Object.freeze(Object.keys(type.fields)),
          // The feature prefs all live under
          // `extensions.formautofill.<prefKey>.*`, so they are derived from
          // prefKey.
          availablePref: `extensions.formautofill.${type.prefKey}.supported`,
          supportedCountriesPref: `extensions.formautofill.${type.prefKey}.supportedCountries`,
          enabledPref: `extensions.formautofill.${type.prefKey}.enabled`,
          experimentPref: `extensions.formautofill.${type.prefKey}.experiments.enabled`,
        })
      )
    );
    this.#byId = new Map(this.all.map(type => [type.id, type]));
    this.#subCategoryToTypeId = new Map(
      this.all.flatMap(type =>
        type.subCategories.map(subCategory => [subCategory, type.id])
      )
    );
    // Flat field-name -> sub-category map across all types, used for field
    // classification.
    this.fieldToSubCategory = Object.freeze(
      Object.fromEntries(
        this.all.flatMap(type =>
          Object.entries(type.fields).flatMap(([subCategory, fieldNames]) =>
            fieldNames.map(fieldName => [fieldName, subCategory])
          )
        )
      )
    );
    this.ADDRESS = AutofillDataTypeRegistry.ADDRESS;
    this.CREDIT_CARD = AutofillDataTypeRegistry.CREDIT_CARD;
    this.PASSPORT = AutofillDataTypeRegistry.PASSPORT;
    Object.freeze(this);
  }

  /**
   * @param {string} id
   * @returns {AutofillDataType} The descriptor, or null if `id` is unknown.
   */
  get(id) {
    return this.#byId.get(id) ?? null;
  }

  /**
   * @param {string} subCategory A field sub-category.
   * @returns {string} The owning type id, or null if the sub-category is unknown.
   */
  typeIdForSubCategory(subCategory) {
    return this.#subCategoryToTypeId.get(subCategory) ?? null;
  }

  /**
   * @param {string} fieldName A field name (e.g. "street-address", "cc-number").
   * @returns {string} The owning type id, or null if the field is unknown.
   */
  typeIdForFieldName(fieldName) {
    return this.typeIdForSubCategory(this.fieldToSubCategory[fieldName]);
  }
}

export const AutofillDataTypes = new AutofillDataTypeRegistry([
  {
    id: AutofillDataTypeRegistry.ADDRESS,
    collectionName: "addresses",
    prefKey: "addresses",
    fields: {
      name: ["name", "given-name", "additional-name", "family-name"],
      organization: ["organization"],
      address: [
        "street-address",
        "address-line1",
        "address-line2",
        "address-line3",
        "address-level1",
        "address-level2",
        "address-level3",
        // DE addresses are often split into street name and house number;
        // combined they form address-line1
        "address-streetname",
        "address-housenumber",
        // NL forms often split the suffix from the house number;
        // for example 35B becomes '35' as the number and 'B' as the suffix.
        "address-extra-housesuffix",
        "postal-code",
        "country",
        "country-name",
      ],
      tel: [
        "tel",
        "tel-country-code",
        "tel-national",
        "tel-area-code",
        "tel-local",
        "tel-local-prefix",
        "tel-local-suffix",
        "tel-extension",
      ],
      email: ["email"],
    },
  },
  {
    id: AutofillDataTypeRegistry.CREDIT_CARD,
    collectionName: "creditCards",
    prefKey: "creditCards",
    fields: {
      creditCard: [
        "cc-name",
        "cc-given-name",
        "cc-additional-name",
        "cc-family-name",
        "cc-number",
        "cc-exp-month",
        "cc-exp-year",
        "cc-exp",
        "cc-type",
        "cc-csc",
      ],
    },
  },
  {
    id: AutofillDataTypeRegistry.PASSPORT,
    collectionName: "passports",
    prefKey: "passports",
    fields: {
      passport: [
        "passport-name",
        "passport-given-name",
        "passport-additional-name",
        "passport-family-name",
        "passport-country",
        "passport-number",
        "passport-issue-date-month",
        "passport-issue-date-day",
        "passport-issue-date-year",
        "passport-issue-date",
        "passport-expiry-date-month",
        "passport-expiry-date-day",
        "passport-expiry-date-year",
        "passport-expiry-date",
      ],
    },
  },
]);
