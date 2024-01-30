/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  AddressMetaData: "resource://gre/modules/shared/AddressMetaData.sys.mjs",
  AddressMetaDataExtension:
    "resource://gre/modules/shared/AddressMetaDataExtension.sys.mjs",
});

export class AddressMetaDataLoader {
  // Status of address data loading. We'll load all the countries with basic level 1
  // information while requesting conutry information, and set country to true.
  // Level 1 Set is for recording which country's level 1/level 2 data is loaded,
  // since we only load this when getCountryAddressData called with level 1 parameter.
  static dataLoaded = {
    country: false,
    level1: new Set(),
  };

  static addressData = {};

  static DATA_PREFIX = "data/";

  /**
   * Load address meta data and extension into one object.
   *
   * @returns {object}
   *          An object containing address data object with properties from extension.
   */
  static loadAddressMetaData() {
    const addressMetaData = lazy.AddressMetaData;

    for (const key in lazy.AddressMetaDataExtension) {
      let addressDataForKey = addressMetaData[key];
      if (!addressDataForKey) {
        addressDataForKey = addressMetaData[key] = {};
      }

      Object.assign(addressDataForKey, lazy.AddressMetaDataExtension[key]);
    }
    return addressMetaData;
  }

  /**
   * Convert certain properties' string value into array. We should make sure
   * the cached data is parsed.
   *
   * @param   {object} data Original metadata from addressReferences.
   * @returns {object} parsed metadata with property value that converts to array.
   */
  static #parse(data) {
    if (!data) {
      return null;
    }

    const properties = [
      "languages",
      "sub_keys",
      "sub_isoids",
      "sub_names",
      "sub_lnames",
    ];
    for (const key of properties) {
      if (!data[key]) {
        continue;
      }
      // No need to normalize data if the value is array already.
      if (Array.isArray(data[key])) {
        return data;
      }

      data[key] = data[key].split("~");
    }
    return data;
  }

  /**
   * We'll cache addressData in the loader once the data loaded from scripts.
   * It'll become the example below after loading addressReferences with extension:
   * addressData: {
   *               "data/US": {"lang": ["en"], ...// Data defined in libaddressinput metadata
   *                           "alternative_names": ... // Data defined in extension }
   *               "data/CA": {} // Other supported country metadata
   *               "data/TW": {} // Other supported country metadata
   *               "data/TW/台北市": {} // Other supported country level 1 metadata
   *              }
   *
   * @param   {string} country
   * @param   {string?} level1
   * @returns {object} Default locale metadata
   */
  static #loadData(country, level1 = null) {
    // Load the addressData if needed
    if (!this.dataLoaded.country) {
      this.addressData = this.loadAddressMetaData();
      this.dataLoaded.country = true;
    }
    if (!level1) {
      return this.#parse(this.addressData[`${this.DATA_PREFIX}${country}`]);
    }
    // If level1 is set, load addressReferences under country folder with specific
    // country/level 1 for level 2 information.
    if (!this.dataLoaded.level1.has(country)) {
      Object.assign(this.addressData, this.loadAddressMetaData());
      this.dataLoaded.level1.add(country);
    }
    return this.#parse(
      this.addressData[`${this.DATA_PREFIX}${country}/${level1}`]
    );
  }

  /**
   * Return the region metadata with default locale and other locales (if exists).
   *
   * @param   {string} country
   * @param   {string?} level1
   * @returns {object} Return default locale and other locales metadata.
   */
  static getData(country, level1 = null) {
    const defaultLocale = this.#loadData(country, level1);
    if (!defaultLocale) {
      return null;
    }

    const countryData = this.#parse(
      this.addressData[`${this.DATA_PREFIX}${country}`]
    );
    let locales = [];
    // TODO: Should be able to support multi-locale level 1/ level 2 metadata query
    //      in Bug 1421886
    if (countryData.languages) {
      const list = countryData.languages.filter(
        key => key !== countryData.lang
      );
      locales = list.map(key =>
        this.#parse(this.addressData[`${defaultLocale.id}--${key}`])
      );
    }
    return { defaultLocale, locales };
  }

  /**
   * Return an array containing countries alpha2 codes.
   *
   * @returns {Array} Return an array containing countries alpha2 codes.
   */
  static get #countryCodes() {
    return Object.keys(lazy.AddressMetaDataExtension).map(dataKey =>
      dataKey.replace(this.DATA_PREFIX, "")
    );
  }

  static getCountries(locales = []) {
    const displayNames = new Intl.DisplayNames(locales, {
      type: "region",
      fallback: "none",
    });
    const countriesMap = new Map();
    for (const countryCode of this.#countryCodes) {
      countriesMap.set(countryCode, displayNames.of(countryCode));
    }
    return countriesMap;
  }
}

export default AddressMetaDataLoader;
