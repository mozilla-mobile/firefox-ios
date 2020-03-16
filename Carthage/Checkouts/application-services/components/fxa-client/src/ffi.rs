/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module implement the traits and some types that make the FFI code easier to manage.
//!
//! Note that the FxA FFI is older than the other FFIs in application-services, and has (direct,
//! low-level) bindings that live in the mozilla-mobile/android-components repo. As a result, it's a
//! bit harder to change (anything breaking the ABI requires careful synchronization of updates
//! across two repos), and doesn't follow all the same conventions that are followed by the other
//! FFIs.
//!
//! None of this is that bad in practice, but much of it is not ideal.

use crate::{
    commands,
    device::{Capability as DeviceCapability, Device, PushSubscription, Type as DeviceType},
    msg_types, send_tab, AccessTokenInfo, AccountEvent, Error, ErrorKind, IncomingDeviceCommand,
    IntrospectInfo, Profile, ScopedKey,
};
use ffi_support::{
    implement_into_ffi_by_delegation, implement_into_ffi_by_protobuf, ErrorCode, ExternError,
};

pub mod error_codes {
    // Note: -1 and 0 (panic and success) codes are reserved by the ffi-support library

    /// Catch-all error code used for anything that's not a panic or covered by AUTHENTICATION.
    pub const OTHER: i32 = 1;

    /// Used for `ErrorKind::NotMarried`, `ErrorKind::NoCachedTokens`, `ErrorKind::NoScopedKey`
    /// and `ErrorKind::RemoteError`'s where `code == 401`.
    pub const AUTHENTICATION: i32 = 2;

    /// Code for network errors.
    pub const NETWORK: i32 = 3;
}

fn get_code(err: &Error) -> ErrorCode {
    match err.kind() {
        ErrorKind::RemoteError { code: 401, .. }
        | ErrorKind::NotMarried
        | ErrorKind::NoRefreshToken
        | ErrorKind::NoScopedKey(_)
        | ErrorKind::NoCachedToken(_) => {
            log::warn!("Authentication error: {:?}", err);
            ErrorCode::new(error_codes::AUTHENTICATION)
        }
        ErrorKind::RequestError(_) => {
            log::warn!("Network error: {:?}", err);
            ErrorCode::new(error_codes::NETWORK)
        }
        _ => {
            log::warn!("Unexpected error: {:?}", err);
            ErrorCode::new(error_codes::OTHER)
        }
    }
}

impl From<Error> for ExternError {
    fn from(err: Error) -> ExternError {
        ExternError::new_error(get_code(&err), err.to_string())
    }
}

impl From<AccessTokenInfo> for msg_types::AccessTokenInfo {
    fn from(a: AccessTokenInfo) -> Self {
        msg_types::AccessTokenInfo {
            scope: a.scope,
            token: a.token,
            key: a.key.map(Into::into),
            expires_at: a.expires_at,
        }
    }
}

impl From<IntrospectInfo> for msg_types::IntrospectInfo {
    fn from(a: IntrospectInfo) -> Self {
        msg_types::IntrospectInfo {
            active: a.active,
            token_type: a.token_type,
            scope: a.scope,
            exp: a.exp,
            iss: a.iss,
        }
    }
}

impl From<ScopedKey> for msg_types::ScopedKey {
    fn from(sk: ScopedKey) -> Self {
        msg_types::ScopedKey {
            kty: sk.kty,
            scope: sk.scope,
            k: sk.k,
            kid: sk.kid,
        }
    }
}

impl From<Profile> for msg_types::Profile {
    fn from(p: Profile) -> Self {
        Self {
            avatar: Some(p.avatar),
            avatar_default: Some(p.avatar_default),
            display_name: p.display_name,
            email: Some(p.email),
            uid: Some(p.uid),
        }
    }
}

fn command_to_capability(command: &str) -> Option<msg_types::device::Capability> {
    match command {
        commands::send_tab::COMMAND_NAME => Some(msg_types::device::Capability::SendTab),
        _ => None,
    }
}

impl From<Device> for msg_types::Device {
    fn from(d: Device) -> Self {
        let capabilities = d
            .available_commands
            .keys()
            .filter_map(|c| command_to_capability(c).map(|cc| cc as i32))
            .collect();
        Self {
            id: d.common.id,
            display_name: d.common.display_name,
            r#type: Into::<msg_types::device::Type>::into(d.common.device_type) as i32,
            push_subscription: d.common.push_subscription.map(Into::into),
            push_endpoint_expired: d.common.push_endpoint_expired,
            is_current_device: d.is_current_device,
            last_access_time: d.last_access_time,
            capabilities,
        }
    }
}

impl From<DeviceType> for msg_types::device::Type {
    fn from(t: DeviceType) -> Self {
        match t {
            DeviceType::Desktop => msg_types::device::Type::Desktop,
            DeviceType::Mobile => msg_types::device::Type::Mobile,
            DeviceType::Tablet => msg_types::device::Type::Tablet,
            DeviceType::VR => msg_types::device::Type::Vr,
            DeviceType::TV => msg_types::device::Type::Tv,
            DeviceType::Unknown => msg_types::device::Type::Unknown,
        }
    }
}

impl From<msg_types::device::Type> for DeviceType {
    fn from(t: msg_types::device::Type) -> Self {
        match t {
            msg_types::device::Type::Desktop => DeviceType::Desktop,
            msg_types::device::Type::Mobile => DeviceType::Mobile,
            msg_types::device::Type::Tablet => DeviceType::Tablet,
            msg_types::device::Type::Vr => DeviceType::VR,
            msg_types::device::Type::Tv => DeviceType::TV,
            msg_types::device::Type::Unknown => DeviceType::Unknown,
        }
    }
}

impl From<PushSubscription> for msg_types::device::PushSubscription {
    fn from(p: PushSubscription) -> Self {
        Self {
            endpoint: p.endpoint,
            public_key: p.public_key,
            auth_key: p.auth_key,
        }
    }
}

impl From<AccountEvent> for msg_types::AccountEvent {
    fn from(e: AccountEvent) -> Self {
        match e {
            AccountEvent::IncomingDeviceCommand(command) => Self {
                r#type: msg_types::account_event::AccountEventType::IncomingDeviceCommand as i32,
                data: Some(msg_types::account_event::Data::DeviceCommand(
                    (*command).into(),
                )),
            },
            AccountEvent::ProfileUpdated => Self {
                r#type: msg_types::account_event::AccountEventType::ProfileUpdated as i32,
                data: None,
            },
            AccountEvent::AccountAuthStateChanged => Self {
                r#type: msg_types::account_event::AccountEventType::AccountAuthStateChanged as i32,
                data: None,
            },
            AccountEvent::AccountDestroyed => Self {
                r#type: msg_types::account_event::AccountEventType::AccountDestroyed as i32,
                data: None,
            },
            AccountEvent::DeviceConnected { device_name } => Self {
                r#type: msg_types::account_event::AccountEventType::DeviceConnected as i32,
                data: Some(msg_types::account_event::Data::DeviceConnectedName(
                    device_name,
                )),
            },
            AccountEvent::DeviceDisconnected {
                device_id,
                is_local_device,
            } => Self {
                r#type: msg_types::account_event::AccountEventType::DeviceDisconnected as i32,
                data: Some(msg_types::account_event::Data::DeviceDisconnectedData(
                    msg_types::account_event::DeviceDisconnectedData {
                        device_id,
                        is_local_device,
                    },
                )),
            },
        }
    }
}

impl From<IncomingDeviceCommand> for msg_types::IncomingDeviceCommand {
    fn from(data: IncomingDeviceCommand) -> Self {
        match data {
            IncomingDeviceCommand::TabReceived { sender, payload } => Self {
                r#type: msg_types::incoming_device_command::IncomingDeviceCommandType::TabReceived
                    as i32,
                data: Some(msg_types::incoming_device_command::Data::TabReceivedData(
                    msg_types::incoming_device_command::SendTabData {
                        from: sender.map(Into::into),
                        entries: payload.entries.into_iter().map(Into::into).collect(),
                    },
                )),
            },
        }
    }
}

impl From<send_tab::TabHistoryEntry>
    for msg_types::incoming_device_command::send_tab_data::TabHistoryEntry
{
    fn from(data: send_tab::TabHistoryEntry) -> Self {
        Self {
            title: data.title,
            url: data.url,
        }
    }
}

impl From<msg_types::device::Capability> for DeviceCapability {
    fn from(cap: msg_types::device::Capability) -> Self {
        match cap {
            msg_types::device::Capability::SendTab => DeviceCapability::SendTab,
        }
    }
}

impl DeviceCapability {
    /// # Safety
    /// Deref pointer thus unsafe
    pub unsafe fn from_protobuf_array_ptr(ptr: *const u8, len: i32) -> Vec<Self> {
        let buffer = get_buffer(ptr, len);
        let capabilities: Result<msg_types::Capabilities, _> = prost::Message::decode(buffer);
        capabilities
            .map(|cc| cc.to_capabilities_vec())
            .unwrap_or_else(|_| vec![])
    }
}

impl msg_types::Capabilities {
    pub fn to_capabilities_vec(&self) -> Vec<DeviceCapability> {
        self.capability
            .iter()
            .map(|c| msg_types::device::Capability::from_i32(*c).unwrap().into())
            .collect()
    }
}

unsafe fn get_buffer<'a>(data: *const u8, len: i32) -> &'a [u8] {
    assert!(len >= 0, "Bad buffer len: {}", len);
    if len == 0 {
        &[]
    } else {
        assert!(!data.is_null(), "Unexpected null data pointer");
        std::slice::from_raw_parts(data, len as usize)
    }
}

implement_into_ffi_by_protobuf!(msg_types::Profile);
implement_into_ffi_by_delegation!(Profile, msg_types::Profile);
implement_into_ffi_by_protobuf!(msg_types::AccessTokenInfo);
implement_into_ffi_by_delegation!(AccessTokenInfo, msg_types::AccessTokenInfo);
implement_into_ffi_by_protobuf!(msg_types::IntrospectInfo);
implement_into_ffi_by_delegation!(IntrospectInfo, msg_types::IntrospectInfo);
implement_into_ffi_by_protobuf!(msg_types::Device);
implement_into_ffi_by_delegation!(Device, msg_types::Device);
implement_into_ffi_by_protobuf!(msg_types::Devices);
implement_into_ffi_by_delegation!(AccountEvent, msg_types::AccountEvent);
implement_into_ffi_by_protobuf!(msg_types::AccountEvent);
implement_into_ffi_by_protobuf!(msg_types::AccountEvents);
implement_into_ffi_by_delegation!(IncomingDeviceCommand, msg_types::IncomingDeviceCommand);
implement_into_ffi_by_protobuf!(msg_types::IncomingDeviceCommand);
implement_into_ffi_by_protobuf!(msg_types::IncomingDeviceCommands);
