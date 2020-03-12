/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

pub mod error;
mod ffi;
mod manager;

pub use error::{Error, ErrorKind, Result};

pub mod msg_types {
    include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
}

use logins::PasswordEngine;
use manager::SyncManager;
use places::PlacesApi;
use std::sync::Arc;
use std::sync::Mutex;
use tabs::TabsEngine;

lazy_static::lazy_static! {
    static ref MANAGER: Mutex<SyncManager> = Mutex::new(SyncManager::new());
}

pub fn set_places(places: Arc<PlacesApi>) {
    let mut manager = MANAGER.lock().unwrap();
    manager.set_places(places);
}

pub fn set_logins(places: Arc<Mutex<PasswordEngine>>) {
    let mut manager = MANAGER.lock().unwrap();
    manager.set_logins(places);
}

pub fn set_tabs(tabs: Arc<Mutex<TabsEngine>>) {
    let mut manager = MANAGER.lock().unwrap();
    manager.set_tabs(tabs);
}

pub fn disconnect() {
    let mut manager = MANAGER.lock().unwrap();
    manager.disconnect();
}

pub fn wipe(engine: &str) -> Result<()> {
    let mut manager = MANAGER.lock().unwrap();
    manager.wipe(engine)
}

pub fn wipe_all() -> Result<()> {
    let mut manager = MANAGER.lock().unwrap();
    manager.wipe_all()
}

pub fn reset(engine: &str) -> Result<()> {
    let mut manager = MANAGER.lock().unwrap();
    manager.reset(engine)
}

pub fn reset_all() -> Result<()> {
    let mut manager = MANAGER.lock().unwrap();
    manager.reset_all()
}

pub fn sync(params: msg_types::SyncParams) -> Result<msg_types::SyncResult> {
    let mut manager = MANAGER.lock().unwrap();
    manager.sync(params)
}
