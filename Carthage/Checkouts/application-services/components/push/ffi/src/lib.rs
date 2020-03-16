/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use ffi_support::{
    define_bytebuffer_destructor, define_handle_map_deleter, define_string_destructor, ByteBuffer,
    ConcurrentHandleMap, ExternError, FfiStr,
};
use std::os::raw::c_char;

use push::config::PushConfiguration;
use push::error::Result;
use push::subscriber::PushManager;

lazy_static::lazy_static! {
    static ref MANAGER: ConcurrentHandleMap<PushManager> = ConcurrentHandleMap::new();
}

/// Instantiate a Http connection. Returned connection must be freed with
/// `push_connection_destroy`. Returns null and logs on errors (for now).
#[no_mangle]
pub extern "C" fn push_connection_new(
    server_host: FfiStr<'_>,
    http_protocol: FfiStr<'_>,
    bridge_type: FfiStr<'_>,
    registration_id: FfiStr<'_>,
    sender_id: FfiStr<'_>,
    database_path: FfiStr<'_>,
    error: &mut ExternError,
) -> u64 {
    MANAGER.insert_with_result(error, || {
        log::trace!(
            "push_connection_new {:?} {:?} -> {:?} {:?}=>{:?}",
            http_protocol,
            server_host,
            bridge_type,
            sender_id,
            registration_id
        );
        // return this as a reference to the map since that map contains the actual handles that rust uses.
        // see ffi layer for details.
        let host = server_host.into_string();
        let protocol = http_protocol.into_opt_string();
        let reg_id = registration_id.into_opt_string();
        let bridge = bridge_type.into_opt_string();
        let sender = sender_id.into_string();
        let db_path = database_path.into_opt_string();
        let config = PushConfiguration {
            server_host: host,
            http_protocol: protocol,
            bridge_type: bridge,
            registration_id: reg_id,
            sender_id: sender,
            database_path: db_path,
            ..Default::default()
        };
        PushManager::new(config)
    })
}

// Add a subscription
/// Errors are logged.
#[no_mangle]
pub extern "C" fn push_subscribe(
    handle: u64,
    channel_id: FfiStr<'_>,
    scope: FfiStr<'_>,
    app_key: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("push_get_subscription");
    use push::msg_types::{KeyInfo, SubscriptionInfo, SubscriptionResponse};
    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<_> {
        let channel = channel_id.as_str();
        let scope_s = scope.as_str();
        let mut app_key = app_key.as_opt_str();
        // While potentially an error, a misconfigured system may use "" as
        // an application key. In that case, we drop the application key.
        if app_key == Some("") {
            app_key = None;
        }
        // Don't auto add the subscription to the db.
        // (endpoint updates also call subscribe and should be lighter weight)
        let (info, subscription_key) = mgr.subscribe(channel, scope_s, app_key)?;
        // it is possible for the
        // store the channel_id => auth + subscription_key
        Ok(SubscriptionResponse {
            channel_id: info.channel_id,
            subscription_info: SubscriptionInfo {
                endpoint: info.endpoint,
                keys: KeyInfo {
                    auth: base64::encode_config(&subscription_key.auth, base64::URL_SAFE_NO_PAD),
                    p256dh: base64::encode_config(
                        &subscription_key.public_key(),
                        base64::URL_SAFE_NO_PAD,
                    ),
                },
            },
        })
    })
}

// Unsubscribe a channel
#[no_mangle]
pub extern "C" fn push_unsubscribe(
    handle: u64,
    channel_id: FfiStr<'_>,
    error: &mut ExternError,
) -> u8 {
    log::debug!("push_unsubscribe");
    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<bool> {
        let channel = channel_id.as_opt_str();
        mgr.unsubscribe(channel)
    })
}

// Unsubscribe a channel
#[no_mangle]
pub extern "C" fn push_unsubscribe_all(handle: u64, error: &mut ExternError) -> u8 {
    log::debug!("push_unsubscribe");
    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<bool> {
        mgr.unsubscribe_all()
    })
}

// Update the OS token
#[no_mangle]
pub extern "C" fn push_update(handle: u64, new_token: FfiStr<'_>, error: &mut ExternError) -> u8 {
    log::debug!("push_update");
    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<_> {
        let token = new_token.as_str();
        mgr.update(&token)
    })
}

// verify connection using channel list
// Returns a bool indicating if channel_ids should resubscribe.
#[no_mangle]
pub extern "C" fn push_verify_connection(handle: u64, error: &mut ExternError) -> ByteBuffer {
    log::debug!("push_verify");
    use push::msg_types::PushSubscriptionChanged;
    use push::msg_types::PushSubscriptionsChanged;

    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<_> {
        let subs = mgr
            .verify_connection()?
            .iter()
            .map(|record| PushSubscriptionChanged {
                channel_id: record.channel_id.clone(),
                scope: record.scope.clone(),
            })
            .collect();

        Ok(PushSubscriptionsChanged { subs })
    })
}

#[no_mangle]
pub extern "C" fn push_decrypt(
    handle: u64,
    chid: FfiStr<'_>,
    body: FfiStr<'_>,
    encoding: FfiStr<'_>,
    salt: FfiStr<'_>,
    dh: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("push_decrypt");
    MANAGER.call_with_result_mut(error, handle, |mgr| {
        let r_chid = chid.as_str();
        let r_body = body.as_str();
        let r_encoding = encoding.as_str();
        let r_salt: Option<&str> = salt.as_opt_str();
        let r_dh: Option<&str> = dh.as_opt_str();
        let uaid = mgr.conn.uaid.clone().unwrap();
        mgr.decrypt(&uaid, r_chid, r_body, r_encoding, r_salt, r_dh)
    })
}

#[no_mangle]
pub extern "C" fn push_dispatch_info_for_chid(
    handle: u64,
    chid: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("push_dispatch_info_for_chid");
    use push::msg_types::DispatchInfo;
    MANAGER.call_with_result_mut(error, handle, |mgr| -> Result<Option<_>> {
        let chid = chid.as_str();
        Ok(mgr.get_record_by_chid(chid)?.map(|record| DispatchInfo {
            uaid: record.uaid,
            scope: record.scope,
            endpoint: record.endpoint,
            app_server_key: record.app_server_key,
        }))
    })
}

define_string_destructor!(push_destroy_string);
define_bytebuffer_destructor!(push_destroy_buffer);
define_handle_map_deleter!(MANAGER, push_connection_destroy);
