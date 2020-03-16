/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use crate::login::{LocalLogin, Login, MirrorLogin, SyncLoginData, SyncStatus};
use crate::schema;
use crate::update_plan::UpdatePlan;
use crate::util;
use lazy_static::lazy_static;
use rusqlite::{
    named_params,
    types::{FromSql, ToSql},
    Connection, OpenFlags, NO_PARAMS,
};
use serde_derive::*;
use sql_support::{self, ConnExt};
use sql_support::{SqlInterruptHandle, SqlInterruptScope};
use std::collections::HashSet;
use std::ops::Deref;
use std::path::Path;
use std::result;
use std::sync::{atomic::AtomicUsize, Arc};
use std::time::{Duration, Instant, SystemTime};
use sync15::{
    extract_v1_state, telemetry, CollSyncIds, CollectionRequest, IncomingChangeset,
    OutgoingChangeset, Payload, ServerTimestamp, Store, StoreSyncAssociation,
};
use sync_guid::Guid;
use url::{Host, Url};

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone, Default)]
pub struct MigrationPhaseMetrics {
    num_processed: u64,
    num_succeeded: u64,
    num_failed: u64,
    total_duration: u128,
    errors: Vec<String>,
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone, Default)]
pub struct MigrationMetrics {
    fixup_phase: MigrationPhaseMetrics,
    insert_phase: MigrationPhaseMetrics,
    num_processed: u64,
    num_succeeded: u64,
    num_failed: u64,
    total_duration: u128,
    errors: Vec<String>,
}

pub struct LoginDb {
    pub db: Connection,
    interrupt_counter: Arc<AtomicUsize>,
}

impl LoginDb {
    pub fn with_connection(
        db: Connection,
        encryption_key: Option<&str>,
        salt: Option<&str>,
    ) -> Result<Self> {
        #[cfg(test)]
        {
            util::init_test_logging();
        }

        if let Some(key) = encryption_key {
            db.set_pragma("key", key)?
                .set_pragma("secure_delete", true)?;

            sqlcipher_3_compat(&db)?;

            if let Some(s) = salt {
                // If a salt is also provided, this means the consumer does not want the salt stored
                // in the database header. Currently only iOS uses this.
                db.set_pragma("cipher_plaintext_header_size", 32)?;
                db.set_pragma("cipher_salt", format!("x'{}'", s))?;
            }
        }

        // `temp_store = 2` is required on Android to force the DB to keep temp
        // files in memory, since on Android there's no tmp partition. See
        // https://github.com/mozilla/mentat/issues/505. Ideally we'd only
        // do this on Android, or allow caller to configure it.
        db.set_pragma("temp_store", 2)?;

        let mut logins = Self {
            db,
            interrupt_counter: Arc::new(AtomicUsize::new(0)),
        };
        let tx = logins.db.transaction()?;
        schema::init(&tx)?;
        tx.commit()?;
        Ok(logins)
    }

    pub fn open(path: impl AsRef<Path>, encryption_key: Option<&str>) -> Result<Self> {
        Ok(Self::with_connection(
            Connection::open(path)?,
            encryption_key,
            None,
        )?)
    }

    pub fn open_with_salt(
        path: impl AsRef<Path>,
        encryption_key: &str,
        salt: &str,
    ) -> Result<Self> {
        ensure_valid_salt(salt)?;
        Ok(Self::with_connection(
            Connection::open(path)?,
            Some(encryption_key),
            Some(salt),
        )?)
    }

    pub fn open_in_memory(encryption_key: Option<&str>) -> Result<Self> {
        Ok(Self::with_connection(
            Connection::open_in_memory()?,
            encryption_key,
            None,
        )?)
    }

    /// Opens an existing database and fetches the salt.
    /// This method is used by iOS consumers as part as the migration plan to store
    /// the salt outside of the sqlite db headers.
    ///
    /// Will return an error if the database does not exist.
    pub fn open_and_get_salt(path: impl AsRef<Path>, encryption_key: &str) -> Result<String> {
        // Open the connection defensively without attempting to create a db if it doesn't exist.
        let db = Connection::open_with_flags(path, OpenFlags::SQLITE_OPEN_READ_ONLY)?;
        db.set_pragma("key", encryption_key)?;
        sqlcipher_3_compat(&db)?;
        let salt = db.query_one::<String>("PRAGMA cipher_salt")?;
        Ok(salt)
    }

    pub fn open_and_migrate_to_plaintext_header(
        path: impl AsRef<Path>,
        encryption_key: &str,
        salt: &str,
    ) -> Result<()> {
        ensure_valid_salt(salt)?;
        // Open the connection defensively without attempting to create a db if it doesn't exist.
        let db = Connection::open_with_flags(path, OpenFlags::SQLITE_OPEN_READ_WRITE)?;
        db.set_pragma("key", encryption_key)?;
        sqlcipher_3_compat(&db)?;
        db.set_pragma("cipher_salt", format!("x'{}'", salt))?;
        // This tricks the `cipher_plaintext_header_size` command to work properly.
        let user_version = db.query_one::<i64>("PRAGMA user_version")?;
        // Remove the salt from the database header.
        db.set_pragma("cipher_plaintext_header_size", 32)?;
        // Flush the header changes.
        db.set_pragma("user_version", user_version)?;
        db.close().map_err(|(_conn, err)| err)?;
        Ok(())
    }

    pub fn disable_mem_security(&self) -> Result<()> {
        self.conn().set_pragma("cipher_memory_security", false)?;
        Ok(())
    }

    /// Change the key on an existing encrypted database,
    /// it must first be unlocked with the current encryption key.
    /// Once the database is readable and writeable, PRAGMA rekey
    /// can be used to re-encrypt every page in the database with a new key.
    /// https://www.zetetic.net/sqlcipher/sqlcipher-api/#Changing_Key
    pub fn rekey_database(&self, new_encryption_key: &str) -> Result<()> {
        self.conn().set_pragma("rekey", new_encryption_key)?;
        Ok(())
    }

    pub fn new_interrupt_handle(&self) -> SqlInterruptHandle {
        SqlInterruptHandle::new(
            self.db.get_interrupt_handle(),
            self.interrupt_counter.clone(),
        )
    }

    #[inline]
    pub fn begin_interrupt_scope(&self) -> SqlInterruptScope {
        SqlInterruptScope::new(self.interrupt_counter.clone())
    }
}

// Checks if the provided string is a 32 len hex string.
fn ensure_valid_salt(salt: &str) -> Result<()> {
    if salt.len() == 32
        && salt.as_bytes().iter().all(|c| match c {
            b'A'..=b'F' => true,
            b'a'..=b'f' => true,
            b'0'..=b'9' => true,
            _ => false,
        })
    {
        return Ok(());
    }
    Err(ErrorKind::InvalidSalt.into())
}

fn sqlcipher_3_compat(conn: &Connection) -> Result<()> {
    // SQLcipher pre-4.0.0 compatibility. Using SHA1 still
    // is less than ideal, but should be fine. Real uses of
    // this (lockwise, etc) use a real random string for the
    // encryption key, so the reduced KDF iteration count
    // is fine.
    conn.set_pragma("cipher_page_size", 1024)?
        .set_pragma("kdf_iter", 64000)?
        .set_pragma("cipher_hmac_algorithm", "HMAC_SHA1")?
        .set_pragma("cipher_kdf_algorithm", "PBKDF2_HMAC_SHA1")?;
    Ok(())
}

impl ConnExt for LoginDb {
    #[inline]
    fn conn(&self) -> &Connection {
        &self.db
    }
}

impl Deref for LoginDb {
    type Target = Connection;
    #[inline]
    fn deref(&self) -> &Connection {
        &self.db
    }
}

// login specific stuff.

impl LoginDb {
    fn mark_as_synchronized(
        &self,
        guids: &[&str],
        ts: ServerTimestamp,
        scope: &SqlInterruptScope,
    ) -> Result<()> {
        let tx = self.unchecked_transaction()?;
        sql_support::each_chunk(guids, |chunk, _| -> Result<()> {
            self.db.execute(
                &format!(
                    "DELETE FROM loginsM WHERE guid IN ({vars})",
                    vars = sql_support::repeat_sql_vars(chunk.len())
                ),
                chunk,
            )?;
            scope.err_if_interrupted()?;

            self.db.execute(
                &format!(
                    "INSERT OR IGNORE INTO loginsM (
                         {common_cols}, is_overridden, server_modified
                     )
                     SELECT {common_cols}, 0, {modified_ms_i64}
                     FROM loginsL
                     WHERE is_deleted = 0 AND guid IN ({vars})",
                    common_cols = schema::COMMON_COLS,
                    modified_ms_i64 = ts.as_millis() as i64,
                    vars = sql_support::repeat_sql_vars(chunk.len())
                ),
                chunk,
            )?;
            scope.err_if_interrupted()?;

            self.db.execute(
                &format!(
                    "DELETE FROM loginsL WHERE guid IN ({vars})",
                    vars = sql_support::repeat_sql_vars(chunk.len())
                ),
                chunk,
            )?;
            scope.err_if_interrupted()?;
            Ok(())
        })?;
        self.set_last_sync(ts)?;
        tx.commit()?;
        Ok(())
    }

    // Fetch all the data for the provided IDs.
    // TODO: Might be better taking a fn instead of returning all of it... But that func will likely
    // want to insert stuff while we're doing this so ugh.
    fn fetch_login_data(
        &self,
        records: &[(sync15::Payload, ServerTimestamp)],
        telem: &mut telemetry::EngineIncoming,
        scope: &SqlInterruptScope,
    ) -> Result<Vec<SyncLoginData>> {
        let mut sync_data = Vec::with_capacity(records.len());
        {
            let mut seen_ids: HashSet<Guid> = HashSet::with_capacity(records.len());
            for incoming in records.iter() {
                if seen_ids.contains(&incoming.0.id) {
                    throw!(ErrorKind::DuplicateGuid(incoming.0.id.to_string()))
                }
                seen_ids.insert(incoming.0.id.clone());
                match SyncLoginData::from_payload(incoming.0.clone(), incoming.1) {
                    Ok(v) => sync_data.push(v),
                    Err(e) => {
                        log::error!("Failed to deserialize record {:?}: {}", incoming.0.id, e);
                        // Ideally we'd track new_failed, but it's unclear how
                        // much value it has.
                        telem.failed(1);
                    }
                }
            }
        }
        scope.err_if_interrupted()?;

        sql_support::each_chunk_mapped(
            &records,
            |r| r.0.id.as_str(),
            |chunk, offset| -> Result<()> {
                // pairs the bound parameter for the guid with an integer index.
                let values_with_idx = sql_support::repeat_display(chunk.len(), ",", |i, f| {
                    write!(f, "({},?)", i + offset)
                });
                let query = format!(
                    "WITH to_fetch(guid_idx, fetch_guid) AS (VALUES {vals})
                     SELECT
                         {common_cols},
                         is_overridden,
                         server_modified,
                         NULL as local_modified,
                         NULL as is_deleted,
                         NULL as sync_status,
                         1 as is_mirror,
                         to_fetch.guid_idx as guid_idx
                     FROM loginsM
                     JOIN to_fetch
                         ON loginsM.guid = to_fetch.fetch_guid

                     UNION ALL

                     SELECT
                         {common_cols},
                         NULL as is_overridden,
                         NULL as server_modified,
                         local_modified,
                         is_deleted,
                         sync_status,
                         0 as is_mirror,
                         to_fetch.guid_idx as guid_idx
                     FROM loginsL
                     JOIN to_fetch
                         ON loginsL.guid = to_fetch.fetch_guid",
                    // give each VALUES item 2 entries, an index and the parameter.
                    vals = values_with_idx,
                    common_cols = schema::COMMON_COLS,
                );

                let mut stmt = self.db.prepare(&query)?;

                let rows = stmt.query_and_then(chunk, |row| {
                    let guid_idx_i = row.get::<_, i64>("guid_idx")?;
                    // Hitting this means our math is wrong...
                    assert!(guid_idx_i >= 0);

                    let guid_idx = guid_idx_i as usize;
                    let is_mirror: bool = row.get("is_mirror")?;
                    if is_mirror {
                        sync_data[guid_idx].set_mirror(MirrorLogin::from_row(row)?)?;
                    } else {
                        sync_data[guid_idx].set_local(LocalLogin::from_row(row)?)?;
                    }
                    scope.err_if_interrupted()?;
                    Ok(())
                })?;
                // `rows` is an Iterator<Item = Result<()>>, so we need to collect to handle the errors.
                rows.collect::<Result<_>>()?;
                Ok(())
            },
        )?;
        Ok(sync_data)
    }

    // It would be nice if this were a batch-ish api (e.g. takes a slice of records and finds dupes
    // for each one if they exist)... I can't think of how to write that query, though.
    fn find_dupe(&self, l: &Login) -> Result<Option<Login>> {
        let form_submit_host_port = l
            .form_submit_url
            .as_ref()
            .and_then(|s| util::url_host_port(&s));
        let args = named_params! {
            ":hostname": l.hostname,
            ":http_realm": l.http_realm,
            ":username": l.username,
            ":form_submit": form_submit_host_port,
        };
        let mut query = format!(
            "SELECT {common}
             FROM loginsL
             WHERE hostname IS :hostname
               AND httpRealm IS :http_realm
               AND username IS :username",
            common = schema::COMMON_COLS,
        );
        if form_submit_host_port.is_some() {
            // Stolen from iOS
            query += " AND (formSubmitURL = '' OR (instr(formSubmitURL, :form_submit) > 0))";
        } else {
            query += " AND formSubmitURL IS :form_submit"
        }
        Ok(self.try_query_row(&query, args, |row| Login::from_row(row), false)?)
    }

    pub fn get_all(&self) -> Result<Vec<Login>> {
        let mut stmt = self.db.prepare_cached(&GET_ALL_SQL)?;
        let rows = stmt.query_and_then(NO_PARAMS, Login::from_row)?;
        rows.collect::<Result<_>>()
    }

    pub fn get_by_base_domain(&self, base_domain: &str) -> Result<Vec<Login>> {
        // We first parse the input string as a host so it is normalized.
        let base_host = match Host::parse(base_domain) {
            Ok(d) => d,
            Err(e) => {
                // don't log the input string as it's PII.
                log::warn!("get_by_base_domain was passed an invalid domain: {}", e);
                return Ok(vec![]);
            }
        };
        // We just do a linear scan. Another option is to have an indexed
        // reverse-host column or similar, but current thinking is that it's
        // extra complexity for (probably) zero actual benefit given the record
        // counts are expected to be so low.
        // A regex would probably make this simpler, but we don't want to drag
        // in a regex lib just for this.
        let mut stmt = self.db.prepare_cached(&GET_ALL_SQL)?;
        let rows = stmt
            .query_and_then(NO_PARAMS, Login::from_row)?
            .filter(|r| {
                let login = r
                    .as_ref()
                    .ok()
                    .and_then(|login| Url::parse(&login.hostname).ok());
                let this_host = login.as_ref().and_then(|url| url.host());
                match (&base_host, this_host) {
                    (Host::Domain(base), Some(Host::Domain(look))) => {
                        // a fairly long-winded way of saying
                        // `login.hostname == base_domain ||
                        //  login.hostname.ends_with('.' + base_domain);`
                        let mut rev_input = base.chars().rev();
                        let mut rev_host = look.chars().rev();
                        loop {
                            match (rev_input.next(), rev_host.next()) {
                                (Some(ref a), Some(ref b)) if a == b => continue,
                                (None, None) => return true, // exactly equal
                                (None, Some(ref h)) => return *h == '.',
                                _ => return false,
                            }
                        }
                    }
                    // ip addresses must match exactly.
                    (Host::Ipv4(base), Some(Host::Ipv4(look))) => *base == look,
                    (Host::Ipv6(base), Some(Host::Ipv6(look))) => *base == look,
                    // all "mismatches" in domain types are false.
                    _ => false,
                }
            });
        rows.collect::<Result<_>>()
    }

    pub fn get_by_id(&self, id: &str) -> Result<Option<Login>> {
        self.try_query_row(
            &GET_BY_GUID_SQL,
            &[(":guid", &id as &dyn ToSql)],
            Login::from_row,
            true,
        )
    }

    pub fn touch(&self, id: &str) -> Result<()> {
        let tx = self.unchecked_transaction()?;
        self.ensure_local_overlay_exists(id)?;
        self.mark_mirror_overridden(id)?;
        let now_ms = util::system_time_ms_i64(SystemTime::now());
        // As on iOS, just using a record doesn't flip it's status to changed.
        // TODO: this might be wrong for lockbox!
        self.execute_named_cached(
            "UPDATE loginsL
             SET timeLastUsed = :now_millis,
                 timesUsed = timesUsed + 1,
                 local_modified = :now_millis
             WHERE guid = :guid
                 AND is_deleted = 0",
            named_params! {
                ":now_millis": now_ms,
                ":guid": id,
            },
        )?;
        tx.commit()?;
        Ok(())
    }

    pub fn add(&self, login: Login) -> Result<Login> {
        let mut login = self.fixup_and_check_for_dupes(login)?;

        let tx = self.unchecked_transaction()?;
        let now_ms = util::system_time_ms_i64(SystemTime::now());

        // Allow an empty GUID to be passed to indicate that we should generate
        // one. (Note that the FFI, does not require that the `id` field be
        // present in the JSON, and replaces it with an empty string if missing).
        if login.guid.is_empty() {
            login.guid = Guid::random()
        }

        // Fill in default metadata.
        if login.time_created == 0 {
            login.time_created = now_ms;
        }
        if login.time_password_changed == 0 {
            login.time_password_changed = now_ms;
        }
        if login.time_last_used == 0 {
            login.time_last_used = now_ms;
        }
        if login.times_used == 0 {
            login.times_used = 1;
        }

        let sql = format!(
            "INSERT OR IGNORE INTO loginsL (
                hostname,
                httpRealm,
                formSubmitURL,
                usernameField,
                passwordField,
                timesUsed,
                username,
                password,
                guid,
                timeCreated,
                timeLastUsed,
                timePasswordChanged,
                local_modified,
                is_deleted,
                sync_status
            ) VALUES (
                :hostname,
                :http_realm,
                :form_submit_url,
                :username_field,
                :password_field,
                :times_used,
                :username,
                :password,
                :guid,
                :time_created,
                :time_last_used,
                :time_password_changed,
                :local_modified,
                0, -- is_deleted
                {new} -- sync_status
            )",
            new = SyncStatus::New as u8
        );

        let rows_changed = self.execute_named(
            &sql,
            named_params! {
                ":hostname": login.hostname,
                ":http_realm": login.http_realm,
                ":form_submit_url": login.form_submit_url,
                ":username_field": login.username_field,
                ":password_field": login.password_field,
                ":username": login.username,
                ":password": login.password,
                ":guid": login.guid,
                ":time_created": login.time_created,
                ":times_used": login.times_used,
                ":time_last_used": login.time_last_used,
                ":time_password_changed": login.time_password_changed,
                ":local_modified": now_ms,
            },
        )?;
        if rows_changed == 0 {
            log::error!(
                "Record {:?} already exists (use `update` to update records, not add)",
                login.guid
            );
            throw!(ErrorKind::DuplicateGuid(login.guid.into_string()));
        }
        tx.commit()?;
        Ok(login)
    }

    pub fn import_multiple(&self, logins: &[Login]) -> Result<MigrationMetrics> {
        // Check if the logins table is empty first.
        let mut num_existing_logins =
            self.query_row::<i64, _, _>("SELECT COUNT(*) FROM loginsL", NO_PARAMS, |r| r.get(0))?;
        num_existing_logins +=
            self.query_row::<i64, _, _>("SELECT COUNT(*) FROM loginsM", NO_PARAMS, |r| r.get(0))?;
        if num_existing_logins > 0 {
            return Err(ErrorKind::NonEmptyTable.into());
        }
        let tx = self.unchecked_transaction()?;
        let now_ms = util::system_time_ms_i64(SystemTime::now());
        let import_start = Instant::now();
        let sql = format!(
            "INSERT OR IGNORE INTO loginsL (
                hostname,
                httpRealm,
                formSubmitURL,
                usernameField,
                passwordField,
                timesUsed,
                username,
                password,
                guid,
                timeCreated,
                timeLastUsed,
                timePasswordChanged,
                local_modified,
                is_deleted,
                sync_status
            ) VALUES (
                :hostname,
                :http_realm,
                :form_submit_url,
                :username_field,
                :password_field,
                :times_used,
                :username,
                :password,
                :guid,
                :time_created,
                :time_last_used,
                :time_password_changed,
                :local_modified,
                0, -- is_deleted
                {new} -- sync_status
            )",
            new = SyncStatus::New as u8
        );
        let import_start_total_logins: u64 = logins.len() as u64;
        let mut num_failed_fixup: u64 = 0;
        let mut num_failed_insert: u64 = 0;
        let mut fixup_phase_duration = Duration::new(0, 0);
        let mut fixup_errors: Vec<String> = Vec::new();
        let mut insert_errors: Vec<String> = Vec::new();

        for login in logins {
            // This is a little bit of hoop-jumping to avoid cloning each borrowed item
            // in order to *possibly* created a fixed-up version.
            let mut login = login;
            let maybe_fixed_login = login.maybe_fixup().and_then(|fixed| {
                match &fixed {
                    None => self.check_for_dupes(login)?,
                    Some(l) => self.check_for_dupes(&l)?,
                };
                Ok(fixed)
            });
            match &maybe_fixed_login {
                Ok(None) => {} // The provided login was fine all along
                Ok(Some(l)) => {
                    // We made a new, fixed-up Login.
                    login = l;
                }
                Err(e) => {
                    log::warn!("Skipping login {} as it is invalid ({}).", login.guid, e);
                    fixup_errors.push(e.label().into());
                    num_failed_fixup += 1;
                    continue;
                }
            };
            // Now we can safely insert it, knowing that it's valid data.
            let old_guid = &login.guid; // Keep the old GUID around so we can debug errors easily.
            let guid = if old_guid.is_valid_for_sync_server() {
                old_guid.clone()
            } else {
                Guid::random()
            };
            fixup_phase_duration = import_start.elapsed();
            match self.execute_named_cached(
                &sql,
                named_params! {
                    ":hostname": login.hostname,
                    ":http_realm": login.http_realm,
                    ":form_submit_url": login.form_submit_url,
                    ":username_field": login.username_field,
                    ":password_field": login.password_field,
                    ":username": login.username,
                    ":password": login.password,
                    ":guid": guid,
                    ":time_created": login.time_created,
                    ":times_used": login.times_used,
                    ":time_last_used": login.time_last_used,
                    ":time_password_changed": login.time_password_changed,
                    ":local_modified": now_ms,
                },
            ) {
                Ok(_) => log::info!("Imported {} (new GUID {}) successfully.", old_guid, guid),
                Err(e) => {
                    log::warn!("Could not import {} ({}).", old_guid, e);
                    insert_errors.push(Error::from(e).label().into());
                    num_failed_insert += 1;
                }
            };
        }
        tx.commit()?;

        let num_post_fixup = import_start_total_logins - num_failed_fixup;
        let num_failed = num_failed_fixup + num_failed_insert;
        let insert_phase_duration = import_start
            .elapsed()
            .checked_sub(fixup_phase_duration)
            .unwrap_or_else(|| Duration::new(0, 0));
        let mut all_errors = Vec::new();
        all_errors.extend(fixup_errors.clone());
        all_errors.extend(insert_errors.clone());

        let metrics = MigrationMetrics {
            fixup_phase: MigrationPhaseMetrics {
                num_processed: import_start_total_logins,
                num_succeeded: num_post_fixup,
                num_failed: num_failed_fixup,
                total_duration: fixup_phase_duration.as_millis(),
                errors: fixup_errors,
            },
            insert_phase: MigrationPhaseMetrics {
                num_processed: num_post_fixup,
                num_succeeded: num_post_fixup - num_failed_insert,
                num_failed: num_failed_insert,
                total_duration: insert_phase_duration.as_millis(),
                errors: insert_errors,
            },
            num_processed: import_start_total_logins,
            num_succeeded: import_start_total_logins - num_failed,
            num_failed,
            total_duration: fixup_phase_duration
                .checked_add(insert_phase_duration)
                .unwrap_or_else(|| Duration::new(0, 0))
                .as_millis(),
            errors: all_errors,
        };
        log::info!(
            "Finished importing logins with the following metrics: {:#?}",
            metrics
        );
        Ok(metrics)
    }

    pub fn update(&self, login: Login) -> Result<()> {
        let login = self.fixup_and_check_for_dupes(login)?;

        let tx = self.unchecked_transaction()?;
        // Note: These fail with DuplicateGuid if the record doesn't exist.
        self.ensure_local_overlay_exists(login.guid_str())?;
        self.mark_mirror_overridden(login.guid_str())?;

        let now_ms = util::system_time_ms_i64(SystemTime::now());

        let sql = format!(
            "UPDATE loginsL
             SET local_modified      = :now_millis,
                 timeLastUsed        = :now_millis,
                 -- Only update timePasswordChanged if, well, the password changed.
                 timePasswordChanged = (CASE
                     WHEN password = :password
                     THEN timePasswordChanged
                     ELSE :now_millis
                 END),
                 httpRealm           = :http_realm,
                 formSubmitURL       = :form_submit_url,
                 usernameField       = :username_field,
                 passwordField       = :password_field,
                 timesUsed           = timesUsed + 1,
                 username            = :username,
                 password            = :password,
                 hostname            = :hostname,
                 -- leave New records as they are, otherwise update them to `changed`
                 sync_status         = max(sync_status, {changed})
             WHERE guid = :guid",
            changed = SyncStatus::Changed as u8
        );

        self.db.execute_named(
            &sql,
            named_params! {
                ":hostname": login.hostname,
                ":username": login.username,
                ":password": login.password,
                ":http_realm": login.http_realm,
                ":form_submit_url": login.form_submit_url,
                ":username_field": login.username_field,
                ":password_field": login.password_field,
                ":guid": login.guid,
                ":now_millis": now_ms,
            },
        )?;
        tx.commit()?;
        Ok(())
    }

    pub fn check_valid_with_no_dupes(&self, login: &Login) -> Result<()> {
        login.check_valid()?;
        self.check_for_dupes(login)
    }

    pub fn fixup_and_check_for_dupes(&self, login: Login) -> Result<Login> {
        let login = login.fixup()?;
        self.check_for_dupes(&login)?;
        Ok(login)
    }

    pub fn check_for_dupes(&self, login: &Login) -> Result<()> {
        if self.dupe_exists(&login)? {
            throw!(InvalidLogin::DuplicateLogin);
        }
        Ok(())
    }

    pub fn dupe_exists(&self, login: &Login) -> Result<bool> {
        // Note: the query below compares the guids of the given login with existing logins
        //  to prevent a login from being considered a duplicate of itself (e.g. during updates).
        Ok(self.db.query_row_named(
            "SELECT EXISTS(
                SELECT 1 FROM loginsL
                WHERE is_deleted = 0
                    AND guid <> :guid
                    AND hostname = :hostname
                    AND NULLIF(username, '') = :username
                    AND (
                        formSubmitURL = :form_submit
                        OR
                        httpRealm = :http_realm
                    )

                UNION ALL

                SELECT 1 FROM loginsM
                WHERE is_overridden = 0
                    AND guid <> :guid
                    AND hostname = :hostname
                    AND NULLIF(username, '') = :username
                    AND (
                        formSubmitURL = :form_submit
                        OR
                        httpRealm = :http_realm
                    )
             )",
            named_params! {
                ":guid": &login.guid,
                ":hostname": &login.hostname,
                ":username": &login.username,
                ":http_realm": login.http_realm.as_ref(),
                ":form_submit": login.form_submit_url.as_ref(),
            },
            |row| row.get(0),
        )?)
    }

    pub fn exists(&self, id: &str) -> Result<bool> {
        Ok(self.db.query_row_named(
            "SELECT EXISTS(
                 SELECT 1 FROM loginsL
                 WHERE guid = :guid AND is_deleted = 0
                 UNION ALL
                 SELECT 1 FROM loginsM
                 WHERE guid = :guid AND is_overridden IS NOT 1
             )",
            named_params! { ":guid": id },
            |row| row.get(0),
        )?)
    }

    /// Delete the record with the provided id. Returns true if the record
    /// existed already.
    pub fn delete(&self, id: &str) -> Result<bool> {
        let tx = self.unchecked_transaction_imm()?;
        let exists = self.exists(id)?;
        let now_ms = util::system_time_ms_i64(SystemTime::now());

        // For IDs that have, mark is_deleted and clear sensitive fields
        self.execute_named(
            &format!(
                "UPDATE loginsL
                 SET local_modified = :now_ms,
                     sync_status = {status_changed},
                     is_deleted = 1,
                     password = '',
                     hostname = '',
                     username = ''
                 WHERE guid = :guid",
                status_changed = SyncStatus::Changed as u8
            ),
            named_params! { ":now_ms": now_ms, ":guid": id },
        )?;

        // Mark the mirror as overridden
        self.execute_named(
            "UPDATE loginsM SET is_overridden = 1 WHERE guid = :guid",
            named_params! { ":guid": id },
        )?;

        // If we don't have a local record for this ID, but do have it in the mirror
        // insert a tombstone.
        self.execute_named(&format!("
            INSERT OR IGNORE INTO loginsL
                    (guid, local_modified, is_deleted, sync_status, hostname, timeCreated, timePasswordChanged, password, username)
            SELECT   guid, :now_ms,        1,          {changed},   '',       timeCreated, :now_ms,                   '',       ''
            FROM loginsM
            WHERE guid = :guid",
            changed = SyncStatus::Changed as u8),
            named_params! { ":now_ms": now_ms, ":guid": id })?;
        tx.commit()?;
        Ok(exists)
    }

    fn mark_mirror_overridden(&self, guid: &str) -> Result<()> {
        self.execute_named_cached(
            "UPDATE loginsM SET is_overridden = 1 WHERE guid = :guid",
            named_params! { ":guid": guid },
        )?;
        Ok(())
    }

    fn ensure_local_overlay_exists(&self, guid: &str) -> Result<()> {
        let already_have_local: bool = self.db.query_row_named(
            "SELECT EXISTS(SELECT 1 FROM loginsL WHERE guid = :guid)",
            named_params! { ":guid": guid },
            |row| row.get(0),
        )?;

        if already_have_local {
            return Ok(());
        }

        log::debug!("No overlay; cloning one for {:?}.", guid);
        let changed = self.clone_mirror_to_overlay(guid)?;
        if changed == 0 {
            log::error!("Failed to create local overlay for GUID {:?}.", guid);
            throw!(ErrorKind::NoSuchRecord(guid.to_owned()));
        }
        Ok(())
    }

    fn clone_mirror_to_overlay(&self, guid: &str) -> Result<usize> {
        Ok(self
            .execute_named_cached(&*CLONE_SINGLE_MIRROR_SQL, &[(":guid", &guid as &dyn ToSql)])?)
    }

    pub fn reset(&self, assoc: &StoreSyncAssociation) -> Result<()> {
        log::info!("Executing reset on password store!");
        let tx = self.db.unchecked_transaction()?;
        self.execute_all(&[
            &*CLONE_ENTIRE_MIRROR_SQL,
            "DELETE FROM loginsM",
            &format!("UPDATE loginsL SET sync_status = {}", SyncStatus::New as u8),
        ])?;
        self.set_last_sync(ServerTimestamp(0))?;
        match assoc {
            StoreSyncAssociation::Disconnected => {
                self.delete_meta(schema::GLOBAL_SYNCID_META_KEY)?;
                self.delete_meta(schema::COLLECTION_SYNCID_META_KEY)?;
            }
            StoreSyncAssociation::Connected(ids) => {
                self.put_meta(schema::GLOBAL_SYNCID_META_KEY, &ids.global)?;
                self.put_meta(schema::COLLECTION_SYNCID_META_KEY, &ids.coll)?;
            }
        };
        self.delete_meta(schema::GLOBAL_STATE_META_KEY)?;
        tx.commit()?;
        Ok(())
    }

    pub fn wipe(&self, scope: &SqlInterruptScope) -> Result<()> {
        let tx = self.unchecked_transaction()?;
        log::info!("Executing wipe on password store!");
        let now_ms = util::system_time_ms_i64(SystemTime::now());
        scope.err_if_interrupted()?;
        self.execute_named(
            &format!(
                "
                UPDATE loginsL
                SET local_modified = :now_ms,
                    sync_status = {changed},
                    is_deleted = 1,
                    password = '',
                    hostname = '',
                    username = ''
                WHERE is_deleted = 0",
                changed = SyncStatus::Changed as u8
            ),
            named_params! { ":now_ms": now_ms },
        )?;
        scope.err_if_interrupted()?;

        self.execute("UPDATE loginsM SET is_overridden = 1", NO_PARAMS)?;
        scope.err_if_interrupted()?;

        self.execute_named(
            &format!("
                INSERT OR IGNORE INTO loginsL
                      (guid, local_modified, is_deleted, sync_status, hostname, timeCreated, timePasswordChanged, password, username)
                SELECT guid, :now_ms,        1,          {changed},   '',       timeCreated, :now_ms,             '',       ''
                FROM loginsM",
                changed = SyncStatus::Changed as u8),
            named_params! { ":now_ms": now_ms })?;
        scope.err_if_interrupted()?;
        tx.commit()?;
        Ok(())
    }

    pub fn wipe_local(&self) -> Result<()> {
        log::info!("Executing wipe_local on password store!");
        let tx = self.unchecked_transaction()?;
        self.execute_all(&[
            "DELETE FROM loginsL",
            "DELETE FROM loginsM",
            "DELETE FROM loginsSyncMeta",
        ])?;
        tx.commit()?;
        Ok(())
    }

    fn reconcile(
        &self,
        records: Vec<SyncLoginData>,
        server_now: ServerTimestamp,
        telem: &mut telemetry::EngineIncoming,
        scope: &SqlInterruptScope,
    ) -> Result<UpdatePlan> {
        let mut plan = UpdatePlan::default();

        for mut record in records {
            scope.err_if_interrupted()?;
            log::debug!("Processing remote change {}", record.guid());
            let upstream = if let Some(inbound) = record.inbound.0.take() {
                inbound
            } else {
                log::debug!("Processing inbound deletion (always prefer)");
                plan.plan_delete(record.guid.clone());
                continue;
            };
            let upstream_time = record.inbound.1;
            match (record.mirror.take(), record.local.take()) {
                (Some(mirror), Some(local)) => {
                    log::debug!("  Conflict between remote and local, Resolving with 3WM");
                    plan.plan_three_way_merge(local, mirror, upstream, upstream_time, server_now);
                    telem.reconciled(1);
                }
                (Some(_mirror), None) => {
                    log::debug!("  Forwarding mirror to remote");
                    plan.plan_mirror_update(upstream, upstream_time);
                    telem.applied(1);
                }
                (None, Some(local)) => {
                    log::debug!("  Conflicting record without shared parent, using newer");
                    plan.plan_two_way_merge(&local.login, (upstream, upstream_time));
                    telem.reconciled(1);
                }
                (None, None) => {
                    if let Some(dupe) = self.find_dupe(&upstream)? {
                        log::debug!(
                            "  Incoming record {} was is a dupe of local record {}",
                            upstream.guid,
                            dupe.guid
                        );
                        plan.plan_two_way_merge(&dupe, (upstream, upstream_time));
                    } else {
                        log::debug!("  No dupe found, inserting into mirror");
                        plan.plan_mirror_insert(upstream, upstream_time, false);
                    }
                    telem.applied(1);
                }
            }
        }
        Ok(plan)
    }

    fn execute_plan(&self, plan: UpdatePlan, scope: &SqlInterruptScope) -> Result<()> {
        // Because rusqlite want a mutable reference to create a transaction
        // (as a way to save us from ourselves), we side-step that by creating
        // it manually.
        let tx = self.db.unchecked_transaction()?;
        plan.execute(&tx, scope)?;
        tx.commit()?;
        Ok(())
    }

    pub fn fetch_outgoing(
        &self,
        st: ServerTimestamp,
        scope: &SqlInterruptScope,
    ) -> Result<OutgoingChangeset> {
        // Taken from iOS. Arbitrarily large, so that clients that want to
        // process deletions first can; for us it doesn't matter.
        const TOMBSTONE_SORTINDEX: i32 = 5_000_000;
        const DEFAULT_SORTINDEX: i32 = 1;
        let mut outgoing = OutgoingChangeset::new("passwords", st);
        let mut stmt = self.db.prepare_cached(&format!(
            "SELECT * FROM loginsL WHERE sync_status IS NOT {synced}",
            synced = SyncStatus::Synced as u8
        ))?;
        let rows = stmt.query_and_then(NO_PARAMS, |row| {
            scope.err_if_interrupted()?;
            Ok(if row.get::<_, bool>("is_deleted")? {
                Payload::new_tombstone(row.get::<_, String>("guid")?)
                    .with_sortindex(TOMBSTONE_SORTINDEX)
            } else {
                let login = Login::from_row(row)?;
                Payload::from_record(login)?.with_sortindex(DEFAULT_SORTINDEX)
            })
        })?;
        outgoing.changes = rows.collect::<Result<_>>()?;

        Ok(outgoing)
    }

    fn do_apply_incoming(
        &self,
        inbound: IncomingChangeset,
        telem: &mut telemetry::Engine,
        scope: &SqlInterruptScope,
    ) -> Result<OutgoingChangeset> {
        let mut incoming_telemetry = telemetry::EngineIncoming::new();
        let data = self.fetch_login_data(&inbound.changes, &mut incoming_telemetry, scope)?;
        let plan = {
            let result = self.reconcile(data, inbound.timestamp, &mut incoming_telemetry, scope);
            telem.incoming(incoming_telemetry);
            result
        }?;
        self.execute_plan(plan, scope)?;
        Ok(self.fetch_outgoing(inbound.timestamp, scope)?)
    }

    fn put_meta(&self, key: &str, value: &dyn ToSql) -> Result<()> {
        self.execute_named_cached(
            "REPLACE INTO loginsSyncMeta (key, value) VALUES (:key, :value)",
            named_params! { ":key": key, ":value": value },
        )?;
        Ok(())
    }

    fn get_meta<T: FromSql>(&self, key: &str) -> Result<Option<T>> {
        Ok(self.try_query_row(
            "SELECT value FROM loginsSyncMeta WHERE key = :key",
            named_params! { ":key": key },
            |row| Ok::<_, Error>(row.get(0)?),
            true,
        )?)
    }

    fn delete_meta(&self, key: &str) -> Result<()> {
        self.execute_named_cached(
            "DELETE FROM loginsSyncMeta WHERE key = :key",
            named_params! { ":key": key },
        )?;
        Ok(())
    }

    fn set_last_sync(&self, last_sync: ServerTimestamp) -> Result<()> {
        log::debug!("Updating last sync to {}", last_sync);
        let last_sync_millis = last_sync.as_millis() as i64;
        self.put_meta(schema::LAST_SYNC_META_KEY, &last_sync_millis)
    }

    fn get_last_sync(&self) -> Result<Option<ServerTimestamp>> {
        let millis = self.get_meta::<i64>(schema::LAST_SYNC_META_KEY)?.unwrap();
        Ok(Some(ServerTimestamp(millis)))
    }

    pub fn set_global_state(&self, state: &Option<String>) -> Result<()> {
        let to_write = match state {
            Some(ref s) => s,
            None => "",
        };
        self.put_meta(schema::GLOBAL_STATE_META_KEY, &to_write)
    }

    pub fn get_global_state(&self) -> Result<Option<String>> {
        self.get_meta::<String>(schema::GLOBAL_STATE_META_KEY)
    }

    /// A utility we can kill by the end of 2019 ;)
    pub fn migrate_global_state(&self) -> Result<()> {
        let tx = self.unchecked_transaction_imm()?;
        if let Some(old_state) = self.get_meta("global_state")? {
            log::info!("there's old global state - migrating");
            let (new_sync_ids, new_global_state) = extract_v1_state(old_state, "passwords");
            if let Some(sync_ids) = new_sync_ids {
                self.put_meta(schema::GLOBAL_SYNCID_META_KEY, &sync_ids.global)?;
                self.put_meta(schema::COLLECTION_SYNCID_META_KEY, &sync_ids.coll)?;
                log::info!("migrated the sync IDs");
            }
            if let Some(new_global_state) = new_global_state {
                self.set_global_state(&Some(new_global_state))?;
                log::info!("migrated the global state");
            }
            self.delete_meta("global_state")?;
        }
        tx.commit()?;
        Ok(())
    }
}

pub struct LoginStore<'a> {
    pub db: &'a LoginDb,
    pub scope: sql_support::SqlInterruptScope,
}

impl<'a> LoginStore<'a> {
    pub fn new(db: &'a LoginDb) -> Self {
        Self {
            db,
            scope: db.begin_interrupt_scope(),
        }
    }
}

impl<'a> Store for LoginStore<'a> {
    fn collection_name(&self) -> std::borrow::Cow<'static, str> {
        "passwords".into()
    }

    fn apply_incoming(
        &self,
        inbound: Vec<IncomingChangeset>,
        telem: &mut telemetry::Engine,
    ) -> result::Result<OutgoingChangeset, failure::Error> {
        assert_eq!(inbound.len(), 1, "logins only requests one item");
        let inbound = inbound.into_iter().next().unwrap();
        Ok(self.db.do_apply_incoming(inbound, telem, &self.scope)?)
    }

    fn sync_finished(
        &self,
        new_timestamp: ServerTimestamp,
        records_synced: Vec<Guid>,
    ) -> result::Result<(), failure::Error> {
        self.db.mark_as_synchronized(
            &records_synced.iter().map(Guid::as_str).collect::<Vec<_>>(),
            new_timestamp,
            &self.scope,
        )?;
        Ok(())
    }

    fn get_collection_requests(
        &self,
        server_timestamp: ServerTimestamp,
    ) -> result::Result<Vec<CollectionRequest>, failure::Error> {
        let since = self.db.get_last_sync()?.unwrap_or_default();
        Ok(if since == server_timestamp {
            vec![]
        } else {
            vec![CollectionRequest::new("passwords").full().newer_than(since)]
        })
    }

    fn get_sync_assoc(&self) -> result::Result<StoreSyncAssociation, failure::Error> {
        let global = self.db.get_meta(schema::GLOBAL_SYNCID_META_KEY)?;
        let coll = self.db.get_meta(schema::COLLECTION_SYNCID_META_KEY)?;
        Ok(if let (Some(global), Some(coll)) = (global, coll) {
            StoreSyncAssociation::Connected(CollSyncIds { global, coll })
        } else {
            StoreSyncAssociation::Disconnected
        })
    }

    fn reset(&self, assoc: &StoreSyncAssociation) -> result::Result<(), failure::Error> {
        self.db.reset(assoc)?;
        Ok(())
    }

    fn wipe(&self) -> result::Result<(), failure::Error> {
        self.db.wipe(&self.scope)?;
        Ok(())
    }
}

lazy_static! {
    static ref GET_ALL_SQL: String = format!(
        "SELECT {common_cols} FROM loginsL WHERE is_deleted = 0
         UNION ALL
         SELECT {common_cols} FROM loginsM WHERE is_overridden = 0",
        common_cols = schema::COMMON_COLS,
    );
    static ref GET_BY_GUID_SQL: String = format!(
        "SELECT {common_cols}
         FROM loginsL
         WHERE is_deleted = 0
           AND guid = :guid

         UNION ALL

         SELECT {common_cols}
         FROM loginsM
         WHERE is_overridden IS NOT 1
           AND guid = :guid
         ORDER BY hostname ASC

         LIMIT 1",
        common_cols = schema::COMMON_COLS,
    );
    static ref CLONE_ENTIRE_MIRROR_SQL: String = format!(
        "INSERT OR IGNORE INTO loginsL ({common_cols}, local_modified, is_deleted, sync_status)
         SELECT {common_cols}, NULL AS local_modified, 0 AS is_deleted, 0 AS sync_status
         FROM loginsM",
        common_cols = schema::COMMON_COLS,
    );
    static ref CLONE_SINGLE_MIRROR_SQL: String =
        format!("{} WHERE guid = :guid", &*CLONE_ENTIRE_MIRROR_SQL,);
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_bad_record() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        let scope = db.begin_interrupt_scope();
        let mut telem = sync15::telemetry::EngineIncoming::new();
        let res = db
            .fetch_login_data(
                &[
                    // tombstone
                    (
                        sync15::Payload::new_tombstone("dummy_000001"),
                        sync15::ServerTimestamp(10000),
                    ),
                    // invalid
                    (
                        sync15::Payload::from_json(serde_json::json!({
                            "id": "dummy_000002",
                            "garbage": "data",
                            "etc": "not a login"
                        }))
                        .unwrap(),
                        sync15::ServerTimestamp(10000),
                    ),
                    // valid
                    (
                        sync15::Payload::from_json(serde_json::json!({
                            "id": "dummy_000003",
                            "formSubmitURL": "https://www.example.com/submit",
                            "hostname": "https://www.example.com",
                            "username": "test",
                            "password": "test",
                        }))
                        .unwrap(),
                        sync15::ServerTimestamp(10000),
                    ),
                ],
                &mut telem,
                &scope,
            )
            .unwrap();
        assert_eq!(telem.get_failed(), 1);
        assert_eq!(res.len(), 2);
        assert_eq!(res[0].guid, "dummy_000001");
        assert_eq!(res[1].guid, "dummy_000003");
    }

    #[test]
    fn test_check_valid_with_no_dupes() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        db.add(Login {
            guid: "dummy_000001".into(),
            form_submit_url: Some("https://www.example.com".into()),
            hostname: "https://www.example.com".into(),
            http_realm: None,
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        })
        .unwrap();

        let unique_login = Login {
            guid: Guid::empty(),
            form_submit_url: None,
            hostname: "https://www.example.com".into(),
            http_realm: Some("https://www.example.com".into()),
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };

        let duplicate_login = Login {
            guid: Guid::empty(),
            form_submit_url: Some("https://www.example.com".into()),
            hostname: "https://www.example.com".into(),
            http_realm: None,
            username: "test".into(),
            password: "test2".into(),
            ..Login::default()
        };

        struct TestCase {
            login: Login,
            should_err: bool,
            expected_err: &'static str,
        }

        let test_cases = [
            TestCase {
                login: unique_login,
                should_err: false,
                expected_err: "",
            },
            TestCase {
                login: duplicate_login,
                should_err: true,
                expected_err: "Invalid login: Login already exists",
            },
        ];

        for tc in &test_cases {
            let login_check = db.check_valid_with_no_dupes(&tc.login);
            if tc.should_err {
                assert!(&login_check.is_err());
                assert_eq!(&login_check.unwrap_err().to_string(), tc.expected_err)
            } else {
                assert!(&login_check.is_ok())
            }
        }
    }

    #[test]
    fn test_unicode_submit() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        db.add(Login {
            guid: "dummy_000001".into(),
            form_submit_url: Some("http://😍.com".into()),
            hostname: "http://😍.com".into(),
            http_realm: None,
            username: "😍".into(),
            username_field: "😍".into(),
            password: "😍".into(),
            password_field: "😍".into(),
            ..Login::default()
        })
        .unwrap();
        let fetched = db
            .get_by_id("dummy_000001")
            .expect("should work")
            .expect("should get a record");
        assert_eq!(fetched.hostname, "http://xn--r28h.com");
        assert_eq!(fetched.form_submit_url.unwrap(), "http://xn--r28h.com");
        assert_eq!(fetched.username, "😍");
        assert_eq!(fetched.username_field, "😍");
        assert_eq!(fetched.password, "😍");
        assert_eq!(fetched.password_field, "😍");
    }

    #[test]
    fn test_unicode_realm() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        db.add(Login {
            guid: "dummy_000001".into(),
            form_submit_url: None,
            hostname: "http://😍.com".into(),
            http_realm: Some("😍😍".into()),
            username: "😍".into(),
            password: "😍".into(),
            ..Login::default()
        })
        .unwrap();
        let fetched = db
            .get_by_id("dummy_000001")
            .expect("should work")
            .expect("should get a record");
        assert_eq!(fetched.hostname, "http://xn--r28h.com");
        assert_eq!(fetched.http_realm.unwrap(), "😍😍");
    }

    fn check_matches(db: &LoginDb, query: &str, expected: &[&str]) {
        let mut results = db
            .get_by_base_domain(query)
            .unwrap()
            .into_iter()
            .map(|l| l.hostname)
            .collect::<Vec<String>>();
        results.sort();
        let mut sorted = expected.to_owned();
        sorted.sort();
        assert_eq!(sorted, results);
    }

    fn check_good_bad(
        good: Vec<&str>,
        bad: Vec<&str>,
        good_queries: Vec<&str>,
        zero_queries: Vec<&str>,
    ) {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        for h in good.iter().chain(bad.iter()) {
            db.add(Login {
                hostname: (*h).into(),
                http_realm: Some((*h).into()),
                password: "test".into(),
                ..Login::default()
            })
            .unwrap();
        }
        for query in good_queries {
            check_matches(&db, query, &good);
        }
        for query in zero_queries {
            check_matches(&db, query, &[]);
        }
    }

    #[test]
    fn test_get_by_base_domain_invalid() {
        check_good_bad(
            vec!["https://example.com"],
            vec![],
            vec![],
            vec!["invalid query"],
        );
    }

    #[test]
    fn test_get_by_base_domain() {
        check_good_bad(
            vec![
                "https://example.com",
                "https://www.example.com",
                "http://www.example.com",
                "http://www.example.com:8080",
                "http://sub.example.com:8080",
                "https://sub.example.com:8080",
                "https://sub.sub.example.com",
                "ftp://sub.example.com",
            ],
            vec![
                "https://badexample.com",
                "https://example.co",
                "https://example.com.au",
            ],
            vec!["example.com"],
            vec!["foo.com"],
        );
        // punycode! This is likely to need adjusting once we normalize
        // on insert.
        check_good_bad(
            vec![
                "http://xn--r28h.com", // punycoded version of "http://😍.com"
            ],
            vec!["http://💖.com"],
            vec!["😍.com", "xn--r28h.com"],
            vec![],
        );
    }

    #[test]
    fn test_get_by_base_domain_ipv4() {
        check_good_bad(
            vec!["http://127.0.0.1", "https://127.0.0.1:8000"],
            vec!["https://127.0.0.0", "https://example.com"],
            vec!["127.0.0.1"],
            vec!["127.0.0.2"],
        );
    }

    #[test]
    fn test_get_by_base_domain_ipv6() {
        check_good_bad(
            vec!["http://[::1]", "https://[::1]:8000"],
            vec!["https://[0:0:0:0:0:0:1:1]", "https://example.com"],
            vec!["[::1]", "[0:0:0:0:0:0:0:1]"],
            vec!["[0:0:0:0:0:0:1:2]"],
        );
    }

    #[test]
    fn test_delete() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        let _login = db
            .add(Login {
                hostname: "https://www.example.com".into(),
                http_realm: Some("https://www.example.com".into()),
                username: "test_user".into(),
                password: "test_password".into(),
                ..Login::default()
            })
            .unwrap();

        assert!(db.delete(_login.guid_str()).unwrap());

        let tombstone_exists: bool = db
            .query_row_named(
                "SELECT EXISTS(
                    SELECT 1 FROM loginsL
                    WHERE guid = :guid AND is_deleted = 1
                )",
                named_params! { ":guid": _login.guid_str() },
                |row| row.get(0),
            )
            .unwrap();

        assert!(tombstone_exists);
        assert!(!db.exists(_login.guid_str()).unwrap());
    }

    #[test]
    fn test_wipe() {
        let db = LoginDb::open_in_memory(Some("testing")).unwrap();
        let login1 = db
            .add(Login {
                hostname: "https://www.example.com".into(),
                http_realm: Some("https://www.example.com".into()),
                username: "test_user_1".into(),
                password: "test_password_1".into(),
                ..Login::default()
            })
            .unwrap();

        let login2 = db
            .add(Login {
                hostname: "https://www.example2.com".into(),
                http_realm: Some("https://www.example2.com".into()),
                username: "test_user_1".into(),
                password: "test_password_2".into(),
                ..Login::default()
            })
            .unwrap();

        assert!(db.wipe(&db.begin_interrupt_scope()).is_ok());

        let expected_tombstone_count = 2;
        let actual_tombstone_count: i32 = db
            .query_row_named(
                "SELECT COUNT(guid)
                    FROM loginsL
                    WHERE guid IN (:guid1,:guid2)
                        AND is_deleted = 1",
                named_params! {
                    ":guid1": login1.guid_str(),
                    ":guid2": login2.guid_str(),
                },
                |row| row.get(0),
            )
            .unwrap();

        assert_eq!(expected_tombstone_count, actual_tombstone_count);
        assert!(!db.exists(login1.guid_str()).unwrap());
        assert!(!db.exists(login2.guid_str()).unwrap());
    }

    fn delete_logins(db: &LoginDb, guids: &[String]) -> Result<()> {
        sql_support::each_chunk(guids, |chunk, _| -> Result<()> {
            db.execute(
                &format!(
                    "DELETE FROM loginsL WHERE guid IN ({vars})",
                    vars = sql_support::repeat_sql_vars(chunk.len())
                ),
                chunk,
            )?;
            Ok(())
        })?;
        Ok(())
    }

    #[test]
    fn test_import_multiple() {
        struct TestCase {
            logins: Vec<Login>,
            has_populated_metrics: bool,
            expected_metrics: MigrationMetrics,
        }

        let db = LoginDb::open_in_memory(Some("testing")).unwrap();

        // Adding login to trigger non-empty table error
        let login = db
            .add(Login {
                hostname: "https://www.example.com".into(),
                http_realm: Some("https://www.example.com".into()),
                username: "test_user_1".into(),
                password: "test_password_1".into(),
                ..Login::default()
            })
            .unwrap();

        let import_with_populated_table = db.import_multiple(Vec::new().as_slice());
        assert!(import_with_populated_table.is_err());
        assert_eq!(
            import_with_populated_table.unwrap_err().to_string(),
            "The logins tables are not empty"
        );

        // Removing added login so the test cases below don't fail
        delete_logins(&db, &[login.guid.into_string()]).unwrap();

        // Setting up test cases
        let valid_login_guid1: Guid = Guid::random();
        let valid_login1 = Login {
            guid: valid_login_guid1,
            form_submit_url: Some("https://www.example.com".into()),
            hostname: "https://www.example.com".into(),
            http_realm: None,
            username: "test".into(),
            password: "test".into(),
            ..Login::default()
        };
        let valid_login_guid2: Guid = Guid::random();
        let valid_login2 = Login {
            guid: valid_login_guid2,
            form_submit_url: Some("https://www.example2.com".into()),
            hostname: "https://www.example2.com".into(),
            http_realm: None,
            username: "test2".into(),
            password: "test2".into(),
            ..Login::default()
        };
        let valid_login_guid3: Guid = Guid::random();
        let valid_login3 = Login {
            guid: valid_login_guid3,
            form_submit_url: Some("https://www.example3.com".into()),
            hostname: "https://www.example3.com".into(),
            http_realm: None,
            username: "test3".into(),
            password: "test3".into(),
            ..Login::default()
        };
        let duplicate_login_guid: Guid = Guid::random();
        let duplicate_login = Login {
            guid: duplicate_login_guid,
            form_submit_url: Some("https://www.example.com".into()),
            hostname: "https://www.example.com".into(),
            http_realm: None,
            username: "test".into(),
            password: "test2".into(),
            ..Login::default()
        };

        let duplicate_logins = vec![valid_login1.clone(), duplicate_login, valid_login2.clone()];

        let duplicate_logins_metrics = MigrationMetrics {
            fixup_phase: MigrationPhaseMetrics {
                num_processed: 3,
                num_succeeded: 2,
                num_failed: 1,
                errors: vec!["InvalidLogin::DuplicateLogin".into()],
                ..MigrationPhaseMetrics::default()
            },
            insert_phase: MigrationPhaseMetrics {
                num_processed: 2,
                num_succeeded: 2,
                ..MigrationPhaseMetrics::default()
            },
            num_processed: 3,
            num_succeeded: 2,
            num_failed: 1,
            errors: vec!["InvalidLogin::DuplicateLogin".into()],
            ..MigrationMetrics::default()
        };

        let valid_logins = vec![valid_login1, valid_login2, valid_login3];

        let valid_logins_metrics = MigrationMetrics {
            fixup_phase: MigrationPhaseMetrics {
                num_processed: 3,
                num_succeeded: 3,
                ..MigrationPhaseMetrics::default()
            },
            insert_phase: MigrationPhaseMetrics {
                num_processed: 3,
                num_succeeded: 3,
                ..MigrationPhaseMetrics::default()
            },
            num_processed: 3,
            num_succeeded: 3,
            ..MigrationMetrics::default()
        };

        let test_cases = [
            TestCase {
                logins: Vec::new(),
                has_populated_metrics: false,
                expected_metrics: MigrationMetrics {
                    ..MigrationMetrics::default()
                },
            },
            TestCase {
                logins: duplicate_logins,
                has_populated_metrics: true,
                expected_metrics: duplicate_logins_metrics,
            },
            TestCase {
                logins: valid_logins,
                has_populated_metrics: true,
                expected_metrics: valid_logins_metrics,
            },
        ];

        for tc in &test_cases {
            let import_result = db.import_multiple(tc.logins.as_slice());
            assert!(import_result.is_ok());

            let mut actual_metrics = import_result.unwrap();

            if tc.has_populated_metrics {
                let mut guids = Vec::new();
                for login in &tc.logins {
                    guids.push(login.clone().guid.into_string());
                }

                assert_eq!(
                    actual_metrics.num_processed,
                    tc.expected_metrics.num_processed
                );
                assert_eq!(
                    actual_metrics.num_succeeded,
                    tc.expected_metrics.num_succeeded
                );
                assert_eq!(actual_metrics.num_failed, tc.expected_metrics.num_failed);
                assert_eq!(actual_metrics.errors, tc.expected_metrics.errors);

                let phases = [
                    (
                        actual_metrics.fixup_phase,
                        tc.expected_metrics.fixup_phase.clone(),
                    ),
                    (
                        actual_metrics.insert_phase,
                        tc.expected_metrics.insert_phase.clone(),
                    ),
                ];

                for (actual, expected) in &phases {
                    assert_eq!(actual.num_processed, expected.num_processed);
                    assert_eq!(actual.num_succeeded, expected.num_succeeded);
                    assert_eq!(actual.num_failed, expected.num_failed);
                    assert_eq!(actual.errors, expected.errors);
                }

                // clearing the database for next test case
                delete_logins(&db, guids.as_slice()).unwrap();
            } else {
                // We could elaborate mock out the clock for tests...
                // or we could just set the duration fields to the right values!
                actual_metrics.total_duration = tc.expected_metrics.total_duration;
                actual_metrics.fixup_phase.total_duration =
                    tc.expected_metrics.fixup_phase.total_duration;
                actual_metrics.insert_phase.total_duration =
                    tc.expected_metrics.insert_phase.total_duration;
                assert_eq!(actual_metrics, tc.expected_metrics);
            }
        }
    }

    #[test]
    fn test_open_with_salt_create_db() {
        let dir = tempdir::TempDir::new("open_with_salt").unwrap();
        let dbpath = dir.path().join("logins.sqlite");
        let dbpath = dbpath.to_str().unwrap();
        let conn =
            LoginDb::open_with_salt(dbpath, "testing", "952b9e3d53b39a8eba70b398acefa0a0").unwrap();
        conn.query_one::<i64>("PRAGMA user_version").unwrap();
    }

    #[test]
    fn test_get_salt_for_key() {
        // First we create a database.
        let dir = tempdir::TempDir::new("salt_for_key_test").unwrap();
        let dbpath = dir.path().join("logins.sqlite");
        let dbpath = dbpath.to_str().unwrap();
        let conn = LoginDb::open(dbpath, Some("testing")).unwrap();
        // Database created.
        let expected_salt = conn.query_one::<String>("PRAGMA cipher_salt").unwrap();

        let salt = LoginDb::open_and_get_salt(dbpath, "testing").unwrap();
        assert_eq!(expected_salt, salt);
    }

    #[test]
    fn test_get_salt_for_key_no_db() {
        assert!(LoginDb::open_and_get_salt("nodbpath", "testing").is_err());
    }

    #[test]
    fn test_plaintext_header_migration_full() {
        // First we create a database.
        let dir = tempdir::TempDir::new("plaintext_header_migration").unwrap();
        let dbpath = dir.path().join("logins.sqlite");
        let dbpath = dbpath.to_str().unwrap();
        let conn = LoginDb::open(dbpath, Some("testing")).unwrap();
        drop(conn);
        // Database created.

        // Step 1: get the salt.
        let salt = LoginDb::open_and_get_salt(dbpath, "testing").unwrap();

        // Step 2: migrate the db.
        LoginDb::open_and_migrate_to_plaintext_header(dbpath, "testing", &salt).unwrap();

        // Step 3: open using the salt.
        let conn = LoginDb::open_with_salt(dbpath, "testing", &salt).unwrap();
        conn.query_one::<i64>("PRAGMA user_version").unwrap();
    }

    #[test]
    fn test_open_db_with_wrong_salt() {
        // First we create a database.
        let dir = tempdir::TempDir::new("wrong_salt_test").unwrap();
        let dbpath = dir.path().join("logins.sqlite");
        let dbpath = dbpath.to_str().unwrap();
        let conn =
            LoginDb::open_with_salt(dbpath, "testing", "deadbeefdeadbeefdeadbeefdeadbeef").unwrap();
        drop(conn);
        // Database created.

        // Try opening the db using a wrong salt.
        assert!(
            LoginDb::open_with_salt(dbpath, "testing", "beefdeadbeefdeadbeefdeadbeefdead").is_err()
        );
    }

    #[test]
    fn test_create_db_with_invalid_salt() {
        let dir = tempdir::TempDir::new("invalid_salt_test").unwrap();
        let dbpath = dir.path().join("logins.sqlite");
        let dbpath = dbpath.to_str().unwrap();
        assert!(
            LoginDb::open_with_salt(dbpath, "testing", "bobobobobobobobobobobobobobobobo").is_err()
        );
    }

    #[test]
    fn test_ensure_valid_salt() {
        assert!(ensure_valid_salt("bobo").is_err());
        assert!(ensure_valid_salt("bobobobobobobobobobobobobobobobo").is_err());
        assert!(ensure_valid_salt("deadbeef").is_err());
        assert!(ensure_valid_salt("deadbeefdeadbeefdeadbeefdeadbeef").is_ok());
    }
}
