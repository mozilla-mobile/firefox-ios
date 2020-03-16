/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.remotetabs

data class ClientTabs(
    val clientId: String, // FxA device ID or the Sync client record ID if unavailable.
    val tabs: List<RemoteTab>
) {
    companion object {
        internal fun fromCollectionMessage(msg: MsgTypes.ClientsTabs): List<ClientTabs> {
            return msg.clientsTabsList.map { ClientTabs.fromMessage(it) }
        }
        private fun fromMessage(msg: MsgTypes.ClientTabs): ClientTabs {
            return ClientTabs(
                    clientId = msg.clientId,
                    tabs = msg.remoteTabsList.map { RemoteTab.fromMessage(it) }
            )
        }
    }
}

data class RemoteTab(
    val title: String,
    val urlHistory: List<String>,
    val icon: String?,
    val lastUsed: Long?
) {
    internal fun toProtobuf(): MsgTypes.RemoteTab {
        val builder = MsgTypes.RemoteTab.newBuilder()
        builder.setTitle(title)
        icon?.let {
            builder.setIcon(it)
        }
        lastUsed?.let {
            builder.setLastUsed(it)
        }
        builder.addAllUrlHistory(urlHistory)
        return builder.build()
    }

    companion object {
        internal fun fromMessage(msg: MsgTypes.RemoteTab): RemoteTab {
            return RemoteTab(
                    title = msg.title,
                    urlHistory = msg.urlHistoryList,
                    icon = msg.icon,
                    lastUsed = msg.lastUsed
            )
        }
    }
}
