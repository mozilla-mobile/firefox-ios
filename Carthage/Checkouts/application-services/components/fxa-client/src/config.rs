/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use serde_derive::*;
use std::{cell::RefCell, sync::Arc};
use url::Url;
use viaduct::Request;

#[derive(Deserialize)]
struct ClientConfigurationResponse {
    auth_server_base_url: String,
    oauth_server_base_url: String,
    profile_server_base_url: String,
    sync_tokenserver_base_url: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct OpenIdConfigurationResponse {
    authorization_endpoint: String,
    issuer: String,
    jwks_uri: String,
    token_endpoint: String,
    userinfo_endpoint: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Config {
    content_url: String,
    // RemoteConfig is lazily fetched from the server.
    remote_config: RefCell<Option<Arc<RemoteConfig>>>,
    pub client_id: String,
    pub redirect_uri: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
/// `RemoteConfig` struct stores configuration values from the FxA
/// `/.well-known/fxa-client-configuration` and the
/// `/.well-known/openid-configuration` endpoints.
pub struct RemoteConfig {
    auth_url: String,
    oauth_url: String,
    profile_url: String,
    token_server_endpoint_url: String,
    authorization_endpoint: String,
    issuer: String,
    jwks_uri: String,
    token_endpoint: String,
    userinfo_endpoint: String,
    // This was added later, and may be mising in serialized configs.
    introspection_endpoint: Option<String>,
}

impl Config {
    pub fn release(client_id: &str, redirect_uri: &str) -> Self {
        Self::new("https://accounts.firefox.com", client_id, redirect_uri)
    }

    pub fn stable_dev(client_id: &str, redirect_uri: &str) -> Self {
        Self::new("https://stable.dev.lcip.org", client_id, redirect_uri)
    }

    pub fn stage_dev(client_id: &str, redirect_uri: &str) -> Self {
        Self::new("https://accounts.stage.mozaws.net", client_id, redirect_uri)
    }

    pub fn china(client_id: &str, redirect_uri: &str) -> Self {
        Self::new("https://accounts.firefox.com.cn", client_id, redirect_uri)
    }

    pub fn new(content_url: &str, client_id: &str, redirect_uri: &str) -> Self {
        Self {
            content_url: content_url.to_string(),
            client_id: client_id.to_string(),
            redirect_uri: redirect_uri.to_string(),
            remote_config: RefCell::new(None),
        }
    }

    // FIXME
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn init(
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
        introspection_endpoint: Option<String>,
        client_id: String,
        redirect_uri: String,
    ) -> Self {
        let remote_config = RemoteConfig {
            auth_url,
            oauth_url,
            profile_url,
            token_server_endpoint_url,
            authorization_endpoint,
            issuer,
            jwks_uri,
            token_endpoint,
            userinfo_endpoint,
            introspection_endpoint,
        };

        Config {
            content_url,
            remote_config: RefCell::new(Some(Arc::new(remote_config))),
            client_id,
            redirect_uri,
        }
    }

    fn remote_config(&self) -> Result<Arc<RemoteConfig>> {
        if let Some(remote_config) = self.remote_config.borrow().clone() {
            return Ok(remote_config);
        }

        let config_url =
            Url::parse(&self.content_url)?.join(".well-known/fxa-client-configuration")?;
        let resp: ClientConfigurationResponse =
            Request::get(config_url).send()?.require_success()?.json()?;

        let openid_config_url =
            Url::parse(&self.content_url)?.join(".well-known/openid-configuration")?;
        let openid_resp: OpenIdConfigurationResponse = Request::get(openid_config_url)
            .send()?
            .require_success()?
            .json()?;

        let remote_config = self.set_remote_config(RemoteConfig {
            auth_url: format!("{}/", resp.auth_server_base_url),
            oauth_url: format!("{}/", resp.oauth_server_base_url),
            profile_url: format!("{}/", resp.profile_server_base_url),
            token_server_endpoint_url: format!("{}/", resp.sync_tokenserver_base_url),
            authorization_endpoint: openid_resp.authorization_endpoint,
            issuer: openid_resp.issuer,
            jwks_uri: openid_resp.jwks_uri,
            // TODO: bring back openid token endpoint once https://github.com/mozilla/fxa/issues/453 has been resolved
            // and the openid response has been switched to the new endpoint.
            // token_endpoint: openid_resp.token_endpoint,
            token_endpoint: format!("{}/v1/oauth/token", resp.auth_server_base_url),
            userinfo_endpoint: openid_resp.userinfo_endpoint,
            introspection_endpoint: Some(format!("{}/v1/introspect", resp.oauth_server_base_url)),
        });
        Ok(remote_config)
    }

    fn set_remote_config(&self, remote_config: RemoteConfig) -> Arc<RemoteConfig> {
        let rc = Arc::new(remote_config);
        let result = rc.clone();
        self.remote_config.replace(Some(rc));
        result
    }

    pub fn content_url(&self) -> Result<Url> {
        Url::parse(&self.content_url).map_err(Into::into)
    }

    pub fn content_url_path(&self, path: &str) -> Result<Url> {
        self.content_url()?.join(path).map_err(Into::into)
    }

    pub fn auth_url(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.auth_url).map_err(Into::into)
    }

    pub fn auth_url_path(&self, path: &str) -> Result<Url> {
        self.auth_url()?.join(path).map_err(Into::into)
    }

    pub fn profile_url(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.profile_url).map_err(Into::into)
    }

    pub fn profile_url_path(&self, path: &str) -> Result<Url> {
        self.profile_url()?.join(path).map_err(Into::into)
    }

    pub fn oauth_url(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.oauth_url).map_err(Into::into)
    }

    pub fn oauth_url_path(&self, path: &str) -> Result<Url> {
        self.oauth_url()?.join(path).map_err(Into::into)
    }

    pub fn token_server_endpoint_url(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.token_server_endpoint_url).map_err(Into::into)
    }

    pub fn authorization_endpoint(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.authorization_endpoint).map_err(Into::into)
    }

    pub fn issuer(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.issuer).map_err(Into::into)
    }

    pub fn jwks_uri(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.jwks_uri).map_err(Into::into)
    }

    pub fn token_endpoint(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.token_endpoint).map_err(Into::into)
    }

    pub fn introspection_endpoint(&self) -> Result<Url> {
        let remote_config = &self.remote_config()?;
        // Fill a default on demand if we don't have this in config.
        if remote_config.introspection_endpoint.is_none() {
            self.set_remote_config(RemoteConfig {
                introspection_endpoint: Some(format!("{}/v1/introspect", remote_config.oauth_url)),
                ..(**remote_config).clone()
            });
        }
        Url::parse(
            &self
                .remote_config()?
                .introspection_endpoint
                .as_ref()
                .unwrap(),
        )
        .map_err(Into::into)
    }

    pub fn userinfo_endpoint(&self) -> Result<Url> {
        Url::parse(&self.remote_config()?.userinfo_endpoint).map_err(Into::into)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_paths() {
        let remote_config = RemoteConfig {
            auth_url: "https://stable.dev.lcip.org/auth/".to_string(),
            oauth_url: "https://oauth-stable.dev.lcip.org/".to_string(),
            profile_url: "https://stable.dev.lcip.org/profile/".to_string(),
            token_server_endpoint_url: "https://stable.dev.lcip.org/syncserver/token/1.0/sync/1.5"
                .to_string(),
            authorization_endpoint: "https://oauth-stable.dev.lcip.org/v1/authorization"
                .to_string(),
            issuer: "https://dev.lcip.org/".to_string(),
            jwks_uri: "https://oauth-stable.dev.lcip.org/v1/jwks".to_string(),
            token_endpoint: "https://stable.dev.lcip.org/auth/v1/oauth/token".to_string(),
            introspection_endpoint: Some(
                "https://oauth-stable.dev.lcip.org/v1/introspect".to_string(),
            ),
            userinfo_endpoint: "https://stable.dev.lcip.org/profile/v1/profile".to_string(),
        };

        let config = Config {
            content_url: "https://stable.dev.lcip.org/".to_string(),
            remote_config: RefCell::new(Some(Arc::new(remote_config))),
            client_id: "263ceaa5546dce83".to_string(),
            redirect_uri: "https://127.0.0.1:8080".to_string(),
        };
        assert_eq!(
            config.auth_url_path("v1/account/keys").unwrap().to_string(),
            "https://stable.dev.lcip.org/auth/v1/account/keys"
        );
        assert_eq!(
            config.oauth_url_path("v1/token").unwrap().to_string(),
            "https://oauth-stable.dev.lcip.org/v1/token"
        );
        assert_eq!(
            config.profile_url_path("v1/profile").unwrap().to_string(),
            "https://stable.dev.lcip.org/profile/v1/profile"
        );
        assert_eq!(
            config.content_url_path("oauth/signin").unwrap().to_string(),
            "https://stable.dev.lcip.org/oauth/signin"
        );
        assert_eq!(
            config.token_server_endpoint_url().unwrap().to_string(),
            "https://stable.dev.lcip.org/syncserver/token/1.0/sync/1.5"
        );

        assert_eq!(
            config.token_endpoint().unwrap().to_string(),
            "https://stable.dev.lcip.org/auth/v1/oauth/token"
        );

        assert_eq!(
            config.introspection_endpoint().unwrap().to_string(),
            "https://oauth-stable.dev.lcip.org/v1/introspect"
        );
    }
}
