/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

module.exports = function chromeAPIWrapper(api) {
  return new Proxy(api, {
    get: function(target, property, receiver) {
      let value = api[property];

      if (typeof value === "function") {
        return function() {
          let args = [].slice.apply(arguments);
          if (typeof args[args.length - 1] === "function") {
            let callback = args.pop();
            let result = value.apply(api, args);
            if (result instanceof Promise) {
              result.then(callback).catch(function() {
                callback.apply(result, arguments);
                // TODO: Set `runtime.lastError`
              });
              return;
            }

            return result;
          }

          let result = value.apply(api, args);
          if (result instanceof Promise) {
            result.catch(function() {
              // TODO: Set `runtime.lastError`
            });
            return;
          }

          return result;
        };
      }

      return value;
    }
  });
};
