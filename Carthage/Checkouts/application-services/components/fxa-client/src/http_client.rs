/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{config::Config, error::*};
use hex;
use rc_crypto::hawk::{Credentials, Key, PayloadHasher, RequestBuilder, SHA256};
use rc_crypto::{digest, hkdf, hmac};
use serde_derive::*;
use serde_json::json;
use std::collections::HashMap;
use url::Url;
use viaduct::{header_names, status_codes, Method, Request, Response};

const HAWK_HKDF_SALT: [u8; 32] = [0b0; 32];
const HAWK_KEY_LENGTH: usize = 32;

#[cfg_attr(test, mockiato::mockable)]
pub trait FxAClient {
    fn refresh_token_with_code(
        &self,
        config: &Config,
        code: &str,
        code_verifier: &str,
    ) -> Result<OAuthTokenResponse>;
    fn refresh_token_with_session_token(
        &self,
        config: &Config,
        session_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse>;
    fn oauth_introspect_refresh_token(
        &self,
        config: &Config,
        refresh_token: &str,
    ) -> Result<IntrospectResponse>;
    fn access_token_with_refresh_token(
        &self,
        config: &Config,
        refresh_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse>;
    fn access_token_with_session_token(
        &self,
        config: &Config,
        session_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse>;
    fn authorization_code_using_session_token(
        &self,
        config: &Config,
        client_id: &str,
        session_token: &str,
        scope: &str,
        state: &str,
        access_type: &str,
    ) -> Result<OAuthAuthResponse>;
    fn duplicate_session(
        &self,
        config: &Config,
        session_token: &str,
    ) -> Result<DuplicateTokenResponse>;
    fn destroy_access_token(&self, config: &Config, token: &str) -> Result<()>;
    fn destroy_refresh_token(&self, config: &Config, token: &str) -> Result<()>;
    fn profile(
        &self,
        config: &Config,
        profile_access_token: &str,
        etag: Option<String>,
    ) -> Result<Option<ResponseAndETag<ProfileResponse>>>;
    fn pending_commands(
        &self,
        config: &Config,
        refresh_token: &str,
        index: u64,
        limit: Option<u64>,
    ) -> Result<PendingCommandsResponse>;
    fn invoke_command(
        &self,
        config: &Config,
        refresh_token: &str,
        command: &str,
        target: &str,
        payload: &serde_json::Value,
    ) -> Result<()>;
    fn devices(&self, config: &Config, refresh_token: &str) -> Result<Vec<GetDeviceResponse>>;
    fn update_device(
        &self,
        config: &Config,
        refresh_token: &str,
        update: DeviceUpdateRequest<'_>,
    ) -> Result<UpdateDeviceResponse>;
    fn destroy_device(&self, config: &Config, refresh_token: &str, id: &str) -> Result<()>;
    fn scoped_key_data(
        &self,
        config: &Config,
        session_token: &str,
        scope: &str,
    ) -> Result<HashMap<String, ScopedKeyDataResponse>>;
}

pub struct Client;
impl FxAClient for Client {
    fn profile(
        &self,
        config: &Config,
        access_token: &str,
        etag: Option<String>,
    ) -> Result<Option<ResponseAndETag<ProfileResponse>>> {
        let url = config.userinfo_endpoint()?;
        let mut request =
            Request::get(url).header(header_names::AUTHORIZATION, bearer_token(access_token))?;
        if let Some(etag) = etag {
            request = request.header(header_names::IF_NONE_MATCH, format!("\"{}\"", etag))?;
        }
        let resp = Self::make_request(request)?;
        if resp.status == status_codes::NOT_MODIFIED {
            return Ok(None);
        }
        let etag = resp
            .headers
            .get(header_names::ETAG)
            .map(ToString::to_string);
        Ok(Some(ResponseAndETag {
            etag,
            response: resp.json()?,
        }))
    }

    // For the one-off generation of a `refresh_token` and associated meta from transient credentials.

    fn refresh_token_with_code(
        &self,
        config: &Config,
        code: &str,
        code_verifier: &str,
    ) -> Result<OAuthTokenResponse> {
        let body = json!({
            "code": code,
            "client_id": config.client_id,
            "code_verifier": code_verifier
        });
        self.make_oauth_token_request(config, body)
    }

    fn refresh_token_with_session_token(
        &self,
        config: &Config,
        session_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse> {
        let url = config.token_endpoint()?;
        let key = derive_auth_key_from_session_token(&session_token)?;
        let body = json!({
            "client_id": config.client_id,
            "scope": scopes.join(" "),
            "grant_type": "fxa-credentials",
            "access_type": "offline",
        });
        let request = HawkRequestBuilder::new(Method::Post, url, &key)
            .body(body)
            .build()?;
        Ok(Self::make_request(request)?.json()?)
    }

    // For the regular generation of an `access_token` from long-lived credentials.

    fn access_token_with_refresh_token(
        &self,
        config: &Config,
        refresh_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse> {
        let body = json!({
            "grant_type": "refresh_token",
            "client_id": config.client_id,
            "refresh_token": refresh_token,
            "scope": scopes.join(" ")
        });
        self.make_oauth_token_request(config, body)
    }

    fn access_token_with_session_token(
        &self,
        config: &Config,
        session_token: &str,
        scopes: &[&str],
    ) -> Result<OAuthTokenResponse> {
        let parameters = json!({
            "client_id": config.client_id,
            "grant_type": "fxa-credentials",
            "scope": scopes.join(" ")
        });
        let key = derive_auth_key_from_session_token(session_token)?;
        let url = config.token_endpoint()?;
        let request = HawkRequestBuilder::new(Method::Post, url, &key)
            .body(parameters)
            .build()?;
        Self::make_request(request)?.json().map_err(Into::into)
    }

    fn authorization_code_using_session_token(
        &self,
        config: &Config,
        client_id: &str,
        session_token: &str,
        scope: &str,
        state: &str,
        access_type: &str,
    ) -> Result<OAuthAuthResponse> {
        let parameters = json!({
            "client_id": client_id,
            "scope": scope,
            "response_type": "code",
            "state": state,
            "access_type": access_type,
        });
        let key = derive_auth_key_from_session_token(session_token)?;
        let url = config.auth_url_path("v1/oauth/authorization")?;
        let request = HawkRequestBuilder::new(Method::Post, url, &key)
            .body(parameters)
            .build()?;

        Ok(Self::make_request(request)?.json()?)
    }

    fn oauth_introspect_refresh_token(
        &self,
        config: &Config,
        refresh_token: &str,
    ) -> Result<IntrospectResponse> {
        let body = json!({
            "token_type_hint": "refresh_token",
            "token": refresh_token,
        });
        let url = config.introspection_endpoint()?;
        Ok(Self::make_request(Request::post(url).json(&body))?.json()?)
    }

    fn duplicate_session(
        &self,
        config: &Config,
        session_token: &str,
    ) -> Result<DuplicateTokenResponse> {
        let url = config.auth_url_path("v1/session/duplicate")?;
        let key = derive_auth_key_from_session_token(&session_token)?;
        let duplicate_body = json!({
            "reason": "migration"
        });
        let request = HawkRequestBuilder::new(Method::Post, url, &key)
            .body(duplicate_body)
            .build()?;

        Ok(Self::make_request(request)?.json()?)
    }

    fn destroy_access_token(&self, config: &Config, access_token: &str) -> Result<()> {
        let body = json!({
            "token": access_token,
        });
        self.destroy_token_helper(config, &body)
    }

    fn destroy_refresh_token(&self, config: &Config, refresh_token: &str) -> Result<()> {
        let body = json!({
            "refresh_token": refresh_token,
        });
        self.destroy_token_helper(config, &body)
    }

    fn pending_commands(
        &self,
        config: &Config,
        refresh_token: &str,
        index: u64,
        limit: Option<u64>,
    ) -> Result<PendingCommandsResponse> {
        let url = config.auth_url_path("v1/account/device/commands")?;
        let mut request = Request::get(url)
            .header(header_names::AUTHORIZATION, bearer_token(refresh_token))?
            .query(&[("index", &index.to_string())]);
        if let Some(limit) = limit {
            request = request.query(&[("limit", &limit.to_string())])
        }
        Ok(Self::make_request(request)?.json()?)
    }

    fn invoke_command(
        &self,
        config: &Config,
        refresh_token: &str,
        command: &str,
        target: &str,
        payload: &serde_json::Value,
    ) -> Result<()> {
        let body = json!({
            "command": command,
            "target": target,
            "payload": payload
        });
        let url = config.auth_url_path("v1/account/devices/invoke_command")?;
        let request = Request::post(url)
            .header(header_names::AUTHORIZATION, bearer_token(refresh_token))?
            .header(header_names::CONTENT_TYPE, "application/json")?
            .body(body.to_string());
        Self::make_request(request)?;
        Ok(())
    }

    fn devices(&self, config: &Config, refresh_token: &str) -> Result<Vec<GetDeviceResponse>> {
        let url = config.auth_url_path("v1/account/devices")?;
        let request =
            Request::get(url).header(header_names::AUTHORIZATION, bearer_token(refresh_token))?;
        Ok(Self::make_request(request)?.json()?)
    }

    fn update_device(
        &self,
        config: &Config,
        refresh_token: &str,
        update: DeviceUpdateRequest<'_>,
    ) -> Result<UpdateDeviceResponse> {
        let url = config.auth_url_path("v1/account/device")?;
        let request = Request::post(url)
            .header(header_names::AUTHORIZATION, bearer_token(refresh_token))?
            .header(header_names::CONTENT_TYPE, "application/json")?
            .body(serde_json::to_string(&update)?);
        Ok(Self::make_request(request)?.json()?)
    }

    fn destroy_device(&self, config: &Config, refresh_token: &str, id: &str) -> Result<()> {
        let body = json!({
            "id": id,
        });
        let url = config.auth_url_path("v1/account/device/destroy")?;
        let request = Request::post(url)
            .header(header_names::AUTHORIZATION, bearer_token(refresh_token))?
            .header(header_names::CONTENT_TYPE, "application/json")?
            .body(body.to_string());

        Self::make_request(request)?;
        Ok(())
    }

    fn scoped_key_data(
        &self,
        config: &Config,
        session_token: &str,
        scope: &str,
    ) -> Result<HashMap<String, ScopedKeyDataResponse>> {
        let body = json!({
            "client_id": config.client_id,
            "scope": scope,
        });
        let url = config.auth_url_path("v1/account/scoped-key-data")?;
        let key = derive_auth_key_from_session_token(session_token)?;
        let request = HawkRequestBuilder::new(Method::Post, url, &key)
            .body(body)
            .build()?;
        Self::make_request(request)?.json().map_err(|e| e.into())
    }
}

impl Client {
    pub fn new() -> Self {
        Self {}
    }

    fn destroy_token_helper(&self, config: &Config, body: &serde_json::Value) -> Result<()> {
        let url = config.oauth_url_path("v1/destroy")?;
        Self::make_request(Request::post(url).json(body))?;
        Ok(())
    }

    fn make_oauth_token_request(
        &self,
        config: &Config,
        body: serde_json::Value,
    ) -> Result<OAuthTokenResponse> {
        let url = config.token_endpoint()?;
        Ok(Self::make_request(Request::post(url).json(&body))?.json()?)
    }

    fn make_request(request: Request) -> Result<Response> {
        let resp = request.send()?;
        if resp.is_success() || resp.status == status_codes::NOT_MODIFIED {
            Ok(resp)
        } else {
            let json: std::result::Result<serde_json::Value, _> = resp.json();
            match json {
                Ok(json) => Err(ErrorKind::RemoteError {
                    code: json["code"].as_u64().unwrap_or(0),
                    errno: json["errno"].as_u64().unwrap_or(0),
                    error: json["error"].as_str().unwrap_or("").to_string(),
                    message: json["message"].as_str().unwrap_or("").to_string(),
                    info: json["info"].as_str().unwrap_or("").to_string(),
                }
                .into()),
                Err(_) => Err(resp.require_success().unwrap_err().into()),
            }
        }
    }
}

fn bearer_token(token: &str) -> String {
    format!("Bearer {}", token)
}

fn kw(name: &str) -> Vec<u8> {
    format!("identity.mozilla.com/picl/v1/{}", name)
        .as_bytes()
        .to_vec()
}

pub fn derive_auth_key_from_session_token(session_token: &str) -> Result<Vec<u8>> {
    let session_token_bytes = hex::decode(session_token)?;
    let context_info = kw("sessionToken");
    let salt = hmac::SigningKey::new(&digest::SHA256, &HAWK_HKDF_SALT);
    let mut out = vec![0u8; HAWK_KEY_LENGTH * 2];
    hkdf::extract_and_expand(&salt, &session_token_bytes, &context_info, &mut out)?;
    Ok(out)
}

struct HawkRequestBuilder<'a> {
    url: Url,
    method: Method,
    body: Option<String>,
    hkdf_sha256_key: &'a [u8],
}

impl<'a> HawkRequestBuilder<'a> {
    pub fn new(method: Method, url: Url, hkdf_sha256_key: &'a [u8]) -> Self {
        rc_crypto::ensure_initialized();
        HawkRequestBuilder {
            url,
            method,
            body: None,
            hkdf_sha256_key,
        }
    }

    // This class assumes that the content being sent it always of the type
    // application/json.
    pub fn body(mut self, body: serde_json::Value) -> Self {
        self.body = Some(body.to_string());
        self
    }

    fn make_hawk_header(&self) -> Result<String> {
        // Make sure we de-allocate the hash after hawk_request_builder.
        let hash;
        let method = format!("{}", self.method);
        let mut hawk_request_builder = RequestBuilder::from_url(method.as_str(), &self.url)?;
        if let Some(ref body) = self.body {
            hash = PayloadHasher::hash("application/json", SHA256, &body)?;
            hawk_request_builder = hawk_request_builder.hash(&hash[..]);
        }
        let hawk_request = hawk_request_builder.request();
        let token_id = hex::encode(&self.hkdf_sha256_key[0..HAWK_KEY_LENGTH]);
        let hmac_key = &self.hkdf_sha256_key[HAWK_KEY_LENGTH..(2 * HAWK_KEY_LENGTH)];
        let hawk_credentials = Credentials {
            id: token_id,
            key: Key::new(hmac_key, SHA256)?,
        };
        let header = hawk_request.make_header(&hawk_credentials)?;
        Ok(format!("Hawk {}", header))
    }

    pub fn build(self) -> Result<Request> {
        let hawk_header = self.make_hawk_header()?;
        let mut request =
            Request::new(self.method, self.url).header(header_names::AUTHORIZATION, hawk_header)?;
        if let Some(body) = self.body {
            request = request
                .header(header_names::CONTENT_TYPE, "application/json")?
                .body(body);
        }
        Ok(request)
    }
}

#[derive(Clone)]
pub struct ResponseAndETag<T> {
    pub response: T,
    pub etag: Option<String>,
}

#[derive(Deserialize)]
pub struct PendingCommandsResponse {
    pub index: u64,
    pub last: Option<bool>,
    pub messages: Vec<PendingCommand>,
}

#[derive(Deserialize)]
pub struct PendingCommand {
    pub index: u64,
    pub data: CommandData,
}

#[derive(Debug, Deserialize)]
pub struct CommandData {
    pub command: String,
    pub payload: serde_json::Value, // Need https://github.com/serde-rs/serde/issues/912 to make payload an enum instead.
    pub sender: Option<String>,
}

#[derive(Clone, Deserialize, Serialize)]
pub struct PushSubscription {
    #[serde(rename = "pushCallback")]
    pub endpoint: String,
    #[serde(rename = "pushPublicKey")]
    pub public_key: String,
    #[serde(rename = "pushAuthKey")]
    pub auth_key: String,
}

/// We use the double Option pattern in this struct.
/// The outer option represents the existence of the field
/// and the inner option its value or null.
/// TL;DR:
/// `None`: the field will not be present in the JSON body.
/// `Some(None)`: the field will have a `null` value.
/// `Some(Some(T))`: the field will have the serialized value of T.
#[derive(Serialize)]
#[allow(clippy::option_option)]
pub struct DeviceUpdateRequest<'a> {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "name")]
    display_name: Option<Option<&'a str>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "type")]
    device_type: Option<Option<&'a DeviceType>>,
    #[serde(flatten)]
    push_subscription: Option<&'a PushSubscription>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "availableCommands")]
    available_commands: Option<Option<&'a HashMap<String, String>>>,
}

#[derive(Clone, Serialize, Deserialize)]
pub enum DeviceType {
    #[serde(rename = "desktop")]
    Desktop,
    #[serde(rename = "mobile")]
    Mobile,
    #[serde(rename = "tablet")]
    Tablet,
    #[serde(rename = "vr")]
    VR,
    #[serde(rename = "tv")]
    TV,
    #[serde(other)]
    #[serde(skip_serializing)] // Don't you dare trying.
    Unknown,
}

#[allow(clippy::option_option)]
pub struct DeviceUpdateRequestBuilder<'a> {
    device_type: Option<Option<&'a DeviceType>>,
    display_name: Option<Option<&'a str>>,
    push_subscription: Option<&'a PushSubscription>,
    available_commands: Option<Option<&'a HashMap<String, String>>>,
}

impl<'a> DeviceUpdateRequestBuilder<'a> {
    pub fn new() -> Self {
        Self {
            device_type: None,
            display_name: None,
            push_subscription: None,
            available_commands: None,
        }
    }

    pub fn push_subscription(mut self, push_subscription: &'a PushSubscription) -> Self {
        self.push_subscription = Some(push_subscription);
        self
    }

    pub fn available_commands(mut self, available_commands: &'a HashMap<String, String>) -> Self {
        self.available_commands = Some(Some(available_commands));
        self
    }

    pub fn clear_available_commands(mut self) -> Self {
        self.available_commands = Some(None);
        self
    }

    pub fn display_name(mut self, display_name: &'a str) -> Self {
        self.display_name = Some(Some(display_name));
        self
    }

    pub fn clear_display_name(mut self) -> Self {
        self.display_name = Some(None);
        self
    }

    #[allow(dead_code)]
    pub fn device_type(mut self, device_type: &'a DeviceType) -> Self {
        self.device_type = Some(Some(device_type));
        self
    }

    pub fn build(self) -> DeviceUpdateRequest<'a> {
        DeviceUpdateRequest {
            display_name: self.display_name,
            device_type: self.device_type,
            push_subscription: self.push_subscription,
            available_commands: self.available_commands,
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DeviceLocation {
    pub city: Option<String>,
    pub country: Option<String>,
    pub state: Option<String>,
    #[serde(rename = "stateCode")]
    pub state_code: Option<String>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct GetDeviceResponse {
    #[serde(flatten)]
    pub common: DeviceResponseCommon,
    #[serde(rename = "isCurrentDevice")]
    pub is_current_device: bool,
    pub location: DeviceLocation,
    #[serde(rename = "lastAccessTime")]
    pub last_access_time: Option<u64>,
}

impl std::ops::Deref for GetDeviceResponse {
    type Target = DeviceResponseCommon;
    fn deref(&self) -> &DeviceResponseCommon {
        &self.common
    }
}

pub type UpdateDeviceResponse = DeviceResponseCommon;

#[derive(Clone, Serialize, Deserialize)]
pub struct DeviceResponseCommon {
    pub id: String,
    #[serde(rename = "name")]
    pub display_name: String,
    #[serde(rename = "type")]
    pub device_type: DeviceType,
    #[serde(flatten)]
    pub push_subscription: Option<PushSubscription>,
    #[serde(rename = "availableCommands")]
    pub available_commands: HashMap<String, String>,
    #[serde(rename = "pushEndpointExpired")]
    pub push_endpoint_expired: bool,
}

#[derive(Deserialize)]
pub struct OAuthTokenResponse {
    pub keys_jwe: Option<String>,
    pub refresh_token: Option<String>,
    pub session_token: Option<String>,
    pub expires_in: u64,
    pub scope: String,
    pub access_token: String,
}

#[derive(Deserialize, Debug)]
pub struct OAuthAuthResponse {
    pub redirect: String,
    pub code: String,
    pub state: String,
}

#[derive(Deserialize)]
pub struct IntrospectResponse {
    pub active: bool,
    pub token_type: String,
    pub scope: Option<String>,
    pub exp: Option<u64>,
    pub iss: Option<String>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct ProfileResponse {
    pub uid: String,
    pub email: String,
    pub locale: String,
    #[serde(rename = "displayName")]
    pub display_name: Option<String>,
    pub avatar: String,
    #[serde(rename = "avatarDefault")]
    pub avatar_default: bool,
    #[serde(rename = "amrValues")]
    pub amr_values: Vec<String>,
    #[serde(rename = "twoFactorAuthentication")]
    pub two_factor_authentication: bool,
}

#[derive(Deserialize)]
pub struct ScopedKeyDataResponse {
    pub identifier: String,
    #[serde(rename = "keyRotationSecret")]
    pub key_rotation_secret: String,
    #[serde(rename = "keyRotationTimestamp")]
    pub key_rotation_timestamp: u64,
}

#[derive(Deserialize, Clone, Debug, PartialEq, Eq)]
pub struct DuplicateTokenResponse {
    pub uid: String,
    #[serde(rename = "sessionToken")]
    pub session_token: String,
    pub verified: bool,
    #[serde(rename = "authAt")]
    pub auth_at: u64,
}
