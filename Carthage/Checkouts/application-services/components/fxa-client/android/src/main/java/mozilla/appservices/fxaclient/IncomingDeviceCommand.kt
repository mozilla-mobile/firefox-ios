/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

data class TabHistoryEntry(
    val title: String,
    val url: String
)

sealed class IncomingDeviceCommand {
    // A tab with all its history entries (back button).
    class TabReceived(val from: Device?, val entries: Array<TabHistoryEntry>) : IncomingDeviceCommand()

    companion object {
        internal fun fromMessage(msg: MsgTypes.IncomingDeviceCommand): IncomingDeviceCommand {
            return when (msg.type) {
                MsgTypes.IncomingDeviceCommand.IncomingDeviceCommandType.TAB_RECEIVED -> {
                    val data = msg.tabReceivedData
                    TabReceived(
                        from = if (data.hasFrom()) Device.fromMessage(data.from) else null,
                        entries = data.entriesList.map {
                            TabHistoryEntry(title = it.title, url = it.url)
                        }.toTypedArray()
                    )
                }
                null -> throw NullPointerException("IncomingDeviceCommand type cannot be null.")
            }.exhaustive
        }
        internal fun fromCollectionMessage(msg: MsgTypes.IncomingDeviceCommands): Array<IncomingDeviceCommand> {
            return msg.commandsList.map {
                fromMessage(it)
            }.toTypedArray()
        }
    }
}
