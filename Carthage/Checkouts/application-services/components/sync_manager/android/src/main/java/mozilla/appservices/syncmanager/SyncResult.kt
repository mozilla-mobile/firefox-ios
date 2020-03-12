/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.syncmanager

import mozilla.appservices.sync15.SyncTelemetryPing

/**
 * Indicates, at a high level whether the sync succeeded or failed.
 */
enum class SyncServiceStatus {
    /**
     * The sync did not fail.
     */
    OK,

    /**
     * The sync failed due to network problems.
     */
    NETWORK_ERROR,

    /**
     * The sync failed due to some apparent error with the servers.
     */
    SERVICE_ERROR,

    /**
     * The auth information we were provided was somehow invalid. Refreshing it
     * with FxA may resolve this issue.
     */
    AUTH_ERROR,

    /**
     * Indicates that we declined to sync because the server had requested a
     * backoff which has not yet expired.
     */
    BACKED_OFF,

    /**
     * Some other error occurred.
     */
    OTHER_ERROR,
}

/**
 * The result of a sync.
 */
data class SyncResult(
    /**
     * The general health.
     */
    val status: SyncServiceStatus,

    /**
     * For engines which failed to sync, contains a string
     * description of the error.
     *
     * The error strings are mostly provided for local debugging,
     * and more robust information is present in e.g. telemetry.
     */
    val failures: Map<String, String>,

    /**
     * The list of engines which synced without any errors.
     */
    val successful: List<String>,

    /**
     * The state string that should be persisted by the caller, and
     * used as the value for `SyncParams.persistedState` in subsequent
     * calls to `SyncManager.sync`.
     */
    val persistedState: String,

    /**
     * The list of engines which have been declined by the user.
     *
     * Null if we didn't make it far enough to know.
     */
    val declined: List<String>?,

    /**
     * The next time we're allowed to sync, in milliseconds since
     * the unix epoch, or null if there are no known restrictions on
     * the next time we can sync.
     *
     * If this value is in the future, then there's some kind of back-off.
     * Note that it's not necessary for the app to enforce this, but should
     * probably be used as an input in the application's sync scheduling logic.
     *
     * Syncs before this passes will generally fail with a BACKED_OFF error,
     * unless they are syncs that were manually requested by the user (that
     * is, they have the reason `SyncReason.USER`).
     */
    val nextSyncAllowedAt: Long?,

    /**
     * A bundle of telemetry information recorded during this sync.
     */
    val telemetry: SyncTelemetryPing?
) {
    companion object {
        @Suppress("ComplexMethod")
        internal fun fromProtobuf(pb: MsgTypes.SyncResult): SyncResult {
            val nextSyncAllowedAt = if (pb.hasNextSyncAllowedAt()) {
                pb.nextSyncAllowedAt
            } else {
                null
            }

            val declined = if (pb.haveDeclined) {
                pb.declinedList
            } else {
                null
            }

            val successful = pb.resultsMap.entries
                .filter { it.value.isEmpty() }
                .map { it.key }
                .toList()

            val failures = pb.resultsMap.filter { it.value.isNotEmpty() }

            val telemetry = if (pb.hasTelemetryJson()) {
                SyncTelemetryPing.fromJSONString(pb.telemetryJson)
            } else {
                null
            }

            val status = when (pb.status) {
                MsgTypes.ServiceStatus.OK -> SyncServiceStatus.OK
                MsgTypes.ServiceStatus.NETWORK_ERROR -> SyncServiceStatus.NETWORK_ERROR
                MsgTypes.ServiceStatus.SERVICE_ERROR -> SyncServiceStatus.SERVICE_ERROR
                MsgTypes.ServiceStatus.AUTH_ERROR -> SyncServiceStatus.AUTH_ERROR
                MsgTypes.ServiceStatus.BACKED_OFF -> SyncServiceStatus.BACKED_OFF
                MsgTypes.ServiceStatus.OTHER_ERROR -> SyncServiceStatus.OTHER_ERROR
                else -> SyncServiceStatus.OTHER_ERROR // impossible *sigh*
            }

            return SyncResult(
                status = status,
                failures = failures,
                successful = successful,
                declined = declined,
                telemetry = telemetry,
                nextSyncAllowedAt = nextSyncAllowedAt,
                persistedState = pb.persistedState
            )
        }
    }
}
