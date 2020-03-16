/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
// Let's allow these in the FFI code, since it's usually just a coincidence if
// the closure is small.
#![allow(clippy::redundant_closure)]
use ffi_support::{
    define_bytebuffer_destructor, define_handle_map_deleter, define_string_destructor, ByteBuffer,
    ConcurrentHandleMap, ExternError, FfiStr,
};
use fxa_client::{
    device::{Capability as DeviceCapability, PushSubscription},
    migrator::MigrationState,
    msg_types, FirefoxAccount,
};
use std::os::raw::c_char;
use url::Url;

lazy_static::lazy_static! {
    static ref ACCOUNTS: ConcurrentHandleMap<FirefoxAccount> = ConcurrentHandleMap::new();
}

/// Creates a [FirefoxAccount].
///
/// # Safety
///
/// A destructor [fxa_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_new(
    content_url: FfiStr<'_>,
    client_id: FfiStr<'_>,
    redirect_uri: FfiStr<'_>,
    err: &mut ExternError,
) -> u64 {
    log::debug!("fxa_new");
    ACCOUNTS.insert_with_output(err, || {
        let content_url = content_url.as_str();
        let client_id = client_id.as_str();
        let redirect_uri = redirect_uri.as_str();
        FirefoxAccount::new(content_url, client_id, redirect_uri)
    })
}

/// Restore a [FirefoxAccount] instance from an serialized state (created with [fxa_to_json]).
///
/// # Safety
///
/// A destructor [fxa_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_from_json(json: FfiStr<'_>, err: &mut ExternError) -> u64 {
    log::debug!("fxa_from_json");
    ACCOUNTS.insert_with_result(err, || FirefoxAccount::from_json(json.as_str()))
}

/// Serializes the state of a [FirefoxAccount] instance. It can be restored later with [fxa_from_json].
///
/// It is the responsability of the caller to persist that serialized state regularly (after operations that mutate [FirefoxAccount])
/// in a **secure** location.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_to_json(handle: u64, error: &mut ExternError) -> *mut c_char {
    log::debug!("fxa_to_json");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.to_json())
}

/// Fetches the profile associated with a Firefox Account.
///
/// The profile might get cached in-memory and the caller might get served a cached version.
/// To bypass this, the `ignore_cache` parameter can be set to `true`.
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_profile(
    handle: u64,
    ignore_cache: bool,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("fxa_profile");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.get_profile(ignore_cache))
}

/// Get the Sync token server endpoint URL.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_token_server_endpoint_url(
    handle: u64,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_get_token_server_endpoint_url");
    ACCOUNTS.call_with_result(error, handle, |fxa| {
        fxa.get_token_server_endpoint_url().map(Url::into_string)
    })
}

/// Get the url to redirect after there has been a successful connection to FxA.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_connection_success_url(
    handle: u64,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_get_connection_success_url");
    ACCOUNTS.call_with_result(error, handle, |fxa| {
        fxa.get_connection_success_url().map(Url::into_string)
    })
}

/// Get the url to open the user's account-management page.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_manage_account_url(
    handle: u64,
    entrypoint: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_get_manage_account_url");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        fxa.get_manage_account_url(entrypoint.as_str())
            .map(Url::into_string)
    })
}

/// Get the url to open the user's devices-management page.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_manage_devices_url(
    handle: u64,
    entrypoint: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_get_manage_devices_url");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        fxa.get_manage_devices_url(entrypoint.as_str())
            .map(Url::into_string)
    })
}

/// Request a OAuth token by starting a new pairing flow, by calling the content server pairing endpoint.
///
/// This function returns a URL string that the caller should open in a webview.
///
/// Pairing assumes you want keys by default, so you must provide a key-bearing scope.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_begin_pairing_flow(
    handle: u64,
    pairing_url: FfiStr<'_>,
    scope: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_begin_pairing_flow");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let pairing_url = pairing_url.as_str();
        let scope = scope.as_str();
        let scopes: Vec<&str> = scope.split(' ').collect();
        fxa.begin_pairing_flow(&pairing_url, &scopes)
    })
}

/// Request a OAuth token by starting a new OAuth flow.
///
/// This function returns a URL string that the caller should open in a webview.
///
/// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
/// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
/// [fxa_complete_oauth_flow] to complete the flow.
///
/// # Safety
///
/// A destructor [fxa_str_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_begin_oauth_flow(
    handle: u64,
    scope: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_begin_oauth_flow");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let scope = scope.as_str();
        let scopes: Vec<&str> = scope.split(' ').collect();
        fxa.begin_oauth_flow(&scopes)
    })
}

/// Finish an OAuth flow initiated by [fxa_begin_oauth_flow].
#[no_mangle]
pub extern "C" fn fxa_complete_oauth_flow(
    handle: u64,
    code: FfiStr<'_>,
    state: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("fxa_complete_oauth_flow");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let code = code.as_str();
        let state = state.as_str();
        fxa.complete_oauth_flow(code, state)
    });
}

/// Migrate from a logged-in sessionToken Firefox Account.
#[no_mangle]
pub extern "C" fn fxa_migrate_from_session_token(
    handle: u64,
    session_token: FfiStr<'_>,
    k_sync: FfiStr<'_>,
    k_xcs: FfiStr<'_>,
    copy_session_token: u8,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_migrate_from_session_token");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| -> fxa_client::Result<String> {
        let session_token = session_token.as_str();
        let k_sync = k_sync.as_str();
        let k_xcs = k_xcs.as_str();
        let migration_metrics =
            fxa.migrate_from_session_token(session_token, k_sync, k_xcs, copy_session_token != 0)?;
        let result = serde_json::to_string(&migration_metrics)?;
        Ok(result)
    })
}

/// Check if there is migration state.
#[no_mangle]
pub extern "C" fn fxa_is_in_migration_state(handle: u64, error: &mut ExternError) -> u8 {
    log::debug!("fxa_is_in_migration_state");
    ACCOUNTS.call_with_result(error, handle, |fxa| -> fxa_client::Result<MigrationState> {
        Ok(fxa.is_in_migration_state())
    })
}

/// Retry the migration attempt using the stored migration state.
#[no_mangle]
pub extern "C" fn fxa_retry_migrate_from_session_token(
    handle: u64,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_retry_migrate_from_session_token");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| -> fxa_client::Result<String> {
        let migration_metrics = fxa.try_migration()?;
        let result = serde_json::to_string(&migration_metrics)?;
        Ok(result)
    })
}

/// Try to get an access token.
///
/// If the system can't find a suitable token but has a `refresh token` or a `session_token`,
/// it will generate a new one on the go.
///
/// If not, the caller must start an OAuth flow with [fxa_begin_oauth_flow].
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_access_token(
    handle: u64,
    scope: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("fxa_get_access_token");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let scope = scope.as_str();
        fxa.get_access_token(scope)
    })
}

/// Try to get a session token.
///
/// If the system can't find a suitable token it will return an error
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_session_token(handle: u64, error: &mut ExternError) -> *mut c_char {
    log::debug!("fxa_get_session_token");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.get_session_token())
}

/// Retrieve the refresh token authorization status.
#[no_mangle]
pub extern "C" fn fxa_check_authorization_status(
    handle: u64,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("fxa_check_authorization_status");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.check_authorization_status())
}

/// This method should be called when a request made with
/// an OAuth token failed with an authentication error.
/// It clears the internal cache of OAuth access tokens,
/// so the caller can try to call `fxa_get_access_token` or `fxa_profile`
/// again.
#[no_mangle]
pub extern "C" fn fxa_clear_access_token_cache(handle: u64, error: &mut ExternError) {
    log::debug!("fxa_clear_access_token_cache");
    ACCOUNTS.call_with_output_mut(error, handle, |fxa| fxa.clear_access_token_cache())
}

/// Try to get the current device id from state.
///
/// If the system can't find it then it will return an error
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_current_device_id(handle: u64, error: &mut ExternError) -> *mut c_char {
    log::debug!("fxa_get_current_device_id");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.get_current_device_id())
}

/// Update the Push subscription information for the current device.
#[no_mangle]
pub extern "C" fn fxa_set_push_subscription(
    handle: u64,
    endpoint: FfiStr<'_>,
    public_key: FfiStr<'_>,
    auth_key: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("fxa_set_push_subscription");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let ps = PushSubscription {
            endpoint: endpoint.into_string(),
            public_key: public_key.into_string(),
            auth_key: auth_key.into_string(),
        };
        // We don't really care about passing back the resulting Device record.
        // We might in the future though.
        fxa.set_push_subscription(&ps).map(|_| ())
    })
}

/// Update the display name for the current device.
#[no_mangle]
pub extern "C" fn fxa_set_device_name(
    handle: u64,
    display_name: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("fxa_set_device_name");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        // We don't really care about passing back the resulting Device record.
        // We might in the future though.
        fxa.set_device_name(display_name.as_str()).map(|_| ())
    })
}

/// Fetch the devices (including the current one) in the current account.
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_get_devices(handle: u64, error: &mut ExternError) -> ByteBuffer {
    log::debug!("fxa_get_devices");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        fxa.get_devices().map(|d| {
            let devices = d.into_iter().map(|device| device.into()).collect();
            fxa_client::msg_types::Devices { devices }
        })
    })
}

/// Try to get an OAuth code using a session token.
///
/// The system will use the stored `session_token` to provision a new code and return it.
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_authorize_auth_code(
    handle: u64,
    client_id: FfiStr<'_>,
    scope: FfiStr<'_>,
    state: FfiStr<'_>,
    access_type: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("fxa_authorize_auth_code");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let client_id = client_id.as_str();
        let scope = scope.as_str();
        let state = state.as_str();
        let access_type = access_type.as_str();
        fxa.authorize_code_using_session_token(client_id, scope, state, access_type)
    })
}

/// Typically called during a password change flow.
/// Invalidate all tokens and get a new refresh token.
#[no_mangle]
pub extern "C" fn fxa_handle_session_token_change(
    handle: u64,
    new_session_token: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("fxa_handle_session_token_change");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let new_session_token = new_session_token.as_str();
        fxa.handle_session_token_change(new_session_token)
    })
}

/// Poll and parse available remote commands targeted to our own device.
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_poll_device_commands(handle: u64, error: &mut ExternError) -> ByteBuffer {
    log::debug!("fxa_poll_device_commands");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        fxa.poll_device_commands().map(|cmds| {
            let commands = cmds.into_iter().map(|e| e.into()).collect();
            fxa_client::msg_types::IncomingDeviceCommands { commands }
        })
    })
}

/// Disconnect from the account and optionaly destroy our device record.
#[no_mangle]
pub extern "C" fn fxa_disconnect(handle: u64, error: &mut ExternError) {
    log::debug!("fxa_disconnect");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| -> fxa_client::Result<()> {
        fxa.disconnect();
        Ok(())
    })
}

/// Handle a push payload coming from the Firefox Account servers.
///
/// # Safety
///
/// A destructor [fxa_bytebuffer_free] is provided for releasing the memory for this
/// pointer type.
#[no_mangle]
pub extern "C" fn fxa_handle_push_message(
    handle: u64,
    json_payload: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("fxa_handle_push_message");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        fxa.handle_push_message(json_payload.as_str()).map(|evs| {
            let events = evs.into_iter().map(|e| e.into()).collect();
            fxa_client::msg_types::AccountEvents { events }
        })
    })
}

/// Initalizes our own device, most of the time this will be called right after
/// logging-in for the first time.
///
/// # Safety
/// This function is unsafe because it will dereference `capabilities_data` and
/// read `capabilities_len` bytes from it.
#[no_mangle]
pub unsafe extern "C" fn fxa_initialize_device(
    handle: u64,
    name: FfiStr<'_>,
    device_type: i32,
    capabilities_data: *const u8,
    capabilities_len: i32,
    error: &mut ExternError,
) {
    log::debug!("fxa_initialize_device");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let capabilities =
            DeviceCapability::from_protobuf_array_ptr(capabilities_data, capabilities_len);
        // This should not fail as device_type i32 representation is derived from our .proto schema.
        let device_type =
            msg_types::device::Type::from_i32(device_type).expect("Unknown device type code");
        fxa.initialize_device(name.as_str(), device_type.into(), &capabilities)
    })
}

/// Ensure that the device capabilities are registered with the server.
///
/// # Safety
/// This function is unsafe because it will dereference `capabilities_data` and
/// read `capabilities_len` bytes from it.
#[no_mangle]
pub unsafe extern "C" fn fxa_ensure_capabilities(
    handle: u64,
    capabilities_data: *const u8,
    capabilities_len: i32,
    error: &mut ExternError,
) {
    log::debug!("fxa_ensure_capabilities");
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| {
        let capabilities =
            DeviceCapability::from_protobuf_array_ptr(capabilities_data, capabilities_len);
        fxa.ensure_capabilities(&capabilities)
    })
}

/// Send a tab to another device identified by its Device ID.
#[no_mangle]
pub extern "C" fn fxa_send_tab(
    handle: u64,
    target_device_id: FfiStr<'_>,
    title: FfiStr<'_>,
    url: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("fxa_send_tab");
    let target = target_device_id.as_str();
    let title = title.as_str();
    let url = url.as_str();
    ACCOUNTS.call_with_result_mut(error, handle, |fxa| fxa.send_tab(target, title, url))
}

define_handle_map_deleter!(ACCOUNTS, fxa_free);
define_string_destructor!(fxa_str_free);
define_bytebuffer_destructor!(fxa_bytebuffer_free);
