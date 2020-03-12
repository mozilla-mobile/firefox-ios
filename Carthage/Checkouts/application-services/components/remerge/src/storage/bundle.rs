/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::{LocalRecord, NativeRecord};
use crate::error::*;
use crate::schema::{FieldKind, FieldType, RecordSchema};
use crate::untyped_map::{OnCollision, UntypedMap};
use crate::{Guid, JsonObject, JsonValue};
use std::sync::Arc;

/// Reason for converting a native record to a local record. Essentially a
/// typesafe `is_creation: bool`. Exists just to be passed to `native_to_local`,
/// see that function's docs for more info.
#[derive(Clone, Debug)]
pub enum ToLocalReason {
    /// The record is going to be compared with existing records, and won't be
    /// inserted into the DB. This means we're going to perform deduping
    Comparison,

    /// The record is being created
    Creation,

    /// The record is expected to exist, and is being updated.
    Update {
        /// Needed for UntypedMap, and eventually RecordSet.
        prev: LocalRecord,
    },
}

#[derive(Clone, Debug, PartialEq)]
pub struct SchemaBundle {
    pub(crate) collection_name: String,
    pub(crate) native: Arc<RecordSchema>,
    pub(crate) local: Arc<RecordSchema>,
}

impl SchemaBundle {
    /// Convert a native record to a local record.
    ///
    /// The reason parameter influences the behavior of this function.
    ///
    /// ### if `reason == Creation`
    ///
    /// - We assume we need to generate an ID for this record, unless it has a
    ///   non-auto OwnGuid field (in which case we ensure this is present).
    ///
    /// - If we have a timestamp field with the created_at semantic, we populate
    ///   that.
    ///
    /// - Note that if you use this, you will likely need to check that no such
    ///   record is in the database already (this function can't).
    ///
    /// ### if `reason == Update`
    ///
    /// - We require the OwnGuid field to be populated.
    /// - If we have a timestamp field with the updated_at semantic, it's
    ///   updated.
    ///
    /// ### if `reason == Comparison`
    ///
    /// - The OwnGuid field may optionally be populated. If it's not populated,
    ///   the resulting LocalRecord will not have a populated guid, and the
    ///   first member of the tuple will be an empty guid.
    ///
    ///     - The OwnGuid field is optional for comparison, since for deduping
    ///       you might want to validate an existing record. If this is the
    ///       case, the guid allows us to avoid saying an item is it's own dupe.
    ///
    ///       However, if validating prior to creation, you wouldn't provide a
    ///       guid (unless the own_guid is not auto)
    ///
    /// - Semantic timestamps are not filled in (Hrm...)
    pub fn native_to_local(
        &self,
        record: &NativeRecord,
        reason: ToLocalReason,
    ) -> Result<(Guid, LocalRecord)> {
        use crate::util::into_obj;
        let mut id = Guid::random();

        let mut fields = JsonObject::default();
        // TODO: Maybe we should ensure this for all `Record`s?
        let mut seen_guid = false;
        let now_ms = crate::MsTime::now();

        for field in &self.local.fields {
            let native_field = &self.native.field(&field.name);
            // XXX `local_name` in the schema should be renamed to something
            // else. It's the property used to rename a field locally, while
            // leaving it's canonical name the same. For example, this is
            // (eventually) what logins wants to do for hostname/origin.
            //
            // All good so far, the confusion is that `local` generally refers
            // to the on-disk type, and `native` refers to the values coming
            // from the running local application (which will use `local_name`).
            //
            // Or maybe renaming `LocalRecord` and such would be enough.
            let native_name = native_field.map(|n| n.local_name.as_str());

            let is_guid = FieldKind::OwnGuid == field.ty.kind();
            let is_umap = FieldKind::UntypedMap == field.ty.kind();
            let ts_sema = field.timestamp_semantic();

            if let Some(v) = native_name.and_then(|s| record.get(s)) {
                let mut fixed = field.validate(v.clone())?;
                if is_guid {
                    if let JsonValue::String(s) = &fixed {
                        id = Guid::from(s.as_str());
                        seen_guid = true;
                    } else {
                        unreachable!(
                            "Field::validate checks that OwnGuid fields have string values."
                        );
                    }
                } else if let Some(semantic) = ts_sema {
                    use crate::schema::TimestampSemantic::*;
                    // Consider a format where in v1 there's a timestamp field
                    // which has no semantic, but the devs are manually making
                    // it behave like it had the `updated_at` semantic.
                    //
                    // Then, in v2, they did a closer read of the remerge docs
                    // (or something) and changed it to have the `updated_at`
                    // semantic.
                    //
                    // Erroring here would make this a breaking change. However,
                    // we don't really want to just support it blindly, so we
                    // check and see if the native schema version thinks this
                    // should be a timestamp field too, and if so we allow it.
                    //
                    // However, we use our own timestamps, so that they're
                    // consistent with timestamps we generate elsewhere.
                    if native_field.map_or(false, |nf| !nf.is_kind(FieldKind::Timestamp)) {
                        throw!(InvalidRecord::InvalidField(
                            native_name
                                .unwrap_or_else(|| field.name.as_str())
                                .to_owned(),
                            format!(
                                "A value was provided for timestamp with {:?} semantic",
                                semantic
                            ),
                        ));
                    }
                    match (&reason, semantic) {
                        (ToLocalReason::Creation, _) => {
                            // Initialize both CreatedAt/UpdatedAt to now_ms on creation
                            fixed = now_ms.into();
                        }
                        (ToLocalReason::Update { .. }, UpdatedAt) => {
                            fixed = now_ms.into();
                        }
                        // Keep these here explicitly to ensure this gets
                        // updated if the enums changed.
                        (ToLocalReason::Update { .. }, CreatedAt) => {}
                        (ToLocalReason::Comparison, _) => {
                            // XXX The result of this won't be "fully" valid...
                            // Shouldn't matter for deduping (what Comparison is
                            // currently used for), since you cant dedupe_on a
                            // semantic timestamp (validation checks this).
                        }
                    }
                } else if is_umap {
                    // Untyped maps have to be converted into a `{ map:
                    // <payload>, tombs: [...] }` payload to handle storing
                    // tombstones.
                    //
                    // Additionally, for updates, we make sure (inside
                    // `update_local_from_native` and callees) that:
                    // - entries which are being removed in this update
                    //   should get tombstones.
                    // - entries which are added which have tombstones
                    //   have the tombstones removed.
                    match &reason {
                        ToLocalReason::Update { prev } => {
                            // Note that the equivalent field in `prev`'s schema
                            // might not exist (or it might exist but have been
                            // optional). For now, just

                            if let Some(prev) = prev.get(&field.name) {
                                fixed = UntypedMap::update_local_from_native(prev.clone(), fixed)?;
                            } else {
                                fixed = UntypedMap::from_native(into_obj(fixed)?).into_local_json();
                            }
                        }
                        ToLocalReason::Creation | ToLocalReason::Comparison => {
                            fixed = UntypedMap::from_native(into_obj(fixed)?).into_local_json();
                        }
                    }
                }
                fields.insert(field.name.clone(), fixed);
            } else if let Some(def) = field.ty.get_default() {
                if is_umap {
                    let def_obj = into_obj(def)?;
                    let val = UntypedMap::new(def_obj, vec![], OnCollision::KeepEntry);
                    fields.insert(field.name.clone(), val.into_local_json());
                } else {
                    fields.insert(field.name.clone(), def);
                }
            } else if is_guid {
                match &reason {
                    ToLocalReason::Update { .. } => {
                        throw!(InvalidRecord::InvalidField(
                            native_name
                                .unwrap_or_else(|| field.name.as_str())
                                .to_owned(),
                            "no value provided in ID field for update".into()
                        ));
                    }
                    ToLocalReason::Creation => {
                        // Note: auto guids are handled below
                        fields.insert(field.name.clone(), id.to_string().into());
                    }
                    ToLocalReason::Comparison => {
                        // Records from Comparison are allowed to omit their
                        // guids. Motivation for this is in fn header comment
                        // (tldr: you'll want to omit it when running a
                        // validation/dupe check for a fresh record, and provide
                        // it for an existing record)

                        // Clear the `id`. This isn't great, but I doubt anybody
                        // will care about it. Using an Option<Guid> for the
                        // return where it will always be Some(id) for
                        // Creation/Update, and None for Comparison seems worse
                        // to me.
                        //
                        // eh. Comparison is only half-implemented for now
                        // anyway.
                        id = Guid::empty();
                    }
                }
            } else if field.required {
                throw!(InvalidRecord::MissingRequiredField(
                    native_name
                        .unwrap_or_else(|| field.name.as_str())
                        .to_owned()
                ));
            }
        }
        // XXX We should error if there are any fields in the native record we
        // don't know about, instead of silently droppin them.

        if !seen_guid && matches::matches!(reason, ToLocalReason::Creation) {
            self.complain_unless_auto_guid()?;
        }

        Ok((id, LocalRecord::new_unchecked(fields)))
    }

    pub fn local_to_native(&self, record: &LocalRecord) -> Result<NativeRecord> {
        let mut fields = JsonObject::default();
        // Note: we should probably report special telemetry for many of these
        // errors, as they indicate (either a bug in remerge or in the provided
        // schema)
        for native_field in &self.native.fields {
            // First try the record. Note that the `name` property isnt'
            // supposed to change, barring removal or similar. (This is why
            // `local_name` exists)
            if let Some(value) = record.get(&native_field.name) {
                let mut value: JsonValue = value.clone();
                // If it's an UntypedMap, we need to replace the `{ map:
                // {payload here}, tombs: ... }` structure with just the payload.
                if native_field.ty.kind() == FieldKind::UntypedMap {
                    value = UntypedMap::from_local_json(value)?.into_native().into();
                }
                fields.insert(native_field.local_name.clone(), value);
                continue;
            } else if let Some(default) = native_field.ty.get_default() {
                // Otherwise, we see if the field has a default value specified
                // in the native schema.
                fields.insert(native_field.local_name.clone(), default);
                continue;
            }
            // If not, see if it has a default specified in the local schema.
            // Even though we apply defaults when writing local records into the
            // DB, this can happen if the local schema we wrote `record` with is
            // an older version than our current local schema version.
            if let Some(default) = self
                .local
                .field(&native_field.name)
                .and_then(|lf| lf.ty.get_default())
            {
                // Make sure that that default is valid. If it's not, we
                // ignore it (unless it's a required native field, in which
                // case we complain).
                if let Ok(fixed) = native_field.validate(default.clone()) {
                    if fixed == default {
                        fields.insert(native_field.local_name.clone(), default);
                        continue;
                    }
                    // If this is actually a problem (e.g. the field is
                    // required), we'll complain loudly below (this is likely a
                    // schema issue if the field is required).
                    log::error!(
                        "More recent schema has default record for field {:?}, but it required fixups according to the native schema!",
                        native_field.local_name,
                    );
                } else {
                    // The local schema's default value for some field is
                    // invalid according to the native schema. This should be a
                    // breaking change if it ever happens, and means the schema
                    // has problems, so we report an error here (even if it's an
                    // optional field...)
                    throw!(ErrorKind::LocalToNativeError(format!(
                        "More recent schema has default record for field {:?}, \
                         but it was not valid according to the native schema",
                        native_field.local_name
                    )));
                }
            }

            if !native_field.required {
                // We didn't have it, but it's optional.
                continue;
            }
            // Everything we tried failed, which means we have a bad record in
            // our DB. This is probably caused by an incompatible schema update
            // that didn't specify the right required version. :(
            //
            // In practice this can be fixed by pushing a updated schema with a
            // default value / fixed default value for this, so it's unclear
            // what to actually do here until we see what kinds of things cause
            // it in the wild, if any.
            throw!(ErrorKind::LocalToNativeError(format!(
                "Local record is missing or has invalid required field {:?}",
                native_field.local_name
            )));
        }
        Ok(NativeRecord::new_unchecked(fields))
    }

    /// Called if the guid isn't provided, returns Err if it wasn't needed.
    fn complain_unless_auto_guid(&self) -> Result<()> {
        let mut required_own_guid_field = None;
        for &schema in &[&*self.local, &*self.native] {
            if let Some(idx) = schema.field_own_guid {
                if let FieldType::OwnGuid { auto } = &schema.fields[idx].ty {
                    if *auto {
                        return Ok(());
                    }
                    required_own_guid_field = Some(schema.fields[idx].name.as_str());
                } else {
                    // Validation ensures this.
                    panic!("bug: field_own_guid refers to non-OwnGuid field");
                }
            }
        }
        if let Some(name) = required_own_guid_field {
            throw!(InvalidRecord::MissingRequiredField(name.to_string()));
        }
        Ok(())
    }

    pub fn collection_name(&self) -> &str {
        &self.collection_name
    }

    pub fn native_schema(&self) -> &RecordSchema {
        &self.native
    }

    pub fn local_schema(&self) -> &RecordSchema {
        &self.local
    }
}
