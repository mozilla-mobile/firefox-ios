/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// From https://searchfox.org/mozilla-central/rev/ea63a0888d406fae720cf24f4727d87569a8cab5/services/sync/modules/constants.js#75
const URI_LENGTH_MAX: usize = 65536;
// https://searchfox.org/mozilla-central/rev/ea63a0888d406fae720cf24f4727d87569a8cab5/services/sync/modules/engines/tabs.js#8
const TAB_ENTRIES_LIMIT: usize = 5;

use std::cell::RefCell;
use sync15::clients::DeviceType;

#[derive(Clone, Debug, PartialEq)]
pub struct RemoteTab {
    pub title: String,
    pub url_history: Vec<String>,
    pub icon: Option<String>,
    pub last_used: u64, // In ms.
}

#[derive(Clone, Debug)]
pub struct ClientRemoteTabs {
    pub client_id: String, // Corresponds to the `clients` collection ID of the client.
    pub client_name: String,
    pub device_type: DeviceType,
    pub remote_tabs: Vec<RemoteTab>,
}

pub struct TabsStorage {
    local_tabs: RefCell<Option<Vec<RemoteTab>>>,
    remote_tabs: RefCell<Option<Vec<ClientRemoteTabs>>>,
}

impl Default for TabsStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl TabsStorage {
    pub fn new() -> Self {
        Self {
            local_tabs: RefCell::default(),
            remote_tabs: RefCell::default(),
        }
    }

    pub fn update_local_state(&mut self, local_state: Vec<RemoteTab>) {
        self.local_tabs.borrow_mut().replace(local_state);
    }

    pub fn prepare_local_tabs_for_upload(&self) -> Option<Vec<RemoteTab>> {
        if let Some(local_tabs) = self.local_tabs.borrow().as_ref() {
            return Some(
                local_tabs
                    .iter()
                    .cloned()
                    .filter_map(|mut tab| {
                        if tab.url_history.is_empty() || !is_url_syncable(&tab.url_history[0]) {
                            return None;
                        }
                        let mut sanitized_history = Vec::with_capacity(TAB_ENTRIES_LIMIT);
                        for url in tab.url_history {
                            if sanitized_history.len() == TAB_ENTRIES_LIMIT {
                                break;
                            }
                            if is_url_syncable(&url) {
                                sanitized_history.push(url);
                            }
                        }
                        tab.url_history = sanitized_history;
                        Some(tab)
                    })
                    .collect(),
            );
        }
        None
    }

    pub fn get_remote_tabs(&self) -> Option<Vec<ClientRemoteTabs>> {
        self.remote_tabs.borrow().clone()
    }

    pub(crate) fn replace_remote_tabs(&self, new_remote_tabs: Vec<ClientRemoteTabs>) {
        let mut remote_tabs = self.remote_tabs.borrow_mut();
        remote_tabs.replace(new_remote_tabs);
    }

    pub fn wipe(&self, delete_local_tabs: bool) {
        self.remote_tabs.replace(None);
        if delete_local_tabs {
            self.local_tabs.replace(None);
        }
    }
}

fn is_url_syncable(url: &str) -> bool {
    url.len() <= URI_LENGTH_MAX
        && !(url.starts_with("about:")
            || url.starts_with("resource:")
            || url.starts_with("chrome:")
            || url.starts_with("wyciwyg:")
            || url.starts_with("blob:")
            || url.starts_with("file:")
            || url.starts_with("moz-extension:"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_url_syncable() {
        assert!(is_url_syncable("https://bobo.com"));
        assert!(is_url_syncable("ftp://bobo.com"));
        assert!(!is_url_syncable("about:blank"));
        assert!(is_url_syncable("aboutbobo.com"));
        assert!(!is_url_syncable("file:///Users/eoger/bobo"));
    }

    #[test]
    fn test_prepare_local_tabs_for_upload() {
        let mut storage = TabsStorage::new();
        assert_eq!(storage.prepare_local_tabs_for_upload(), None);
        storage.update_local_state(vec![
            RemoteTab {
                title: "".to_owned(),
                url_history: vec!["about:blank".to_owned(), "https://foo.bar".to_owned()],
                icon: None,
                last_used: 0,
            },
            RemoteTab {
                title: "".to_owned(),
                url_history: vec![
                    "https://foo.bar".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                    "about:blank".to_owned(),
                ],
                icon: None,
                last_used: 0,
            },
            RemoteTab {
                title: "".to_owned(),
                url_history: vec![
                    "https://foo.bar".to_owned(),
                    "about:blank".to_owned(),
                    "https://foo2.bar".to_owned(),
                    "https://foo3.bar".to_owned(),
                    "https://foo4.bar".to_owned(),
                    "https://foo5.bar".to_owned(),
                    "https://foo6.bar".to_owned(),
                ],
                icon: None,
                last_used: 0,
            },
            RemoteTab {
                title: "".to_owned(),
                url_history: vec![],
                icon: None,
                last_used: 0,
            },
        ]);
        assert_eq!(
            storage.prepare_local_tabs_for_upload(),
            Some(vec![
                RemoteTab {
                    title: "".to_owned(),
                    url_history: vec!["https://foo.bar".to_owned()],
                    icon: None,
                    last_used: 0,
                },
                RemoteTab {
                    title: "".to_owned(),
                    url_history: vec![
                        "https://foo.bar".to_owned(),
                        "https://foo2.bar".to_owned(),
                        "https://foo3.bar".to_owned(),
                        "https://foo4.bar".to_owned(),
                        "https://foo5.bar".to_owned()
                    ],
                    icon: None,
                    last_used: 0,
                },
            ])
        );
    }
}
