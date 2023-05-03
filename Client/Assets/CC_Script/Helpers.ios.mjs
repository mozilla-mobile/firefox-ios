/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { IOSAppConstants } from "resource://gre/modules/shared/Constants.ios.mjs";

HTMLSelectElement.isInstance = element => element instanceof HTMLSelectElement;
HTMLInputElement.isInstance = element => element instanceof HTMLInputElement;
HTMLFormElement.isInstance = element => element instanceof HTMLFormElement;
ShadowRoot.isInstance = element => element instanceof ShadowRoot;

HTMLElement.prototype.ownerGlobal = window;
HTMLInputElement.prototype.setUserInput = function(value) {
  this.value = value;
  this.dispatchEvent(new Event("input", { bubbles: true }));
};

// TODO: Bug 1828408.
// Use  WeakRef API directly in our codebase instead of legacy Cu.getWeakReference.
window.Cu = class {
  static getWeakReference(elements) {
    const elementsWeakRef = new WeakRef(elements);
    return {
      get: () => elementsWeakRef.deref(),
    };
  }
};

// Mimic the behavior of .getAutocompleteInfo()
// It should return an object with a fieldName property matching the autocomplete attribute
// only if it's a valid value from this list https://searchfox.org/mozilla-central/source/dom/base/AutocompleteFieldList.h#89-149
// Also found here: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
HTMLElement.prototype.getAutocompleteInfo = function() {
  const autocomplete = this.getAttribute("autocomplete");

  return {
    fieldName: IOSAppConstants.validAutocompleteFields.includes(autocomplete)
      ? autocomplete
      : "",
  };
};

// This function  helps us debug better when an error occurs because a certain mock is missing
const withNotImplementedError = obj =>
  new Proxy(obj, {
    get(target, prop) {
      if (!Object.keys(target).includes(prop)) {
        throw new Error(
          `Not implemented: ${prop} doesn't exist in mocked object `
        );
      }
      return Reflect.get(...arguments);
    },
  });

// Define mock for XPCOMUtils
export const XPCOMUtils = withNotImplementedError({
  defineLazyGetter: (obj, prop, getFn) => {
    obj[prop] = getFn?.();
  },
  defineLazyPreferenceGetter: (
    obj,
    prop,
    pref,
    defaultValue = null,
    onUpdate = null,
    transform = val => val
  ) => {
    if (!Object.keys(IOSAppConstants.prefs).includes(pref)) {
      throw Error(`Pref ${pref} is not defined.`);
    }
    obj[prop] = transform(IOSAppConstants.prefs[pref] ?? defaultValue);
  },
});

// Define mock for Region.sys.mjs
export const Region = withNotImplementedError({
  home: "US",
});

// Define mock for OSKeyStore.sys.mjs
export const OSKeyStore = withNotImplementedError({
  ensureLoggedIn: () => true,
});

// Define mock for Services
// NOTE: Services is a global so we need to attach it to the window
// eslint-disable-next-line no-shadow
export const Services = withNotImplementedError({
  intl: withNotImplementedError({
    getAvailableLocaleDisplayNames: () => [],
    getRegionDisplayNames: () => [],
  }),
  locale: withNotImplementedError({ isAppLocaleRTL: false }),
  prefs: withNotImplementedError({ prefIsLocked: () => false }),
  strings: withNotImplementedError({
    createBundle: () =>
      withNotImplementedError({
        GetStringFromName: () => "",
        formatStringFromName: () => "",
      }),
  }),
  uuid: withNotImplementedError({ generateUUID: () => "" }),
});
window.Services = Services;

export const windowUtils = withNotImplementedError({
  removeManuallyManagedState: () => {},
  addManuallyManagedState: () => {},
});
window.windowUtils = windowUtils;

export const AutofillTelemetry = withNotImplementedError({
  recordFormInteractionEvent: () => {},
  recordDetectedSectionCount: () => {},
});

export { IOSAppConstants as AppConstants } from "resource://gre/modules/shared/Constants.ios.mjs";
