/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.remotetabs

open class RemoteTabProviderException(msg: String) : Exception(msg)

/** This indicates that the sync authentication is invalid, likely due to having
 * expired.
 */
class SyncAuthInvalidException(msg: String) : RemoteTabProviderException(msg)

/**
 * This error is emitted if a request to a sync server failed.
 */
class RequestFailedException(msg: String) : RemoteTabProviderException(msg)
