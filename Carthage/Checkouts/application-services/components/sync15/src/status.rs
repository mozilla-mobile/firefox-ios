/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::{Error, ErrorKind, ErrorResponse};
use crate::telemetry::SyncTelemetryPing;
use std::collections::HashMap;
use std::time::{Duration, SystemTime};

/// The general status of sync - should probably be moved to the "sync manager"
/// once we have one!
#[derive(Debug, Clone, PartialEq)]
pub enum ServiceStatus {
    /// Everything is fine.
    Ok,
    /// Some general network issue.
    NetworkError,
    /// Some apparent issue with the servers.
    ServiceError,
    /// Some external FxA action needs to be taken.
    AuthenticationError,
    /// We declined to do anything for backoff or rate-limiting reasons.
    BackedOff,
    /// We were interrupted.
    Interrupted,
    /// Something else - you need to check the logs for more details. May
    /// or may not be transient, we really don't know.
    OtherError,
}

impl ServiceStatus {
    // This is a bit naive and probably will not survive in this form in the
    // SyncManager - eg, we'll want to handle backoff etc.
    pub fn from_err(err: &Error) -> ServiceStatus {
        match err.kind() {
            // HTTP based errors.
            ErrorKind::TokenserverHttpError(status) => {
                // bit of a shame the tokenserver is different to storage...
                if *status == 401 {
                    ServiceStatus::AuthenticationError
                } else {
                    ServiceStatus::ServiceError
                }
            }
            // BackoffError is also from the tokenserver.
            ErrorKind::BackoffError(_) => ServiceStatus::ServiceError,
            ErrorKind::StorageHttpError(ref e) => match e {
                ErrorResponse::Unauthorized { .. } => ServiceStatus::AuthenticationError,
                _ => ServiceStatus::ServiceError,
            },

            // Network errors.
            ErrorKind::RequestError(_)
            | ErrorKind::UnexpectedStatus(_)
            | ErrorKind::HawkError(_) => ServiceStatus::NetworkError,

            ErrorKind::Interrupted(_) => ServiceStatus::Interrupted,
            _ => ServiceStatus::OtherError,
        }
    }
}

/// The result of a sync request. This too is from the "sync manager", but only
/// has a fraction of the things it will have when we actually build that.
#[derive(Debug)]
pub struct SyncResult {
    /// The general health.
    pub service_status: ServiceStatus,

    /// The set of declined engines, if we know them.
    pub declined: Option<Vec<String>>,

    /// The result of the sync.
    pub result: Result<(), Error>,

    /// The result for each engine.
    /// Note that we expect the `String` to be replaced with an enum later.
    pub engine_results: HashMap<String, Result<(), Error>>,

    pub telemetry: SyncTelemetryPing,

    pub next_sync_after: Option<std::time::SystemTime>,
}

// If `r` has a BackoffError, then returns the later backoff value.
fn advance_backoff(cur_best: SystemTime, r: &Result<(), Error>) -> SystemTime {
    if let Err(e) = r {
        if let Some(time) = e.get_backoff() {
            return std::cmp::max(time, cur_best);
        }
    }
    cur_best
}

impl SyncResult {
    pub(crate) fn set_sync_after(&mut self, backoff_duration: Duration) {
        let now = SystemTime::now();
        let toplevel = advance_backoff(now + backoff_duration, &self.result);
        let sync_after = self
            .engine_results
            .values()
            .fold(toplevel, |b, r| advance_backoff(b, r));
        if sync_after <= now {
            self.next_sync_after = None;
        } else {
            self.next_sync_after = Some(sync_after);
        }
    }
}
