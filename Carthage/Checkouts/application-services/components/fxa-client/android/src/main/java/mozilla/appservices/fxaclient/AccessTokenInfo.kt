/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

data class AccessTokenInfo(
    val scope: String,
    val token: String,
    val key: ScopedKey?,
    val expiresAt: Long
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.AccessTokenInfo): AccessTokenInfo {
            return AccessTokenInfo(
                    scope = msg.scope,
                    token = msg.token,
                    key = if (msg.hasKey()) ScopedKey.fromMessage(msg.key) else null,
                    expiresAt = msg.expiresAt
            )
        }
    }
}

data class ScopedKey(
    val kty: String,
    val scope: String,
    val k: String,
    val kid: String
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.ScopedKey): ScopedKey {
            return ScopedKey(
                    kty = msg.kty,
                    scope = msg.scope,
                    k = msg.k,
                    kid = msg.kid
            )
        }
    }
}
