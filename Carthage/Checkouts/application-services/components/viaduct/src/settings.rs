/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::time::Duration;

/// Note: reqwest allows these only to be specified per-Client. concept-fetch
/// allows these to be specified on each call to fetch. I think it's worth
/// keeping a single global reqwest::Client in the reqwest backend, to simplify
/// the way we abstract away from these.
///
/// In the future, should we need it, we might be able to add a CustomClient type
/// with custom settings. In the reqwest backend this would store a Client, and
/// in the concept-fetch backend it would only store the settings, and populate
/// things on the fly.
#[derive(Debug, PartialEq)]
pub(crate) struct Settings {
    pub read_timeout: Option<Duration>,
    pub connect_timeout: Option<Duration>,
    pub follow_redirects: bool,
    pub include_cookies: bool,
    pub use_caches: bool,
    _priv: (),
}

#[cfg(target_os = "ios")]
const TIMEOUT_DURATION: Duration = Duration::from_secs(30);

#[cfg(not(target_os = "ios"))]
const TIMEOUT_DURATION: Duration = Duration::from_secs(10);

// The singleton instance of our settings.
pub(crate) static GLOBAL_SETTINGS: &Settings = &Settings {
    read_timeout: Some(TIMEOUT_DURATION),
    connect_timeout: Some(TIMEOUT_DURATION),
    follow_redirects: true,
    include_cookies: false,
    use_caches: false,
    _priv: (),
};
