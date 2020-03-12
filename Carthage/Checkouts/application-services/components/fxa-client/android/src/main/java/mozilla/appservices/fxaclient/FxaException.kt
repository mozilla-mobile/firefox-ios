/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

open class FxaException(message: String) : Exception(message) {
    class Unspecified(msg: String) : FxaException(msg)
    class Unauthorized(msg: String) : FxaException(msg)
    class Network(msg: String) : FxaException(msg)
    class Panic(msg: String) : FxaException(msg)
}
