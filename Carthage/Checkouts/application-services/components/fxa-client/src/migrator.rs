/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{error::*, scoped_keys::ScopedKey, scopes, FirefoxAccount};
use ffi_support::IntoFfi;
use serde_derive::*;
use std::time::Instant;

// Values to pass back to calling code over the FFI.

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone, Default)]
pub struct FxAMigrationResult {
    pub total_duration: u128,
}

pub enum MigrationState {
    // No in-flight migration.
    None,
    // An in-flight migration that will copy the sessionToken.
    CopySessionToken,
    // An in-flight migration that will re-use the sessionToken.
    ReuseSessionToken,
}

unsafe impl IntoFfi for MigrationState {
    type Value = u8;
    fn ffi_default() -> u8 {
        0
    }
    fn into_ffi_value(self) -> u8 {
        match self {
            MigrationState::None => 0,
            MigrationState::CopySessionToken => 1,
            MigrationState::ReuseSessionToken => 2,
        }
    }
}

// Migration-related data that we may need to serialize in the persisted account state.

#[derive(Clone, Serialize, Deserialize)]
pub struct MigrationData {
    k_xcs: String,
    k_sync: String,
    copy_session_token: bool,
    session_token: String,
}

impl FirefoxAccount {
    /// Migrate from a logged-in with a sessionToken Firefox Account.
    ///
    /// * `session_token` - Hex-formatted session token.
    /// * `k_xcs` - Hex-formatted kXCS.
    /// * `k_sync` - Hex-formatted kSync.
    /// * `copy_session_token` - If true then the provided 'session_token' will be duplicated
    ///     and the resulting session will use a new session token. If false, the provided
    ///     token will be reused.
    ///
    /// This method remembers the provided token details and may persist them in the
    /// account state if it encounters a temporary failure such as a network error.
    /// Calling code is expected to store the updated state even if an error is thrown.
    ///
    /// **💾 This method alters the persisted account state.**
    pub fn migrate_from_session_token(
        &mut self,
        session_token: &str,
        k_sync: &str,
        k_xcs: &str,
        copy_session_token: bool,
    ) -> Result<FxAMigrationResult> {
        // if there is already a session token on account, we error out.
        if self.state.session_token.is_some() {
            return Err(ErrorKind::IllegalState("Session Token is already set.").into());
        }

        self.state.in_flight_migration = Some(MigrationData {
            k_sync: k_sync.to_string(),
            k_xcs: k_xcs.to_string(),
            copy_session_token,
            session_token: session_token.to_string(),
        });

        self.try_migration()
    }

    /// Check if the client is in a pending migration state
    pub fn is_in_migration_state(&self) -> MigrationState {
        match self.state.in_flight_migration {
            None => MigrationState::None,
            Some(MigrationData {
                copy_session_token: true,
                ..
            }) => MigrationState::CopySessionToken,
            Some(MigrationData {
                copy_session_token: false,
                ..
            }) => MigrationState::ReuseSessionToken,
        }
    }

    pub fn try_migration(&mut self) -> Result<FxAMigrationResult> {
        let import_start = Instant::now();

        match self.network_migration() {
            Ok(_) => {}
            Err(err) => {
                match err.kind() {
                    ErrorKind::RemoteError {
                        code: 500..=599, ..
                    }
                    | ErrorKind::RemoteError { code: 429, .. }
                    | ErrorKind::RequestError(_) => {
                        // network errors that will allow hopefully migrate later
                        log::warn!("Network error: {:?}", err);
                        return Err(err);
                    }
                    _ => {
                        // probably will not recover

                        self.state.in_flight_migration = None;

                        return Err(err);
                    }
                };
            }
        }

        self.state.in_flight_migration = None;

        let metrics = FxAMigrationResult {
            total_duration: import_start.elapsed().as_millis(),
        };

        Ok(metrics)
    }

    fn network_migration(&mut self) -> Result<()> {
        let migration_data = match self.state.in_flight_migration {
            Some(ref data) => data.clone(),
            None => {
                return Err(ErrorKind::NoMigrationData.into());
            }
        };

        // If we need to copy the sessionToken, do that first so we can use it
        // for subsequent requests. TODO: we should store the duplicated token
        // in the account state in case we fail in later steps, but need to remember
        // the original value of `copy_session_token` if we do so.
        let migration_session_token = if migration_data.copy_session_token {
            let duplicate_session = self
                .client
                .duplicate_session(&self.state.config, &migration_data.session_token)?;

            duplicate_session.session_token
        } else {
            migration_data.session_token.to_string()
        };

        // Synthesize a scoped key from our kSync.
        // Do this before creating OAuth tokens because it doesn't have any side-effects,
        // so it's low-consequence if we fail in later steps.
        let k_sync = hex::decode(&migration_data.k_sync)?;
        let k_sync = base64::encode_config(&k_sync, base64::URL_SAFE_NO_PAD);
        let k_xcs = hex::decode(&migration_data.k_xcs)?;
        let k_xcs = base64::encode_config(&k_xcs, base64::URL_SAFE_NO_PAD);
        let scoped_key_data = self.client.scoped_key_data(
            &self.state.config,
            &migration_session_token,
            scopes::OLD_SYNC,
        )?;
        let oldsync_key_data = scoped_key_data.get(scopes::OLD_SYNC).ok_or_else(|| {
            ErrorKind::IllegalState("The session token doesn't have access to kSync!")
        })?;
        let kid = format!("{}-{}", oldsync_key_data.key_rotation_timestamp, k_xcs);
        let k_sync_scoped_key = ScopedKey {
            kty: "oct".to_string(),
            scope: scopes::OLD_SYNC.to_string(),
            k: k_sync,
            kid,
        };

        // Trade our session token for a refresh token.
        let oauth_response = self.client.refresh_token_with_session_token(
            &self.state.config,
            &migration_session_token,
            &[scopes::PROFILE, scopes::OLD_SYNC],
        )?;

        // Store the new tokens in the account state.
        // We do this all at one at the end to avoid leaving partial state.
        self.state.session_token = Some(migration_session_token);
        self.handle_oauth_response(oauth_response, None)?;
        self.state
            .scoped_keys
            .insert(scopes::OLD_SYNC.to_string(), k_sync_scoped_key);

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::http_client::*;
    use std::collections::HashMap;
    use std::sync::Arc;

    fn setup() -> FirefoxAccount {
        // I'd love to be able to configure a single mocked client here,
        // but can't work out how to do that within the typesystem.
        FirefoxAccount::new("https://stable.dev.lcip.org", "12345678", "https://foo.bar")
    }

    macro_rules! assert_match {
        ($value:expr, $pattern:pat) => {
            assert!(match $value {
                $pattern => true,
                _ => false,
            });
        };
    }

    #[test]
    fn test_migration_can_retry_after_network_errors() {
        let mut fxa = setup();

        assert_match!(fxa.is_in_migration_state(), MigrationState::None);

        // Initial attempt fails with a server-side failure, which we can retry.
        let mut client = FxAClientMock::new();
        client
            .expect_duplicate_session(mockiato::Argument::any, |arg| arg.partial_eq("session"))
            .returns_once(Err(ErrorKind::RemoteError {
                code: 500,
                errno: 999,
                error: "server error".to_string(),
                message: "there was a server error".to_string(),
                info: "fyi, there was a server error".to_string(),
            }
            .into()));
        fxa.set_client(Arc::new(client));

        let err = fxa
            .migrate_from_session_token("session", "aabbcc", "ddeeff", true)
            .unwrap_err();
        assert_match!(err.kind(), ErrorKind::RemoteError { code: 500, .. });
        assert_match!(
            fxa.is_in_migration_state(),
            MigrationState::CopySessionToken
        );

        // Retrying can succeed.
        // It makes a lot of network requests, so we have a lot to mock!
        let mut client = FxAClientMock::new();
        client
            .expect_duplicate_session(mockiato::Argument::any, |arg| arg.partial_eq("session"))
            .returns_once(Ok(DuplicateTokenResponse {
                uid: "userid".to_string(),
                session_token: "dup_session".to_string(),
                verified: true,
                auth_at: 12345,
            }));
        let mut key_data = HashMap::new();
        key_data.insert(
            scopes::OLD_SYNC.to_string(),
            ScopedKeyDataResponse {
                identifier: scopes::OLD_SYNC.to_string(),
                key_rotation_secret: "00000000000000000000000000000000".to_string(),
                key_rotation_timestamp: 12345,
            },
        );
        client
            .expect_scoped_key_data(
                mockiato::Argument::any,
                |arg| arg.partial_eq("dup_session"),
                |arg| arg.partial_eq(scopes::OLD_SYNC),
            )
            .returns_once(Ok(key_data));
        client
            .expect_refresh_token_with_session_token(
                mockiato::Argument::any,
                |arg| arg.partial_eq("dup_session"),
                |arg| arg.unordered_vec_eq([scopes::PROFILE, scopes::OLD_SYNC].to_vec()),
            )
            .returns_once(Ok(OAuthTokenResponse {
                keys_jwe: None,
                refresh_token: Some("refresh".to_string()),
                session_token: None,
                expires_in: 12345,
                scope: "profile oldsync".to_string(),
                access_token: "access".to_string(),
            }));
        client
            .expect_destroy_access_token(mockiato::Argument::any, |arg| arg.partial_eq("access"))
            .returns_once(Ok(()));
        fxa.set_client(Arc::new(client));

        fxa.try_migration().unwrap();
        assert_match!(fxa.is_in_migration_state(), MigrationState::None);
    }

    #[test]
    fn test_migration_cannot_retry_after_other_errors() {
        let mut fxa = setup();

        assert_match!(fxa.is_in_migration_state(), MigrationState::None);

        let mut client = FxAClientMock::new();
        client
            .expect_duplicate_session(mockiato::Argument::any, |arg| arg.partial_eq("session"))
            .returns_once(Err(ErrorKind::RemoteError {
                code: 400,
                errno: 102,
                error: "invalid token".to_string(),
                message: "the token was invalid".to_string(),
                info: "fyi, the provided token was invalid".to_string(),
            }
            .into()));
        fxa.set_client(Arc::new(client));

        let err = fxa
            .migrate_from_session_token("session", "aabbcc", "ddeeff", true)
            .unwrap_err();
        assert_match!(err.kind(), ErrorKind::RemoteError { code: 400, .. });
        assert_match!(fxa.is_in_migration_state(), MigrationState::None);
    }

    #[test]
    fn try_migration_fails_if_nothing_in_flight() {
        let mut fxa = setup();

        assert_match!(fxa.is_in_migration_state(), MigrationState::None);

        let err = fxa.try_migration().unwrap_err();
        assert_match!(err.kind(), ErrorKind::NoMigrationData);
        assert_match!(fxa.is_in_migration_state(), MigrationState::None);
    }

    #[test]
    fn test_migration_state_remembers_whether_to_copy_session_token() {
        let mut fxa = setup();

        assert_match!(fxa.is_in_migration_state(), MigrationState::None);

        let mut client = FxAClientMock::new();
        client
            .expect_scoped_key_data(
                mockiato::Argument::any,
                |arg| arg.partial_eq("session"),
                |arg| arg.partial_eq(scopes::OLD_SYNC),
            )
            .returns_once(Err(ErrorKind::RemoteError {
                code: 500,
                errno: 999,
                error: "server error".to_string(),
                message: "there was a server error".to_string(),
                info: "fyi, there was a server error".to_string(),
            }
            .into()));
        fxa.set_client(Arc::new(client));

        let err = fxa
            .migrate_from_session_token("session", "aabbcc", "ddeeff", false)
            .unwrap_err();
        assert_match!(err.kind(), ErrorKind::RemoteError { code: 500, .. });
        assert_match!(
            fxa.is_in_migration_state(),
            MigrationState::ReuseSessionToken
        );

        // Retrying should fail again in the same way (as opposed to, say, trying
        // to duplicate the sessionToken rather than reusing it).
        let mut client = FxAClientMock::new();
        client
            .expect_scoped_key_data(
                mockiato::Argument::any,
                |arg| arg.partial_eq("session"),
                |arg| arg.partial_eq(scopes::OLD_SYNC),
            )
            .returns_once(Err(ErrorKind::RemoteError {
                code: 500,
                errno: 999,
                error: "server error".to_string(),
                message: "there was a server error".to_string(),
                info: "fyi, there was a server error".to_string(),
            }
            .into()));
        fxa.set_client(Arc::new(client));

        let err = fxa.try_migration().unwrap_err();
        assert_match!(err.kind(), ErrorKind::RemoteError { code: 500, .. });
        assert_match!(
            fxa.is_in_migration_state(),
            MigrationState::ReuseSessionToken
        );
    }
}
