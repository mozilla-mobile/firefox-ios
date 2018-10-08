/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const { windowProxy, exportFunction, cloneInto } = (function(nativeWindow) {
  "use strict";

  const targetScopeKey = Symbol("targetScope");

  let deletedProps = {};
  let setProps = {};
  let nonConfigurableProps = {};

  function cloneObject(obj, cloneFunctions) {
    let clone = {};
    for (let key in obj) {
      let value = obj[key];
      if (typeof value === "function" && cloneFunctions !== true) {
        continue;
      }
      if (typeof value === "object") {
        if (value.constructor !== Object.prototype.constructor) {
          continue;
        }

        clone[key] = cloneObject(value, cloneFunctions);
      } else {
        clone[key] = value;
      }
    }
    return clone;
  }

  function getOwnPropertyDescriptor(property) {
    return Object.getOwnPropertyDescriptor(setProps, property) || Object.getOwnPropertyDescriptor(nativeWindow, property);
  }

  function getNativeProperty(property) {
    let value = nativeWindow[property];
    if (typeof value === "function") {
      if (property === "addEventListener") {
        return function(type, listener, options) {
          value.call(nativeWindow, type, function(event) {
            let mappedEvent = {};
            // Ensure references to the native `window` are mapped to
            // the `Proxy` to allow for equality testing.
            for (let property in event) {
              mappedEvent[property] = event[property] === nativeWindow ? windowProxy : event[property];
            }

            listener(mappedEvent);
          }, options);
        };
      }

      return function() {
        return value.apply(this === windowProxy ? nativeWindow : this, arguments);
      };
    }

    return value;
  }

  const wrappedJSObject = new Proxy(nativeWindow, {
    get: function(target, property, receiver) {
      return getNativeProperty(property);
    },
    set: function(target, property, value, receiver) {
      if (value && value instanceof ClonedObject && value[targetScopeKey] === windowProxy) {
        nativeWindow[property] = value;
      }
    },
    defineProperty: function(target, property, descriptor) {
      return false;
    },
    deleteProperty: function(target, property) {
      return false;
    }
  });

  const windowProxy = new Proxy(nativeWindow, {
    get: function(target, property, receiver) {
      if (property === "wrappedJSObject") {
        return wrappedJSObject;
      }
      if (deletedProps[property]) {
        return undefined;
      }
      return setProps[property] || getNativeProperty(property);
    },
    set: function(target, property, value, receiver) {
      delete deletedProps[property];
      setProps[property] = value;
    },
    has: function(target, property) {
      return (property in setProps) || (property in nativeWindow);
    },
    getOwnPropertyDescriptor(target, property) {
      return getOwnPropertyDescriptor(property);
    },
    defineProperty: function(target, property, descriptor) {
      delete deletedProps[property];
      let oldDescriptor = getOwnPropertyDescriptor(property);
      if (oldDescriptor && (nonConfigurableProps[property] || !oldDescriptor.configurable)) {
        if (oldDescriptor.value !== descriptor.value) {
          throw TypeError("Attempting to change value of a readonly property.");
        }
        return false;
      }
      if (!descriptor.configurable) {
        nonConfigurableProps[property] = true;
        descriptor.configurable = true;
      }
      Object.defineProperty(setProps, property, descriptor);
      return false;
    },
    deleteProperty: function(target, property) {
      let descriptor = getOwnPropertyDescriptor(property);
      if (descriptor && (nonConfigurableProps[property] || !descriptor.configurable)) {
        return false;
      }
      delete setProps[property];
      deletedProps[property] = true;
      return true;
    }
  });

  function exportFunction(func, targetScope, options) {
    if (typeof func !== "function") {
      console.error("Invalid function targeted for export.");
      return;
    }

    if (!options) {
      options = {};
    }

    let name = func.name || options.defineAs;
    if (!name) {
      console.error("Unable to export anonymous function without `defineAs` option.");
      return;
    }

    if (targetScope === windowProxy) {
      targetScope = window;
    }

    targetScope[name] = func;
  }

  function cloneInto(obj, targetScope, options) {
    if (!obj || typeof obj !== "object") {
      console.error("Invalue object targeted for cloning.");
      return null;
    }

    if (!options) {
      options = {};
    }

    return new ClonedObject(obj, targetScope, options);
  }

  class ClonedObject {
    constructor(obj, targetScope, options) {
      this[targetScopeKey] = targetScope;

      let clone = cloneObject(obj, options.cloneFunctions);
      for (let key in clone) {
        this[key] = clone[key];
      }
    }
  }

  return { windowProxy, exportFunction, cloneInto };
})(window);
