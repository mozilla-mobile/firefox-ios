/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

data class IntrospectInfo(
    val active: Boolean,
    val tokenType: String,
    val scope: String?,
    val exp: Long,
    val iss: String
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.IntrospectInfo): IntrospectInfo {
            return IntrospectInfo(
                active = msg.active,
                tokenType = msg.tokenType,
                scope = if (msg.hasScope()) msg.scope else null,
                exp = msg.exp,
                iss = msg.iss
            )
        }
    }
}
