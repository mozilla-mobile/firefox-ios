/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.syncmanager

/**
 * Base class for sync manager errors. Generally should not
 * have concrete instances.
 */
open class SyncManagerException(msg: String) : Exception(msg)

/**
 * General catch-all error, generally indicating API misuse of some sort.
 */
open class UnexpectedError(msg: String) : SyncManagerException(msg)

/**
 * The sync manager paniced. Please report these.
 */
open class InternalPanic(msg: String) : SyncManagerException(msg)

/**
 * We were asked to sync an engine which is either unknown, or which the sync
 * manager was not compiled with support for (message will elaborate).
 */
open class UnsupportedEngine(msg: String) : SyncManagerException(msg)

/**
 * We were asked to sync an engine but we couldn't because the connection is closed.
 *
 * Note: When not syncing, the manager holds a weak reference to connection
 * objects, and so performing something like: `SyncManager.setLogins(handle)`,
 * closing/locking the logins connection, and then trying to sync logins will
 * produce this error.
 */
open class ClosedEngine(msg: String) : SyncManagerException(msg)
