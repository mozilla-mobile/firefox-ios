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

// We cannot mock this in WebKit because we lack access to low-level APIs.
// For completeness, we simply return true when the input type is "password".
HTMLInputElement.prototype.hasBeenTypePassword = function () {
  return this.type === "password";
};

HTMLInputElement.prototype.setUserInput = function (value) {
  this.value = value;

  // In React apps, setting .value may not always work reliably.
  // We dispatch change, input as a workaround.
  // There are other more "robust" solutions:
  // - Dispatching keyboard events and comparing the value after setting it
  //   (https://github.com/fmeum/browserpass-extension/blob/5efb1f9de6078b509904a83847d370c8e92fc097/src/inject.js#L412-L440)
  // - Using the native setter
  //   (https://github.com/facebook/react/issues/10135#issuecomment-401496776)
  // These are a bit more bloated. We can consider using these later if we encounter any further issues.
  ["input", "change"].forEach(eventName => {
    this.dispatchEvent(new Event(eventName, { bubbles: true }));
  });

  this.dispatchEvent(new Event("blur", { bubbles: true }));
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

// This function will create a proxy for each undefined property
// This is useful when the accessed property name is unkonwn beforehand
const undefinedProxy = () =>
  new Proxy(() => {}, {
    get() {
      return undefinedProxy();
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
  defineLazyPreferenceGetter: (
    obj,
    prop,
    pref,
    defaultValue = null,
    onUpdate,
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
  defineLazyServiceGetter() {
    // Don't do anything
    // We need this for OS Auth fixes for formautofill.
    // TODO(issam, Bug 1894967): Move os auth to separate module and remove this.
  },
});

// eslint-disable-next-line no-shadow
export const ChromeUtils = withNotImplementedError({
  defineLazyGetter: (obj, prop, getFn) => {
    const callback = prop === "log" ? genericLogger : getFn;
    obj[prop] = callback?.call(obj);
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

// Define mock for Services
// NOTE: Services is a global so we need to attach it to the window
// eslint-disable-next-line no-shadow
export const Services = withNotImplementedError({
  locale: withNotImplementedError({ isAppLocaleRTL: false }),
  prefs: withNotImplementedError({ prefIsLocked: () => false }),
  strings: withNotImplementedError({
    createBundle: () =>
      withNotImplementedError({
        GetStringFromName: () => "",
        formatStringFromName: () => "",
      }),
  }),
  telemetry: withNotImplementedError({
    scalarAdd: (scalarName, scalarValue) => {
      // For now, we only care about the address form telemetry
      // TODO(FXCM-935): move address telemetry to Glean so we can remove this
      // Data format of the sent message is:
      // {
      //   type: "scalar",
      //   name: "formautofill.addresses.detected_sections_count",
      //   value: Number,
      // }
      if (scalarName !== "formautofill.addresses.detected_sections_count") {
        return;
      }

      // eslint-disable-next-line no-undef
      webkit.messageHandlers.addressFormTelemetryMessageHandler.postMessage(
        JSON.stringify({
          type: "scalar",
          object: scalarName,
          value: scalarValue,
        })
      );
    },
    recordEvent: (category, method, object, value, extra) => {
      // For now, we only care about the address form telemetry
      // TODO(FXCM-935): move address telemetry to Glean so we can remove this
      // Data format of the sent message is:
      // {
      //   type: "event",
      //   category: "address",
      //   method: "detected" | "filled" | "filled_modified",
      //   object: "address_form" | "address_form_ext",
      //   value: String,
      //   extra: Any,
      // }
      if (category !== "address") {
        return;
      }

      // eslint-disable-next-line no-undef
      webkit.messageHandlers.addressFormTelemetryMessageHandler.postMessage(
        JSON.stringify({
          type: "event",
          category,
          method,
          object,
          value,
          extra,
        })
      );
    },
  }),
  // TODO(FXCM-936): we should use crypto.randomUUID() instead of Services.uuid.generateUUID() in our codebase
  // Underneath crypto.randomUUID() uses the same implementation as generateUUID()
  // https://searchfox.org/mozilla-central/rev/d405168c4d3c0fb900a7354ae17bb34e939af996/dom/base/Crypto.cpp#96
  // The only limitation is that it's not available in insecure contexts, which should be fine for both iOS and Desktop
  // since we only autofill in secure contexts
  uuid: withNotImplementedError({ generateUUID: () => crypto.randomUUID() }),
});
window.Services = Services;

// Define mock for Localization
window.Localization = function () {
  return { formatValueSync: () => "" };
};

// For now, we ignore all calls to glean.
// TODO(FXCM-935): move address telemetry to Glean so we can create a universal mock for glean that
// dispatches telemetry messages to the iOS.
window.Glean = {
  formautofillCreditcards: undefinedProxy(),
  formautofill: undefinedProxy(),
};

const genericLogger = () =>
  withNotImplementedError({
    info: () => {},
    error: () => {},
    warn: () => {},
    debug: () => {},
  });

export { IOSAppConstants as AppConstants } from "resource://gre/modules/shared/Constants.ios.mjs";
