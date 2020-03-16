/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.logins

/**
 * Raw password data that is stored by the LoginsStorage implementation.
 */
data class ServerPassword(

    /**
     * The unique ID associated with this login.
     *
     * It is recommended that you not make assumptions about its format, but in practice it is
     * typically (but not guaranteed to be) either 12 random Base64URL-safe characters or a
     * UUID-v4 surrounded in curly-braces.
     */
   val id: String,

    /**
     * The hostname this record corresponds to. It is an error to
     * attempt to insert or update a record to have a blank hostname.
     */
    val hostname: String,

    val username: String,

    /**
     * The password field of this record. It is an error to attempt to insert or update
     * a record to have a blank password.
     */
    val password: String,

    /**
     * The HTTP realm, which is the challenge string for HTTP Basic Auth. May be null in the case
     * that this login has a formSubmitURL instead.
     */
    val httpRealm: String? = null,

    /**
     * The formSubmitURL (as a string). This may be null in the case that this login has a
     * httpRealm instead.
     */
    val formSubmitURL: String? = null,

    /**
     * Number of times this password has been used.
     */
    val timesUsed: Int = 0,

    /**
     * Time of creation in milliseconds from the unix epoch.
     */
    val timeCreated: Long = 0L,

    /**
     * Time of last use in milliseconds from the unix epoch.
     */
    val timeLastUsed: Long = 0L,

    /**
     * Time of last password change in milliseconds from the unix epoch.
     */
    val timePasswordChanged: Long = 0L,

    val usernameField: String,
    val passwordField: String
) {

    fun toProtobuf(): MsgTypes.PasswordInfo {
        val builder = MsgTypes.PasswordInfo.newBuilder()
                .setId(this.id)
                .setHostname(this.hostname)
                .setPassword(this.password)
                .setUsername(this.username)
                .setUsernameField(this.usernameField)
                .setPasswordField(this.passwordField)
                .setTimesUsed(this.timesUsed.toLong())
                .setTimeCreated(this.timeCreated)
                .setTimeLastUsed(this.timeLastUsed)
                .setTimePasswordChanged(this.timePasswordChanged)
        this.formSubmitURL?.let { builder.setFormSubmitURL(it) }
        this.httpRealm?.let { builder.setHttpRealm(it) }
        return builder.build()
    }

    companion object {

        fun fromMessage(msg: MsgTypes.PasswordInfo): ServerPassword {
            return ServerPassword(
                id = msg.id,
                hostname = msg.hostname,
                username = msg.username,
                password = msg.password,
                httpRealm = if (msg.hasHttpRealm()) msg.httpRealm else null,
                formSubmitURL = if (msg.hasFormSubmitURL()) msg.formSubmitURL else null,
                timesUsed = msg.timesUsed.toInt(),
                timeCreated = msg.timeCreated,
                timeLastUsed = msg.timeLastUsed,
                timePasswordChanged = msg.timePasswordChanged,
                usernameField = msg.usernameField,
                passwordField = msg.passwordField
            )
        }

        fun fromCollectionMessage(msgs: MsgTypes.PasswordInfos): List<ServerPassword> {
            return msgs.infosList.map {
                fromMessage(it)
            }
        }
    }
}

fun Array<ServerPassword>.toCollectionMessage(): MsgTypes.PasswordInfos {
    val builder = MsgTypes.PasswordInfos.newBuilder()
    this.forEach {
        builder.addInfos(it.toProtobuf())
    }
    return builder.build()
}
