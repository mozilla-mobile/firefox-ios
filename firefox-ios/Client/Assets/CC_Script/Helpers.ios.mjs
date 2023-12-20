/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { IOSAppConstants } from "resource://gre/modules/shared/Constants.ios.mjs";
import Overrides from "resource://gre/modules/Overrides.ios.js";

/* eslint mozilla/use-isInstance: 0 */
HTMLSelectElement.isInstance = element => element instanceof HTMLSelectElement;
HTMLInputElement.isInstance = element => element instanceof HTMLInputElement;
HTMLFormElement.isInstance = element => element instanceof HTMLFormElement;
ShadowRoot.isInstance = element => element instanceof ShadowRoot;

HTMLElement.prototype.ownerGlobal = window;
HTMLInputElement.prototype.setUserInput = function (value) {
  this.value = value;
  this.dispatchEvent(new Event("input", { bubbles: true }));
};

// Mimic the behavior of .getAutocompleteInfo()
// It should return an object with a fieldName property matching the autocomplete attribute
// only if it's a valid value from this list https://searchfox.org/mozilla-central/source/dom/base/AutocompleteFieldList.h#89-149
// Also found here: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
HTMLElement.prototype.getAutocompleteInfo = function () {
  const autocomplete = this.getAttribute("autocomplete");

  return {
    fieldName: IOSAppConstants.validAutocompleteFields.includes(autocomplete)
      ? autocomplete
      : "",
  };
};

// Bug 1835024. Webkit doesn't support `checkVisibility` API
// https://drafts.csswg.org/cssom-view-1/#dom-element-checkvisibility
HTMLElement.prototype.checkVisibility = function (options) {
  throw new Error(`Not implemented: WebKit doesn't support checkVisibility `);
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

// Webpack needs to be able to statically analyze require statements in order to build the dependency graph
// In order to require modules dynamically at runtime, we use require.context() to create a dynamic require
// that is still able to be parsed by Webpack at compile time. The "./" and ".mjs" tells webpack that files
// in the current directory ending with .mjs might be needed and should be added to the dependency graph.
// NOTE: This can't handle circular dependencies. A static import can be used in this case.
// https://webpack.js.org/guides/dependency-management/
const internalModuleResolvers = {
  resolveModule(moduleURI) {
    // eslint-disable-next-line no-undef
    const moduleResolver = require.context("./", false, /.mjs$/);
    // Desktop code uses uris for importing modules of the form resource://gre/modules/<module_path>
    // We only need the filename here
    const moduleName = moduleURI.split("/").pop();
    const modulePath =
      "./" + (Overrides.ModuleOverrides[moduleName] ?? moduleName);
    return moduleResolver(modulePath);
  },

  resolveModules(obj, modules) {
    for (const [exportName, moduleURI] of Object.entries(modules)) {
      const resolvedModule = this.resolveModule(moduleURI);
      obj[exportName] = resolvedModule?.[exportName];
    }
  },
};

// Define mock for XPCOMUtils
export const XPCOMUtils = withNotImplementedError({
  defineLazyGetter: (obj, prop, getFn) => {
    obj[prop] = getFn?.call(obj);
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
  defineLazyModuleGetters(obj, modules) {
    internalModuleResolvers.resolveModules(obj, modules);
  },
});

// eslint-disable-next-line no-shadow
export const ChromeUtils = withNotImplementedError({
  defineLazyGetter: (obj, prop, getFn) => {
    obj[prop] = getFn?.call(obj);
  },
  defineESModuleGetters(obj, modules) {
    internalModuleResolvers.resolveModules(obj, modules);
  },
  importESModule(moduleURI) {
    return internalModuleResolvers.resolveModule(moduleURI);
  },
});
window.ChromeUtils = ChromeUtils;

// Define mock for Region.sys.mjs
export const Region = withNotImplementedError({
  home: "US",
});

// Define mock for OSKeyStore.sys.mjs
export const OSKeyStore = withNotImplementedError({
  ensureLoggedIn: () => true,
});

// Checks an element's focusability and accessibility via keyboard navigation
const checkFocusability = element => {
  return (
    !element.disabled &&
    !element.hidden &&
    element.style.display != "none" &&
    element.tabIndex != "-1"
  );
};

// Define mock for Services
// NOTE: Services is a global so we need to attach it to the window
// eslint-disable-next-line no-shadow
export const Services = withNotImplementedError({
  focus: withNotImplementedError({
    elementIsFocusable: checkFocusability,
  }),
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

// Define mock for Localization
window.Localization = function () {
  return { formatValueSync: () => "" };
};

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
