/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{error::*, AccountEvent, FirefoxAccount};
use serde_derive::Deserialize;

impl FirefoxAccount {
    /// Handle any incoming push message payload coming from the Firefox Accounts
    /// servers that has been decrypted and authenticated by the Push crate.
    ///
    /// Due to iOS platform restrictions, a push notification must always show UI.
    /// Since FxA sends one push notification per command received,
    /// we must only retrieve 1 command per push message,
    /// otherwise we risk receiving push messages for which the UI has already been shown.
    ///
    /// **💾 This method alters the persisted account state.**
    pub fn handle_push_message(&mut self, payload: &str) -> Result<Vec<AccountEvent>> {
        let payload = serde_json::from_str(payload)?;
        match payload {
            PushPayload::CommandReceived(CommandReceivedPushPayload { index, .. }) => {
                if cfg!(target_os = "ios") {
                    self.fetch_device_command(index)
                        .map(|cmd| vec![AccountEvent::IncomingDeviceCommand(Box::new(cmd))])
                } else {
                    self.poll_device_commands().map(|cmds| {
                        cmds.into_iter()
                            .map(|cmd| AccountEvent::IncomingDeviceCommand(Box::new(cmd)))
                            .collect()
                    })
                }
            }
            PushPayload::ProfileUpdated => {
                self.state.last_seen_profile = None;
                Ok(vec![AccountEvent::ProfileUpdated])
            }
            PushPayload::DeviceConnected(DeviceConnectedPushPayload { device_name }) => {
                Ok(vec![AccountEvent::DeviceConnected { device_name }])
            }
            PushPayload::DeviceDisconnected(DeviceDisconnectedPushPayload { device_id }) => {
                let local_device = self.get_current_device_id();
                let is_local_device = match local_device {
                    Err(_) => false,
                    Ok(id) => id == device_id,
                };
                if is_local_device {
                    self.disconnect();
                }
                Ok(vec![AccountEvent::DeviceDisconnected {
                    device_id,
                    is_local_device,
                }])
            }
            PushPayload::AccountDestroyed(AccountDestroyedPushPayload { account_uid }) => {
                let is_local_account = match &self.state.last_seen_profile {
                    None => false,
                    Some(profile) => profile.response.uid == account_uid,
                };
                Ok(if is_local_account {
                    vec![AccountEvent::AccountDestroyed]
                } else {
                    vec![]
                })
            }
            PushPayload::PasswordChanged | PushPayload::PasswordReset => {
                let status = self.check_authorization_status()?;
                Ok(if !status.active {
                    vec![AccountEvent::AccountAuthStateChanged]
                } else {
                    vec![]
                })
            }
            PushPayload::Unknown => {
                log::info!("Unknown Push command.");
                Ok(vec![])
            }
        }
    }
}

#[derive(Debug, Deserialize)]
#[serde(tag = "command", content = "data")]
pub enum PushPayload {
    #[serde(rename = "fxaccounts:command_received")]
    CommandReceived(CommandReceivedPushPayload),
    #[serde(rename = "fxaccounts:profile_updated")]
    ProfileUpdated,
    #[serde(rename = "fxaccounts:device_connected")]
    DeviceConnected(DeviceConnectedPushPayload),
    #[serde(rename = "fxaccounts:device_disconnected")]
    DeviceDisconnected(DeviceDisconnectedPushPayload),
    #[serde(rename = "fxaccounts:password_changed")]
    PasswordChanged,
    #[serde(rename = "fxaccounts:password_reset")]
    PasswordReset,
    #[serde(rename = "fxaccounts:account_destroyed")]
    AccountDestroyed(AccountDestroyedPushPayload),
    #[serde(other)]
    Unknown,
}

#[derive(Debug, Deserialize)]
pub struct CommandReceivedPushPayload {
    command: String,
    index: u64,
    sender: String,
    url: String,
}

#[derive(Debug, Deserialize)]
pub struct DeviceConnectedPushPayload {
    #[serde(rename = "deviceName")]
    device_name: String,
}

#[derive(Debug, Deserialize)]
pub struct DeviceDisconnectedPushPayload {
    #[serde(rename = "id")]
    device_id: String,
}

#[derive(Debug, Deserialize)]
pub struct AccountDestroyedPushPayload {
    #[serde(rename = "uid")]
    account_uid: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deserialize_send_tab_command() {
        let json = "{\"version\":1,\"command\":\"fxaccounts:command_received\",\"data\":{\"command\":\"send-tab-recv\",\"index\":1,\"sender\":\"bobo\",\"url\":\"https://mozilla.org\"}}";
        let _: PushPayload = serde_json::from_str(&json).unwrap();
    }

    #[test]
    fn test_push_profile_updated() {
        let mut fxa =
            FirefoxAccount::with_config(crate::Config::stable_dev("12345678", "https://foo.bar"));
        fxa.add_cached_profile("123", "test@example.com");
        let json = "{\"version\":1,\"command\":\"fxaccounts:profile_updated\"}";
        let events = fxa.handle_push_message(json).unwrap();
        assert!(fxa.state.last_seen_profile.is_none());
        assert_eq!(events.len(), 1);
        match events[0] {
            AccountEvent::ProfileUpdated => {}
            _ => unreachable!(),
        };
    }

    #[test]
    fn test_push_device_disconnected_local() {
        let mut fxa =
            FirefoxAccount::with_config(crate::Config::stable_dev("12345678", "https://foo.bar"));
        let refresh_token_scopes = std::collections::HashSet::new();
        fxa.state.refresh_token = Some(crate::oauth::RefreshToken {
            token: "refresh_token".to_owned(),
            scopes: refresh_token_scopes,
        });
        fxa.state.current_device_id = Some("my_id".to_owned());
        let json = "{\"version\":1,\"command\":\"fxaccounts:device_disconnected\",\"data\":{\"id\":\"my_id\"}}";
        let events = fxa.handle_push_message(json).unwrap();
        assert!(fxa.state.refresh_token.is_none());
        assert_eq!(events.len(), 1);
        match &events[0] {
            AccountEvent::DeviceDisconnected {
                device_id,
                is_local_device,
            } => {
                assert!(is_local_device);
                assert_eq!(device_id, "my_id");
            }
            _ => unreachable!(),
        };
    }

    #[test]
    fn test_push_device_disconnected_remote() {
        let mut fxa =
            FirefoxAccount::with_config(crate::Config::stable_dev("12345678", "https://foo.bar"));
        let json = "{\"version\":1,\"command\":\"fxaccounts:device_disconnected\",\"data\":{\"id\":\"remote_id\"}}";
        let events = fxa.handle_push_message(json).unwrap();
        assert_eq!(events.len(), 1);
        match &events[0] {
            AccountEvent::DeviceDisconnected {
                device_id,
                is_local_device,
            } => {
                assert!(!is_local_device);
                assert_eq!(device_id, "remote_id");
            }
            _ => unreachable!(),
        };
    }

    #[test]
    fn test_handle_push_message_unknown_command() {
        let mut fxa =
            FirefoxAccount::with_config(crate::Config::stable_dev("12345678", "https://foo.bar"));
        let json = "{\"version\":1,\"command\":\"huh\"}";
        let events = fxa.handle_push_message(json).unwrap();
        assert!(events.is_empty());
    }
}
