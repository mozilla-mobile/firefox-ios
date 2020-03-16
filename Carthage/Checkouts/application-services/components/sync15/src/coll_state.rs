/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::collection_keys::CollectionKeys;
use crate::error;
use crate::key_bundle::KeyBundle;
use crate::request::InfoConfiguration;
use crate::state::GlobalState;
use crate::sync::Store;
use crate::util::ServerTimestamp;

pub use sync15_traits::{CollSyncIds, StoreSyncAssociation};

/// Holds state for a collection. In general, only the CollState is
/// needed to sync a collection (but a valid GlobalState is needed to obtain
/// a CollState)
#[derive(Debug, Clone)]
pub struct CollState {
    pub config: InfoConfiguration,
    // initially from meta/global, updated after an xius POST/PUT.
    pub last_modified: ServerTimestamp,
    pub key: KeyBundle,
}

#[derive(Debug)]
pub enum LocalCollState {
    /// The state is unknown, with the StoreSyncAssociation the collection
    /// reports.
    Unknown { assoc: StoreSyncAssociation },

    /// The engine has been declined. This is a "terminal" state.
    Declined,

    /// There's no such collection in meta/global. We could possibly update
    /// meta/global, but currently all known collections are there by default,
    /// so this is, basically, an error condition.
    NoSuchCollection,

    /// Either the global or collection sync ID has changed - we will reset the engine.
    SyncIdChanged { ids: CollSyncIds },

    /// The collection is ready to sync.
    Ready { key: KeyBundle },
}

pub struct LocalCollStateMachine<'state> {
    global_state: &'state GlobalState,
    root_key: &'state KeyBundle,
}

impl<'state> LocalCollStateMachine<'state> {
    fn advance(&self, from: LocalCollState, store: &dyn Store) -> error::Result<LocalCollState> {
        let name = &store.collection_name().to_string();
        let meta_global = &self.global_state.global;
        match from {
            LocalCollState::Unknown { assoc } => {
                if meta_global.declined.contains(name) {
                    return Ok(LocalCollState::Declined);
                }
                match meta_global.engines.get(name) {
                    Some(engine_meta) => match assoc {
                        StoreSyncAssociation::Disconnected => Ok(LocalCollState::SyncIdChanged {
                            ids: CollSyncIds {
                                global: meta_global.sync_id.clone(),
                                coll: engine_meta.sync_id.clone(),
                            },
                        }),
                        StoreSyncAssociation::Connected(ref ids)
                            if ids.global == meta_global.sync_id
                                && ids.coll == engine_meta.sync_id =>
                        {
                            let coll_keys = CollectionKeys::from_encrypted_bso(
                                self.global_state.keys.clone(),
                                self.root_key,
                            )?;
                            Ok(LocalCollState::Ready {
                                key: coll_keys.key_for_collection(name).clone(),
                            })
                        }
                        _ => Ok(LocalCollState::SyncIdChanged {
                            ids: CollSyncIds {
                                global: meta_global.sync_id.clone(),
                                coll: engine_meta.sync_id.clone(),
                            },
                        }),
                    },
                    None => Ok(LocalCollState::NoSuchCollection),
                }
            }

            LocalCollState::Declined => unreachable!("can't advance from declined"),

            LocalCollState::NoSuchCollection => unreachable!("the collection is unknown"),

            LocalCollState::SyncIdChanged { ids } => {
                let assoc = StoreSyncAssociation::Connected(ids);
                log::info!("Resetting {} store", store.collection_name());
                store.reset(&assoc)?;
                Ok(LocalCollState::Unknown { assoc })
            }

            LocalCollState::Ready { .. } => unreachable!("can't advance from ready"),
        }
    }

    // A little whimsy - a portmanteau of far and fast
    fn run_and_run_as_farst_as_you_can(
        &mut self,
        store: &dyn Store,
    ) -> error::Result<Option<CollState>> {
        let mut s = LocalCollState::Unknown {
            assoc: store.get_sync_assoc()?,
        };
        // This is a simple state machine and should never take more than
        // 10 goes around.
        let mut count = 0;
        loop {
            log::trace!("LocalCollState in {:?}", s);
            match s {
                LocalCollState::Ready { key } => {
                    let name = store.collection_name();
                    let config = self.global_state.config.clone();
                    let last_modified = self
                        .global_state
                        .collections
                        .get(name.as_ref())
                        .cloned()
                        .unwrap_or_default();
                    return Ok(Some(CollState {
                        config,
                        last_modified,
                        key,
                    }));
                }
                LocalCollState::Declined | LocalCollState::NoSuchCollection => return Ok(None),

                _ => {
                    count += 1;
                    if count > 10 {
                        log::warn!("LocalCollStateMachine appears to be looping");
                        return Ok(None);
                    }
                    // should we have better loop detection? Our limit of 10
                    // goes is probably OK for now, but not really ideal.
                    s = self.advance(s, store)?;
                }
            };
        }
    }

    pub fn get_state(
        store: &dyn Store,
        global_state: &'state GlobalState,
        root_key: &'state KeyBundle,
    ) -> error::Result<Option<CollState>> {
        let mut gingerbread_man = Self {
            global_state,
            root_key,
        };
        gingerbread_man.run_and_run_as_farst_as_you_can(store)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::changeset::{IncomingChangeset, OutgoingChangeset};
    use crate::collection_keys::CollectionKeys;
    use crate::record_types::{MetaGlobalEngine, MetaGlobalRecord};
    use crate::request::{CollectionRequest, InfoCollections, InfoConfiguration};
    use crate::telemetry;
    use std::cell::{Cell, RefCell};
    use std::collections::HashMap;
    use sync_guid::Guid;

    fn get_global_state(root_key: &KeyBundle) -> GlobalState {
        let keys = CollectionKeys::new_random()
            .unwrap()
            .to_encrypted_bso(&root_key)
            .unwrap();
        GlobalState {
            config: InfoConfiguration::default(),
            collections: InfoCollections::new(HashMap::new()),
            global: MetaGlobalRecord {
                sync_id: "syncIDAAAAAA".into(),
                storage_version: 5usize,
                engines: vec![(
                    "bookmarks",
                    MetaGlobalEngine {
                        version: 1usize,
                        sync_id: "syncIDBBBBBB".into(),
                    },
                )]
                .into_iter()
                .map(|(key, value)| (key.to_owned(), value))
                .collect(),
                declined: vec![],
            },
            global_timestamp: ServerTimestamp::default(),
            keys,
        }
    }

    struct TestStore {
        collection_name: &'static str,
        assoc: Cell<StoreSyncAssociation>,
        num_resets: RefCell<usize>,
    }

    impl TestStore {
        fn new(collection_name: &'static str, assoc: StoreSyncAssociation) -> Self {
            Self {
                collection_name,
                assoc: Cell::new(assoc),
                num_resets: RefCell::new(0),
            }
        }
        fn get_num_resets(&self) -> usize {
            *self.num_resets.borrow()
        }
    }

    impl Store for TestStore {
        fn collection_name(&self) -> std::borrow::Cow<'static, str> {
            self.collection_name.into()
        }

        fn apply_incoming(
            &self,
            _inbound: Vec<IncomingChangeset>,
            _telem: &mut telemetry::Engine,
        ) -> Result<OutgoingChangeset, failure::Error> {
            unreachable!("these tests shouldn't call these");
        }

        fn sync_finished(
            &self,
            _new_timestamp: ServerTimestamp,
            _records_synced: Vec<Guid>,
        ) -> Result<(), failure::Error> {
            unreachable!("these tests shouldn't call these");
        }

        fn get_collection_requests(
            &self,
            _server_timestamp: ServerTimestamp,
        ) -> Result<Vec<CollectionRequest>, failure::Error> {
            unreachable!("these tests shouldn't call these");
        }

        fn get_sync_assoc(&self) -> Result<StoreSyncAssociation, failure::Error> {
            Ok(self.assoc.replace(StoreSyncAssociation::Disconnected))
        }

        fn reset(&self, new_assoc: &StoreSyncAssociation) -> Result<(), failure::Error> {
            self.assoc.replace(new_assoc.clone());
            *self.num_resets.borrow_mut() += 1;
            Ok(())
        }

        fn wipe(&self) -> Result<(), failure::Error> {
            unreachable!("these tests shouldn't call these");
        }
    }

    #[test]
    fn test_unknown() {
        let root_key = KeyBundle::new_random().expect("should work");
        let gs = get_global_state(&root_key);
        let store = TestStore::new("unknown", StoreSyncAssociation::Disconnected);
        let cs = LocalCollStateMachine::get_state(&store, &gs, &root_key).expect("should work");
        assert!(cs.is_none(), "unknown collection name can't sync");
        assert_eq!(store.get_num_resets(), 0);
    }

    #[test]
    fn test_known_no_state() {
        let root_key = KeyBundle::new_random().expect("should work");
        let gs = get_global_state(&root_key);
        let store = TestStore::new("bookmarks", StoreSyncAssociation::Disconnected);
        let cs = LocalCollStateMachine::get_state(&store, &gs, &root_key).expect("should work");
        assert!(cs.is_some(), "collection can sync");
        assert_eq!(
            store.assoc.replace(StoreSyncAssociation::Disconnected),
            StoreSyncAssociation::Connected(CollSyncIds {
                global: "syncIDAAAAAA".into(),
                coll: "syncIDBBBBBB".into(),
            })
        );
        assert_eq!(store.get_num_resets(), 1);
    }

    #[test]
    fn test_known_wrong_state() {
        let root_key = KeyBundle::new_random().expect("should work");
        let gs = get_global_state(&root_key);
        let store = TestStore::new(
            "bookmarks",
            StoreSyncAssociation::Connected(CollSyncIds {
                global: "syncIDXXXXXX".into(),
                coll: "syncIDYYYYYY".into(),
            }),
        );
        let cs = LocalCollStateMachine::get_state(&store, &gs, &root_key).expect("should work");
        assert!(cs.is_some(), "collection can sync");
        assert_eq!(
            store.assoc.replace(StoreSyncAssociation::Disconnected),
            StoreSyncAssociation::Connected(CollSyncIds {
                global: "syncIDAAAAAA".into(),
                coll: "syncIDBBBBBB".into(),
            })
        );
        assert_eq!(store.get_num_resets(), 1);
    }

    #[test]
    fn test_known_good_state() {
        let root_key = KeyBundle::new_random().expect("should work");
        let gs = get_global_state(&root_key);
        let store = TestStore::new(
            "bookmarks",
            StoreSyncAssociation::Connected(CollSyncIds {
                global: "syncIDAAAAAA".into(),
                coll: "syncIDBBBBBB".into(),
            }),
        );
        let cs = LocalCollStateMachine::get_state(&store, &gs, &root_key).expect("should work");
        assert!(cs.is_some(), "collection can sync");
        assert_eq!(store.get_num_resets(), 0);
    }

    #[test]
    fn test_declined() {
        let root_key = KeyBundle::new_random().expect("should work");
        let mut gs = get_global_state(&root_key);
        gs.global.declined.push("bookmarks".to_string());
        let store = TestStore::new(
            "bookmarks",
            StoreSyncAssociation::Connected(CollSyncIds {
                global: "syncIDAAAAAA".into(),
                coll: "syncIDBBBBBB".into(),
            }),
        );
        let cs = LocalCollStateMachine::get_state(&store, &gs, &root_key).expect("should work");
        assert!(cs.is_none(), "declined collection can sync");
        assert_eq!(store.get_num_resets(), 0);
    }
}
