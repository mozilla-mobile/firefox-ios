/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    http_client::OAuthTokenResponse,
    scoped_keys::{ScopedKey, ScopedKeysFlow},
    util, FirefoxAccount,
};
use rc_crypto::digest;
use serde_derive::*;
use std::{
    collections::HashSet,
    iter::FromIterator,
    time::{SystemTime, UNIX_EPOCH},
};
use url::Url;

// If a cached token has less than `OAUTH_MIN_TIME_LEFT` seconds left to live,
// it will be considered already expired.
const OAUTH_MIN_TIME_LEFT: u64 = 60;
// Special redirect urn based on the OAuth native spec, signals that the
// WebChannel flow is used
pub const OAUTH_WEBCHANNEL_REDIRECT: &str = "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel";

impl FirefoxAccount {
    /// Fetch a short-lived access token using the saved refresh token.
    /// If there is no refresh token held or if it is not authorized for some of the requested
    /// scopes, this method will error-out and a login flow will need to be initiated
    /// using `begin_oauth_flow`.
    ///
    /// * `scopes` - Space-separated list of requested scopes.
    ///
    /// **💾 This method may alter the persisted account state.**
    pub fn get_access_token(&mut self, scope: &str) -> Result<AccessTokenInfo> {
        if scope.contains(' ') {
            return Err(ErrorKind::MultipleScopesRequested.into());
        }
        if let Some(oauth_info) = self.state.access_token_cache.get(scope) {
            if oauth_info.expires_at > util::now_secs() + OAUTH_MIN_TIME_LEFT {
                return Ok(oauth_info.clone());
            }
        }
        let resp = match self.state.refresh_token {
            Some(ref refresh_token) => {
                if refresh_token.scopes.contains(scope) {
                    self.client.access_token_with_refresh_token(
                        &self.state.config,
                        &refresh_token.token,
                        &[scope],
                    )?
                } else {
                    return Err(ErrorKind::NoCachedToken(scope.to_string()).into());
                }
            }
            None => match self.state.session_token {
                Some(ref session_token) => self.client.access_token_with_session_token(
                    &self.state.config,
                    &session_token,
                    &[scope],
                )?,
                None => return Err(ErrorKind::NoCachedToken(scope.to_string()).into()),
            },
        };
        let since_epoch = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|_| ErrorKind::IllegalState("Current date before Unix Epoch."))?;
        let expires_at = since_epoch.as_secs() + resp.expires_in;
        let token_info = AccessTokenInfo {
            scope: resp.scope,
            token: resp.access_token,
            key: self.state.scoped_keys.get(scope).cloned(),
            expires_at,
        };
        self.state
            .access_token_cache
            .insert(scope.to_string(), token_info.clone());
        Ok(token_info)
    }

    /// Retrieve the current session token from state
    pub fn get_session_token(&self) -> Result<String> {
        match self.state.session_token {
            Some(ref session_token) => Ok(session_token.to_string()),
            None => Err(ErrorKind::NoSessionToken.into()),
        }
    }

    /// Check whether user is authorized using our refresh token.
    pub fn check_authorization_status(&self) -> Result<IntrospectInfo> {
        let resp = match self.state.refresh_token {
            Some(ref refresh_token) => self
                .client
                .oauth_introspect_refresh_token(&self.state.config, &refresh_token.token)?,
            None => return Err(ErrorKind::NoRefreshToken.into()),
        };
        Ok(IntrospectInfo {
            active: resp.active,
            token_type: resp.token_type,
            scope: resp.scope,
            exp: resp.exp,
            iss: resp.iss,
        })
    }

    /// Initiate a pairing flow and return a URL that should be navigated to.
    ///
    /// * `pairing_url` - A pairing URL obtained by scanning a QR code produced by
    /// the pairing authority.
    /// * `scopes` - Space-separated list of requested scopes by the pairing supplicant.
    pub fn begin_pairing_flow(&mut self, pairing_url: &str, scopes: &[&str]) -> Result<String> {
        let mut url = self.state.config.content_url_path("/pair/supp")?;
        let pairing_url = Url::parse(pairing_url)?;
        if url.host_str() != pairing_url.host_str() {
            return Err(ErrorKind::OriginMismatch.into());
        }
        url.set_fragment(pairing_url.fragment());
        self.oauth_flow(url, scopes)
    }

    /// Initiate an OAuth login flow and return a URL that should be navigated to.
    ///
    /// * `scopes` - Space-separated list of requested scopes.
    pub fn begin_oauth_flow(&mut self, scopes: &[&str]) -> Result<String> {
        let mut url = if self.state.last_seen_profile.is_some() {
            self.state.config.content_url_path("/oauth/force_auth")?
        } else {
            self.state.config.authorization_endpoint()?
        };

        url.query_pairs_mut()
            .append_pair("action", "email")
            .append_pair("response_type", "code");

        if let Some(ref cached_profile) = self.state.last_seen_profile {
            url.query_pairs_mut()
                .append_pair("email", &cached_profile.response.email);
        }

        let scopes: Vec<String> = match self.state.refresh_token {
            Some(ref refresh_token) => {
                // Union of the already held scopes and the one requested.
                let mut all_scopes: Vec<String> = vec![];
                all_scopes.extend(scopes.iter().map(ToString::to_string));
                let existing_scopes = refresh_token.scopes.clone();
                all_scopes.extend(existing_scopes);
                HashSet::<String>::from_iter(all_scopes)
                    .into_iter()
                    .collect()
            }
            None => scopes.iter().map(ToString::to_string).collect(),
        };
        let scopes: Vec<&str> = scopes.iter().map(<_>::as_ref).collect();
        self.oauth_flow(url, &scopes)
    }

    /// Fetch an OAuth code for a particular client using a session token from the account state.
    /// This method doesn't support OAuth public clients at this time.
    ///
    /// * `client_id` - OAuth client id.
    /// * `scopes` - Space-separated list of requested scopes.
    /// * `state` - OAuth state.
    /// * `access_type` - Type of OAuth access, can be "offline" and "online.
    pub fn authorize_code_using_session_token(
        &self,
        client_id: &str,
        scope: &str,
        state: &str,
        access_type: &str,
    ) -> Result<String> {
        let session_token = self.get_session_token()?;
        let resp = self.client.authorization_code_using_session_token(
            &self.state.config,
            &client_id,
            &session_token,
            &scope,
            &state,
            &access_type,
        )?;

        Ok(resp.code)
    }

    fn oauth_flow(&mut self, mut url: Url, scopes: &[&str]) -> Result<String> {
        self.clear_access_token_cache();
        let state = util::random_base64_url_string(16)?;
        let code_verifier = util::random_base64_url_string(43)?;
        let code_challenge = digest::digest(&digest::SHA256, &code_verifier.as_bytes())?;
        let code_challenge = base64::encode_config(&code_challenge, base64::URL_SAFE_NO_PAD);
        let scoped_keys_flow = ScopedKeysFlow::with_random_key()?;
        let jwk_json = scoped_keys_flow.generate_keys_jwk()?;
        let keys_jwk = base64::encode_config(&jwk_json, base64::URL_SAFE_NO_PAD);
        url.query_pairs_mut()
            .append_pair("client_id", &self.state.config.client_id)
            .append_pair("scope", &scopes.join(" "))
            .append_pair("state", &state)
            .append_pair("code_challenge_method", "S256")
            .append_pair("code_challenge", &code_challenge)
            .append_pair("access_type", "offline")
            .append_pair("keys_jwk", &keys_jwk);

        if self.state.config.redirect_uri == OAUTH_WEBCHANNEL_REDIRECT {
            url.query_pairs_mut()
                .append_pair("context", "oauth_webchannel_v1");
        } else {
            url.query_pairs_mut()
                .append_pair("redirect_uri", &self.state.config.redirect_uri);
        }

        self.flow_store.insert(
            state, // Since state is supposed to be unique, we use it to key our flows.
            OAuthFlow {
                scoped_keys_flow: Some(scoped_keys_flow),
                code_verifier,
            },
        );
        Ok(url.to_string())
    }

    /// Complete an OAuth flow initiated in `begin_oauth_flow` or `begin_pairing_flow`.
    /// The `code` and `state` parameters can be obtained by parsing out the
    /// redirect URL after a successful login.
    ///
    /// **💾 This method alters the persisted account state.**
    pub fn complete_oauth_flow(&mut self, code: &str, state: &str) -> Result<()> {
        self.clear_access_token_cache();
        let oauth_flow = match self.flow_store.remove(state) {
            Some(oauth_flow) => oauth_flow,
            None => return Err(ErrorKind::UnknownOAuthState.into()),
        };
        let resp = self.client.refresh_token_with_code(
            &self.state.config,
            &code,
            &oauth_flow.code_verifier,
        )?;
        self.handle_oauth_response(resp, oauth_flow.scoped_keys_flow)
    }

    pub(crate) fn handle_oauth_response(
        &mut self,
        resp: OAuthTokenResponse,
        scoped_keys_flow: Option<ScopedKeysFlow>,
    ) -> Result<()> {
        if let Some(ref jwe) = resp.keys_jwe {
            let scoped_keys_flow = scoped_keys_flow.ok_or_else(|| {
                ErrorKind::UnrecoverableServerError("Got a JWE but have no JWK to decrypt it.")
            })?;
            let decrypted_keys = scoped_keys_flow.decrypt_keys_jwe(jwe)?;
            let scoped_keys: serde_json::Map<String, serde_json::Value> =
                serde_json::from_str(&decrypted_keys)?;
            for (scope, key) in scoped_keys {
                let scoped_key: ScopedKey = serde_json::from_value(key)?;
                self.state.scoped_keys.insert(scope, scoped_key);
            }
        }

        // If the client requested a 'tokens/session' OAuth scope then as part of the code
        // exchange this will get a session_token in the response.
        if resp.session_token.is_some() {
            self.state.session_token = resp.session_token;
        }

        // We are only interested in the refresh token at this time because we
        // don't want to return an over-scoped access token.
        // Let's be good citizens and destroy this access token.
        if let Err(err) = self
            .client
            .destroy_access_token(&self.state.config, &resp.access_token)
        {
            log::warn!("Access token destruction failure: {:?}", err);
        }
        let old_refresh_token = self.state.refresh_token.clone();
        let new_refresh_token = resp
            .refresh_token
            .ok_or_else(|| ErrorKind::RefreshTokenNotPresent)?;
        // Destroying a refresh token also destroys its associated device,
        // grab the device information for replication later.
        let old_device_info = match old_refresh_token {
            Some(_) => match self.get_current_device() {
                Ok(maybe_device) => maybe_device,
                Err(err) => {
                    log::warn!("Error while getting previous device information: {:?}", err);
                    None
                }
            },
            None => None,
        };
        self.state.refresh_token = Some(RefreshToken {
            token: new_refresh_token,
            scopes: HashSet::from_iter(resp.scope.split(' ').map(ToString::to_string)),
        });
        // In order to keep 1 and only 1 refresh token alive per client instance,
        // we also destroy the existing refresh token.
        if let Some(ref refresh_token) = old_refresh_token {
            if let Err(err) = self
                .client
                .destroy_refresh_token(&self.state.config, &refresh_token.token)
            {
                log::warn!("Refresh token destruction failure: {:?}", err);
            }
        }
        if let Some(ref device_info) = old_device_info {
            if let Err(err) = self.replace_device(
                &device_info.display_name,
                &device_info.device_type,
                &device_info.push_subscription,
                &device_info.available_commands,
            ) {
                log::warn!("Device information restoration failed: {:?}", err);
            }
        }
        // When our keys change, we might need to re-register device capabilities with the server.
        // Ensure that this happens on the next call to ensure_capabilities.
        self.state.device_capabilities.clear();
        Ok(())
    }

    /// Typically called during a password change flow.
    /// Invalidates all tokens and fetches a new refresh token.
    /// Because the old refresh token is not valid anymore, we can't do like `handle_oauth_response`
    /// and re-create the device, so it is the responsibility of the caller to do so after we're
    /// done.
    ///
    /// **💾 This method alters the persisted account state.**
    pub fn handle_session_token_change(&mut self, session_token: &str) -> Result<()> {
        let old_refresh_token = self
            .state
            .refresh_token
            .as_ref()
            .ok_or_else(|| ErrorKind::NoRefreshToken)?;
        let scopes: Vec<&str> = old_refresh_token.scopes.iter().map(AsRef::as_ref).collect();
        let resp = self.client.refresh_token_with_session_token(
            &self.state.config,
            &session_token,
            &scopes,
        )?;
        let new_refresh_token = resp
            .refresh_token
            .ok_or_else(|| ErrorKind::RefreshTokenNotPresent)?;
        self.state.refresh_token = Some(RefreshToken {
            token: new_refresh_token,
            scopes: HashSet::from_iter(resp.scope.split(' ').map(ToString::to_string)),
        });
        self.state.session_token = Some(session_token.to_owned());
        self.clear_access_token_cache();
        // When our keys change, we might need to re-register device capabilities with the server.
        // Ensure that this happens on the next call to ensure_capabilities.
        self.state.device_capabilities.clear();
        Ok(())
    }

    /// **💾 This method may alter the persisted account state.**
    pub fn clear_access_token_cache(&mut self) {
        self.state.access_token_cache.clear();
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct RefreshToken {
    pub token: String,
    pub scopes: HashSet<String>,
}

impl std::fmt::Debug for RefreshToken {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("RefreshToken")
            .field("scopes", &self.scopes)
            .finish()
    }
}

pub struct OAuthFlow {
    pub scoped_keys_flow: Option<ScopedKeysFlow>,
    pub code_verifier: String,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct AccessTokenInfo {
    pub scope: String,
    pub token: String,
    pub key: Option<ScopedKey>,
    pub expires_at: u64, // seconds since epoch
}

impl std::fmt::Debug for AccessTokenInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AccessTokenInfo")
            .field("scope", &self.scope)
            .field("key", &self.key)
            .field("expires_at", &self.expires_at)
            .finish()
    }
}

#[derive(Clone, Serialize, Deserialize, Debug)]
pub struct IntrospectInfo {
    pub active: bool,
    pub token_type: String,
    pub scope: Option<String>,
    pub exp: Option<u64>,
    pub iss: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::http_client::*;
    use std::borrow::Cow;
    use std::collections::HashMap;
    use std::sync::Arc;

    impl FirefoxAccount {
        pub fn add_cached_token(&mut self, scope: &str, token_info: AccessTokenInfo) {
            self.state
                .access_token_cache
                .insert(scope.to_string(), token_info);
        }
    }

    #[test]
    fn test_oauth_flow_url() {
        let mut fxa = FirefoxAccount::new(
            "https://accounts.firefox.com",
            "12345678",
            "https://foo.bar",
        );
        let url = fxa.begin_oauth_flow(&["profile"]).unwrap();
        let flow_url = Url::parse(&url).unwrap();

        assert_eq!(flow_url.host_str(), Some("accounts.firefox.com"));
        assert_eq!(flow_url.path(), "/authorization");

        let mut pairs = flow_url.query_pairs();
        assert_eq!(pairs.count(), 10);
        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("action"), Cow::Borrowed("email")))
        );
        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("response_type"), Cow::Borrowed("code")))
        );

        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("client_id"), Cow::Borrowed("12345678")))
        );

        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("scope"), Cow::Borrowed("profile")))
        );
        let state_param = pairs.next().unwrap();
        assert_eq!(state_param.0, Cow::Borrowed("state"));
        assert_eq!(state_param.1.len(), 22);
        assert_eq!(
            pairs.next(),
            Some((
                Cow::Borrowed("code_challenge_method"),
                Cow::Borrowed("S256")
            ))
        );
        let code_challenge_param = pairs.next().unwrap();
        assert_eq!(code_challenge_param.0, Cow::Borrowed("code_challenge"));
        assert_eq!(code_challenge_param.1.len(), 43);
        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("access_type"), Cow::Borrowed("offline")))
        );
        let keys_jwk = pairs.next().unwrap();
        assert_eq!(keys_jwk.0, Cow::Borrowed("keys_jwk"));
        assert_eq!(keys_jwk.1.len(), 168);

        assert_eq!(
            pairs.next(),
            Some((
                Cow::Borrowed("redirect_uri"),
                Cow::Borrowed("https://foo.bar")
            ))
        );
    }

    #[test]
    fn test_force_auth_url() {
        let mut fxa =
            FirefoxAccount::new("https://stable.dev.lcip.org", "12345678", "https://foo.bar");
        let email = "test@example.com";
        fxa.add_cached_profile("123", email);
        let url = fxa.begin_oauth_flow(&["profile"]).unwrap();
        let url = Url::parse(&url).unwrap();
        assert_eq!(url.path(), "/oauth/force_auth");
        let mut pairs = url.query_pairs();
        assert_eq!(
            pairs.find(|e| e.0 == "email"),
            Some((Cow::Borrowed("email"), Cow::Borrowed(email),))
        );
    }

    #[test]
    fn test_webchannel_context_url() {
        const SCOPES: &[&str] = &["https://identity.mozilla.com/apps/oldsync"];
        let mut fxa = FirefoxAccount::new(
            "https://accounts.firefox.com",
            "12345678",
            "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel",
        );
        let url = fxa.begin_oauth_flow(&SCOPES).unwrap();
        let url = Url::parse(&url).unwrap();
        let query_params: HashMap<_, _> = url.query_pairs().into_owned().collect();
        let context = &query_params["context"];
        assert_eq!(context, "oauth_webchannel_v1");
        assert_eq!(query_params.get("redirect_uri"), None);
    }

    #[test]
    fn test_webchannel_pairing_context_url() {
        const SCOPES: &[&str] = &["https://identity.mozilla.com/apps/oldsync"];
        const PAIRING_URL: &str = "https://accounts.firefox.com/pair#channel_id=658db7fe98b249a5897b884f98fb31b7&channel_key=1hIDzTj5oY2HDeSg_jA2DhcOcAn5Uqq0cAYlZRNUIo4";

        let mut fxa = FirefoxAccount::new(
            "https://accounts.firefox.com",
            "12345678",
            "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel",
        );
        let url = fxa.begin_pairing_flow(&PAIRING_URL, &SCOPES).unwrap();
        let url = Url::parse(&url).unwrap();
        let query_params: HashMap<_, _> = url.query_pairs().into_owned().collect();
        let context = &query_params["context"];
        assert_eq!(context, "oauth_webchannel_v1");
        assert_eq!(query_params.get("redirect_uri"), None);
    }

    #[test]
    fn test_pairing_flow_url() {
        const SCOPES: &[&str] = &["https://identity.mozilla.com/apps/oldsync"];
        const PAIRING_URL: &str = "https://accounts.firefox.com/pair#channel_id=658db7fe98b249a5897b884f98fb31b7&channel_key=1hIDzTj5oY2HDeSg_jA2DhcOcAn5Uqq0cAYlZRNUIo4";
        const EXPECTED_URL: &str = "https://accounts.firefox.com/pair/supp?client_id=12345678&redirect_uri=https%3A%2F%2Ffoo.bar&scope=https%3A%2F%2Fidentity.mozilla.com%2Fapps%2Foldsync&state=SmbAA_9EA5v1R2bgIPeWWw&code_challenge_method=S256&code_challenge=ZgHLPPJ8XYbXpo7VIb7wFw0yXlTa6MUOVfGiADt0JSM&access_type=offline&keys_jwk=eyJjcnYiOiJQLTI1NiIsImt0eSI6IkVDIiwieCI6Ing5LUltQjJveDM0LTV6c1VmbW5sNEp0Ti14elV2eFZlZXJHTFRXRV9BT0kiLCJ5IjoiNXBKbTB3WGQ4YXdHcm0zREl4T1pWMl9qdl9tZEx1TWlMb1RkZ1RucWJDZyJ9#channel_id=658db7fe98b249a5897b884f98fb31b7&channel_key=1hIDzTj5oY2HDeSg_jA2DhcOcAn5Uqq0cAYlZRNUIo4";

        let mut fxa = FirefoxAccount::new(
            "https://accounts.firefox.com",
            "12345678",
            "https://foo.bar",
        );
        let url = fxa.begin_pairing_flow(&PAIRING_URL, &SCOPES).unwrap();
        let flow_url = Url::parse(&url).unwrap();
        let expected_parsed_url = Url::parse(EXPECTED_URL).unwrap();

        assert_eq!(flow_url.host_str(), Some("accounts.firefox.com"));
        assert_eq!(flow_url.path(), "/pair/supp");
        assert_eq!(flow_url.fragment(), expected_parsed_url.fragment());

        let mut pairs = flow_url.query_pairs();
        assert_eq!(pairs.count(), 8);
        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("client_id"), Cow::Borrowed("12345678")))
        );
        assert_eq!(
            pairs.next(),
            Some((
                Cow::Borrowed("scope"),
                Cow::Borrowed("https://identity.mozilla.com/apps/oldsync")
            ))
        );

        let state_param = pairs.next().unwrap();
        assert_eq!(state_param.0, Cow::Borrowed("state"));
        assert_eq!(state_param.1.len(), 22);
        assert_eq!(
            pairs.next(),
            Some((
                Cow::Borrowed("code_challenge_method"),
                Cow::Borrowed("S256")
            ))
        );
        let code_challenge_param = pairs.next().unwrap();
        assert_eq!(code_challenge_param.0, Cow::Borrowed("code_challenge"));
        assert_eq!(code_challenge_param.1.len(), 43);
        assert_eq!(
            pairs.next(),
            Some((Cow::Borrowed("access_type"), Cow::Borrowed("offline")))
        );
        let keys_jwk = pairs.next().unwrap();
        assert_eq!(keys_jwk.0, Cow::Borrowed("keys_jwk"));
        assert_eq!(keys_jwk.1.len(), 168);

        assert_eq!(
            pairs.next(),
            Some((
                Cow::Borrowed("redirect_uri"),
                Cow::Borrowed("https://foo.bar")
            ))
        );
    }

    #[test]
    fn test_pairing_flow_origin_mismatch() {
        static PAIRING_URL: &str = "https://bad.origin.com/pair#channel_id=foo&channel_key=bar";
        let mut fxa = FirefoxAccount::new(
            "https://accounts.firefox.com",
            "12345678",
            "https://foo.bar",
        );
        let url =
            fxa.begin_pairing_flow(&PAIRING_URL, &["https://identity.mozilla.com/apps/oldsync"]);

        assert!(url.is_err());

        match url {
            Ok(_) => {
                panic!("should have error");
            }
            Err(err) => match err.kind() {
                ErrorKind::OriginMismatch { .. } => {}
                _ => panic!("error not OriginMismatch"),
            },
        }
    }

    #[test]
    fn test_check_authorization_status() {
        let mut fxa =
            FirefoxAccount::new("https://stable.dev.lcip.org", "12345678", "https://foo.bar");

        let refresh_token_scopes = std::collections::HashSet::new();
        fxa.state.refresh_token = Some(RefreshToken {
            token: "refresh_token".to_owned(),
            scopes: refresh_token_scopes,
        });

        let mut client = FxAClientMock::new();
        client
            .expect_oauth_introspect_refresh_token(mockiato::Argument::any, |token| {
                token.partial_eq("refresh_token")
            })
            .times(1)
            .returns_once(Ok(IntrospectResponse {
                active: true,
                token_type: "refresh".to_string(),
                scope: None,
                exp: None,
                iss: None,
            }));
        fxa.set_client(Arc::new(client));

        let auth_status = fxa.check_authorization_status().unwrap();
        assert_eq!(auth_status.active, true);
        assert_eq!(auth_status.token_type, "refresh".to_string());
        assert_eq!(auth_status.scope, None);
        assert_eq!(auth_status.exp, None);
        assert_eq!(auth_status.iss, None);
    }
}
