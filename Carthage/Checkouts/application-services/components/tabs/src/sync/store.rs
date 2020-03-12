/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::storage::TabsStorage;
use crate::storage::{ClientRemoteTabs, RemoteTab};
use crate::sync::record::{TabsRecord, TabsRecordTab};
use std::cell::{Cell, RefCell};
use std::{collections::HashMap, result};
use sync15::{
    clients::{self, DeviceType, RemoteClient},
    telemetry, CollectionRequest, IncomingChangeset, OutgoingChangeset, Payload, ServerTimestamp,
    Store, StoreSyncAssociation,
};
use sync_guid::Guid;

impl RemoteTab {
    fn from_record_tab(tab: &TabsRecordTab) -> Self {
        Self {
            title: tab.title.clone(),
            url_history: tab.url_history.clone(),
            icon: tab.icon.clone(),
            last_used: tab.last_used.checked_mul(1000).unwrap_or_default(),
        }
    }
    fn to_record_tab(&self) -> TabsRecordTab {
        TabsRecordTab {
            title: self.title.clone(),
            url_history: self.url_history.clone(),
            icon: self.icon.clone(),
            last_used: self.last_used.checked_div(1000).unwrap_or_default(),
        }
    }
}

impl ClientRemoteTabs {
    fn from_record_with_remote_client(
        client_id: String,
        remote_client: &RemoteClient,
        record: TabsRecord,
    ) -> Self {
        Self {
            client_id,
            client_name: remote_client.device_name.clone(),
            device_type: remote_client.device_type.unwrap_or(DeviceType::Mobile),
            remote_tabs: record.tabs.iter().map(RemoteTab::from_record_tab).collect(),
        }
    }

    fn from_record(client_id: String, record: TabsRecord) -> Self {
        Self {
            client_id,
            client_name: record.client_name,
            device_type: DeviceType::Mobile,
            remote_tabs: record.tabs.iter().map(RemoteTab::from_record_tab).collect(),
        }
    }
    fn to_record(&self) -> TabsRecord {
        TabsRecord {
            id: self.client_id.clone(),
            client_name: self.client_name.clone(),
            tabs: self
                .remote_tabs
                .iter()
                .map(RemoteTab::to_record_tab)
                .collect(),
        }
    }
}

pub struct TabsStore<'a> {
    storage: &'a TabsStorage,
    remote_clients: RefCell<HashMap<String, RemoteClient>>,
    last_sync: Cell<Option<ServerTimestamp>>, // We use a cell because `sync_finished` doesn't take a mutable reference to &self.
    sync_store_assoc: RefCell<StoreSyncAssociation>,
    pub(crate) local_id: RefCell<String>,
}

impl<'a> TabsStore<'a> {
    pub fn new(storage: &'a TabsStorage) -> Self {
        Self {
            storage,
            remote_clients: RefCell::default(),
            last_sync: Cell::default(),
            sync_store_assoc: RefCell::new(StoreSyncAssociation::Disconnected),
            local_id: RefCell::default(), // Will get replaced in `prepare_for_sync`.
        }
    }
    fn wipe_reset_helper(&self, is_wipe: bool) -> result::Result<(), failure::Error> {
        self.remote_clients.borrow_mut().clear();
        self.storage.wipe(is_wipe);
        Ok(())
    }
}

impl<'a> Store for TabsStore<'a> {
    fn collection_name(&self) -> std::borrow::Cow<'static, str> {
        "tabs".into()
    }

    fn prepare_for_sync(
        &self,
        get_client_data: &dyn Fn() -> clients::ClientData,
    ) -> Result<(), failure::Error> {
        let data = get_client_data();
        self.remote_clients.replace(data.recent_clients);
        self.local_id.replace(data.local_client_id);
        Ok(())
    }

    fn apply_incoming(
        &self,
        inbound: Vec<IncomingChangeset>,
        telem: &mut telemetry::Engine,
    ) -> result::Result<OutgoingChangeset, failure::Error> {
        assert_eq!(inbound.len(), 1, "only requested one item");
        let inbound = inbound.into_iter().next().unwrap();
        let mut incoming_telemetry = telemetry::EngineIncoming::new();
        let local_id = self.local_id.borrow().clone();
        let mut remote_tabs = Vec::with_capacity(inbound.changes.len());

        for incoming in inbound.changes {
            if incoming.0.id() == local_id {
                // That's our own record, ignore it.
                continue;
            }
            let record = match TabsRecord::from_payload(incoming.0) {
                Ok(record) => record,
                Err(e) => {
                    log::warn!("Error deserializing incoming record: {}", e);
                    incoming_telemetry.failed(1);
                    continue;
                }
            };
            let id = record.id.clone();
            let tab = if let Some(remote_client) = self.remote_clients.borrow().get(&id) {
                ClientRemoteTabs::from_record_with_remote_client(
                    remote_client
                        .fxa_device_id
                        .as_ref()
                        .unwrap_or(&id)
                        .to_owned(),
                    remote_client,
                    record,
                )
            } else {
                ClientRemoteTabs::from_record(id, record)
            };
            remote_tabs.push(tab);
        }
        self.storage.replace_remote_tabs(remote_tabs);
        let mut outgoing = OutgoingChangeset::new("tabs", inbound.timestamp);
        if let Some(local_tabs) = self.storage.prepare_local_tabs_for_upload() {
            let (client_name, device_type) = self
                .remote_clients
                .borrow()
                .get(&local_id)
                .map(|client| {
                    (
                        client.device_name.clone(),
                        client.device_type.unwrap_or(DeviceType::Mobile),
                    )
                })
                .unwrap_or_else(|| (String::new(), DeviceType::Mobile));
            let local_record = ClientRemoteTabs {
                client_id: local_id,
                client_name,
                device_type,
                remote_tabs: local_tabs.to_vec(),
            };
            let payload = Payload::from_record(local_record.to_record())?;
            log::trace!("outgoing {:?}", payload);
            outgoing.changes.push(payload);
        }
        telem.incoming(incoming_telemetry);
        Ok(outgoing)
    }

    fn sync_finished(
        &self,
        new_timestamp: ServerTimestamp,
        records_synced: Vec<Guid>,
    ) -> result::Result<(), failure::Error> {
        log::info!(
            "sync completed after uploading {} records",
            records_synced.len()
        );
        self.last_sync.set(Some(new_timestamp));
        Ok(())
    }

    fn get_collection_requests(
        &self,
        server_timestamp: ServerTimestamp,
    ) -> result::Result<Vec<CollectionRequest>, failure::Error> {
        let since = self.last_sync.get().unwrap_or_default();
        Ok(if since == server_timestamp {
            vec![]
        } else {
            vec![CollectionRequest::new("tabs").full().newer_than(since)]
        })
    }

    fn get_sync_assoc(&self) -> result::Result<StoreSyncAssociation, failure::Error> {
        Ok(self.sync_store_assoc.borrow().clone())
    }

    fn reset(&self, assoc: &StoreSyncAssociation) -> result::Result<(), failure::Error> {
        self.sync_store_assoc.replace(assoc.clone());
        self.wipe_reset_helper(false)
    }

    fn wipe(&self) -> result::Result<(), failure::Error> {
        self.wipe_reset_helper(true)
    }
}
