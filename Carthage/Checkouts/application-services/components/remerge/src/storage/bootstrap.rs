/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module is concerned mainly with initializing the schema and metadata
//! tables in the database. Specifically it has to handle the following cases
//!
//! ## First time initialization
//!
//! - Must insert the provided native schema into schemas table
//! - Must populate the metadata keys with their initial values. Specifically:
//!   - remerge/collection-name
//!   - remerge/local-schema-version
//!   - remerge/native-schema-version
//!   - remerge/client-id
//!   - remerge/change-counter

use super::{meta, SchemaBundle};
use crate::error::*;
use crate::Guid;
use rusqlite::Connection;
use std::sync::Arc;

pub(super) fn load_or_bootstrap(
    db: &Connection,
    native: super::NativeSchemaAndText<'_>,
) -> Result<(SchemaBundle, Guid)> {
    if let Some(name) = meta::try_get::<String>(db, meta::COLLECTION_NAME)? {
        let native = native.parsed;
        if name != native.name {
            throw!(ErrorKind::SchemaNameMatchError(native.name.clone(), name));
        }
        let local_ver: String = meta::get(db, meta::LOCAL_SCHEMA_VERSION)?;
        let native_ver: String = meta::get(db, meta::NATIVE_SCHEMA_VERSION)?;
        let client_id: sync_guid::Guid = meta::get(db, meta::OWN_CLIENT_ID)?;

        if native_ver != native.version.to_string() {
            // XXX migrate existing records here!
            let native_ver = semver::Version::parse(&*native_ver)
                .expect("previously-written version is no longer semver");
            if native.version < native_ver {
                throw!(ErrorKind::SchemaVersionWentBackwards(
                    native.version.to_string(),
                    native_ver.to_string()
                ));
            }
            meta::put(db, meta::NATIVE_SCHEMA_VERSION, &native.version.to_string())?;
        } else {
            let previous_native: String = db.query_row(
                "SELECT schema_text FROM remerge_schemas WHERE version = ?",
                rusqlite::params![native_ver],
                |r| r.get(0),
            )?;
            let previous_native = crate::schema::parse_from_string(&*previous_native, false)?;
            if *native != previous_native {
                throw!(ErrorKind::SchemaChangedWithoutVersionBump(
                    native.version.to_string()
                ));
            }
        }
        let local_schema: String = db.query_row(
            "SELECT schema_text FROM remerge_schemas WHERE version = ?",
            rusqlite::params![local_ver],
            |r| r.get(0),
        )?;
        // XXX need to think about what to do if this fails! More generally, is
        // it sane to run validation on schemas already in the DB? If the answer
        // is yes, we should probably have more tests to ensure we never begin
        // rejecting a schema we previously considered valid!
        let parsed = crate::schema::parse_from_string(&local_schema, false)?;
        Ok((
            SchemaBundle {
                local: Arc::new(parsed),
                native,
                collection_name: name,
            },
            client_id,
        ))
    } else {
        bootstrap(db, native)
    }
}

pub(super) fn bootstrap(
    db: &Connection,
    native: super::NativeSchemaAndText<'_>,
) -> Result<(SchemaBundle, Guid)> {
    let guid = sync_guid::Guid::random();
    meta::put(db, meta::OWN_CLIENT_ID, &guid)?;
    let sql = "
        INSERT INTO remerge_schemas (is_legacy, version, required_version, schema_text)
        VALUES (:legacy, :version, :req_version, :text)
    ";
    let ver_str = native.parsed.version.to_string();
    db.execute_named(
        sql,
        rusqlite::named_params! {
            ":legacy": native.parsed.legacy,
            ":version": ver_str,
            ":req_version": native.parsed.required_version.to_string(),
            ":text": native.source,
        },
    )?;
    meta::put(db, meta::LOCAL_SCHEMA_VERSION, &ver_str)?;
    meta::put(db, meta::NATIVE_SCHEMA_VERSION, &ver_str)?;
    meta::put(db, meta::COLLECTION_NAME, &native.parsed.name)?;
    meta::put(db, meta::CHANGE_COUNTER, &1)?;
    Ok((
        SchemaBundle {
            collection_name: native.parsed.name.clone(),
            native: native.parsed.clone(),
            local: native.parsed.clone(),
        },
        guid,
    ))
}
