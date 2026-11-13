/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Provides builtins missing on iOS < 17.4. Remove once the minimum supported iOS is 17.4+.

if (typeof Promise.withResolvers !== "function") {
  Object.defineProperty(Promise, "withResolvers", {
    configurable: true,
    writable: true,
    enumerable: false,
    value: function withResolvers() {
      let resolve, reject;
      const promise = new this((res, rej) => {
        resolve = res;
        reject = rej;
      });
      return { promise, resolve, reject };
    },
  });
}

if (typeof ArrayBuffer.prototype.transfer !== "function") {
  Object.defineProperty(ArrayBuffer.prototype, "transfer", {
    configurable: true,
    writable: true,
    enumerable: false,
    value: function transfer() {
      if (typeof structuredClone === "function") {
        return structuredClone(this, { transfer: [this] });
      }
      return this;
    },
  });
}