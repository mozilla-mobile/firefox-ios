/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Provides builtins missing on iOS < 17.4. Remove once the minimum supported iOS is 17.4+.

if (typeof Promise.withResolvers !== "function") {
  Promise.withResolvers = function () {
      let resolve, reject;
      const promise = new Promise((res, rej) => {
        resolve = res;
        reject = rej;
      });
      return { promise, resolve, reject };
  };
}

if (typeof ArrayBuffer.prototype.transfer !== "function") {
  ArrayBuffer.prototype.transfer = function () {
    return structuredClone(this, { transfer: [this] });
  };
}