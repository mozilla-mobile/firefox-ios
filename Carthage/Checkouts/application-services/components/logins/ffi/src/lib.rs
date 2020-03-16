/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
// Let's allow these in the FFI code, since it's usually just a coincidence if
// the closure is small.
#![allow(clippy::redundant_closure)]

use ffi_support::ConcurrentHandleMap;
use ffi_support::{
    define_box_destructor, define_bytebuffer_destructor, define_handle_map_deleter,
    define_string_destructor, ByteBuffer, ExternError, FfiStr,
};
use logins::msg_types::{PasswordInfo, PasswordInfos};
use logins::{Login, LoginDb, PasswordEngine, Result};
use std::os::raw::c_char;
use std::sync::{Arc, Mutex};

lazy_static::lazy_static! {
    // TODO: this is basically a RwLock<HandleMap<Mutex<Arc<Mutex<...>>>>.
    // but could just be a `RwLock<HandleMap<Arc<Mutex<...>>>>`.
    // Find a way to express this cleanly in ffi_support?
    pub static ref ENGINES: ConcurrentHandleMap<Arc<Mutex<PasswordEngine>>> = ConcurrentHandleMap::new();
}

#[no_mangle]
pub extern "C" fn sync15_passwords_state_new(
    db_path: FfiStr<'_>,
    encryption_key: FfiStr<'_>,
    error: &mut ExternError,
) -> u64 {
    log::debug!("sync15_passwords_state_new");
    ENGINES.insert_with_result(error, || -> logins::Result<_> {
        let path = db_path.as_str();
        let key = encryption_key.as_str();
        Ok(Arc::new(Mutex::new(PasswordEngine::new(path, Some(key))?)))
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_state_new_with_salt(
    db_path: FfiStr<'_>,
    encryption_key: FfiStr<'_>,
    salt: FfiStr<'_>,
    error: &mut ExternError,
) -> u64 {
    log::debug!("sync15_passwords_state_new_with_salt");
    ENGINES.insert_with_result(error, || -> logins::Result<_> {
        let path = db_path.as_str();
        let key = encryption_key.as_str();
        let salt = salt.as_str();
        Ok(Arc::new(Mutex::new(PasswordEngine::new_with_salt(
            path, key, salt,
        )?)))
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_num_open_connections(error: &mut ExternError) -> u64 {
    ffi_support::call_with_output(error, || ENGINES.len() as u64)
}

unsafe fn bytes_to_key_string(key_bytes: *const u8, len: usize) -> Option<String> {
    if len == 0 {
        log::info!("Opening/Creating unencrypted database!");
        return None;
    } else {
        assert!(
            !key_bytes.is_null(),
            "Null pointer provided with nonzero length"
        );
    }
    let byte_slice = std::slice::from_raw_parts(key_bytes, len);
    Some(base16::encode_lower(byte_slice))
}

/// Same as sync15_passwords_state_new, but automatically hex-encodes the string.
///
/// If a key_len of 0 is provided, then the database will not be encrypted.
///
/// Note: lowercase hex characters are used (e.g. it encodes using the character set 0-9a-f and NOT 0-9A-F).
///
/// # Safety
///
/// Dereferences the `encryption_key` pointer, and is thus unsafe.
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_state_new_with_hex_key(
    db_path: FfiStr<'_>,
    encryption_key: *const u8,
    encryption_key_len: u32,
    error: &mut ExternError,
) -> u64 {
    log::debug!("sync15_passwords_state_new_with_hex_key");
    ENGINES.insert_with_result(error, || -> logins::Result<_> {
        let path = db_path.as_str();
        let key = bytes_to_key_string(encryption_key, encryption_key_len as usize);
        // We have a Option<String>, but need an Option<&str>...
        let opt_key_ref = key.as_ref().map(String::as_str);
        Ok(Arc::new(Mutex::new(PasswordEngine::new(
            path,
            opt_key_ref,
        )?)))
    })
}

/// Opens an existing database that stores its salt in the header bytes and retrieves its salt.
///
/// # Safety
///
/// Dereferences the `encryption_key` pointer, and is thus unsafe.
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_get_db_salt(
    db_path: FfiStr<'_>,
    encryption_key: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("sync15_passwords_get_db_salt");
    let path = db_path.as_str();
    let key = encryption_key.as_str();
    ffi_support::call_with_result(error, || LoginDb::open_and_get_salt(path, key))
}

/// Opens an existing database that stores its salt in the header bytes and migrates it
/// to a plaintext header one.
///
/// # Safety
///
/// Dereferences the `encryption_key` and `salt` pointers, and is thus unsafe.
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_migrate_plaintext_header(
    db_path: FfiStr<'_>,
    encryption_key: FfiStr<'_>,
    salt: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_migrate_plaintext_header");
    let path = db_path.as_str();
    let key = encryption_key.as_str();
    let salt = salt.as_str();
    ffi_support::call_with_result(error, || {
        LoginDb::open_and_migrate_to_plaintext_header(path, key, salt)
    })
}

// indirection to help `?` figure out the target error type
fn parse_url(url: &str) -> sync15::Result<url::Url> {
    Ok(url::Url::parse(url)?)
}

#[no_mangle]
pub extern "C" fn sync15_passwords_disable_mem_security(handle: u64, error: &mut ExternError) {
    log::debug!("sync15_passwords_disable_mem_security");
    ENGINES.call_with_result(error, handle, |state| -> Result<()> {
        state.lock().unwrap().disable_mem_security()
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_rekey_database(
    handle: u64,
    new_encryption_key: FfiStr<'_>,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_rekey_database");
    let new_key = new_encryption_key.as_str();
    ENGINES.call_with_result(error, handle, |state| -> Result<()> {
        state.lock().unwrap().rekey_database(new_key)
    })
}

/// Same as sync15_passwords_rekey_database, but accepts a byte array encryption key.
///
/// If a key_len of 0 is provided, then the database will not be encrypted.
///
/// Note: lowercase hex characters are used (e.g. it encodes using the character set 0-9a-f and NOT 0-9A-F).
///
/// # Safety
///
/// Dereferences the `new_encryption_key` pointer, and is thus unsafe.
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_rekey_database_with_hex_key(
    handle: u64,
    new_encryption_key: *const u8,
    new_encryption_key_len: u32,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_rekey_database_with_hex_key");
    ENGINES.call_with_result(error, handle, |state| -> Result<()> {
        let new_key =
            bytes_to_key_string(new_encryption_key, new_encryption_key_len as usize).unwrap();
        state.lock().unwrap().rekey_database(&new_key)
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_sync(
    handle: u64,
    key_id: FfiStr<'_>,
    access_token: FfiStr<'_>,
    sync_key: FfiStr<'_>,
    tokenserver_url: FfiStr<'_>,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("sync15_passwords_sync");
    ENGINES.call_with_result(error, handle, |state| -> Result<_> {
        let ping = state.lock().unwrap().sync(
            &sync15::Sync15StorageClientInit {
                key_id: key_id.into_string(),
                access_token: access_token.into_string(),
                tokenserver_url: parse_url(tokenserver_url.as_str())?,
            },
            &sync15::KeyBundle::from_ksync_base64(sync_key.as_str())?,
        )?;
        Ok(ping)
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_touch(handle: u64, id: FfiStr<'_>, error: &mut ExternError) {
    log::debug!("sync15_passwords_touch");
    ENGINES.call_with_result(error, handle, |state| {
        state.lock().unwrap().touch(id.as_str())
    })
}

// Should we put this function in ffi_support as a `unsafe pub fn`?
unsafe fn get_buffer<'a>(data: *const u8, len: i32) -> &'a [u8] {
    assert!(len >= 0, "Bad buffer len: {}", len);
    if len == 0 {
        // This will still fail, but as a bad protobuf format.
        &[]
    } else {
        assert!(!data.is_null(), "Unexpected null data pointer");
        std::slice::from_raw_parts(data, len as usize)
    }
}

/// # Safety
/// Deref pointer, thus unsafe
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_check_valid(
    handle: u64,
    data: *const u8,
    len: i32,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_check_valid");
    ENGINES.call_with_result(error, handle, |state| {
        let buffer = get_buffer(data, len);
        let login: PasswordInfo = prost::Message::decode(buffer)?;
        state
            .lock()
            .unwrap()
            .check_valid_with_no_dupes(&login.into())
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_delete(
    handle: u64,
    id: FfiStr<'_>,
    error: &mut ExternError,
) -> u8 {
    log::debug!("sync15_passwords_delete");
    ENGINES.call_with_result(error, handle, |state| {
        state.lock().unwrap().delete(id.as_str())
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_wipe(handle: u64, error: &mut ExternError) {
    log::debug!("sync15_passwords_wipe");
    ENGINES.call_with_result(error, handle, |state| state.lock().unwrap().wipe())
}

#[no_mangle]
pub extern "C" fn sync15_passwords_wipe_local(handle: u64, error: &mut ExternError) {
    log::debug!("sync15_passwords_wipe_local");
    ENGINES.call_with_result(error, handle, |state| state.lock().unwrap().wipe_local())
}

#[no_mangle]
pub extern "C" fn sync15_passwords_reset(handle: u64, error: &mut ExternError) {
    log::debug!("sync15_passwords_reset");
    ENGINES.call_with_result(error, handle, |state| state.lock().unwrap().reset())
}

#[no_mangle]
pub extern "C" fn sync15_passwords_new_interrupt_handle(
    handle: u64,
    error: &mut ExternError,
) -> *mut sql_support::SqlInterruptHandle {
    log::debug!("sync15_passwords_new_interrupt_handle");
    ENGINES.call_with_output(error, handle, |state| {
        state.lock().unwrap().new_interrupt_handle()
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_interrupt(
    handle: &sql_support::SqlInterruptHandle,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_interrupt");
    ffi_support::call_with_output(error, || handle.interrupt())
}

#[no_mangle]
pub extern "C" fn sync15_passwords_get_all(handle: u64, error: &mut ExternError) -> ByteBuffer {
    log::debug!("sync15_passwords_get_all");
    ENGINES.call_with_result(error, handle, |state| -> Result<_> {
        let infos = state
            .lock()
            .unwrap()
            .list()?
            .into_iter()
            .map(Login::into)
            .collect();
        Ok(PasswordInfos { infos })
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_get_by_base_domain(
    handle: u64,
    base_domain: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("sync15_passwords_get_by_base_domain");
    ENGINES.call_with_result(error, handle, |state| -> Result<_> {
        let infos = state
            .lock()
            .unwrap()
            .get_by_base_domain(base_domain.as_str())?
            .into_iter()
            .map(Login::into)
            .collect();
        Ok(PasswordInfos { infos })
    })
}

#[no_mangle]
pub extern "C" fn sync15_passwords_get_by_id(
    handle: u64,
    id: FfiStr<'_>,
    error: &mut ExternError,
) -> ByteBuffer {
    log::debug!("sync15_passwords_get_by_id");
    ENGINES.call_with_result(error, handle, |state| -> Result<Option<PasswordInfo>> {
        Ok(state.lock().unwrap().get(id.as_str())?.map(Login::into))
    })
}

/// # Safety
/// Deref pointer, thus unsafe
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_add(
    handle: u64,
    data: *const u8,
    len: i32,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("sync15_passwords_add");
    ENGINES.call_with_result(error, handle, |state| {
        let buffer = get_buffer(data, len);
        let login: PasswordInfo = prost::Message::decode(buffer)?;
        state.lock().unwrap().add(login.into())
    })
}

/// # Safety
/// Deref pointer, thus unsafe
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_import(
    handle: u64,
    data: *const u8,
    len: i32,
    error: &mut ExternError,
) -> *mut c_char {
    log::debug!("sync15_passwords_import");
    ENGINES.call_with_result(error, handle, |state| -> Result<String> {
        let buffer = get_buffer(data, len);
        let messages: PasswordInfos = prost::Message::decode(buffer)?;
        let logins: Vec<Login> = messages.infos.into_iter().map(PasswordInfo::into).collect();
        let import_metrics = state.lock().unwrap().import_multiple(&logins)?;
        let result = serde_json::to_string(&import_metrics)?;
        Ok(result)
    })
}

/// # Safety
/// Deref pointer, thus unsafe
#[no_mangle]
pub unsafe extern "C" fn sync15_passwords_update(
    handle: u64,
    data: *const u8,
    len: i32,
    error: &mut ExternError,
) {
    log::debug!("sync15_passwords_update");
    ENGINES.call_with_result(error, handle, |state| {
        let buffer = get_buffer(data, len);
        let login: PasswordInfo = prost::Message::decode(buffer)?;
        state.lock().unwrap().update(login.into())
    });
}

define_string_destructor!(sync15_passwords_destroy_string);
define_bytebuffer_destructor!(sync15_passwords_destroy_buffer);
define_handle_map_deleter!(ENGINES, sync15_passwords_state_destroy);
define_box_destructor!(
    sql_support::SqlInterruptHandle,
    sync15_passwords_interrupt_handle_destroy
);
