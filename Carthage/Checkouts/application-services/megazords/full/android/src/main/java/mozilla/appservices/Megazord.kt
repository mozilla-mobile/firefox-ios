/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices

import org.mozilla.appservices.full_megazord.BuildConfig

class Megazord {
    companion object {
        @JvmStatic
        fun init() {
            System.setProperty("mozilla.appservices.megazord.library", "megazord")
            System.setProperty("mozilla.appservices.megazord.version", BuildConfig.LIBRARY_VERSION)
        }
    }
}
