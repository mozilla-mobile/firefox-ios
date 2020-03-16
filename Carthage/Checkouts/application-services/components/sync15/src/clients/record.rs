/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use serde_derive::*;

use super::Command;

/// The serialized form of a client record.
#[derive(Clone, Debug, Eq, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ClientRecord {
    #[serde(rename = "id")]
    pub id: String,

    pub name: String,

    #[serde(default, rename = "type")]
    pub typ: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub commands: Vec<CommandRecord>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub fxa_device_id: Option<String>,

    /// `version`, `protocols`, `formfactor`, `os`, `appPackage`, `application`,
    /// and `device` are unused and optional in all implementations (Desktop,
    /// iOS, and Fennec), but we round-trip them.

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub version: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub protocols: Vec<String>,

    #[serde(
        default,
        rename = "formfactor",
        skip_serializing_if = "Option::is_none"
    )]
    pub form_factor: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub os: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub app_package: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub application: Option<String>,

    /// The model of the device, like "iPhone" or "iPod touch" on iOS. Note
    /// that this is _not_ the client ID (`id`) or the FxA device ID
    /// (`fxa_device_id`).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub device: Option<String>,

    // This field is somewhat magic - it's moved to and from the
    // BSO record, so is  not expected to be on the unencrypted payload
    // when incoming and are not put on the unencrypted payload when outgoing.
    // There are hysterical raisens for this, which we should fix.
    // https://github.com/mozilla/application-services/issues/2712
    #[serde(default)]
    pub ttl: u32,
}

/// The serialized form of a client command.
#[derive(Clone, Debug, Eq, Deserialize, Hash, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CommandRecord {
    /// The command name. This is a string, not an enum, because we want to
    /// round-trip commands that we don't support yet.
    #[serde(rename = "command")]
    pub name: String,

    /// Extra, command-specific arguments. Note that we must send an empty
    /// array if the command expects no arguments.
    #[serde(default)]
    pub args: Vec<String>,

    /// Some commands, like repair, send a "flow ID" that other cliennts can
    /// record in their telemetry. We don't currently send commands with
    /// flow IDs, but we round-trip them.
    #[serde(default, rename = "flowID", skip_serializing_if = "Option::is_none")]
    pub flow_id: Option<String>,
}

impl CommandRecord {
    /// Converts a serialized command into one that we can apply. Returns `None`
    /// if we don't support the command.
    pub fn as_command(&self) -> Option<Command> {
        match self.name.as_str() {
            "wipeEngine" => self.args.get(0).map(|e| Command::Wipe(e.into())),
            "wipeAll" => Some(Command::WipeAll),
            "resetEngine" => self.args.get(0).map(|e| Command::Reset(e.into())),
            "resetAll" => Some(Command::ResetAll),
            _ => None,
        }
    }
}

impl From<Command> for CommandRecord {
    fn from(command: Command) -> CommandRecord {
        match command {
            Command::Wipe(engine) => CommandRecord {
                name: "wipeEngine".into(),
                args: vec![engine],
                flow_id: None,
            },
            Command::WipeAll => CommandRecord {
                name: "wipeAll".into(),
                args: Vec::new(),
                flow_id: None,
            },
            Command::Reset(engine) => CommandRecord {
                name: "resetEngine".into(),
                args: vec![engine],
                flow_id: None,
            },
            Command::ResetAll => CommandRecord {
                name: "resetAll".into(),
                args: Vec::new(),
                flow_id: None,
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sync15_traits::Payload;

    #[test]
    fn test_ttl() {
        // The ttl hacks in place mean that magically the ttl field from the
        // client record should make it down to a BSO.
        let record = ClientRecord {
            id: "id".into(),
            name: "my device".into(),
            typ: Some("type".into()),
            commands: Vec::new(),
            fxa_device_id: Some("12345".into()),
            version: None,
            protocols: vec!["1.5".into()],
            form_factor: None,
            os: None,
            app_package: None,
            application: None,
            device: None,
            ttl: 123,
        };
        let p = Payload::from_record(record).unwrap();
        let bso = crate::CleartextBso::from_payload(p, "clients");
        assert_eq!(bso.ttl, Some(123));
    }
}
