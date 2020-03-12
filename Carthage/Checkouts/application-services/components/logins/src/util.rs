/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use rusqlite::Row;
use std::time;
use url::Url;

pub fn url_host_port(url_str: &str) -> Option<String> {
    let url = Url::parse(url_str).ok()?;
    let host = url.host_str()?;
    Some(if let Some(p) = url.port() {
        format!("{}:{}", host, p)
    } else {
        host.to_string()
    })
}

pub fn system_time_millis_from_row(row: &Row<'_>, col_name: &str) -> Result<time::SystemTime> {
    let time_ms = row.get::<_, Option<i64>>(col_name)?.unwrap_or_default() as u64;
    Ok(time::UNIX_EPOCH + time::Duration::from_millis(time_ms))
}

pub fn duration_ms_i64(d: time::Duration) -> i64 {
    (d.as_secs() as i64) * 1000 + (i64::from(d.subsec_nanos()) / 1_000_000)
}

pub fn system_time_ms_i64(t: time::SystemTime) -> i64 {
    duration_ms_i64(t.duration_since(time::UNIX_EPOCH).unwrap_or_default())
}

// Unfortunately, there's not a better way to turn on logging in tests AFAICT
#[cfg(test)]
pub(crate) fn init_test_logging() {
    use std::sync::Once;
    static INIT_LOGGING: Once = Once::new();
    INIT_LOGGING.call_once(|| {
        env_logger::init_from_env(env_logger::Env::default().filter_or("RUST_LOG", "trace"));
    });
}
