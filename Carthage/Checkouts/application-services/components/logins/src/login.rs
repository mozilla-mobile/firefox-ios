/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//  N.B. if you're making a documentation change here, you might also want to make it in:
//
//    * The API docs in ../ios/Logins/LoginRecord.swift
//    * The API docs in ../android/src/main/java/mozilla/appservices/logins/ServerPassword.kt
//    * The android-components docs at
//      https://github.com/mozilla-mobile/android-components/tree/master/components/service/sync-logins
//
//  We'll figure out a more scalable approach to maintaining all those docs at some point...

//!
//! Login Records
//! =============
//!
//! The core datatype managed by this component is a "login record", which contains the following fields:
//!
//! - `id`:  A unique string identifier for this record.
//!
//!   Consumers may assume that `id` contains only "safe" ASCII characters but should otherwise
//!   treat this it as an opaque identifier. It should be left blank when adding a new record,
//!   in which case a new id will be automatically generated.
//!
//! - `hostname`:  The origin at which this login can be used, as a string.
//!
//!   The login should only be used on sites that match this origin (for whatever definition
//!   of "matches" makes sense at the application level, e.g. eTLD+1 matching).
//!   This field is required, must be a valid origin in punycode format, and must not be
//!   set to the empty string.
//!
//!   **YES, THIS FIELD IS CONFUSINGLY NAMED. IT SHOULD BE A FULL ORIGIN, NOT A HOSTNAME.
//!   WE INTEND TO RENAME THIS TO `origin` IN A FUTURE RELEASE.**
//!
//!   Examples of valid `hostname` values include:
//!   - "https://site.com"
//!   - "http://site.com:1234"
//!   - "ftp://ftp.site.com"
//!   - "moz-proxy://127.0.0.1:8888"
//!   - "chrome://MyLegacyExtension"
//!   - "file://"
//!   - "https://[::1]"
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - truncating full URLs to just their origin component, if it is not an opaque origin
//!   - converting values with non-ascii characters into punycode
//!
//!   **XXX TODO:**
//!   - return a "display" field (exact name TBD) in the serialized
//!     version, which will be the unicode version of punycode urls.
//!   - the great renaming
//!
//! - `password`:  The saved password, as a string.
//!
//!   This field is required, and must not be set to the empty string. It must not contain
//!   null bytes, but can otherwise be an arbitrary unicode string.
//!
//! - `username`:  The username associated with this login, if any, as a string.
//!
//!   This field is required, but may be set to the empty string if no username is associated
//!   with the login. It must not contain null bytes, but can otherwise be an arbitrary unicode
//!   string.
//!
//! - `httpRealm`:  The challenge string for HTTP Basic authentication, if any.
//!
//!   If present, the login should only be used in response to a HTTP Basic Auth
//!   challenge that specifies a matching realm. For legacy reasons this string may not
//!   contain null bytes, carriage returns or newlines.
//!
//!   If this field is set to the empty string, this indicates a wildcard match on realm.
//!
//!   This field must not be present if `formSubmitURL` is set, since they indicate different types
//!   of login (HTTP-Auth based versus form-based). Exactly one of `httpRealm` and `formSubmitURL`
//!   must be present.
//!
//! - `formSubmitURL`:  The target origin of forms in which this login can be used, if any, as a string.
//!
//!   If present, the login should only be used in forms whose target submission URL matches this origin.
//!   This field must be a valid origin or one of the following special cases:
//!   - An empty string, which is a wildcard match for any origin.
//!   - The single character ".", which is equivalent to the empty string
//!   - The string "javascript:", which matches any form with javascript target URL.
//!
//!   **YES, THIS FIELD IS CONFUSINGLY NAMED. IT SHOULD BE AN ORIGIN, NOT A FULL URL. WE INTEND TO
//!   RENAME THIS TO `formActionOrigin` IN A FUTURE RELEASE.**
//!
//!   This field must not be present if `httpRealm` is set, since they indicate different types of login
//!   (HTTP-Auth based versus form-based). Exactly one of `httpRealm` and `formSubmitURL` must be present.
//!
//!   If invalid data is received in this field (either from the application, or via sync) then the
//!   logins store will attempt to coerce it into valid data by:
//!   - truncating full URLs to just their origin component
//!   - converting origins with non-ascii characters into punycode
//!   - replacing invalid values with null if a valid 'httpRealm' field is present
//!
//!   **XXX TODO**:
//!   - return a "display" field (exact name TBD) in the serialized
//!     version, which will be the unicode version of punycode urls.
//!   - the great renaming (maybe we can do the punycode thing at the same time?)
//!
//! - `usernameField`:  The name of the form field into which the 'username' should be filled, if any.
//!
//!   This value is stored if provided by the application, but does not imply any restrictions on
//!   how the login may be used in practice. For legacy reasons this string may not contain null
//!   bytes, carriage returns or newlines. This field must be empty unless `formSubmitURL` is set.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - setting to the empty string if 'formSubmitURL' is not present
//!
//! - `passwordField`:  The name of the form field into which the 'password' should be filled, if any.
//!
//!   This value is stored if provided by the application, but does not imply any restrictions on
//!   how the login may be used in practice. For legacy reasons this string may not contain null
//!   bytes, carriage returns or newlines. This field must be empty unless `formSubmitURL` is set.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - setting to the empty string if 'formSubmitURL' is not present
//!
//! - `timesUsed`:  A lower bound on the number of times the password from this record has been used, as an integer.
//!
//!   Applications should use the `touch()` method of the logins store to indicate when a password
//!   has been used, and should ensure that they only count uses of the actual `password` field
//!   (so for example, copying the `password` field to the clipboard should count as a "use", but
//!   copying just the `username` field should not).
//!
//!   This number may not record uses that occurred on other devices, since some legacy
//!   sync clients do not record this information. It may be zero for records obtained
//!   via sync that have never been used locally.
//!
//!   When merging duplicate records, the two usage counts are summed.
//!
//!   This field is managed internally by the logins store by default and does not need to
//!   be set explicitly, although any application-provided value will be preserved when creating
//!   a new record.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - replacing missing or negative values with 0
//!
//!   **XXX TODO:**
//!   - test that we prevent this counter from moving backwards.
//!   - test fixups of missing or negative values
//!   - test that we correctly merge dupes
//!
//! - `timeCreated`: An upper bound on the time of creation of this login, in integer milliseconds from the unix epoch.
//!
//!   This is an upper bound because some legacy sync clients do not record this information.
//!
//!   Note that this field is typically a timestamp taken from the local machine clock, so it
//!   may be wildly inaccurate if the client does not have an accurate clock.
//!
//!   This field is managed internally by the logins store by default and does not need to
//!   be set explicitly, although any application-provided value will be preserved when creating
//!   a new record.
//!
//!   When merging duplicate records, the smallest non-zero value is taken.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - replacing missing or negative values with the current time
//!
//!   **XXX TODO:**
//!   - test that we prevent this timestamp from moving backwards.
//!   - test fixups of missing or negative values
//!   - test that we correctly merge dupes
//!
//! - `timeLastUsed`: A lower bound on the time of last use of this login, in integer milliseconds from the unix epoch.
//!
//!   This is a lower bound because some legacy sync clients do not record this information;
//!   in that case newer clients set `timeLastUsed` when they use the record for the first time.
//!
//!   Note that this field is typically a timestamp taken from the local machine clock, so it
//!   may be wildly inaccurate if the client does not have an accurate clock.
//!
//!   This field is managed internally by the logins store by default and does not need to
//!   be set explicitly, although any application-provided value will be preserved when creating
//!   a new record.
//!
//!   When merging duplicate records, the largest non-zero value is taken.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - removing negative values
//!
//!   **XXX TODO:**
//!   - test that we prevent this timestamp from moving backwards.
//!   - test fixups of missing or negative values
//!   - test that we correctly merge dupes
//!
//! - `timePasswordChanged`: A lower bound on the time that the `password` field was last changed, in integer
//!                          milliseconds from the unix epoch.
//!
//!   Changes to other fields (such as `username`) are not reflected in this timestamp.
//!   This is a lower bound because some legacy sync clients do not record this information;
//!   in that case newer clients set `timePasswordChanged` when they change the `password` field.
//!
//!   Note that this field is typically a timestamp taken from the local machine clock, so it
//!   may be wildly inaccurate if the client does not have an accurate clock.
//!
//!   This field is managed internally by the logins store by default and does not need to
//!   be set explicitly, although any application-provided value will be preserved when creating
//!   a new record.
//!
//!   When merging duplicate records, the largest non-zero value is taken.
//!
//!   If invalid data is received in this field (either from the application, or via sync)
//!   then the logins store will attempt to coerce it into valid data by:
//!   - removing negative values
//!
//!   **XXX TODO:**
//!   - test that we prevent this timestamp from moving backwards.
//!   - test that we don't set this for changes to other fields.
//!   - test that we correctly merge dupes
//!
//! In order to deal with data from legacy clients in a robust way, it is necessary to be able to build
//! and manipulate `Login` structs that contain invalid data.  The following methods can be used by callers
//! to ensure that they're only working with valid records:
//!
//! - `Login::check_valid()`:    Checks valdity of a login record, returning `()` if it is valid
//!                              or an error if it is not.
//!
//! - `Login::fixup()`:   Returns either the existing login if it is valid, a clone with invalid fields
//!                       fixed up if it was safe to do so, or an error if the login is irreparably invalid.

use crate::error::*;
use crate::msg_types::PasswordInfo;
use crate::util;
use rusqlite::Row;
use serde_derive::*;
use std::time::{self, SystemTime};
use sync15::ServerTimestamp;
use sync_guid::Guid;
use url::Url;

#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Login {
    #[serde(rename = "id")]
    pub guid: Guid,

    pub hostname: String,

    // rename_all = "camelCase" by default will do formSubmitUrl, but we can just
    // override this one field.
    #[serde(rename = "formSubmitURL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub form_submit_url: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub http_realm: Option<String>,

    #[serde(default)]
    pub username: String,

    pub password: String,

    #[serde(default)]
    pub username_field: String,

    #[serde(default)]
    pub password_field: String,

    #[serde(default)]
    #[serde(deserialize_with = "deserialize_timestamp")]
    pub time_created: i64,

    #[serde(default)]
    #[serde(deserialize_with = "deserialize_timestamp")]
    pub time_password_changed: i64,

    #[serde(default)]
    #[serde(deserialize_with = "deserialize_timestamp")]
    pub time_last_used: i64,

    #[serde(default)]
    pub times_used: i64,
}

fn deserialize_timestamp<'de, D>(deserializer: D) -> std::result::Result<i64, D::Error>
where
    D: serde::de::Deserializer<'de>,
{
    use serde::de::Deserialize;
    // Invalid and negative timestamps are all replaced with 0. Eventually we
    // should investigate replacing values that are unreasonable but still fit
    // in an i64 (a date 1000 years in the future, for example), but
    // appropriately handling that is complex.
    Ok(i64::deserialize(deserializer).unwrap_or_default().max(0))
}

fn string_or_default(row: &Row<'_>, col: &str) -> Result<String> {
    Ok(row.get::<_, Option<String>>(col)?.unwrap_or_default())
}

impl Login {
    #[inline]
    pub fn guid(&self) -> &Guid {
        &self.guid
    }

    #[inline]
    pub fn guid_str(&self) -> &str {
        self.guid.as_str()
    }

    /// Checks whether the Login is valid, without attempting to fix any fields.
    /// Returns an error if invalid data is found, even if it could have been fixed.
    pub fn check_valid(&self) -> Result<()> {
        self.validate_and_fixup(false)?;
        Ok(())
    }

    /// Return either the existing login, a fixed-up verion, or an error.
    /// This consumes `self` to make it easy for callers to unconditionally
    /// replace a Login with an owned fixed-up version, preventing them from
    /// using one that is invalid.
    pub fn fixup(self) -> Result<Self> {
        match self.maybe_fixup()? {
            None => Ok(self),
            Some(login) => Ok(login),
        }
    }

    /// Like `fixup()` above, but takes `self` by reference and returns
    /// an Option for the fixed-up version, allowing the caller to make
    /// more choices about what to do next.
    pub fn maybe_fixup(&self) -> Result<Option<Self>> {
        self.validate_and_fixup(true)
    }

    /// Internal helper for validation and fixups of an "origin" stored as
    /// a string.
    fn validate_and_fixup_origin(origin: &str) -> Result<Option<String>> {
        // Check we can parse the origin, then use the normalized version of it.
        match Url::parse(&origin) {
            Ok(mut u) => {
                // Presumably this is a faster path than always setting?
                if u.path() != "/"
                    || u.fragment().is_some()
                    || u.query().is_some()
                    || u.username() != "/"
                    || u.password().is_some()
                {
                    // Not identical - we only want the origin part, so kill
                    // any other parts which may exist.
                    // But first special case `file://` URLs which always
                    // resolve to `file://`
                    if u.scheme() == "file" {
                        return Ok(if origin == "file://" {
                            None
                        } else {
                            Some("file://".into())
                        });
                    }
                    u.set_path("");
                    u.set_fragment(None);
                    u.set_query(None);
                    let _ = u.set_username("");
                    let _ = u.set_password(None);
                    let mut href = u.into_string();
                    // We always store without the trailing "/" which Urls have.
                    if href.ends_with('/') {
                        href.pop().expect("url must have a length");
                    }
                    if origin != href {
                        // Needs to be fixed up.
                        return Ok(Some(href));
                    }
                }
                Ok(None)
            }
            Err(_) => {
                // We can't fixup completely invalid records, so always throw.
                throw!(InvalidLogin::IllegalFieldValue {
                    field_info: "Origin is Malformed".into()
                });
            }
        }
    }

    /// Internal helper for doing validation and fixups.
    fn validate_and_fixup(&self, fixup: bool) -> Result<Option<Self>> {
        // XXX TODO: we've definitely got more validation and fixups to add here!

        let mut maybe_fixed = None;

        /// A little helper to magic a Some(self.clone()) into existence when needed.
        macro_rules! get_fixed_or_throw {
            ($err:expr) => {
                // This is a block expression returning a local variable,
                // entirely so we can give it an explicit type declaration.
                {
                    if !fixup {
                        throw!($err)
                    }
                    log::warn!("Fixing login record {}: {:?}", self.guid, $err);
                    let fixed: Result<&mut Login> =
                        Ok(maybe_fixed.get_or_insert_with(|| self.clone()));
                    fixed
                }
            };
        };

        if self.hostname.is_empty() {
            throw!(InvalidLogin::EmptyOrigin);
        }

        if self.password.is_empty() {
            throw!(InvalidLogin::EmptyPassword);
        }

        if self.form_submit_url.is_some() && self.http_realm.is_some() {
            get_fixed_or_throw!(InvalidLogin::BothTargets)?.http_realm = None;
        }

        if self.form_submit_url.is_none() && self.http_realm.is_none() {
            throw!(InvalidLogin::NoTarget);
        }

        let form_submit_url = self.form_submit_url.clone().unwrap_or_default();
        let http_realm = maybe_fixed
            .as_ref()
            .unwrap_or(self)
            .http_realm
            .clone()
            .unwrap_or_default();

        let field_data = [
            ("formSubmitUrl", &form_submit_url),
            ("httpRealm", &http_realm),
            ("hostname", &self.hostname),
            ("usernameField", &self.username_field),
            ("passwordField", &self.password_field),
            ("username", &self.username),
            ("password", &self.password),
        ];

        for (field_name, field_value) in &field_data {
            // Nuls are invalid.
            if field_value.contains('\0') {
                throw!(InvalidLogin::IllegalFieldValue {
                    field_info: format!("`{}` contains Nul", field_name)
                });
            }

            // Newlines are invalid in Desktop with the exception of the username
            // and password fields.
            if field_name != &"username"
                && field_name != &"password"
                && (field_value.contains('\n') || field_value.contains('\r'))
            {
                throw!(InvalidLogin::IllegalFieldValue {
                    field_info: format!("`{}` contains newline", field_name)
                });
            }
        }

        // Desktop doesn't like fields with the below patterns
        if self.username_field == "." {
            throw!(InvalidLogin::IllegalFieldValue {
                field_info: "`usernameField` is a period".into()
            });
        }

        // Check we can parse the origin, then use the normalized version of it.
        if let Some(fixed) = Login::validate_and_fixup_origin(&self.hostname)? {
            get_fixed_or_throw!(InvalidLogin::IllegalFieldValue {
                field_info: "Origin is not normalized".into()
            })?
            .hostname = fixed;
        }

        match &maybe_fixed.as_ref().unwrap_or(self).form_submit_url {
            None => {
                if !self.username_field.is_empty() {
                    get_fixed_or_throw!(InvalidLogin::IllegalFieldValue {
                        field_info: "usernameField must be empty when formSubmitURL is null".into()
                    })?
                    .username_field
                    .clear();
                }
                if !self.password_field.is_empty() {
                    get_fixed_or_throw!(InvalidLogin::IllegalFieldValue {
                        field_info: "passwordField must be empty when formSubmitURL is null".into()
                    })?
                    .password_field
                    .clear();
                }
            }
            Some(href) => {
                // "." and "javascript:" are special cases documented at the top of this file.
                if href == "." {
                    // A bit of a special case - if we are being asked to fixup, we replace
                    // "." with an empty string - but if not fixing up we don't complain.
                    if fixup {
                        maybe_fixed
                            .get_or_insert_with(|| self.clone())
                            .form_submit_url = Some("".into());
                    }
                } else if href != "javascript:" {
                    if let Some(fixed) = Login::validate_and_fixup_origin(&href)? {
                        get_fixed_or_throw!(InvalidLogin::IllegalFieldValue {
                            field_info: "formActionOrigin is not normalized".into()
                        })?
                        .form_submit_url = Some(fixed);
                    }
                }
            }
        }

        Ok(maybe_fixed)
    }

    pub(crate) fn from_row(row: &Row<'_>) -> Result<Login> {
        let login = Login {
            guid: row.get("guid")?,
            password: row.get("password")?,
            username: string_or_default(row, "username")?,

            hostname: row.get("hostname")?,
            http_realm: row.get("httpRealm")?,

            form_submit_url: row.get("formSubmitURL")?,

            username_field: string_or_default(row, "usernameField")?,
            password_field: string_or_default(row, "passwordField")?,

            time_created: row.get("timeCreated")?,
            // Might be null
            time_last_used: row
                .get::<_, Option<i64>>("timeLastUsed")?
                .unwrap_or_default(),

            time_password_changed: row.get("timePasswordChanged")?,
            times_used: row.get("timesUsed")?,
        };
        // For now, we want to apply fixups but still return the record if
        // there is unfixably invalid data in the db.
        Ok(login.maybe_fixup().unwrap_or(None).unwrap_or(login))
    }
}

impl From<Login> for PasswordInfo {
    fn from(login: Login) -> Self {
        Self {
            id: login.guid.into_string(),
            hostname: login.hostname,
            password: login.password,
            username: login.username,
            http_realm: login.http_realm,
            form_submit_url: login.form_submit_url,
            username_field: login.username_field,
            password_field: login.password_field,
            times_used: login.times_used,
            time_created: login.time_created,
            time_last_used: login.time_last_used,
            time_password_changed: login.time_password_changed,
        }
    }
}

impl From<PasswordInfo> for Login {
    fn from(info: PasswordInfo) -> Self {
        Self {
            guid: Guid::from_string(info.id),
            hostname: info.hostname,
            password: info.password,
            username: info.username,
            http_realm: info.http_realm,
            form_submit_url: info.form_submit_url,
            username_field: info.username_field,
            password_field: info.password_field,
            times_used: info.times_used,
            time_created: info.time_created,
            time_last_used: info.time_last_used,
            time_password_changed: info.time_password_changed,
        }
    }
}

#[derive(Clone, Debug)]
pub(crate) struct MirrorLogin {
    pub login: Login,
    pub is_overridden: bool,
    pub server_modified: ServerTimestamp,
}

impl MirrorLogin {
    #[inline]
    pub fn guid_str(&self) -> &str {
        self.login.guid_str()
    }

    pub(crate) fn from_row(row: &Row<'_>) -> Result<MirrorLogin> {
        Ok(MirrorLogin {
            login: Login::from_row(row)?,
            is_overridden: row.get("is_overridden")?,
            server_modified: ServerTimestamp(row.get::<_, i64>("server_modified")?),
        })
    }
}

// This doesn't really belong here.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
#[repr(u8)]
pub(crate) enum SyncStatus {
    Synced = 0,
    Changed = 1,
    New = 2,
}

impl SyncStatus {
    #[inline]
    pub fn from_u8(v: u8) -> Result<Self> {
        match v {
            0 => Ok(SyncStatus::Synced),
            1 => Ok(SyncStatus::Changed),
            2 => Ok(SyncStatus::New),
            v => throw!(ErrorKind::BadSyncStatus(v)),
        }
    }
}

#[derive(Clone, Debug)]
pub(crate) struct LocalLogin {
    pub login: Login,
    pub sync_status: SyncStatus,
    pub is_deleted: bool,
    pub local_modified: SystemTime,
}

impl LocalLogin {
    #[inline]
    pub fn guid_str(&self) -> &str {
        self.login.guid_str()
    }

    pub(crate) fn from_row(row: &Row<'_>) -> Result<LocalLogin> {
        Ok(LocalLogin {
            login: Login::from_row(row)?,
            sync_status: SyncStatus::from_u8(row.get("sync_status")?)?,
            is_deleted: row.get("is_deleted")?,
            local_modified: util::system_time_millis_from_row(row, "local_modified")?,
        })
    }
}

macro_rules! impl_login {
    ($ty:ty { $($fields:tt)* }) => {
        impl AsRef<Login> for $ty {
            #[inline]
            fn as_ref(&self) -> &Login {
                &self.login
            }
        }

        impl AsMut<Login> for $ty {
            #[inline]
            fn as_mut(&mut self) -> &mut Login {
                &mut self.login
            }
        }

        impl From<$ty> for Login {
            #[inline]
            fn from(l: $ty) -> Self {
                l.login
            }
        }

        impl From<Login> for $ty {
            #[inline]
            fn from(login: Login) -> Self {
                Self { login, $($fields)* }
            }
        }
    };
}

impl_login!(LocalLogin {
    sync_status: SyncStatus::New,
    is_deleted: false,
    local_modified: time::UNIX_EPOCH
});

impl_login!(MirrorLogin {
    is_overridden: false,
    server_modified: ServerTimestamp(0)
});

// Stores data needed to do a 3-way merge
pub(crate) struct SyncLoginData {
    pub guid: Guid,
    pub local: Option<LocalLogin>,
    pub mirror: Option<MirrorLogin>,
    // None means it's a deletion
    pub inbound: (Option<Login>, ServerTimestamp),
}

impl SyncLoginData {
    #[inline]
    pub fn guid_str(&self) -> &str {
        &self.guid.as_str()
    }

    #[inline]
    pub fn guid(&self) -> &Guid {
        &self.guid
    }

    // Note: fetch_login_data in db.rs assumes that this can only fail with a deserialization error. Currently, this is true,
    // but you'll need to adjust that function if you make this return another type of Result.
    pub fn from_payload(
        payload: sync15::Payload,
        ts: ServerTimestamp,
    ) -> std::result::Result<Self, serde_json::Error> {
        let guid = payload.id.clone();
        let login: Option<Login> = if payload.is_tombstone() {
            None
        } else {
            let record: Login = payload.into_record()?;
            // If we can fixup incoming records from sync, do so.
            // But if we can't then keep the invalid data.
            record.maybe_fixup().unwrap_or(None).or(Some(record))
        };
        Ok(Self {
            guid,
            local: None,
            mirror: None,
            inbound: (login, ts),
        })
    }
}

macro_rules! impl_login_setter {
    ($setter_name:ident, $field:ident, $Login:ty) => {
        impl SyncLoginData {
            pub(crate) fn $setter_name(&mut self, record: $Login) -> Result<()> {
                // TODO: We probably shouldn't panic in this function!
                if self.$field.is_some() {
                    // Shouldn't be possible (only could happen if UNIQUE fails in sqlite, or if we
                    // get duplicate guids somewhere,but we check).
                    panic!(
                        "SyncLoginData::{} called on object that already has {} data",
                        stringify!($setter_name),
                        stringify!($field)
                    );
                }

                if self.guid_str() != record.guid_str() {
                    // This is almost certainly a bug in our code.
                    panic!(
                        "Wrong guid on login in {}: {:?} != {:?}",
                        stringify!($setter_name),
                        self.guid_str(),
                        record.guid_str()
                    );
                }

                self.$field = Some(record);
                Ok(())
            }
        }
    };
}

impl_login_setter!(set_local, local, LocalLogin);
impl_login_setter!(set_mirror, mirror, MirrorLogin);

#[derive(Debug, Default, Clone)]
pub(crate) struct LoginDelta {
    // "non-commutative" fields
    pub hostname: Option<String>,
    pub password: Option<String>,
    pub username: Option<String>,
    pub http_realm: Option<String>,
    pub form_submit_url: Option<String>,

    pub time_created: Option<i64>,
    pub time_last_used: Option<i64>,
    pub time_password_changed: Option<i64>,

    // "non-conflicting" fields (which are the same)
    pub password_field: Option<String>,
    pub username_field: Option<String>,

    // Commutative field
    pub times_used: i64,
}

macro_rules! merge_field {
    ($merged:ident, $b:ident, $prefer_b:expr, $field:ident) => {
        if let Some($field) = $b.$field.take() {
            if $merged.$field.is_some() {
                log::warn!("Collision merging login field {}", stringify!($field));
                if $prefer_b {
                    $merged.$field = Some($field);
                }
            } else {
                $merged.$field = Some($field);
            }
        }
    };
}

impl LoginDelta {
    #[allow(clippy::cognitive_complexity)] // Looks like clippy considers this after macro-expansion...
    pub fn merge(self, mut b: LoginDelta, b_is_newer: bool) -> LoginDelta {
        let mut merged = self;
        merge_field!(merged, b, b_is_newer, hostname);
        merge_field!(merged, b, b_is_newer, password);
        merge_field!(merged, b, b_is_newer, username);
        merge_field!(merged, b, b_is_newer, http_realm);
        merge_field!(merged, b, b_is_newer, form_submit_url);

        merge_field!(merged, b, b_is_newer, time_created);
        merge_field!(merged, b, b_is_newer, time_last_used);
        merge_field!(merged, b, b_is_newer, time_password_changed);

        merge_field!(merged, b, b_is_newer, password_field);
        merge_field!(merged, b, b_is_newer, username_field);

        // commutative fields
        merged.times_used += b.times_used;

        merged
    }
}

macro_rules! apply_field {
    ($login:ident, $delta:ident, $field:ident) => {
        if let Some($field) = $delta.$field.take() {
            $login.$field = $field.into();
        }
    };
}

impl Login {
    pub(crate) fn apply_delta(&mut self, mut delta: LoginDelta) {
        apply_field!(self, delta, hostname);

        apply_field!(self, delta, password);
        apply_field!(self, delta, username);

        apply_field!(self, delta, time_created);
        apply_field!(self, delta, time_last_used);
        apply_field!(self, delta, time_password_changed);

        apply_field!(self, delta, password_field);
        apply_field!(self, delta, username_field);

        // Use Some("") to indicate that it should be changed to be None (hacky...)
        if let Some(realm) = delta.http_realm.take() {
            self.http_realm = if realm.is_empty() { None } else { Some(realm) };
        }

        if let Some(url) = delta.form_submit_url.take() {
            self.form_submit_url = if url.is_empty() { None } else { Some(url) };
        }

        self.times_used += delta.times_used;
    }

    pub(crate) fn delta(&self, older: &Login) -> LoginDelta {
        let mut delta = LoginDelta::default();

        if self.form_submit_url != older.form_submit_url {
            delta.form_submit_url = Some(self.form_submit_url.clone().unwrap_or_default());
        }

        if self.http_realm != older.http_realm {
            delta.http_realm = Some(self.http_realm.clone().unwrap_or_default());
        }

        if self.hostname != older.hostname {
            delta.hostname = Some(self.hostname.clone());
        }
        if self.username != older.username {
            delta.username = Some(self.username.clone());
        }
        if self.password != older.password {
            delta.password = Some(self.password.clone());
        }
        if self.password_field != older.password_field {
            delta.password_field = Some(self.password_field.clone());
        }
        if self.username_field != older.username_field {
            delta.username_field = Some(self.username_field.clone());
        }

        // We discard zero (and negative numbers) for timestamps so that a
        // record that doesn't contain this information (these are
        // `#[serde(default)]`) doesn't skew our records.
        //
        // Arguably, we should also also ignore values later than our
        // `time_created`, or earlier than our `time_last_used` or
        // `time_password_changed`. Doing this properly would probably require
        // a scheme analogous to Desktop's weak-reupload system, so I'm punting
        // on it for now.
        if self.time_created > 0 && self.time_created != older.time_created {
            delta.time_created = Some(self.time_created);
        }
        if self.time_last_used > 0 && self.time_last_used != older.time_last_used {
            delta.time_last_used = Some(self.time_last_used);
        }
        if self.time_password_changed > 0
            && self.time_password_changed != older.time_password_changed
        {
            delta.time_password_changed = Some(self.time_password_changed);
        }

        if self.times_used > 0 && self.times_used != older.times_used {
            delta.times_used = self.times_used - older.times_used;
        }

        delta
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_invalid_payload_timestamps() {
        #[allow(clippy::unreadable_literal)]
        let bad_timestamp = 18446732429235952000u64;
        let bad_payload: sync15::Payload = serde_json::from_value(serde_json::json!({
            "id": "123412341234",
            "formSubmitURL": "https://www.example.com/submit",
            "hostname": "https://www.example.com",
            "username": "test",
            "password": "test",
            "timeCreated": bad_timestamp,
            "timeLastUsed": "some other garbage",
            "timePasswordChanged": -30, // valid i64 but negative
        }))
        .unwrap();
        let login = SyncLoginData::from_payload(bad_payload, ServerTimestamp::default())
            .unwrap()
            .inbound
            .0
            .unwrap();
        assert_eq!(login.time_created, 0);
        assert_eq!(login.time_last_used, 0);
        assert_eq!(login.time_password_changed, 0);

        let now64 = util::system_time_ms_i64(std::time::SystemTime::now());
        let good_payload: sync15::Payload = serde_json::from_value(serde_json::json!({
            "id": "123412341234",
            "formSubmitURL": "https://www.example.com/submit",
            "hostname": "https://www.example.com",
            "username": "test",
            "password": "test",
            "timeCreated": now64 - 100,
            "timeLastUsed": now64 - 50,
            "timePasswordChanged": now64 - 25,
        }))
        .unwrap();

        let login = SyncLoginData::from_payload(good_payload, ServerTimestamp::default())
            .unwrap()
            .inbound
            .0
            .unwrap();

        assert_eq!(login.time_created, now64 - 100);
        assert_eq!(login.time_last_used, now64 - 50);
        assert_eq!(login.time_password_changed, now64 - 25);
    }

    #[test]
    fn test_url_fixups() -> Result<()> {
        // Start with URLs which are all valid and already normalized.
        for input in &[
            // The list of valid hostnames documented at the top of this file.
            "https://site.com",
            "http://site.com:1234",
            "ftp://ftp.site.com",
            "moz-proxy://127.0.0.1:8888",
            "chrome://MyLegacyExtension",
            "file://",
            "https://[::1]",
        ] {
            assert_eq!(Login::validate_and_fixup_origin(input)?, None);
        }

        // And URLs which get normalized.
        for (input, output) in &[
            ("https://site.com/", "https://site.com"),
            ("http://site.com:1234/", "http://site.com:1234"),
            ("http://example.com/foo?query=wtf#bar", "http://example.com"),
            ("http://example.com/foo#bar", "http://example.com"),
            (
                "http://username:password@example.com/",
                "http://example.com",
            ),
            ("http://😍.com/", "http://xn--r28h.com"),
            ("https://[0:0:0:0:0:0:0:1]", "https://[::1]"),
            // All `file://` URLs normalize to exactly `file://`. See #2384 for
            // why we might consider changing that later.
            ("file:///", "file://"),
            ("file://foo/bar", "file://"),
            ("file://foo/bar/", "file://"),
            ("moz-proxy://127.0.0.1:8888/", "moz-proxy://127.0.0.1:8888"),
            (
                "moz-proxy://127.0.0.1:8888/foo",
                "moz-proxy://127.0.0.1:8888",
            ),
            ("chrome://MyLegacyExtension/", "chrome://MyLegacyExtension"),
            (
                "chrome://MyLegacyExtension/foo",
                "chrome://MyLegacyExtension",
            ),
        ] {
            assert_eq!(
                Login::validate_and_fixup_origin(input)?,
                Some((*output).into())
            );
        }
        Ok(())
    }

    #[test]
    fn test_check_valid() {
        struct TestCase {
            login: Login,
            should_err: bool,
            expected_err: &'static str,
        }

        let valid_login = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_empty_hostname = Login {
            hostname: "".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_empty_password = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "".into(),
            ..Login::default()
        };

        let login_with_form_submit_and_http_realm = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            form_submit_url: Some("https://www.example.com".into()),
            password: "test".into(),
            ..Login::default()
        };

        let login_without_form_submit_or_http_realm = Login {
            hostname: "https://www.example.com".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_null_http_realm = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.\0com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_null_username = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "\0".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_null_password = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "username".into(),
            password: "test\0".into(),
            ..Login::default()
        };

        let login_with_newline_hostname = Login {
            hostname: "\rhttps://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_newline_username_field = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            username_field: "\n".into(),
            ..Login::default()
        };

        let login_with_newline_realm = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("foo\nbar".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_newline_password = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test\n".into(),
            ..Login::default()
        };

        let login_with_period_username_field = Login {
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            username_field: ".".into(),
            ..Login::default()
        };

        let login_with_period_form_submit_url = Login {
            form_submit_url: Some(".".into()),
            hostname: "https://www.example.com".into(),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_javascript_form_submit_url = Login {
            form_submit_url: Some("javascript:".into()),
            hostname: "https://www.example.com".into(),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_malformed_origin_parens = Login {
            hostname: " (".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_host_unicode = Login {
            hostname: "http://💖.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_hostname_trailing_slash = Login {
            hostname: "https://www.example.com/".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_hostname_expanded_ipv6 = Login {
            hostname: "https://[0:0:0:0:0:0:1:1]".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_unknown_protocol = Login {
            hostname: "moz-proxy://127.0.0.1:8888".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let test_cases = [
            TestCase {
                login: valid_login,
                should_err: false,
                expected_err: "",
            },
            TestCase {
                login: login_with_empty_hostname,
                should_err: true,
                expected_err: "Invalid login: Origin is empty",
            },
            TestCase {
                login: login_with_empty_password,
                should_err: true,
                expected_err: "Invalid login: Password is empty",
            },
            TestCase {
                login: login_with_form_submit_and_http_realm,
                should_err: true,
                expected_err: "Invalid login: Both `formSubmitUrl` and `httpRealm` are present",
            },
            TestCase {
                login: login_without_form_submit_or_http_realm,
                should_err: true,
                expected_err: "Invalid login: Neither `formSubmitUrl` or `httpRealm` are present",
            },
            TestCase {
                login: login_with_null_http_realm,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: `httpRealm` contains Nul",
            },
            TestCase {
                login: login_with_null_username,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: `username` contains Nul",
            },
            TestCase {
                login: login_with_null_password,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: `password` contains Nul",
            },
            TestCase {
                login: login_with_newline_hostname,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: `hostname` contains newline",
            },
            TestCase {
                login: login_with_newline_realm,
                should_err: true,
                expected_err:
                    "Invalid login: Login has illegal field: `httpRealm` contains newline",
            },
            TestCase {
                login: login_with_newline_username_field,
                should_err: true,
                expected_err:
                    "Invalid login: Login has illegal field: `usernameField` contains newline",
            },
            TestCase {
                login: login_with_newline_password,
                should_err: false,
                expected_err: "",
            },
            TestCase {
                login: login_with_period_username_field,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: `usernameField` is a period",
            },
            TestCase {
                login: login_with_period_form_submit_url,
                should_err: false,
                expected_err: "",
            },
            TestCase {
                login: login_with_javascript_form_submit_url,
                should_err: false,
                expected_err: "",
            },
            TestCase {
                login: login_with_malformed_origin_parens,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: Origin is Malformed",
            },
            TestCase {
                login: login_with_host_unicode,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: Origin is not normalized",
            },
            TestCase {
                login: login_with_hostname_trailing_slash,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: Origin is not normalized",
            },
            TestCase {
                login: login_with_hostname_expanded_ipv6,
                should_err: true,
                expected_err: "Invalid login: Login has illegal field: Origin is not normalized",
            },
            TestCase {
                login: login_with_unknown_protocol,
                should_err: false,
                expected_err: "",
            },
        ];

        for tc in &test_cases {
            let actual = tc.login.check_valid();

            if tc.should_err {
                assert!(actual.is_err());
                assert_eq!(tc.expected_err, actual.unwrap_err().to_string());
            } else {
                assert!(actual.is_ok());
            }
        }
    }

    #[test]
    fn test_fixup() {
        #[derive(Default)]
        struct TestCase {
            login: Login,
            fixedup_host: Option<&'static str>,
            fixedup_form_submit_url: Option<String>,
        }

        // Note that most URL fixups are tested above, but we have one or 2 here.
        let login_with_full_url = Login {
            hostname: "http://example.com/foo?query=wtf#bar".into(),
            form_submit_url: Some("http://example.com/foo?query=wtf#bar".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_host_unicode = Login {
            hostname: "http://😍.com".into(),
            form_submit_url: Some("http://😍.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_period_fsu = Login {
            hostname: "https://example.com".into(),
            form_submit_url: Some(".".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let login_with_form_submit_and_http_realm = Login {
            hostname: "https://www.example.com".into(),
            form_submit_url: Some("https://www.example.com".into()),
            // If both http_realm and form_submit_url are specified, we drop
            // the former when fixing up. So for this test we must have an
            // invalid value in http_realm to ensure we don't validate a value
            // we end up dropping.
            http_realm: Some("\n".into()),
            password: "test".into(),
            ..Login::default()
        };

        let test_cases = [
            TestCase {
                login: login_with_full_url,
                fixedup_host: "http://example.com".into(),
                fixedup_form_submit_url: Some("http://example.com".into()),
            },
            TestCase {
                login: login_with_host_unicode,
                fixedup_host: "http://xn--r28h.com".into(),
                fixedup_form_submit_url: Some("http://xn--r28h.com".into()),
            },
            TestCase {
                login: login_with_period_fsu,
                fixedup_form_submit_url: Some("".into()),
                ..TestCase::default()
            },
            TestCase {
                login: login_with_form_submit_and_http_realm,
                fixedup_form_submit_url: Some("https://www.example.com".into()),
                ..TestCase::default()
            },
        ];

        for tc in &test_cases {
            let login = tc.login.clone().fixup().expect("should work");
            if let Some(expected) = tc.fixedup_host {
                assert_eq!(login.hostname, expected);
            }
            assert_eq!(login.form_submit_url, tc.fixedup_form_submit_url);
        }
    }

    #[test]
    fn test_username_field_requires_a_form_target() {
        let bad_payload: sync15::Payload = serde_json::from_value(serde_json::json!({
            "id": "123412341234",
            "httpRealm": "test",
            "hostname": "https://www.example.com",
            "username": "test",
            "password": "test",
            "usernameField": "invalid"
        }))
        .unwrap();

        let login: Login = bad_payload.clone().into_record().unwrap();
        assert_eq!(login.username_field, "invalid");
        assert!(login.check_valid().is_err());
        assert_eq!(login.fixup().unwrap().username_field, "");

        // Incoming sync data gets fixed automatically.
        let login = SyncLoginData::from_payload(bad_payload, ServerTimestamp::default())
            .unwrap()
            .inbound
            .0
            .unwrap();
        assert_eq!(login.username_field, "");
    }

    #[test]
    fn test_password_field_requires_a_form_target() {
        let bad_payload: sync15::Payload = serde_json::from_value(serde_json::json!({
            "id": "123412341234",
            "httpRealm": "test",
            "hostname": "https://www.example.com",
            "username": "test",
            "password": "test",
            "passwordField": "invalid"
        }))
        .unwrap();

        let login: Login = bad_payload.into_record().unwrap();
        assert_eq!(login.password_field, "invalid");
        assert!(login.check_valid().is_err());
        assert_eq!(login.fixup().unwrap().password_field, "");
    }
}
