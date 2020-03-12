/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use crate::db::{LoginDb, LoginStore, MigrationMetrics};
use crate::error::*;
use crate::login::Login;
use std::cell::Cell;
use std::path::Path;
use sync15::{
    sync_multiple, telemetry, KeyBundle, MemoryCachedState, StoreSyncAssociation,
    Sync15StorageClientInit,
};

// This isn't really an engine in the firefox sync15 desktop sense -- it's
// really a bundle of state that contains the sync storage client, the sync
// state, and the login DB.
pub struct PasswordEngine {
    pub db: LoginDb,
    pub mem_cached_state: Cell<MemoryCachedState>,
}

impl PasswordEngine {
    pub fn new(path: impl AsRef<Path>, encryption_key: Option<&str>) -> Result<Self> {
        let db = LoginDb::open(path, encryption_key)?;
        Ok(Self {
            db,
            mem_cached_state: Cell::default(),
        })
    }

    pub fn new_with_salt(path: impl AsRef<Path>, encryption_key: &str, salt: &str) -> Result<Self> {
        let db = LoginDb::open_with_salt(path, encryption_key, salt)?;
        Ok(Self {
            db,
            mem_cached_state: Cell::default(),
        })
    }

    pub fn new_in_memory(encryption_key: Option<&str>) -> Result<Self> {
        let db = LoginDb::open_in_memory(encryption_key)?;
        Ok(Self {
            db,
            mem_cached_state: Cell::default(),
        })
    }

    pub fn list(&self) -> Result<Vec<Login>> {
        self.db.get_all()
    }

    pub fn get(&self, id: &str) -> Result<Option<Login>> {
        self.db.get_by_id(id)
    }

    pub fn get_by_base_domain(&self, base_domain: &str) -> Result<Vec<Login>> {
        self.db.get_by_base_domain(base_domain)
    }

    pub fn touch(&self, id: &str) -> Result<()> {
        self.db.touch(id)
    }

    pub fn delete(&self, id: &str) -> Result<bool> {
        self.db.delete(id)
    }

    pub fn wipe(&self) -> Result<()> {
        let scope = self.db.begin_interrupt_scope();
        self.db.wipe(&scope)?;
        Ok(())
    }

    pub fn wipe_local(&self) -> Result<()> {
        self.db.wipe_local()?;
        Ok(())
    }

    pub fn reset(&self) -> Result<()> {
        self.db.reset(&StoreSyncAssociation::Disconnected)?;
        Ok(())
    }

    pub fn update(&self, login: Login) -> Result<()> {
        self.db.update(login)
    }

    pub fn add(&self, login: Login) -> Result<String> {
        // Just return the record's ID (which we may have generated).
        self.db.add(login).map(|record| record.guid.into_string())
    }

    pub fn import_multiple(&self, logins: &[Login]) -> Result<MigrationMetrics> {
        self.db.import_multiple(logins)
    }

    pub fn disable_mem_security(&self) -> Result<()> {
        self.db.disable_mem_security()
    }

    pub fn rekey_database(&self, new_encryption_key: &str) -> Result<()> {
        self.db.rekey_database(new_encryption_key)
    }

    // This is basically exposed just for sync_pass_sql, but it doesn't seem
    // unreasonable.
    pub fn conn(&self) -> &rusqlite::Connection {
        &self.db.db
    }

    pub fn new_interrupt_handle(&self) -> sql_support::SqlInterruptHandle {
        self.db.new_interrupt_handle()
    }

    /// A convenience wrapper around sync_multiple.
    pub fn sync(
        &self,
        storage_init: &Sync15StorageClientInit,
        root_sync_key: &KeyBundle,
    ) -> Result<telemetry::SyncTelemetryPing> {
        // migrate our V1 state - this needn't live for long.
        self.db.migrate_global_state()?;

        let mut disk_cached_state = self.db.get_global_state()?;
        let mut mem_cached_state = self.mem_cached_state.take();
        let store = LoginStore::new(&self.db);

        let mut result = sync_multiple(
            &[&store],
            &mut disk_cached_state,
            &mut mem_cached_state,
            storage_init,
            root_sync_key,
            &store.scope,
            None,
        );
        // We always update the state - sync_multiple does the right thing
        // if it needs to be dropped (ie, they will be None or contain Nones etc)
        self.db.set_global_state(&disk_cached_state)?;

        // for b/w compat reasons, we do some dances with the result.
        // XXX - note that this means telemetry isn't going to be reported back
        // to the app - we need to check with lockwise about whether they really
        // need these failures to be reported or whether we can loosen this.
        if let Err(e) = result.result {
            return Err(e.into());
        }
        match result.engine_results.remove("passwords") {
            None | Some(Ok(())) => Ok(result.telemetry),
            Some(Err(e)) => Err(e.into()),
        }
    }

    pub fn check_valid_with_no_dupes(&self, login: &Login) -> Result<()> {
        self.db.check_valid_with_no_dupes(login)
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::util;
    use more_asserts::*;
    use std::time::SystemTime;
    use sync_guid::Guid;
    // Doesn't check metadata fields
    fn assert_logins_equiv(a: &Login, b: &Login) {
        assert_eq!(b.guid, a.guid);
        assert_eq!(b.hostname, a.hostname);
        assert_eq!(b.form_submit_url, a.form_submit_url);
        assert_eq!(b.http_realm, a.http_realm);
        assert_eq!(b.username, a.username);
        assert_eq!(b.password, a.password);
        assert_eq!(b.username_field, a.username_field);
        assert_eq!(b.password_field, a.password_field);
    }

    #[test]
    fn test_general() {
        let engine = PasswordEngine::new_in_memory(Some("secret")).unwrap();
        let list = engine.list().expect("Grabbing Empty list to work");
        assert_eq!(list.len(), 0);
        let start_us = util::system_time_ms_i64(SystemTime::now());

        let a = Login {
            guid: "aaaaaaaaaaaa".into(),
            hostname: "https://www.example.com".into(),
            form_submit_url: Some("https://www.example.com".into()),
            username: "coolperson21".into(),
            password: "p4ssw0rd".into(),
            username_field: "user_input".into(),
            password_field: "pass_input".into(),
            ..Login::default()
        };

        let b = Login {
            // Note: no ID, should be autogenerated for us
            hostname: "https://www.example2.com".into(),
            http_realm: Some("Some String Here".into()),
            username: "asdf".into(),
            password: "fdsa".into(),
            ..Login::default()
        };

        let a_id = engine.add(a.clone()).expect("added a");
        let b_id = engine.add(b.clone()).expect("added b");

        assert_eq!(a_id, a.guid);

        assert_ne!(b_id, b.guid, "Should generate guid when none provided");

        let a_from_db = engine
            .get(&a_id)
            .expect("Not to error getting a")
            .expect("a to exist");

        assert_logins_equiv(&a, &a_from_db);
        assert_ge!(a_from_db.time_created, start_us);
        assert_ge!(a_from_db.time_password_changed, start_us);
        assert_ge!(a_from_db.time_last_used, start_us);
        assert_eq!(a_from_db.times_used, 1);

        let b_from_db = engine
            .get(&b_id)
            .expect("Not to error getting b")
            .expect("b to exist");

        assert_logins_equiv(
            &b_from_db,
            &Login {
                guid: Guid::from(b_id.as_str()),
                ..b.clone()
            },
        );
        assert_ge!(b_from_db.time_created, start_us);
        assert_ge!(b_from_db.time_password_changed, start_us);
        assert_ge!(b_from_db.time_last_used, start_us);
        assert_eq!(b_from_db.times_used, 1);

        let mut list = engine.list().expect("Grabbing list to work");
        assert_eq!(list.len(), 2);

        let mut expect = vec![a_from_db, b_from_db.clone()];

        list.sort_by(|a, b| b.guid.cmp(&a.guid));
        expect.sort_by(|a, b| b.guid.cmp(&a.guid));
        assert_eq!(list, expect);

        engine.delete(&a_id).expect("Successful delete");
        assert!(engine
            .get(&a_id)
            .expect("get after delete should still work")
            .is_none());

        let list = engine.list().expect("Grabbing list to work");
        assert_eq!(list.len(), 1);
        assert_eq!(list[0], b_from_db);

        let list = engine
            .get_by_base_domain("example2.com")
            .expect("Expect a list for this hostname");
        assert_eq!(list.len(), 1);
        assert_eq!(list[0], b_from_db);

        let list = engine
            .get_by_base_domain("www.example.com")
            .expect("Expect an empty list");
        assert_eq!(list.len(), 0);

        let now_us = util::system_time_ms_i64(SystemTime::now());
        let b2 = Login {
            password: "newpass".into(),
            guid: Guid::from(b_id.as_str()),
            ..b
        };

        engine.update(b2.clone()).expect("update b should work");

        let b_after_update = engine
            .get(&b_id)
            .expect("Not to error getting b")
            .expect("b to exist");

        assert_logins_equiv(&b_after_update, &b2);
        assert_ge!(b_after_update.time_created, start_us);
        assert_le!(b_after_update.time_created, now_us);
        assert_ge!(b_after_update.time_password_changed, now_us);
        assert_ge!(b_after_update.time_last_used, now_us);
        // Should be two even though we updated twice
        assert_eq!(b_after_update.times_used, 2);
    }

    #[test]
    fn test_rekey() {
        let engine = PasswordEngine::new_in_memory(Some("secret")).unwrap();
        engine.rekey_database("new_encryption_key").unwrap();
        let list = engine.list().expect("Grabbing Empty list to work");
        assert_eq!(list.len(), 0);
    }
}

#[test]
fn test_send() {
    fn ensure_send<T: Send>() {}
    ensure_send::<PasswordEngine>();
}
