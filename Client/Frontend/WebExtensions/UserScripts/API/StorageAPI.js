/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const noimpl = require("./common/noimpl.js");

const storage = {
  local: {
    get: function(keys) {
      let store = JSON.parse(localStorage.getItem(WEB_EXTENSION_BASE_URL) || "{}");
      if (keys === null) {
        return Promise.resolve(store);
      }

      let result = {};
      if (!keys) {
        return Promise.resolve(result);
      }

      if (typeof keys === "string") {
        let value = store[keys];
        if (value !== undefined) {
          result[keys] = value;
        }
      } else if (Array.isArray(keys)) {
        keys.forEach((key) => {
          let value = store[key];
          if (value !== undefined) {
            result[key] = value;
          }
        });
      } else if (typeof keys === "object") {
        for (let key in keys) {
          let value = store[key];
          result[key] = value !== undefined ? value : keys[key];
        }
      }

      return Promise.resolve(result);
    },
    getBytesInUse: function(keys) {
      let json = localStorage.getItem(WEB_EXTENSION_BASE_URL) || "";
      return Promise.resolve(json.length);
    },
    set: function(keys) {
      if (!keys || typeof keys !== "object") {
        return Promise.reject();
      }

      let store = JSON.parse(localStorage.getItem(WEB_EXTENSION_BASE_URL) || "{}");
      for (let key in keys) {
        store[key] = keys[key];
      }
      localStorage.setItem(WEB_EXTENSION_BASE_URL, JSON.stringify(store));

      return Promise.resolve();
    },
    remove: function(keys) {
      let keysArray;
      if (typeof keys === 'string') {
        keysArray = [keys];
      } else if (Array.isArray(keys)) {
        keysArray = keys;
      } else {
        return Promise.reject();
      }

      let store = JSON.parse(localStorage.getItem(WEB_EXTENSION_BASE_URL) || "{}");
      keysArray.forEach((key) => {
        delete store[key];
      });
      localStorage.setItem(WEB_EXTENSION_BASE_URL, JSON.stringify(store));

      return Promise.resolve();
    },
    clear: function() {
      localStorage.removeItem(WEB_EXTENSION_BASE_URL);
      return Promise.resolve();
    }
  },

  onChanged: new NativeEvent(SECURITY_TOKEN, WEB_EXTENSION_ID, "browser.storage.onChanged")
};

module.exports = storage;
