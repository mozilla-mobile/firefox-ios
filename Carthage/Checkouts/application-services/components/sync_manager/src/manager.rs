/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use crate::msg_types::{DeviceType, ServiceStatus, SyncParams, SyncReason, SyncResult};
use crate::{reset, reset_all, wipe, wipe_all};
use logins::PasswordEngine;
use places::{bookmark_sync::store::BookmarksStore, history_sync::store::HistoryStore, PlacesApi};
use std::collections::{HashMap, HashSet};
use std::result;
use std::sync::{atomic::AtomicUsize, Arc, Mutex, Weak};
use std::time::SystemTime;
use sync15::{
    self,
    clients::{self, Command, CommandProcessor, CommandStatus, Settings},
    MemoryCachedState,
};
use tabs::TabsEngine;

const LOGINS_ENGINE: &str = "passwords";
const HISTORY_ENGINE: &str = "history";
const BOOKMARKS_ENGINE: &str = "bookmarks";
const TABS_ENGINE: &str = "tabs";

// Casts aren't allowed in `match` arms, so we can't directly match
// `SyncParams.device_type`, which is an `i32`, against `DeviceType`
// variants. Instead, we reflect all variants into constants, cast them
// into the target type, and match against them. Please keep this list in sync
// with `msg_types::DeviceType` and `sync15::clients::DeviceType`.
const DEVICE_TYPE_DESKTOP: i32 = DeviceType::Desktop as i32;
const DEVICE_TYPE_MOBILE: i32 = DeviceType::Mobile as i32;
const DEVICE_TYPE_TABLET: i32 = DeviceType::Tablet as i32;
const DEVICE_TYPE_VR: i32 = DeviceType::Vr as i32;
const DEVICE_TYPE_TV: i32 = DeviceType::Tv as i32;

pub struct SyncManager {
    mem_cached_state: Option<MemoryCachedState>,
    places: Weak<PlacesApi>,
    logins: Weak<Mutex<PasswordEngine>>,
    tabs: Weak<Mutex<TabsEngine>>,
}

impl SyncManager {
    pub fn new() -> Self {
        Self {
            mem_cached_state: None,
            places: Weak::new(),
            logins: Weak::new(),
            tabs: Weak::new(),
        }
    }

    pub fn set_places(&mut self, places: Arc<PlacesApi>) {
        self.places = Arc::downgrade(&places);
    }

    pub fn set_logins(&mut self, logins: Arc<Mutex<PasswordEngine>>) {
        self.logins = Arc::downgrade(&logins);
    }

    pub fn set_tabs(&mut self, tabs: Arc<Mutex<TabsEngine>>) {
        self.tabs = Arc::downgrade(&tabs);
    }

    pub fn wipe(&mut self, engine: &str) -> Result<()> {
        match engine {
            "logins" => {
                if let Some(logins) = self
                    .logins
                    .upgrade()
                    .as_ref()
                    .map(|l| l.lock().expect("poisoned logins mutex"))
                {
                    logins.wipe()?;
                    Ok(())
                } else {
                    Err(ErrorKind::ConnectionClosed(engine.into()).into())
                }
            }
            "bookmarks" => {
                if let Some(places) = self.places.upgrade() {
                    places.wipe_bookmarks()?;
                    Ok(())
                } else {
                    Err(ErrorKind::ConnectionClosed(engine.into()).into())
                }
            }
            "history" => {
                if let Some(places) = self.places.upgrade() {
                    places.wipe_history()?;
                    Ok(())
                } else {
                    Err(ErrorKind::ConnectionClosed(engine.into()).into())
                }
            }
            _ => Err(ErrorKind::UnknownEngine(engine.into()).into()),
        }
    }

    pub fn wipe_all(&mut self) -> Result<()> {
        if let Some(logins) = self
            .logins
            .upgrade()
            .as_ref()
            .map(|l| l.lock().expect("poisoned logins mutex"))
        {
            logins.wipe()?;
        }
        if let Some(places) = self.places.upgrade() {
            places.wipe_bookmarks()?;
            places.wipe_history()?;
        }
        Ok(())
    }

    pub fn reset(&mut self, engine: &str) -> Result<()> {
        match engine {
            "logins" => {
                if let Some(logins) = self
                    .logins
                    .upgrade()
                    .as_ref()
                    .map(|l| l.lock().expect("poisoned logins mutex"))
                {
                    logins.reset()?;
                    Ok(())
                } else {
                    Err(ErrorKind::ConnectionClosed(engine.into()).into())
                }
            }
            "bookmarks" | "history" => {
                if let Some(places) = self.places.upgrade() {
                    if engine == "bookmarks" {
                        places.reset_bookmarks()?;
                    } else {
                        places.reset_history()?;
                    }
                    Ok(())
                } else {
                    Err(ErrorKind::ConnectionClosed(engine.into()).into())
                }
            }
            _ => Err(ErrorKind::UnknownEngine(engine.into()).into()),
        }
    }

    pub fn reset_all(&mut self) -> Result<()> {
        if let Some(logins) = self
            .logins
            .upgrade()
            .as_ref()
            .map(|l| l.lock().expect("poisoned logins mutex"))
        {
            logins.reset()?;
        }
        if let Some(places) = self.places.upgrade() {
            places.reset_bookmarks()?;
            places.reset_history()?;
        }
        Ok(())
    }

    pub fn disconnect(&mut self) {
        if let Some(logins) = self
            .logins
            .upgrade()
            .as_ref()
            .map(|l| l.lock().expect("poisoned logins mutex"))
        {
            if let Err(e) = logins.reset() {
                log::error!("Failed to reset logins: {}", e);
            }
        } else {
            log::warn!("Unable to reset logins, be sure to call set_logins before disconnect if this is surprising");
        }

        if let Some(places) = self.places.upgrade() {
            if let Err(e) = places.reset_bookmarks() {
                log::error!("Failed to reset bookmarks: {}", e);
            }
            if let Err(e) = places.reset_history() {
                log::error!("Failed to reset history: {}", e);
            }
        } else {
            log::warn!("Unable to reset places, be sure to call set_places before disconnect if this is surprising");
        }
    }

    pub fn sync(&mut self, params: SyncParams) -> Result<SyncResult> {
        let mut have_engines = vec![];
        let places = self.places.upgrade();
        let tabs = self.tabs.upgrade();
        let logins = self.logins.upgrade();
        if places.is_some() {
            have_engines.push(HISTORY_ENGINE);
            have_engines.push(BOOKMARKS_ENGINE);
        }
        if logins.is_some() {
            have_engines.push(LOGINS_ENGINE);
        }
        if tabs.is_some() {
            have_engines.push(TABS_ENGINE);
        }
        check_engine_list(&params.engines_to_sync, &have_engines)?;

        let next_sync_after = self
            .mem_cached_state
            .as_ref()
            .and_then(|mcs| mcs.get_next_sync_after());
        if !backoff_in_effect(next_sync_after, &params) {
            log::info!("No backoff in effect (or we decided to ignore it), starting sync");
            self.do_sync(params)
        } else {
            let ts = system_time_to_millis(next_sync_after);
            log::warn!(
                "Backoff still in effect (until {:?}), bailing out early",
                ts
            );
            Ok(SyncResult {
                status: ServiceStatus::BackedOff as i32,
                results: Default::default(),
                have_declined: false,
                declined: vec![],
                next_sync_allowed_at: ts,
                persisted_state: params.persisted_state.unwrap_or_default(),
                // It would be nice to record telemetry here.
                telemetry_json: None,
            })
        }
    }

    fn do_sync(&mut self, mut params: SyncParams) -> Result<SyncResult> {
        let mut places = self.places.upgrade();
        let logins = self.logins.upgrade();
        let tabs = self.tabs.upgrade();

        let key_bundle = sync15::KeyBundle::from_ksync_base64(&params.acct_sync_key)?;
        let tokenserver_url = url::Url::parse(&params.acct_tokenserver_url)?;

        let bookmarks_sync = should_sync(&params, BOOKMARKS_ENGINE) && places.is_some();
        let history_sync = should_sync(&params, HISTORY_ENGINE) && places.is_some();
        let logins_sync = should_sync(&params, LOGINS_ENGINE) && logins.is_some();
        let tabs_sync = should_sync(&params, TABS_ENGINE) && tabs.is_some();

        let places_conn = if bookmarks_sync || history_sync {
            places
                .as_mut()
                .expect("trying to sync an engine that has not been configured")
                .open_sync_connection()
                .ok()
        } else {
            None
        };
        let l = if logins_sync {
            logins.as_ref().map(|l| l.lock().expect("poisoned mutex"))
        } else {
            None
        };
        let t = if tabs_sync {
            tabs.as_ref().map(|t| t.lock().expect("poisoned mutex"))
        } else {
            None
        };

        // TODO(issue 1684) this isn't ideal, we should have real support for interruption.
        let p = Arc::new(AtomicUsize::new(0));
        let interruptee = sql_support::SqlInterruptScope::new(p);

        let mut mem_cached_state = self.mem_cached_state.take().unwrap_or_default();
        let mut disk_cached_state = params.persisted_state.take();
        // `sync_multiple` takes a &[&dyn Store], but we need something to hold
        // ownership of our stores.
        let mut stores: Vec<Box<dyn sync15::Store>> = vec![];

        if let Some(pc) = places_conn.as_ref() {
            assert!(
                history_sync || bookmarks_sync,
                "Should have already checked"
            );
            if history_sync {
                stores.push(Box::new(HistoryStore::new(pc, &interruptee)))
            }
            if bookmarks_sync {
                stores.push(Box::new(BookmarksStore::new(pc, &interruptee)))
            }
        }

        if let Some(le) = l.as_ref() {
            assert!(logins_sync, "Should have already checked");
            stores.push(Box::new(logins::LoginStore::new(&le.db)));
        }

        if let Some(tbs) = t.as_ref() {
            assert!(tabs_sync, "Should have already checked");
            stores.push(Box::new(tabs::TabsStore::new(&tbs.storage)));
        }

        let store_refs: Vec<&dyn sync15::Store> = stores.iter().map(|s| &**s).collect();

        let client_init = sync15::Sync15StorageClientInit {
            key_id: params.acct_key_id.clone(),
            access_token: params.acct_access_token.clone(),
            tokenserver_url,
        };
        let engines_to_change = if params.engines_to_change_state.is_empty() {
            None
        } else {
            Some(&params.engines_to_change_state)
        };

        let settings = Settings {
            fxa_device_id: params.fxa_device_id,
            device_name: params.device_name,
            device_type: match params.device_type {
                DEVICE_TYPE_DESKTOP => clients::DeviceType::Desktop,
                DEVICE_TYPE_MOBILE => clients::DeviceType::Mobile,
                DEVICE_TYPE_TABLET => clients::DeviceType::Tablet,
                DEVICE_TYPE_VR => clients::DeviceType::VR,
                DEVICE_TYPE_TV => clients::DeviceType::TV,
                _ => {
                    log::warn!(
                        "Unknown device type {}; assuming desktop",
                        params.device_type
                    );
                    clients::DeviceType::Desktop
                }
            },
        };
        let c = SyncClient::new(settings);
        let result = sync15::sync_multiple_with_command_processor(
            Some(&c),
            &store_refs,
            &mut disk_cached_state,
            &mut mem_cached_state,
            &client_init,
            &key_bundle,
            &interruptee,
            Some(sync15::SyncRequestInfo {
                engines_to_state_change: engines_to_change,
                is_user_action: params.reason == (SyncReason::User as i32),
            }),
        );
        self.mem_cached_state = Some(mem_cached_state);

        log::info!("Sync finished with status {:?}", result.service_status);
        let status = ServiceStatus::from(result.service_status) as i32;
        let results: HashMap<String, String> = result
            .engine_results
            .into_iter()
            .map(|(e, r)| {
                log::info!("engine {:?} status: {:?}", e, r);
                (
                    e,
                    match r {
                        Ok(()) => "".to_string(),
                        Err(err) => {
                            let msg = err.to_string();
                            if msg.is_empty() {
                                log::error!(
                                    "Bug: error message string is empty for error: {:?}",
                                    err
                                );
                                // This shouldn't happen, but we use empty string to
                                // indicate success on the other side, so just ensure
                                // our errors error can't be
                                "<unspecified error>".to_string()
                            } else {
                                msg
                            }
                        }
                    },
                )
            })
            .collect();

        // Unwrap here can never fail -- it indicates trying to serialize an
        // unserializable type.
        let telemetry_json = serde_json::to_string(&result.telemetry).unwrap();

        Ok(SyncResult {
            status,
            results,
            have_declined: result.declined.is_some(),
            declined: result.declined.unwrap_or_default(),
            next_sync_allowed_at: system_time_to_millis(result.next_sync_after),
            persisted_state: disk_cached_state.unwrap_or_default(),
            telemetry_json: Some(telemetry_json),
        })
    }
}

fn backoff_in_effect(next_sync_after: Option<SystemTime>, p: &SyncParams) -> bool {
    let now = SystemTime::now();
    if let Some(nsa) = next_sync_after {
        if nsa > now {
            return if p.reason == (SyncReason::User as i32)
                || p.reason == (SyncReason::EnabledChange as i32)
            {
                log::info!(
                    "Still under backoff, but syncing anyway because reason is {:?}",
                    p.reason
                );
                false
            } else if !p.engines_to_change_state.is_empty() {
                log::info!(
                    "Still under backoff, but syncing because we have enabled state changes."
                );
                false
            } else {
                log::info!(
                    "Still under backoff, and there's no compelling reason for us to ignore it"
                );
                true
            };
        }
    }
    log::debug!("Not under backoff");
    false
}

impl From<sync15::ServiceStatus> for ServiceStatus {
    fn from(s15s: sync15::ServiceStatus) -> Self {
        use sync15::ServiceStatus::*;
        match s15s {
            Ok => ServiceStatus::Ok,
            NetworkError => ServiceStatus::NetworkError,
            ServiceError => ServiceStatus::ServiceError,
            AuthenticationError => ServiceStatus::AuthError,
            BackedOff => ServiceStatus::BackedOff,
            Interrupted => ServiceStatus::OtherError, // Eh...
            OtherError => ServiceStatus::OtherError,
        }
    }
}

fn system_time_to_millis(st: Option<SystemTime>) -> Option<i64> {
    use std::convert::TryFrom;
    let d = st?.duration_since(std::time::UNIX_EPOCH).ok()?;
    // This should always succeed for remotely sane values.
    i64::try_from(d.as_secs() * 1_000 + u64::from(d.subsec_nanos()) / 1_000_000).ok()
}

fn should_sync(p: &SyncParams, engine: &str) -> bool {
    p.sync_all_engines || p.engines_to_sync.iter().any(|e| e == engine)
}

fn check_engine_list(list: &[String], have_engines: &[&str]) -> Result<()> {
    log::trace!(
        "Checking engines requested ({:?}) vs local engines ({:?})",
        list,
        have_engines
    );
    for e in list {
        if [BOOKMARKS_ENGINE, HISTORY_ENGINE, LOGINS_ENGINE, TABS_ENGINE].contains(&e.as_ref()) {
            if !have_engines.iter().any(|engine| e == engine) {
                return Err(ErrorKind::UnsupportedFeature(e.to_string()).into());
            }
        } else {
            return Err(ErrorKind::UnknownEngine(e.to_string()).into());
        }
    }
    Ok(())
}

struct SyncClient(Settings);

impl SyncClient {
    pub fn new(settings: Settings) -> SyncClient {
        SyncClient(settings)
    }
}

impl CommandProcessor for SyncClient {
    fn settings(&self) -> &Settings {
        &self.0
    }

    fn apply_incoming_command(
        &self,
        command: Command,
    ) -> result::Result<CommandStatus, failure::Error> {
        let result = match command {
            Command::Wipe(engine) => wipe(&engine),
            Command::WipeAll => wipe_all(),
            Command::Reset(engine) => reset(&engine),
            Command::ResetAll => reset_all(),
        };
        match result {
            Ok(()) => Ok(CommandStatus::Applied),
            Err(err) => match err.kind() {
                ErrorKind::UnknownEngine(_) => Ok(CommandStatus::Unsupported),
                _ => Err(err.into()),
            },
        }
    }

    fn fetch_outgoing_commands(&self) -> result::Result<HashSet<Command>, failure::Error> {
        Ok(HashSet::new())
    }
}
