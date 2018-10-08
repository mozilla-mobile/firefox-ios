/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("MessagePipe", function() {
  let _connections = {};

  // https://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript
  function generateUUID() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, function(c) {
      return (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16);
    });
  }

  class MessagePipe {
    constructor(id) {
      this.id = id;
    }

    static respond(pipeId, connectionId, response, error) {
      let connection = _connections[connectionId];
      if (!connection) {
        console.error("MessagePipeConnection does not exist: " + connectionId);
        return;
      }

      if (connection.pipeId !== pipeId) {
        console.error("MessagePipeConnection responded to wrong MessagePipe; received " + pipeId + ", expected " + connection.pipeId);
        return;
      }

      delete _connections[connectionId];

      if (error) {
        connection.reject(error);
        return;
      }

      connection.resolve(response);
    }

    get MessagePipeConnection() {
      const pipeId = this.id;

      return class MessagePipeConnection {
        constructor() {
          this.id = generateUUID();
        }

        get pipeId() { return pipeId; }

        send(type, method, payload) {
          let connectionId = this.id;

          return new Promise((resolve, reject) => {
            webkit.messageHandlers.webExtensionAPI.postMessage({
              pipeId, connectionId, type, method, payload
            });

            this.resolve = resolve;
            this.reject = reject;

            _connections[connectionId] = this;
          });
        }
      };
    }
  }

  Object.defineProperty(window.__firefox__, "MessagePipe", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: MessagePipe
  });
});
