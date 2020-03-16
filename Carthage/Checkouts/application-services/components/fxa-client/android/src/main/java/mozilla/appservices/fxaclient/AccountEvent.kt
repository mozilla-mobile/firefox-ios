/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

// https://proandroiddev.com/til-when-is-when-exhaustive-31d69f630a8b
val <T> T.exhaustive: T
    get() = this

sealed class AccountEvent {
    // A tab with all its history entries (back button).
    class IncomingDeviceCommand(val command: mozilla.appservices.fxaclient.IncomingDeviceCommand) : AccountEvent()
    class ProfileUpdated : AccountEvent()
    class AccountAuthStateChanged : AccountEvent()
    class AccountDestroyed : AccountEvent()
    class DeviceConnected(val deviceName: String) : AccountEvent()
    class DeviceDisconnected(val deviceId: String, val isLocalDevice: Boolean) : AccountEvent()

    companion object {
        private fun fromMessage(msg: MsgTypes.AccountEvent): AccountEvent {
            return when (msg.type) {
                MsgTypes.AccountEvent.AccountEventType.INCOMING_DEVICE_COMMAND -> IncomingDeviceCommand(
                    command = mozilla.appservices.fxaclient.IncomingDeviceCommand.fromMessage(msg.deviceCommand)
                )
                MsgTypes.AccountEvent.AccountEventType.PROFILE_UPDATED -> ProfileUpdated()
                MsgTypes.AccountEvent.AccountEventType.ACCOUNT_AUTH_STATE_CHANGED -> AccountAuthStateChanged()
                MsgTypes.AccountEvent.AccountEventType.ACCOUNT_DESTROYED -> AccountDestroyed()
                MsgTypes.AccountEvent.AccountEventType.DEVICE_CONNECTED -> DeviceConnected(
                    deviceName = msg.deviceConnectedName
                )
                MsgTypes.AccountEvent.AccountEventType.DEVICE_DISCONNECTED -> DeviceDisconnected(
                    deviceId = msg.deviceDisconnectedData.deviceId,
                    isLocalDevice = msg.deviceDisconnectedData.isLocalDevice
                )
                null -> throw NullPointerException("AccountEvent type cannot be null.")
            }.exhaustive
        }
        internal fun fromCollectionMessage(msg: MsgTypes.AccountEvents): Array<AccountEvent> {
            return msg.eventsList.map {
                fromMessage(it)
            }.toTypedArray()
        }
    }
}
