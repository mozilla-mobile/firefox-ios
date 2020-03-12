/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module has to be here because of some hard-to-avoid hacks done for the
//! tabs engine... See issue #2590

use std::collections::HashMap;

/// Argument to Store::prepare_for_sync. See comment there for more info. Only
/// really intended to be used by tabs engine.
#[derive(Clone, Debug)]
pub struct ClientData {
    pub local_client_id: String,
    pub recent_clients: HashMap<String, RemoteClient>,
}

/// Information about a remote client in the clients collection.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct RemoteClient {
    pub fxa_device_id: Option<String>,
    pub device_name: String,
    pub device_type: Option<DeviceType>,
}

/// The type of a client. Please keep these variants in sync with the device
/// types in the FxA client and sync manager.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum DeviceType {
    Desktop,
    Mobile,
    Tablet,
    VR,
    TV,
}

impl DeviceType {
    pub fn try_from_str(d: impl AsRef<str>) -> Option<DeviceType> {
        match d.as_ref() {
            "desktop" => Some(DeviceType::Desktop),
            "mobile" => Some(DeviceType::Mobile),
            "tablet" => Some(DeviceType::Tablet),
            "vr" => Some(DeviceType::VR),
            "tv" => Some(DeviceType::TV),
            _ => None,
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            DeviceType::Desktop => "desktop",
            DeviceType::Mobile => "mobile",
            DeviceType::Tablet => "tablet",
            DeviceType::VR => "vr",
            DeviceType::TV => "tv",
        }
    }
}
