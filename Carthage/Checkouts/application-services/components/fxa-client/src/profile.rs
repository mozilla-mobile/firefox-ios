/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

pub use crate::http_client::ProfileResponse as Profile;
use crate::{error::*, scopes, util, CachedResponse, FirefoxAccount};

// A cached profile response is considered fresh for `PROFILE_FRESHNESS_THRESHOLD` ms.
const PROFILE_FRESHNESS_THRESHOLD: u64 = 120_000; // 2 minutes

impl FirefoxAccount {
    /// Fetch the profile for the user.
    /// This method will error-out if the `profile` scope is not
    /// authorized for the current refresh token or or if we do
    /// not have a valid refresh token.
    ///
    /// * `ignore_cache` - If set to true, bypass the in-memory cache
    /// and fetch the entire profile data from the server.
    ///
    /// **💾 This method alters the persisted account state.**
    pub fn get_profile(&mut self, ignore_cache: bool) -> Result<Profile> {
        match self.get_profile_helper(ignore_cache) {
            Ok(res) => Ok(res),
            Err(e) => match e.kind() {
                ErrorKind::RemoteError { code: 401, .. } => {
                    log::warn!(
                        "Access token rejected, clearing the tokens cache and trying again."
                    );
                    self.clear_access_token_cache();
                    self.get_profile_helper(ignore_cache)
                }
                _ => Err(e),
            },
        }
    }

    fn get_profile_helper(&mut self, ignore_cache: bool) -> Result<Profile> {
        let mut etag = None;
        if let Some(ref cached_profile) = self.state.last_seen_profile {
            if !ignore_cache && util::now() < cached_profile.cached_at + PROFILE_FRESHNESS_THRESHOLD
            {
                return Ok(cached_profile.response.clone());
            }
            etag = Some(cached_profile.etag.clone());
        }
        let profile_access_token = self.get_access_token(scopes::PROFILE)?.token;
        match self
            .client
            .profile(&self.state.config, &profile_access_token, etag)?
        {
            Some(response_and_etag) => {
                if let Some(etag) = response_and_etag.etag {
                    self.state.last_seen_profile = Some(CachedResponse {
                        response: response_and_etag.response.clone(),
                        cached_at: util::now(),
                        etag,
                    });
                }
                Ok(response_and_etag.response)
            }
            None => {
                match self.state.last_seen_profile.take() {
                    Some(ref cached_profile) => {
                        // Update `cached_at` timestamp.
                        self.state.last_seen_profile.replace(CachedResponse {
                            response: cached_profile.response.clone(),
                            cached_at: util::now(),
                            etag: cached_profile.etag.clone(),
                        });
                        Ok(cached_profile.response.clone())
                    }
                    None => Err(ErrorKind::UnrecoverableServerError(
                        "Got a 304 without having sent an eTag.",
                    )
                    .into()),
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        http_client::*,
        oauth::{AccessTokenInfo, RefreshToken},
    };
    use std::sync::Arc;

    impl FirefoxAccount {
        pub fn add_cached_profile(&mut self, uid: &str, email: &str) {
            self.state.last_seen_profile = Some(CachedResponse {
                response: Profile {
                    uid: uid.into(),
                    email: email.into(),
                    locale: "en-US".into(),
                    display_name: None,
                    avatar: "".into(),
                    avatar_default: true,
                    amr_values: vec![],
                    two_factor_authentication: false,
                },
                cached_at: util::now(),
                etag: "fake etag".into(),
            });
        }
    }

    #[test]
    fn test_fetch_profile() {
        let mut fxa =
            FirefoxAccount::new("https://stable.dev.lcip.org", "12345678", "https://foo.bar");

        fxa.add_cached_token(
            "profile",
            AccessTokenInfo {
                scope: "profile".to_string(),
                token: "profiletok".to_string(),
                key: None,
                expires_at: u64::max_value(),
            },
        );

        let mut client = FxAClientMock::new();
        client
            .expect_profile(
                mockiato::Argument::any,
                |token| token.partial_eq("profiletok"),
                mockiato::Argument::any,
            )
            .times(1)
            .returns_once(Ok(Some(ResponseAndETag {
                response: ProfileResponse {
                    uid: "12345ab".to_string(),
                    email: "foo@bar.com".to_string(),
                    locale: "fr-FR".to_string(),
                    display_name: None,
                    avatar: "https://foo.avatar".to_string(),
                    avatar_default: true,
                    amr_values: vec![],
                    two_factor_authentication: false,
                },
                etag: None,
            })));
        fxa.set_client(Arc::new(client));

        let p = fxa.get_profile(false).unwrap();
        assert_eq!(p.email, "foo@bar.com");
    }

    #[test]
    fn test_expired_access_token_refetch() {
        let mut fxa =
            FirefoxAccount::new("https://stable.dev.lcip.org", "12345678", "https://foo.bar");

        fxa.add_cached_token(
            "profile",
            AccessTokenInfo {
                scope: "profile".to_string(),
                token: "bad_access_token".to_string(),
                key: None,
                expires_at: u64::max_value(),
            },
        );
        let mut refresh_token_scopes = std::collections::HashSet::new();
        refresh_token_scopes.insert("profile".to_owned());
        fxa.state.refresh_token = Some(RefreshToken {
            token: "refreshtok".to_owned(),
            scopes: refresh_token_scopes,
        });

        let mut client = FxAClientMock::new();
        // First call to profile() we fail with 401.
        client
            .expect_profile(
                mockiato::Argument::any,
                |token| token.partial_eq("bad_access_token"),
                mockiato::Argument::any,
            )
            .times(1)
            .returns_once(Err(ErrorKind::RemoteError{
                code: 401,
                errno: 110,
                error: "Unauthorized".to_owned(),
                message: "Invalid authentication token in request signature".to_owned(),
                info: "https://github.com/mozilla/fxa-auth-server/blob/master/docs/api.md#response-format".to_owned(),
            }.into()));
        // Then we'll try to get a new access token.
        client
            .expect_access_token_with_refresh_token(
                mockiato::Argument::any,
                |token| token.partial_eq("refreshtok"),
                mockiato::Argument::any,
            )
            .times(1)
            .returns_once(Ok(OAuthTokenResponse {
                keys_jwe: None,
                refresh_token: None,
                expires_in: 6_000_000,
                scope: "profile".to_owned(),
                access_token: "good_profile_token".to_owned(),
                session_token: None,
            }));
        // Then hooray it works!
        client
            .expect_profile(
                mockiato::Argument::any,
                |token| token.partial_eq("good_profile_token"),
                mockiato::Argument::any,
            )
            .times(1)
            .returns_once(Ok(Some(ResponseAndETag {
                response: ProfileResponse {
                    uid: "12345ab".to_string(),
                    email: "foo@bar.com".to_string(),
                    locale: "fr-FR".to_string(),
                    display_name: None,
                    avatar: "https://foo.avatar".to_string(),
                    avatar_default: true,
                    amr_values: vec![],
                    two_factor_authentication: false,
                },
                etag: None,
            })));
        fxa.set_client(Arc::new(client));

        let p = fxa.get_profile(false).unwrap();
        assert_eq!(p.email, "foo@bar.com");
    }
}
