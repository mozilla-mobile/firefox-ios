/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module implements the ability to serialize a `FirefoxAccount` struct to and from
//! a JSON string. The idea is that calling code will use this to persist the account state
//! to storage.
//!
//! Many of the details here are a straightforward use of `serde`, with all persisted data being
//! a field on a `State` struct. This is, however, some additional complexity around handling data
//! migrations - we need to be able to evolve the internal details of the `State` struct while
//! gracefully handing users who are upgrading from an older version of a consuming app, which has
//! stored account state from an older version of this component.
//!
//! Data migration is handled by explicitly naming different versions of the state struct to
//! correspond to different incompatible changes to the data representation, e.g. `StateV1` and
//! `StateV2`. We then wrap this in a `PersistedState` enum whose serialization gets explicitly
//! tagged with the corresponding state version number.
//!
//! For backwards-compatible changes to the data (such as adding a new field that has a sensible
//! default) we keep the current `State` struct, but modify it in such a way that `serde` knows
//! how to do the right thing.
//!
//! For backwards-incompatible changes to the data (such as removing or significantly refactoring
//! fields) we define a new `StateV{X+1}` struct, and use the `From` trait to define how to update
//! from older struct versions.

use serde_derive::*;
use std::{
    collections::{HashMap, HashSet},
    iter::FromIterator,
};

use crate::{
    config::Config,
    device::Capability as DeviceCapability,
    migrator::MigrationData,
    oauth::{AccessTokenInfo, RefreshToken},
    profile::Profile,
    scoped_keys::ScopedKey,
    CachedResponse, Result,
};

// These are public API for working with the persisted state.

pub(crate) type State = StateV2;

pub(crate) fn state_from_json(data: &str) -> Result<State> {
    let stored_state: PersistedState = serde_json::from_str(data)?;
    upgrade_state(stored_state)
}

pub(crate) fn state_to_json(state: &State) -> Result<String> {
    let state = PersistedState::V2(state.clone());
    serde_json::to_string(&state).map_err(Into::into)
}

fn upgrade_state(in_state: PersistedState) -> Result<State> {
    match in_state {
        PersistedState::V1(state) => state.into(),
        PersistedState::V2(state) => Ok(state),
    }
}

// `PersistedState` is a tagged container for one of the state versions.
// Serde picks the right `StructVX` to deserialized based on the schema_version tag.

#[derive(Serialize, Deserialize)]
#[serde(tag = "schema_version")]
#[allow(clippy::large_enum_variant)]
enum PersistedState {
    #[serde(skip_serializing)]
    V1(StateV1),
    V2(StateV2),
}

// `StateV2` is the current state schema. It and its fields all need to be public
// so that they can be used directly elsewhere in the crate.
//
// If you want to modify what gets stored in the state, consider the following:
//
//   * Is the change backwards-compatible with previously-serialized data?
//     If so then you'll need to tell serde how to fill in a suitable default.
//     If not then you'll need to make a new `StateV3` and implement an explicit migration.
//
//   * Does the new field need to be modified when the user disconnects from the account?
//     If so then you'll need to update `StateV2.start_over` function.

#[derive(Clone, Serialize, Deserialize)]
pub(crate) struct StateV2 {
    pub(crate) config: Config,
    pub(crate) current_device_id: Option<String>,
    pub(crate) refresh_token: Option<RefreshToken>,
    pub(crate) scoped_keys: HashMap<String, ScopedKey>,
    pub(crate) last_handled_command: Option<u64>,
    // Everything below here was added after `StateV2` was initially defined,
    // and hence needs to have a suitable default value.
    // We can remove serde(default) when we define a `StateV3`.
    #[serde(default)]
    pub(crate) commands_data: HashMap<String, String>,
    #[serde(default)]
    pub(crate) device_capabilities: HashSet<DeviceCapability>,
    #[serde(default)]
    pub(crate) access_token_cache: HashMap<String, AccessTokenInfo>,
    pub(crate) session_token: Option<String>, // Hex-formatted string.
    pub(crate) last_seen_profile: Option<CachedResponse<Profile>>,
    pub(crate) in_flight_migration: Option<MigrationData>,
}

impl StateV2 {
    /// Clear the whole persisted state of the account, but keep just enough
    /// information to eventually reconnect to the same user account later.
    pub(crate) fn start_over(&self) -> StateV2 {
        StateV2 {
            config: self.config.clone(),
            current_device_id: None,
            // Leave the profile cache untouched so we can reconnect later.
            last_seen_profile: self.last_seen_profile.clone(),
            refresh_token: None,
            scoped_keys: HashMap::new(),
            last_handled_command: None,
            commands_data: HashMap::new(),
            access_token_cache: HashMap::new(),
            device_capabilities: HashSet::new(),
            session_token: None,
            in_flight_migration: None,
        }
    }
}

// Migration from `StateV1`. There was a lot of changing of structs and renaming of fields,
// but the key change is that we went from supporting multiple active refresh_tokens to
// only supporting a single one.

impl From<StateV1> for Result<StateV2> {
    fn from(state: StateV1) -> Self {
        let mut all_refresh_tokens: Vec<V1AuthInfo> = vec![];
        let mut all_scoped_keys = HashMap::new();
        for access_token in state.oauth_cache.values() {
            if access_token.refresh_token.is_some() {
                all_refresh_tokens.push(access_token.clone());
            }
            if let Some(ref scoped_keys) = access_token.keys {
                let scoped_keys: serde_json::Map<String, serde_json::Value> =
                    serde_json::from_str(scoped_keys)?;
                for (scope, key) in scoped_keys {
                    let scoped_key: ScopedKey = serde_json::from_value(key)?;
                    all_scoped_keys.insert(scope, scoped_key);
                }
            }
        }
        // In StateV2 we hold one and only one refresh token.
        // Obviously this means a loss of information.
        // Heuristic: We keep the most recent token.
        let refresh_token = all_refresh_tokens
            .iter()
            .max_by(|a, b| a.expires_at.cmp(&b.expires_at))
            .map(|token| RefreshToken {
                token: token.refresh_token.clone().expect(
                    "all_refresh_tokens should only contain access tokens with refresh tokens",
                ),
                scopes: HashSet::from_iter(token.scopes.iter().map(ToString::to_string)),
            });
        Ok(StateV2 {
            config: Config::init(
                state.config.content_url,
                state.config.auth_url,
                state.config.oauth_url,
                state.config.profile_url,
                state.config.token_server_endpoint_url,
                state.config.authorization_endpoint,
                state.config.issuer,
                state.config.jwks_uri,
                state.config.token_endpoint,
                state.config.userinfo_endpoint,
                None,
                state.client_id,
                state.redirect_uri,
            ),
            refresh_token,
            scoped_keys: all_scoped_keys,
            last_handled_command: None,
            commands_data: HashMap::new(),
            device_capabilities: HashSet::new(),
            session_token: None,
            current_device_id: None,
            last_seen_profile: None,
            in_flight_migration: None,
            access_token_cache: HashMap::new(),
        })
    }
}

// `StateV1` was a previous state schema.
//
// The below is sufficient to read existing state data serialized in this form, but should not
// be used to create new data using that schema, so it is deliberately private and deliberately
// does not derive(Serialize).
//
// If you find yourself modifying this code, you're almost certainly creating a potential data-migration
// problem and should reconsider.

#[derive(Deserialize)]
struct StateV1 {
    client_id: String,
    redirect_uri: String,
    config: V1Config,
    oauth_cache: HashMap<String, V1AuthInfo>,
}

#[derive(Deserialize)]
struct V1Config {
    content_url: String,
    auth_url: String,
    oauth_url: String,
    profile_url: String,
    token_server_endpoint_url: String,
    authorization_endpoint: String,
    issuer: String,
    jwks_uri: String,
    token_endpoint: String,
    userinfo_endpoint: String,
}

#[derive(Deserialize, Clone)]
struct V1AuthInfo {
    pub access_token: String,
    pub keys: Option<String>,
    pub refresh_token: Option<String>,
    pub expires_at: u64, // seconds since epoch
    pub scopes: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_migration_from_v1() {
        // This is a snapshot of what some persisted StateV1 data would look like in practice.
        // It's very important that you don't modify this string, which would defeat the point of the test!
        let state_v1_json = "{\"schema_version\":\"V1\",\"client_id\":\"98adfa37698f255b\",\"redirect_uri\":\"https://lockbox.firefox.com/fxa/ios-redirect.html\",\"config\":{\"content_url\":\"https://accounts.firefox.com\",\"auth_url\":\"https://api.accounts.firefox.com/\",\"oauth_url\":\"https://oauth.accounts.firefox.com/\",\"profile_url\":\"https://profile.accounts.firefox.com/\",\"token_server_endpoint_url\":\"https://token.services.mozilla.com/1.0/sync/1.5\",\"authorization_endpoint\":\"https://accounts.firefox.com/authorization\",\"issuer\":\"https://accounts.firefox.com\",\"jwks_uri\":\"https://oauth.accounts.firefox.com/v1/jwks\",\"token_endpoint\":\"https://oauth.accounts.firefox.com/v1/token\",\"userinfo_endpoint\":\"https://profile.accounts.firefox.com/v1/profile\"},\"oauth_cache\":{\"https://identity.mozilla.com/apps/oldsync https://identity.mozilla.com/apps/lockbox profile\":{\"access_token\":\"bef37ec0340783356bcac67a86c4efa23a56f2ddd0c7a6251d19988bab7bdc99\",\"keys\":\"{\\\"https://identity.mozilla.com/apps/oldsync\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/oldsync\\\",\\\"k\\\":\\\"kMtwpVC0ZaYFJymPza8rXK_0CgCp3KMwRStwGfBRBDtL6hXRDVJgQFaoOQ2dimw0Bko5WVv2gNTy7RX5zFYZHg\\\",\\\"kid\\\":\\\"1542236016429-Ox1FbJfFfwTe5t-xq4v2hQ\\\"},\\\"https://identity.mozilla.com/apps/lockbox\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/lockbox\\\",\\\"k\\\":\\\"Qk4K4xF2PgQ6XvBXW8X7B7AWwWgW2bHQov9NHNd4v-k\\\",\\\"kid\\\":\\\"1231014287-KDVj0DFaO3wGpPJD8oPwVg\\\"}}\",\"refresh_token\":\"bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188\",\"expires_at\":1543474657,\"scopes\":[\"https://identity.mozilla.com/apps/oldsync\",\"https://identity.mozilla.com/apps/lockbox\",\"profile\"]}}}";
        let state = state_from_json(state_v1_json).unwrap();
        assert!(state.refresh_token.is_some());
        let refresh_token = state.refresh_token.unwrap();
        assert_eq!(
            refresh_token.token,
            "bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188"
        );
        assert_eq!(refresh_token.scopes.len(), 3);
        assert!(refresh_token.scopes.contains("profile"));
        assert!(refresh_token
            .scopes
            .contains("https://identity.mozilla.com/apps/oldsync"));
        assert!(refresh_token
            .scopes
            .contains("https://identity.mozilla.com/apps/lockbox"));
        assert_eq!(state.scoped_keys.len(), 2);
        let oldsync_key = &state.scoped_keys["https://identity.mozilla.com/apps/oldsync"];
        assert_eq!(oldsync_key.kid, "1542236016429-Ox1FbJfFfwTe5t-xq4v2hQ");
        assert_eq!(oldsync_key.k, "kMtwpVC0ZaYFJymPza8rXK_0CgCp3KMwRStwGfBRBDtL6hXRDVJgQFaoOQ2dimw0Bko5WVv2gNTy7RX5zFYZHg");
        assert_eq!(oldsync_key.kty, "oct");
        assert_eq!(
            oldsync_key.scope,
            "https://identity.mozilla.com/apps/oldsync"
        );
        let lockbox_key = &state.scoped_keys["https://identity.mozilla.com/apps/lockbox"];

        assert_eq!(lockbox_key.kid, "1231014287-KDVj0DFaO3wGpPJD8oPwVg");
        assert_eq!(lockbox_key.k, "Qk4K4xF2PgQ6XvBXW8X7B7AWwWgW2bHQov9NHNd4v-k");
        assert_eq!(lockbox_key.kty, "oct");
        assert_eq!(
            lockbox_key.scope,
            "https://identity.mozilla.com/apps/lockbox"
        );
    }

    #[test]
    fn test_v2_ignores_unknown_fields_introduced_by_future_changes_to_the_schema() {
        // This is a snapshot of what some persisted StateV2 data would look before any backwards-compatible changes
        // were made. It's very important that you don't modify this string, which would defeat the point of the test!
        let state_v2_json = "{\"schema_version\":\"V2\",\"config\":{\"client_id\":\"98adfa37698f255b\",\"redirect_uri\":\"https://lockbox.firefox.com/fxa/ios-redirect.html\",\"content_url\":\"https://accounts.firefox.com\",\"remote_config\":{\"auth_url\":\"https://api.accounts.firefox.com/\",\"oauth_url\":\"https://oauth.accounts.firefox.com/\",\"profile_url\":\"https://profile.accounts.firefox.com/\",\"token_server_endpoint_url\":\"https://token.services.mozilla.com/1.0/sync/1.5\",\"authorization_endpoint\":\"https://accounts.firefox.com/authorization\",\"issuer\":\"https://accounts.firefox.com\",\"jwks_uri\":\"https://oauth.accounts.firefox.com/v1/jwks\",\"token_endpoint\":\"https://oauth.accounts.firefox.com/v1/token\",\"userinfo_endpoint\":\"https://profile.accounts.firefox.com/v1/profile\"}},\"refresh_token\":{\"token\":\"bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188\",\"scopes\":[\"https://identity.mozilla.com/apps/oldysnc\"]},\"scoped_keys\":{\"https://identity.mozilla.com/apps/oldsync\":{\"kty\":\"oct\",\"scope\":\"https://identity.mozilla.com/apps/oldsync\",\"k\":\"kMtwpVC0ZaYFJymPza8rXK_0CgCp3KMwRStwGfBRBDtL6hXRDVJgQFaoOQ2dimw0Bko5WVv2gNTy7RX5zFYZHg\",\"kid\":\"1542236016429-Ox1FbJfFfwTe5t-xq4v2hQ\"}},\"login_state\":{\"Unknown\":null},\"a_new_field\":42}";
        let state = state_from_json(state_v2_json).unwrap();
        let refresh_token = state.refresh_token.unwrap();
        assert_eq!(
            refresh_token.token,
            "bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188"
        );
    }

    #[test]
    fn test_v2_creates_an_empty_access_token_cache_if_its_missing() {
        let state_v2_json = "{\"schema_version\":\"V2\",\"config\":{\"client_id\":\"98adfa37698f255b\",\"redirect_uri\":\"https://lockbox.firefox.com/fxa/ios-redirect.html\",\"content_url\":\"https://accounts.firefox.com\", \"remote_config\":{\"auth_url\":\"https://api.accounts.firefox.com/\",\"oauth_url\":\"https://oauth.accounts.firefox.com/\",\"profile_url\":\"https://profile.accounts.firefox.com/\",\"token_server_endpoint_url\":\"https://token.services.mozilla.com/1.0/sync/1.5\",\"authorization_endpoint\":\"https://accounts.firefox.com/authorization\",\"issuer\":\"https://accounts.firefox.com\",\"jwks_uri\":\"https://oauth.accounts.firefox.com/v1/jwks\",\"token_endpoint\":\"https://oauth.accounts.firefox.com/v1/token\",\"userinfo_endpoint\":\"https://profile.accounts.firefox.com/v1/profile\"}},\"refresh_token\":{\"token\":\"bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188\",\"scopes\":[\"https://identity.mozilla.com/apps/oldysnc\"]},\"scoped_keys\":{\"https://identity.mozilla.com/apps/oldsync\":{\"kty\":\"oct\",\"scope\":\"https://identity.mozilla.com/apps/oldsync\",\"k\":\"kMtwpVC0ZaYFJymPza8rXK_0CgCp3KMwRStwGfBRBDtL6hXRDVJgQFaoOQ2dimw0Bko5WVv2gNTy7RX5zFYZHg\",\"kid\":\"1542236016429-Ox1FbJfFfwTe5t-xq4v2hQ\"}},\"login_state\":{\"Unknown\":null}}";
        let state = state_from_json(state_v2_json).unwrap();
        let refresh_token = state.refresh_token.unwrap();
        assert_eq!(
            refresh_token.token,
            "bed5532f4fea7e39c5c4f609f53603ee7518fd1c103cc4034da3618f786ed188"
        );
        assert_eq!(state.access_token_cache.len(), 0);
    }
}
