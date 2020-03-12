/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! Process the incoming notification
//!
//! Workhorse function that handles incoming notifications, processing them into PushMessages,
//! and distributing them to the appropriate handlers via the internal event bus.
//!
//! Called from the Connection Manager.

pub struct NotifierError;

use storage::ChannelID;

/// Incoming WebPush Notification
pub struct Notification {
    /// Associated channel ID
    pub channel_id: ChannelID,
    /// Raw body of the incoming notification
    pub body: Vec<u8>,
    /// Encoding from Content-Encoding
    pub con: String,
    /// Salt from encryption header
    pub salt: Option<Vec<u8>>,
    /// from crypto-key
    pub dh: Option<Vec<u8>>,
}

/// Outbound Push Message
pub struct PushMessage {
    pub channel_id: ChannelID,
    pub body: Vec<u8>,
}

pub trait Notifier {
    /// process notification, broadcast, etc.
    fn process_notification(notification: Notification) -> Result<PushMessage, NotifierError>;
    // fetch sub data
    // decrypt the notification (if required)
    // route to proper handler (DOM, system)
    // the PushMessage result is handed off to the DOM or internal service
}

pub struct NotifHandler {}
