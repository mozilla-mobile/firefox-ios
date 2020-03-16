/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

/**
 * Config represents the server endpoint configurations needed for the
 * authentication flow.
 */
class Config constructor(val contentUrl: String, val clientId: String, val redirectUri: String) {

    enum class Server(val contentUrl: String) {
        RELEASE("https://accounts.firefox.com"),
        STABLE("https://stable.dev.lcip.org"),
        DEV("https://accounts.stage.mozaws.net"),
        CHINA("https://accounts.firefox.com.cn")
    }

    constructor(server: Server, clientId: String, redirectUri: String) :
        this(server.contentUrl, clientId, redirectUri)

    companion object {
        /**
         * Set up endpoints used in the production Firefox Accounts instance.
         *
         * @param clientId Client Id of the FxA relier
         * @param redirectUri Redirect Uri of the FxA relier
         */
        fun release(clientId: String, redirectUri: String): Config {
            return Config(Server.RELEASE.contentUrl, clientId, redirectUri)
        }

        /**
         * Set up endpoints used in the stable Firefox Accounts instance.
         *
         * @param clientId Client Id of the FxA relier
         * @param redirectUri Redirect Uri of the FxA relier
         */
        fun stable(clientId: String, redirectUri: String): Config {
            return Config(Server.STABLE.contentUrl, clientId, redirectUri)
        }

        /**
         * Set up endpoints used in the dev
         * Firefox Accounts instance.
         *
         * @param clientId Client Id of the FxA relier
         * @param redirectUri Redirect Uri of the FxA relier
         */
        fun dev(clientId: String, redirectUri: String): Config {
            return Config(Server.DEV.contentUrl, clientId, redirectUri)
        }

        /**
         * Set up endpoints used in the production Firefox Accounts China
         * instance.
         *
         * @param clientId Client Id of the FxA relier
         * @param redirectUri Redirect Uri of the FxA relier
         */
        fun china(clientId: String, redirectUri: String): Config {
            return Config(Server.CHINA.contentUrl, clientId, redirectUri)
        }
    }
}
