/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use crate::storage::{db::RemergeDb, NativeRecord, NativeSchemaAndText, SchemaBundle};
use crate::Guid;
use std::convert::{TryFrom, TryInto};
use std::path::Path;

/// "Friendly" public api for using Remerge.
pub struct RemergeEngine {
    pub(crate) db: RemergeDb,
}

impl RemergeEngine {
    pub fn open(path: impl AsRef<Path>, schema_json: impl AsRef<str>) -> Result<Self> {
        let schema = NativeSchemaAndText::try_from(schema_json.as_ref())?;
        let conn = rusqlite::Connection::open(path.as_ref())?;
        let db = RemergeDb::with_connection(conn, schema)?;
        Ok(Self { db })
    }

    pub fn open_in_memory(schema_json: impl AsRef<str>) -> Result<Self> {
        let schema = NativeSchemaAndText::try_from(schema_json.as_ref())?;
        let conn = rusqlite::Connection::open_in_memory()?;
        let db = RemergeDb::with_connection(conn, schema)?;
        Ok(Self { db })
    }

    pub fn conn(&self) -> &rusqlite::Connection {
        self.db.conn()
    }

    pub fn bundle(&self) -> &SchemaBundle {
        self.db.bundle()
    }

    pub fn list(&self) -> Result<Vec<NativeRecord>> {
        self.db.get_all()
    }

    pub fn exists(&self, id: impl AsRef<str>) -> Result<bool> {
        self.db.exists(id.as_ref())
    }

    pub fn get(&self, id: impl AsRef<str>) -> Result<Option<NativeRecord>> {
        self.db.get_by_id(id.as_ref())
    }

    pub fn delete(&self, id: impl AsRef<str>) -> Result<bool> {
        self.db.delete_by_id(id.as_ref())
    }

    pub fn update<R>(&self, rec: R) -> Result<()>
    where
        R: TryInto<NativeRecord>,
        Error: From<R::Error>,
    {
        self.db.update_record(&rec.try_into()?)
    }

    pub fn insert<R>(&self, rec: R) -> Result<Guid>
    where
        R: TryInto<NativeRecord>,
        Error: From<R::Error>,
    {
        self.db.create(&rec.try_into()?)
    }
}
#[cfg(test)]
mod test {
    use super::*;
    use crate::untyped_map::UntypedMap;
    use crate::JsonValue;
    use rusqlite::{params, Connection};
    use serde_json::json;
    lazy_static::lazy_static! {
        pub static ref SCHEMA: String = json!({
            "version": "1.0.0",
            "name": "logins-example",
            "legacy": true,
            "fields": [
                {
                    "name": "id",
                    "type": "own_guid"
                },
                {
                    "name": "formSubmitUrl",
                    "type": "url",
                    "is_origin": true,
                    "local_name": "formActionOrigin"
                },
                {
                    "name": "httpRealm",
                    "type": "text",
                    "composite_root": "formSubmitUrl"
                },
                {
                    "name": "timesUsed",
                    "type": "integer",
                    "merge": "take_sum"
                },
                {
                    "name": "hostname",
                    "local_name": "origin",
                    "type": "url",
                    "is_origin": true,
                    "required": true
                },
                {
                    "name": "password",
                    "type": "text",
                    "required": true
                },
                {
                    "name": "username",
                    "type": "text"
                },
                {
                    "name": "extra",
                    "type": "untyped_map",
                },
            ],
            "dedupe_on": [
                "username",
                "password",
                "hostname"
            ]
        }).to_string();
    }

    #[test]
    fn test_init() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        assert_eq!(e.bundle().collection_name(), "logins-example");
    }

    #[test]
    fn test_insert() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        let id = e
            .insert(json!({
                "username": "test",
                "password": "p4ssw0rd",
                "origin": "https://www.example.com",
                "formActionOrigin": "https://login.example.com",
            }))
            .unwrap();
        assert!(e.exists(&id).unwrap());
        let r = e.get(&id).unwrap().expect("should exist");

        let v: JsonValue = r.into_val();
        assert_eq!(v["id"], id.as_str());
        assert_eq!(v["username"], "test");
        assert_eq!(v["password"], "p4ssw0rd");
        assert_eq!(v["origin"], "https://www.example.com");
        assert_eq!(v["formActionOrigin"], "https://login.example.com");
    }

    #[test]
    fn test_duplicate_insert() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        let id = e
            .insert(json!({
                "username": "test2",
                "password": "p4ssw0rd2",
                "origin": "https://www.example2.com",
                "formActionOrigin": "https://login.example2.com",
            }))
            .unwrap();
        assert!(e.exists(&id).unwrap());
        e.get(&id).unwrap().expect("should exist");

        let id2 = e
            .insert(json!({
                "username": "test3",
                "password": "p4ssw0rd2",
                "origin": "https://www.example3.com",
                "formActionOrigin": "https://login.example3.com",
            }))
            .unwrap();
        assert!(e.exists(&id2).unwrap());
        e.get(&id2).unwrap().expect("should exist");

        let r = e
            .insert(json!({
                "username": "test2",
                "password": "p4ssw0rd2",
                "origin": "https://www.example2.com",
                "formActionOrigin": "https://login.example2.com",
            }))
            .unwrap_err();

        assert_eq!(
            r.to_string(),
            "Invalid record: Record violates a `dedupe_on` constraint"
        );

        let id3 = e
            .insert(json!({
                "username": "test4",
                "password": "p4ssw0rd2",
                "origin": "https://www.example3.com",
                "formActionOrigin": "https://login.example3.com",
            }))
            .unwrap();
        assert!(e.exists(&id3).unwrap());
        e.get(&id3).unwrap().expect("should exist");
    }

    #[test]
    fn test_list_delete() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        let id = e
            .insert(json!({
                "username": "test",
                "password": "p4ssw0rd",
                "origin": "https://www.example.com",
                "formActionOrigin": "https://login.example.com",
            }))
            .unwrap();
        assert!(e.exists(&id).unwrap());

        e.get(&id).unwrap().expect("should exist");

        let id2 = e
            .insert(json!({
                "id": "abcd12349876",
                "username": "test2",
                "password": "p4ssw0rd0",
                "origin": "https://www.ex4mple.com",
                "httpRealm": "stuff",
            }))
            .unwrap();
        assert_eq!(id2, "abcd12349876");

        let l = e.list().unwrap();
        assert_eq!(l.len(), 2);
        assert!(l.iter().any(|r| r["id"] == id.as_str()));

        let v2 = l
            .iter()
            .find(|r| r["id"] == id2.as_str())
            .expect("should exist")
            .clone()
            .into_val();
        assert_eq!(v2["username"], "test2");
        assert_eq!(v2["password"], "p4ssw0rd0");
        assert_eq!(v2["origin"], "https://www.ex4mple.com");
        assert_eq!(v2["httpRealm"], "stuff");

        let del = e.delete(&id).unwrap();
        assert!(del);
        assert!(!e.exists(&id).unwrap());

        let l = e.list().unwrap();
        assert_eq!(l.len(), 1);
        assert_eq!(l[0]["id"], id2.as_str());
    }

    #[test]
    fn test_update() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        let id = e
            .insert(json!({
                "username": "test",
                "password": "p4ssw0rd",
                "origin": "https://www.example.com",
                "formActionOrigin": "https://login.example.com",
            }))
            .unwrap();
        assert!(e.exists(&id).unwrap());
        let v = e.get(&id).unwrap().expect("should exist").into_val();
        assert_eq!(v["id"], id.as_str());
        assert_eq!(v["username"], "test");
        assert_eq!(v["password"], "p4ssw0rd");
        assert_eq!(v["origin"], "https://www.example.com");
        assert_eq!(v["formActionOrigin"], "https://login.example.com");

        e.update(json!({
            "id": id,
            "username": "test2",
            "password": "p4ssw0rd0",
            "origin": "https://www.ex4mple.com",
            "httpRealm": "stuff",
        }))
        .unwrap();

        let v = e
            .get(&id)
            .unwrap()
            .expect("should (still) exist")
            .into_val();
        assert_eq!(v["id"], id.as_str());
        assert_eq!(v["username"], "test2");
        assert_eq!(v["password"], "p4ssw0rd0");
        assert_eq!(v["origin"], "https://www.ex4mple.com");
        assert_eq!(v["httpRealm"], "stuff");
    }

    fn extra(conn: &Connection, id: &str) -> Result<UntypedMap> {
        let data: JsonValue = conn.query_row_and_then(
            "SELECT record_data FROM rec_local WHERE guid = ?",
            params![id],
            |row| row.get(0),
        )?;
        UntypedMap::from_local_json(data["extra"].clone())
    }

    #[test]
    fn test_untyped_map_update() {
        let e: RemergeEngine = RemergeEngine::open_in_memory(&*SCHEMA).unwrap();
        let id = e
            .insert(json!({
                "username": "test",
                "password": "p4ssw0rd",
                "origin": "https://www.example.com",
                "formActionOrigin": "https://login.example.com",
                "extra": {
                    "foo": "a",
                    "bar": 4,
                }
            }))
            .unwrap();
        assert!(e.exists(&id).unwrap());
        let v = e.get(&id).unwrap().expect("should exist").into_val();
        assert_eq!(v["id"], id.as_str());
        assert_eq!(v["username"], "test");
        assert_eq!(v["password"], "p4ssw0rd");
        assert_eq!(v["origin"], "https://www.example.com");
        assert_eq!(v["formActionOrigin"], "https://login.example.com");
        assert_eq!(
            v["extra"],
            json!({
                "foo": "a",
                "bar": 4,
            })
        );
        let um0: UntypedMap = extra(e.conn(), &id).unwrap();
        assert_eq!(um0.len(), 2);
        assert_eq!(um0["foo"], "a");
        assert_eq!(um0["bar"], 4);
        assert_eq!(um0.tombstones().len(), 0);

        e.update(json!({
            "id": id,
            "username": "test2",
            "password": "p4ssw0rd0",
            "origin": "https://www.ex4mple.com",
            "httpRealm": "stuff",
            "extra": json!({
                "foo": "a",
                "quux": 4,
            })
        }))
        .unwrap();

        let v = e
            .get(&id)
            .unwrap()
            .expect("should (still) exist")
            .into_val();
        assert_eq!(v["id"], id.as_str());
        assert_eq!(v["username"], "test2");
        assert_eq!(v["password"], "p4ssw0rd0");
        assert_eq!(v["origin"], "https://www.ex4mple.com");
        assert_eq!(v["httpRealm"], "stuff");
        assert_eq!(
            v["extra"],
            json!({
                "foo": "a",
                "quux": 4,
            })
        );

        let um1: UntypedMap = extra(e.conn(), &id).unwrap();
        assert_eq!(um1.len(), 2);
        assert_eq!(um1["foo"], "a");
        assert_eq!(um1["quux"], 4);

        um1.assert_tombstones(vec!["bar"]);

        e.update(json!({
            "id": id,
            "username": "test2",
            "password": "p4ssw0rd0",
            "origin": "https://www.ex4mple.com",
            "httpRealm": "stuff",
            "extra": json!({
                "bar": "test",
            })
        }))
        .unwrap();

        let um2: UntypedMap = extra(e.conn(), &id).unwrap();
        assert_eq!(um2.len(), 1);
        assert_eq!(um2["bar"], "test");
        um2.assert_tombstones(vec!["foo", "quux"]);
    }

    #[test]
    fn test_schema_cant_go_backwards() {
        const FILENAME: &str = "file:test_schema_go_backwards.sqlite?mode=memory&cache=shared";
        let _e: RemergeEngine = RemergeEngine::open(FILENAME, &*SCHEMA).unwrap();
        let backwards_schema: String = json!({
            "version": "0.1.0",
            "name": "logins-example",
            "fields": [],
        })
        .to_string();
        let open_result = RemergeEngine::open(FILENAME, &*backwards_schema);

        if let Err(e) = open_result {
            assert_eq!(
                e.to_string(),
                "Schema given is of an earlier version (0.1.0) than previously stored (1.0.0)"
            );
        } else {
            panic!("permitted going backwards in schema versions");
        }
    }

    #[test]
    fn test_schema_doesnt_change_same_version() {
        const FILENAME: &str =
            "file:test_schema_change_without_version.sqlite?mode=memory&cache=shared";
        let _e: RemergeEngine = RemergeEngine::open(FILENAME, &*SCHEMA).unwrap();
        let backwards_schema: String = json!({
            "version": "1.0.0",
            "name": "logins-example",
            "fields": [],
        })
        .to_string();
        let open_result = RemergeEngine::open(FILENAME, &*backwards_schema);

        if let Err(e) = open_result {
            assert_eq!(
                e.to_string(),
                "Schema version did not change (1.0.0) but contents are different"
            );
        } else {
            panic!("permitted changing without version bump");
        }
    }
}
