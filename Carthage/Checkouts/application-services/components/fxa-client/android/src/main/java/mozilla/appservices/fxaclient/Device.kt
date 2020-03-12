/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.fxaclient

data class Device(
    val id: String,
    val displayName: String,
    val deviceType: Type,
    val pushSubscription: PushSubscription?,
    val pushEndpointExpired: Boolean,
    val isCurrentDevice: Boolean,
    val lastAccessTime: Long?,
    val capabilities: List<Capability>
) {
    enum class Capability {
        SEND_TAB;

        companion object {
            internal fun fromMessage(msg: MsgTypes.Device.Capability): Capability {
                return when (msg) {
                    MsgTypes.Device.Capability.SEND_TAB -> SEND_TAB
                }.exhaustive
            }
        }
    }

    enum class Type {
        DESKTOP,
        MOBILE,
        TABLET,
        VR,
        TV,
        UNKNOWN;

        companion object {
            internal fun fromMessage(msg: MsgTypes.Device.Type): Type {
                return when (msg) {
                    MsgTypes.Device.Type.DESKTOP -> DESKTOP
                    MsgTypes.Device.Type.MOBILE -> MOBILE
                    MsgTypes.Device.Type.TABLET -> TABLET
                    MsgTypes.Device.Type.VR -> VR
                    MsgTypes.Device.Type.TV -> TV
                    else -> UNKNOWN
                }
            }
        }

        fun toNumber(): Int {
            // the number resolves to values in fxa_msg_types.proto#L41
            return when (this) {
                DESKTOP -> MsgTypes.Device.Type.DESKTOP.number
                MOBILE -> MsgTypes.Device.Type.MOBILE.number
                TABLET -> MsgTypes.Device.Type.TABLET.number
                VR -> MsgTypes.Device.Type.VR.number
                TV -> MsgTypes.Device.Type.TV.number
                else -> MsgTypes.Device.Type.UNKNOWN.number
            }
        }
    }
    data class PushSubscription(
        val endpoint: String,
        val publicKey: String,
        val authKey: String
    ) {
        companion object {
            internal fun fromMessage(msg: MsgTypes.Device.PushSubscription): PushSubscription {
                return PushSubscription(
                        endpoint = msg.endpoint,
                        publicKey = msg.publicKey,
                        authKey = msg.authKey
                )
            }
        }
    }
    companion object {
        internal fun fromMessage(msg: MsgTypes.Device): Device {
            return Device(
                    id = msg.id,
                    displayName = msg.displayName,
                    deviceType = Type.fromMessage(msg.type),
                    pushSubscription = if (msg.hasPushSubscription()) {
                        PushSubscription.fromMessage(msg.pushSubscription)
                    } else null,
                    pushEndpointExpired = msg.pushEndpointExpired,
                    isCurrentDevice = msg.isCurrentDevice,
                    lastAccessTime = if (msg.hasLastAccessTime()) msg.lastAccessTime else null,
                    capabilities = msg.capabilitiesList.map { Capability.fromMessage(it) }
            )
        }
        internal fun fromCollectionMessage(msg: MsgTypes.Devices): Array<Device> {
            return msg.devicesList.map {
                fromMessage(it)
            }.toTypedArray()
        }
    }
}

fun Set<Device.Capability>.toCollectionMessage(): MsgTypes.Capabilities {
    val builder = MsgTypes.Capabilities.newBuilder()
    this.forEach {
        when (it) {
            Device.Capability.SEND_TAB -> builder.addCapability(MsgTypes.Device.Capability.SEND_TAB)
        }.exhaustive
    }
    return builder.build()
}
