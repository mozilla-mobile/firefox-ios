/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

data class Profile(
    val uid: String?,
    val email: String?,
    val avatar: String?,
    val avatarDefault: Boolean,
    val displayName: String?
) {
    companion object {
        internal fun fromMessage(msg: MsgTypes.Profile): Profile {
            return Profile(uid = if (msg.hasUid()) msg.uid else null,
                email = if (msg.hasEmail()) msg.email else null,
                avatar = if (msg.hasAvatar()) msg.avatar else null,
                avatarDefault = msg.avatarDefault,
                displayName = if (msg.hasDisplayName()) msg.displayName else null
            )
        }
    }
}
