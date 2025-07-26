/* eslint-disable no-useless-concat */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { FormAutofillNameUtils } from "resource://gre/modules/shared/FormAutofillNameUtils.sys.mjs";
import { FormAutofillUtils } from "resource://gre/modules/shared/FormAutofillUtils.sys.mjs";
import { PhoneNumber } from "resource://gre/modules/shared/PhoneNumber.sys.mjs";
import { FormAutofill } from "resource://autofill/FormAutofill.sys.mjs";
import { AddressParser } from "resource://gre/modules/shared/AddressParser.sys.mjs";

/**
 * The AddressRecord class serves to handle and normalize internal address records.
 * AddressRecord is used for processing and consistent data representation.
 */
export class AddressRecord {
  static NAME_COMPONENTS = ["given-name", "additional-name", "family-name"];

  static STREET_ADDRESS_COMPONENTS = [
    "address-line1",
    "address-line2",
    "address-line3",
  ];
  static TEL_COMPONENTS = [
    "tel-country-code",
    "tel-national",
    "tel-area-code",
    "tel-local",
    "tel-local-prefix",
    "tel-local-suffix",
  ];

  static computeFields(address) {
    this.#computeNameFields(address);
    this.#computeAddressLineFields(address);
    this.#computeStreetAndHouseNumberFields(address);
    this.#computeCountryFields(address);
    this.#computeTelFields(address);
  }

  static #computeNameFields(address) {
    // Compute split names
    if (!("given-name" in address)) {
      const nameParts = FormAutofillNameUtils.splitName(address.name);
      address["given-name"] = nameParts.given;
      address["additional-name"] = nameParts.middle;
      address["family-name"] = nameParts.family;
    }
  }

  static #computeAddressLineFields(address) {
    // Compute address lines
    if (!("address-line1" in address)) {
      let streetAddress = [];
      if (address["street-address"]) {
        streetAddress = address["street-address"]
          .split("\n")
          .map(s => s.trim());
      }
      for (let i = 0; i < 3; i++) {
        address[`address-line${i + 1}`] = streetAddress[i] || "";
      }
      if (streetAddress.length > 3) {
        address["address-line3"] = FormAutofillUtils.toOneLineAddress(
          streetAddress.slice(2)
        );
      }
    }
  }

  static #computeStreetAndHouseNumberFields(address) {
    if (!("address-housenumber" in address) && "street-address" in address) {
      let streetAddress = AddressParser.parseStreetAddress(
        address["street-address"]
      );
      if (streetAddress) {
        address["address-housenumber"] = streetAddress.street_number;
      }
    }
  }

  static #computeCountryFields(address) {
    // Compute country name
    if (!("country-name" in address)) {
      address["country-name"] =
        FormAutofill.countries.get(address.country) ?? "";
    }
  }

  static #computeTelFields(address) {
    // Compute tel
    if (!("tel-national" in address)) {
      if (address.tel) {
        let tel = PhoneNumber.Parse(
          address.tel,
          address.country || FormAutofill.DEFAULT_REGION
        );
        if (tel) {
          if (tel.countryCode) {
            address["tel-country-code"] = tel.countryCode;
          }
          if (tel.nationalNumber) {
            address["tel-national"] = tel.nationalNumber;
          }

          // PhoneNumberUtils doesn't support parsing the components of a telephone
          // number so we hard coded the parser for US numbers only. We will need
          // to figure out how to parse numbers from other regions when we support
          // new countries in the future.
          if (tel.nationalNumber && tel.countryCode == "+1") {
            let telComponents = tel.nationalNumber.match(
              /(\d{3})((\d{3})(\d{4}))$/
            );
            if (telComponents) {
              address["tel-area-code"] = telComponents[1];
              address["tel-local"] = telComponents[2];
              address["tel-local-prefix"] = telComponents[3];
              address["tel-local-suffix"] = telComponents[4];
            }
          }
        } else {
          // Treat "tel" as "tel-national" directly if it can't be parsed.
          address["tel-national"] = address.tel;
        }
      }

      this.TEL_COMPONENTS.forEach(c => {
        address[c] = address[c] || "";
      });
    }
  }
}
