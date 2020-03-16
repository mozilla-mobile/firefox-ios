/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

enum class MigrationState {
    NONE,
    COPY_SESSION_TOKEN,
    REUSE_SESSION_TOKEN;

    companion object {
        @Suppress("TooGenericExceptionThrown")
        internal fun fromNumber(v: Number): MigrationState {
            return when (v) {
                0 -> NONE
                1 -> COPY_SESSION_TOKEN
                2 -> REUSE_SESSION_TOKEN
                else -> throw RuntimeException("[Bug] unknown MigrationState value $v")
            }
        }
    }
}
