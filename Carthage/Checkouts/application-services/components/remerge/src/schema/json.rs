/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module is concerned primarially with schema parsing (from RawSchema,
//! e.g. the schema represented as JSON), and validation. It's a little bit
//! hairy, and for the definitive documentation, you should refer to the
//! `docs/design/remerge/schema-format.md` docs.

// Clippy seems to be upset about serde's output:
// https://github.com/rust-lang/rust-clippy/issues/4326
#![allow(clippy::type_repetition_in_bounds)]

use super::desc::*;
use super::error::*;
use super::merge_kinds::*;
use crate::util::is_default;
use crate::{JsonObject, JsonValue};
use index_vec::IndexVec;
use matches::matches;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use url::Url;

pub const FORMAT_VERSION: usize = 1;

pub fn parse_from_string(json: &str, is_remote: bool) -> Result<RecordSchema, SchemaError> {
    let schema = match serde_json::from_str::<RawSchema>(json) {
        Ok(schema) => schema,
        Err(e) => {
            // If it's local then this is just a format error.
            if !is_remote {
                // For some reason throw! and ensure! both complain about moving
                // `e` here, but this works...
                return Err(SchemaError::FormatError(e));
            }
            // If it's remote, then it failed, but it could have failed because
            // it's from a future version. Check that.
            let version = match serde_json::from_str::<JustFormatVersion>(json) {
                Ok(s) => s.format_version,
                Err(_) => {
                    // Ditto with moving `e` (which we want to use because it can give
                    // better error messages).
                    return Err(SchemaError::FormatError(e));
                }
            };
            return Err(if version != FORMAT_VERSION {
                SchemaError::WrongFormatVersion(version)
            } else {
                SchemaError::FormatError(e)
            });
        }
    };
    let parser = SchemaParser::new(&schema, false);
    Ok(parser.parse()?)
}

/// Helper trait to make marking results / errors with which field were were
/// parsing more convenient.
trait FieldErrorHelper {
    type Out;
    fn named(self, name: &str) -> Self::Out;
}

impl FieldErrorHelper for FieldError {
    type Out = SchemaError;
    fn named(self, name: &str) -> SchemaError {
        SchemaError::FieldError(name.into(), self)
    }
}

impl<T> FieldErrorHelper for Result<T, FieldError> {
    type Out = Result<T, SchemaError>;
    fn named(self, name: &str) -> Result<T, SchemaError> {
        match self {
            Ok(v) => Ok(v),
            Err(e) => Err(e.named(name)),
        }
    }
}

// Used just to parse out the required version in case JsonSchema changes incompatibly.
#[derive(Clone, Debug, Serialize, Deserialize)]
struct JustFormatVersion {
    format_version: usize,
}
/// The serialized representation of the schema.
///
/// Note that if you change this, you will likely have to change the data in
/// `schema/desc.rs`.
///
/// Important: Note that changes to this are in general not allowed to fail to
/// parse older versions of this format.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RawSchema {
    /// The name of this collection
    pub name: String,
    /// The version of the schema
    pub version: String,

    /// The required version of the schema
    pub required_version: Option<String>,

    #[serde(default)]
    pub remerge_features_used: Vec<String>,

    #[serde(default)]
    pub legacy: bool,

    pub fields: Vec<RawFieldType>,

    #[serde(default)]
    pub dedupe_on: Vec<String>,
}
// OptDefaultType not just being the type and made into an Option here is for serde's benefit.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct RawFieldCommon<OptDefaultType: PartialEq + Default> {
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub local_name: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub required: bool,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub deprecated: bool,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub composite_root: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub merge: Option<ParsedMerge>,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub change_preference: Option<ChangePreference>,

    #[serde(default)]
    #[serde(skip_serializing_if = "is_default")]
    pub default: OptDefaultType,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum RawFieldType {
    #[serde(rename = "untyped")]
    Untyped {
        #[serde(flatten)]
        // XXX does using JsonValue here still work now that we use json?
        common: RawFieldCommon<Option<JsonValue>>,
    },

    #[serde(rename = "text")]
    Text {
        #[serde(flatten)]
        common: RawFieldCommon<Option<String>>,
    },

    #[serde(rename = "url")]
    Url {
        #[serde(flatten)]
        common: RawFieldCommon<Option<String>>, // XXX: Option<Url>...
        #[serde(default)]
        is_origin: bool,
    },

    #[serde(rename = "boolean")]
    Boolean {
        #[serde(flatten)]
        common: RawFieldCommon<Option<bool>>,
    },

    #[serde(rename = "real")]
    Real {
        #[serde(flatten)]
        common: RawFieldCommon<Option<f64>>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        min: Option<f64>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        max: Option<f64>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        if_out_of_bounds: Option<IfOutOfBounds>,
    },

    #[serde(rename = "integer")]
    Integer {
        #[serde(flatten)]
        common: RawFieldCommon<Option<i64>>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        min: Option<i64>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        max: Option<i64>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        if_out_of_bounds: Option<IfOutOfBounds>,
    },

    #[serde(rename = "timestamp")]
    Timestamp {
        #[serde(flatten)]
        common: RawFieldCommon<Option<RawTimeDefault>>,

        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        semantic: Option<RawTimestampSemantic>,
    },

    #[serde(rename = "own_guid")]
    OwnGuid {
        #[serde(flatten)]
        // TODO: check that serde does what I want with the `()` field.
        common: RawFieldCommon<()>,
        #[serde(default)]
        #[serde(skip_serializing_if = "is_default")]
        auto: Option<bool>,
    },

    #[serde(rename = "untyped_map")]
    UntypedMap {
        #[serde(flatten)]
        common: RawFieldCommon<Option<JsonObject>>,

        #[serde(default)]
        prefer_deletions: bool,
    },

    #[serde(rename = "record_set")]
    RecordSet {
        #[serde(flatten)]
        common: RawFieldCommon<Option<Vec<JsonObject>>>,

        // Note: required!
        id_key: String,

        #[serde(default)]
        prefer_deletions: bool,
    },
}

macro_rules! common_getter {
    ($name:ident, $T:ty) => {
        pub fn $name(&self) -> $T {
            match self {
                RawFieldType::Untyped { common, .. } => &common.$name,
                RawFieldType::Text { common, .. } => &common.$name,
                RawFieldType::Url { common, .. } => &common.$name,
                RawFieldType::Boolean { common, .. } => &common.$name,
                RawFieldType::Real { common, .. } => &common.$name,
                RawFieldType::Integer { common, .. } => &common.$name,
                RawFieldType::Timestamp { common, .. } => &common.$name,
                RawFieldType::OwnGuid { common, .. } => &common.$name,
                RawFieldType::RecordSet { common, .. } => &common.$name,
                RawFieldType::UntypedMap { common, .. } => &common.$name,
            }
        }
    };
}

impl RawFieldType {
    common_getter!(name, &str);
    common_getter!(local_name, &Option<String>);
    common_getter!(required, &bool);
    common_getter!(deprecated, &bool);
    common_getter!(composite_root, &Option<String>);
    common_getter!(merge, &Option<ParsedMerge>);
    common_getter!(change_preference, &Option<ChangePreference>);

    pub fn kind(&self) -> FieldKind {
        match self {
            RawFieldType::Untyped { .. } => FieldKind::Untyped,
            RawFieldType::Text { .. } => FieldKind::Text,
            RawFieldType::Url { .. } => FieldKind::Url,
            RawFieldType::Real { .. } => FieldKind::Real,
            RawFieldType::Integer { .. } => FieldKind::Integer,
            RawFieldType::Timestamp { .. } => FieldKind::Timestamp,
            RawFieldType::Boolean { .. } => FieldKind::Boolean,
            RawFieldType::OwnGuid { .. } => FieldKind::OwnGuid,
            RawFieldType::UntypedMap { .. } => FieldKind::UntypedMap,
            RawFieldType::RecordSet { .. } => FieldKind::RecordSet,
        }
    }

    pub fn get_merge(&self) -> Option<ParsedMerge> {
        self.merge().or_else(|| match self {
            RawFieldType::Timestamp {
                semantic: Some(RawTimestampSemantic::CreatedAt),
                ..
            } => Some(ParsedMerge::TakeMin),
            RawFieldType::Timestamp {
                semantic: Some(RawTimestampSemantic::UpdatedAt),
                ..
            } => Some(ParsedMerge::TakeMax),
            _ => None,
        })
    }

    pub fn has_default(&self) -> bool {
        match self {
            RawFieldType::Untyped { common, .. } => common.default.is_some(),
            RawFieldType::Text { common, .. } => common.default.is_some(),
            RawFieldType::Url { common, .. } => common.default.is_some(),
            RawFieldType::Boolean { common, .. } => common.default.is_some(),
            RawFieldType::Real { common, .. } => common.default.is_some(),
            RawFieldType::Integer { common, .. } => common.default.is_some(),
            RawFieldType::Timestamp { common, .. } => common.default.is_some(),
            RawFieldType::OwnGuid { .. } => false,
            RawFieldType::RecordSet { common, .. } => common.default.is_some(),
            RawFieldType::UntypedMap { common, .. } => common.default.is_some(),
        }
    }
}

/// This (and RawSpecialTime) are basically the same as TimestampDefault, just done
/// in such a way to make serde deserialize things the way we want for us.
#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum RawTimeDefault {
    Num(i64),
    Special(RawSpecialTime),
}

#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]
pub enum RawSpecialTime {
    #[serde(rename = "now")]
    Now,
}
#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]
pub enum RawTimestampSemantic {
    #[serde(rename = "created_at")]
    CreatedAt,

    #[serde(rename = "updated_at")]
    UpdatedAt,

    #[serde(other)]
    Unknown,
}

impl RawTimestampSemantic {
    pub fn into_semantic(self) -> Option<TimestampSemantic> {
        match self {
            RawTimestampSemantic::CreatedAt => Some(TimestampSemantic::CreatedAt),
            RawTimestampSemantic::UpdatedAt => Some(TimestampSemantic::UpdatedAt),
            RawTimestampSemantic::Unknown => None,
        }
    }
}
struct SchemaParser<'a> {
    input: &'a RawSchema,
    input_fields: HashMap<String, &'a RawFieldType>,

    parsed_fields: IndexVec<FieldIndex, Field>,
    dedupe_ons: HashSet<String>,
    possible_composite_roots: HashSet<String>,
    composite_members: HashSet<String>,
    indices: HashMap<String, FieldIndex>,
}

fn parse_version(v: &str, prop: SemverProp) -> SchemaResult<semver::Version> {
    semver::Version::parse(v).map_err(|err| SchemaError::VersionParseFailed {
        got: v.into(),
        prop,
        err,
    })
}

fn parse_version_req(
    o: &Option<String>,
    prop: SemverProp,
) -> SchemaResult<Option<semver::VersionReq>> {
    // when transpose is stable this could be simpler...
    if let Some(v) = o {
        Ok(Some(semver::VersionReq::parse(v).map_err(|err| {
            SchemaError::VersionReqParseFailed {
                got: v.clone(),
                prop,
                err,
            }
        })?))
    } else {
        Ok(None)
    }
}

fn compatible_version_req(v: &semver::Version) -> semver::VersionReq {
    let mut without_build = v.clone();
    without_build.build.clear();
    let version_req = format!("^ {}", without_build);
    match semver::VersionReq::parse(&version_req) {
        Ok(v) => v,
        Err(e) => {
            // Include this info in the panic string so we can debug if this ever happens.
            panic!(
                "Bug: Failed to parse our generated VersionReq {:?}: {}",
                version_req, e
            );
        }
    }
}

impl<'a> SchemaParser<'a> {
    pub fn new(repr: &'a RawSchema, _is_remote: bool) -> Self {
        let composite_roots = repr
            .fields
            .iter()
            .filter_map(|f| f.composite_root().clone())
            .collect::<HashSet<_>>();

        let composite_members = repr
            .fields
            .iter()
            .filter_map(|f| f.composite_root().as_ref().map(|_| f.name().into()))
            .chain(composite_roots.iter().cloned())
            .collect::<HashSet<_>>();

        let indices = repr
            .fields
            .iter()
            .enumerate()
            .map(|(i, f)| (f.name().to_string(), FieldIndex::from(i)))
            .collect();

        Self {
            input: repr,
            indices,
            input_fields: repr.fields.iter().map(|f| (f.name().into(), f)).collect(),
            parsed_fields: IndexVec::with_capacity(repr.fields.len()),
            // parsed_composites: HashMap::new(),
            dedupe_ons: repr.dedupe_on.iter().cloned().collect(),
            possible_composite_roots: composite_roots,
            composite_members,
        }
    }

    fn check_user_version(&self) -> SchemaResult<(semver::Version, semver::VersionReq)> {
        let cur_version = parse_version(&self.input.version, SemverProp::Version)?;
        let req_version =
            parse_version_req(&self.input.required_version, SemverProp::RequiredVersion)?
                .unwrap_or_else(|| compatible_version_req(&cur_version));

        ensure!(
            req_version.matches(&cur_version),
            SchemaError::LocalRequiredVersionNotCompatible(req_version, cur_version)
        );
        Ok((cur_version, req_version))
    }

    fn is_identity(&self, name: &str) -> bool {
        self.dedupe_ons.contains(name)
    }

    fn is_composite_root(&self, name: &str) -> bool {
        // Someone thinks it's a composite, at least.
        self.possible_composite_roots.contains(name)
    }

    pub fn parse(mut self) -> SchemaResult<RecordSchema> {
        let (version, required_version) = self.check_user_version()?;

        let unknown_feat = self
            .input
            .remerge_features_used
            .iter()
            .find(|f| !REMERGE_FEATURES_UNDERSTOOD.contains(&f.as_str()));
        if let Some(f) = unknown_feat {
            return Err(SchemaError::MissingRemergeFeature(f.clone()));
        }

        let mut own_guid_idx: Option<FieldIndex> = None;
        let mut updated_at_idx: Option<FieldIndex> = None;

        for (i, field) in self.input.fields.iter().enumerate() {
            let parsed = self.parse_field(field)?;
            // look for 'special' fields.
            match &parsed.ty {
                FieldType::OwnGuid { .. } => {
                    ensure!(own_guid_idx.is_none(), SchemaError::MultipleOwnGuid);
                    own_guid_idx = Some(i.into());
                }
                FieldType::Timestamp {
                    semantic: Some(TimestampSemantic::UpdatedAt),
                    ..
                } => {
                    ensure!(updated_at_idx.is_none(), SchemaError::MultipleUpdateAt);
                    updated_at_idx = Some(i.into());
                }
                _ => {}
            }

            self.parsed_fields.push(parsed);
        }

        let is_legacy = self.input.legacy;
        if is_legacy {
            ensure!(own_guid_idx.is_some(), SchemaError::LegacyMissingId);
        }

        self.check_dedupe_on()?;

        let (dedupe_on, composite_roots, composite_fields) = self.get_index_vecs();

        self.check_used_features(&self.input.remerge_features_used)?;

        Ok(RecordSchema {
            name: self.input.name.clone(),
            version,
            required_version,
            remerge_features_used: self.input.remerge_features_used.clone(),
            legacy: is_legacy,
            fields: self.parsed_fields,
            dedupe_on,
            composite_roots,
            composite_fields,
            field_map: self.indices,
            field_updated_at: updated_at_idx,
            field_own_guid: own_guid_idx,
        })
    }

    fn get_index_vecs(&self) -> (Vec<FieldIndex>, Vec<FieldIndex>, Vec<FieldIndex>) {
        let dedupe_on = self
            .input
            .dedupe_on
            .iter()
            .map(|s| *self.indices.get(s).unwrap())
            .collect();

        let composite_roots = self
            .parsed_fields
            .iter()
            .filter(|f| matches!(f.composite, Some(CompositeInfo::Root { .. })))
            .map(|f| f.own_idx)
            .collect();

        let composite_fields = self
            .parsed_fields
            .iter()
            .filter(|f| f.composite.is_some())
            .map(|f| f.own_idx)
            .collect();

        (dedupe_on, composite_roots, composite_fields)
    }

    fn check_dedupe_on(&self) -> Result<(), SchemaError> {
        assert!(self.parsed_fields.len() == self.input_fields.len());

        for name in &self.input.dedupe_on {
            let field_idx = *self
                .indices
                .get(name)
                .ok_or_else(|| SchemaError::UnknownDedupeOnField(name.clone()))?;

            if !self.composite_members.contains(name) {
                continue;
            }

            let field = &self.parsed_fields[field_idx];
            let root = match field.composite.as_ref().unwrap() {
                CompositeInfo::Member { root } => &self.parsed_fields[*root],
                CompositeInfo::Root { .. } => field,
            };
            let root_kids =
                if let CompositeInfo::Root { children } = &root.composite.as_ref().unwrap() {
                    children
                } else {
                    unreachable!("composite root isn't a root even though we just checked");
                };
            let all_id = std::iter::once(root.name.as_str())
                .chain(
                    root_kids
                        .iter()
                        .map(|k| self.parsed_fields[*k].name.as_str()),
                )
                .all(|name| self.is_identity(name));
            ensure!(all_id, SchemaError::PartialCompositeDedupeOn);
        }
        Ok(())
    }

    fn parse_field(&self, field: &RawFieldType) -> SchemaResult<Field> {
        let field_name = field.name();
        let local_name = field.local_name().clone();
        self.check_field_name(field_name, &local_name)?;

        self.check_type_restrictions(field).named(field_name)?;

        let merge = field.get_merge();

        if field.composite_root().is_some() {
            self.check_composite_member_field(field, merge)
                .named(field_name)?;
        }

        if self.is_composite_root(field_name) {
            self.check_composite_root_field(field, merge)
                .named(field_name)?;
        }

        // using TakeNewest as the default is not really necessarially true.
        let merge = merge.unwrap_or(ParsedMerge::TakeNewest);

        let result_field_type: FieldType = self.get_field_type(merge, field)?;

        if result_field_type.uses_untyped_merge(UntypedMerge::Duplicate)
            && !self.input.dedupe_on.is_empty()
        {
            throw!(SchemaError::DedupeOnWithDuplicateField);
        }

        let deprecated = *field.deprecated();
        let required = *field.required();
        let change_preference = *field.change_preference();

        if deprecated {
            ensure!(
                !self.is_identity(field.name()),
                SchemaError::DeprecatedFieldDedupeOn(field_name.into())
            );
        }
        ensure!(
            !(deprecated && required),
            FieldError::DeprecatedRequiredConflict.named(field_name)
        );

        let composite = self.get_composite_info(field);
        let name = field_name.to_string();
        let f = Field {
            local_name: local_name.unwrap_or_else(|| name.clone()),
            name,
            deprecated,
            required,
            ty: result_field_type,
            change_preference,
            own_idx: *self.indices.get(field_name).unwrap(),
            composite,
        };
        Ok(f)
    }

    // Note: Asserts if anything is wrong, caller is expected to check all that first.
    fn get_composite_info(&self, field: &RawFieldType) -> Option<CompositeInfo> {
        let field_name = field.name();
        if self.is_composite_root(field_name) {
            let children = self
                .input_fields
                .iter()
                .filter(|(_, f)| {
                    f.composite_root().as_ref().map(|r| r.as_str()) == Some(field_name)
                })
                .map(|(n, _)| *self.indices.get(n).unwrap())
                .collect();

            Some(CompositeInfo::Root { children })
        } else if let Some(root) = field.composite_root() {
            let root_idx = self.indices.get(root).unwrap();
            Some(CompositeInfo::Member { root: *root_idx })
        } else {
            None
        }
    }

    fn check_field_name(&self, field_name: &str, local_name: &Option<String>) -> SchemaResult<()> {
        ensure!(
            self.parsed_fields
                .iter()
                .find(|f| f.name == field_name || f.local_name == field_name)
                .is_none(),
            SchemaError::DuplicateField(field_name.into())
        );
        ensure!(
            is_valid_field_ident(field_name),
            FieldError::InvalidName.named(field_name)
        );
        if let Some(n) = local_name {
            ensure!(
                self.parsed_fields
                    .iter()
                    .find(|f| &f.name == n || &f.local_name == n)
                    .is_none(),
                SchemaError::DuplicateField(n.into())
            );
            ensure!(
                is_valid_field_ident(n),
                FieldError::InvalidName.named(field_name)
            );
        }
        Ok(())
    }

    fn check_type_restrictions(&self, field: &RawFieldType) -> Result<(), FieldError> {
        let name = field.name();
        let kind = field.kind();
        let restriction = TypeRestriction::for_kind(kind);
        // could be `ensure!` but they got hard to read.
        if !restriction.can_dedupe_on && self.is_identity(name) {
            throw!(FieldError::BadTypeInDedupeOn(kind));
        }
        if restriction.forces_merge_strat && field.merge().is_some() {
            throw!(FieldError::TypeForbidsMergeStrat(kind));
        }
        if !restriction.valid_composite_member && field.composite_root().is_some() {
            throw!(FieldError::TypeNotComposite(kind));
        }
        Ok(())
    }

    fn check_composite_member_field(
        &self,
        field: &RawFieldType,
        merge: Option<ParsedMerge>,
    ) -> Result<(), FieldError> {
        let root = field
            .composite_root()
            .as_ref()
            .expect("Should check before calling");
        ensure!(merge.is_none(), FieldError::CompositeFieldMergeStrat);
        ensure!(
            self.input_fields.contains_key(root),
            FieldError::UnknownCompositeRoot(root.clone())
        );
        Ok(())
    }

    fn check_composite_root_field(
        &self,
        field: &RawFieldType,
        merge: Option<ParsedMerge>,
    ) -> Result<(), FieldError> {
        let field_name = field.name();
        assert!(self.is_composite_root(field_name));
        ensure!(
            field.composite_root().is_none(),
            FieldError::CompositeRecursion
        );
        match merge {
            None
            | Some(ParsedMerge::TakeNewest)
            | Some(ParsedMerge::PreferRemote)
            | Some(ParsedMerge::TakeMin)
            | Some(ParsedMerge::TakeMax) => {
                // all good.
            }

            Some(other) => {
                throw!(FieldError::CompositeRootInvalidMergeStrat(other));
            }
        }
        Ok(())
    }

    fn check_used_features(&self, declared_features: &[String]) -> SchemaResult<()> {
        for f in &self.parsed_fields {
            if let FieldType::RecordSet { .. } = &f.ty {
                if !declared_features.contains(&"record_set".to_string()) {
                    return Err(SchemaError::UndeclaredFeatureRequired(
                        "record_set".to_string(),
                    ));
                }
            }
        }
        Ok(())
    }

    fn get_field_type(&self, merge: ParsedMerge, field: &RawFieldType) -> SchemaResult<FieldType> {
        let field_name = field.name();
        let bad_merge = || {
            FieldError::IllegalMergeForType {
                ty: field.kind(),
                merge,
            }
            .named(field_name)
        };
        Ok(match field {
            RawFieldType::Untyped { common } => {
                let merge = merge.to_untyped_merge(field).ok_or_else(bad_merge)?;
                FieldType::Untyped {
                    merge,
                    default: common.default.clone(),
                }
            }
            RawFieldType::Boolean { common } => {
                let merge = merge.to_boolean_merge(field).ok_or_else(bad_merge)?;
                FieldType::Boolean {
                    merge,
                    default: common.default,
                }
            }
            RawFieldType::Text { common } => {
                let merge = merge.to_text_merge(field).ok_or_else(bad_merge)?;
                FieldType::Text {
                    merge,
                    default: common.default.clone(),
                }
            }
            RawFieldType::Url { common, is_origin } => {
                let merge = merge.to_text_merge(field).ok_or_else(bad_merge)?;
                let default = if let Some(url) = &common.default {
                    let u = Url::parse(url)
                        .map_err(|e| FieldError::BadDefaultUrl(url.clone(), e))
                        .named(field_name)?;
                    if *is_origin && !valid_origin_only_url(&u) {
                        return Err(FieldError::BadDefaultOrigin(u.into_string()).named(field_name));
                    }
                    Some(u)
                } else {
                    None
                };
                FieldType::Url {
                    merge,
                    default,
                    is_origin: *is_origin,
                }
            }
            RawFieldType::Real {
                common,
                min,
                max,
                if_out_of_bounds,
            } => {
                self.check_number_bounds(field, min, max, *if_out_of_bounds, &common.default)
                    .named(field_name)?;
                let merge = merge.to_number_merge(field).ok_or_else(bad_merge)?;
                FieldType::Real {
                    merge,
                    min: *min,
                    max: *max,
                    if_out_of_bounds: if_out_of_bounds.unwrap_or(IfOutOfBounds::Discard),
                    default: common.default,
                }
            }
            RawFieldType::Integer {
                common,
                min,
                max,
                if_out_of_bounds,
            } => {
                self.check_number_bounds(field, min, max, *if_out_of_bounds, &common.default)
                    .named(field_name)?;
                let merge = merge.to_number_merge(field).ok_or_else(bad_merge)?;
                FieldType::Integer {
                    merge,
                    min: *min,
                    max: *max,
                    if_out_of_bounds: if_out_of_bounds.unwrap_or(IfOutOfBounds::Discard),
                    default: common.default,
                }
            }
            RawFieldType::Timestamp { common, semantic } => {
                let merge = merge.to_timestamp_merge(field).ok_or_else(bad_merge)?;
                self.get_timestamp_field(merge, common, *semantic)
                    .named(field_name)?
            }
            RawFieldType::OwnGuid { auto, .. } => FieldType::OwnGuid {
                auto: auto.unwrap_or(true),
            },
            RawFieldType::UntypedMap {
                common,
                prefer_deletions,
            } => FieldType::UntypedMap {
                prefer_deletions: *prefer_deletions,
                default: common.default.clone(),
            },
            RawFieldType::RecordSet {
                common,
                id_key,
                prefer_deletions,
            } => self
                .get_record_set_field(common, id_key, *prefer_deletions)
                .named(field_name)?,
        })
    }

    fn get_timestamp_field(
        &self,
        merge: TimestampMerge,
        common: &RawFieldCommon<Option<RawTimeDefault>>,
        semantic: Option<RawTimestampSemantic>,
    ) -> Result<FieldType, FieldError> {
        let semantic = if let Some(sem) = semantic.and_then(|ts| ts.into_semantic()) {
            let want = sem.required_merge();
            ensure!(
                merge == want,
                FieldError::BadMergeForTimestampSemantic {
                    sem,
                    want,
                    got: merge,
                }
            );
            Some(sem)
        } else {
            None
        };
        let tsd: Option<TimestampDefault> = common.default.map(|d| match d {
            RawTimeDefault::Num(v) => TimestampDefault::Value(v),
            RawTimeDefault::Special(RawSpecialTime::Now) => TimestampDefault::Now,
        });

        if let Some(TimestampDefault::Value(default)) = tsd {
            ensure!(
                default >= crate::ms_time::EARLIEST_SANE_TIME,
                FieldError::DefaultTimestampTooOld,
            );
        }
        Ok(FieldType::Timestamp {
            merge,
            semantic,
            default: tsd,
        })
    }

    fn get_record_set_field(
        &self,
        common: &RawFieldCommon<Option<Vec<JsonObject>>>,
        id_key: &str,
        prefer_deletions: bool,
    ) -> Result<FieldType, FieldError> {
        if let Some(s) = &common.default {
            let mut seen: HashSet<&str> = HashSet::with_capacity(s.len());
            for r in s {
                let id = r.get(id_key).ok_or_else(|| {
                    FieldError::BadRecordSetDefault(BadRecordSetDefaultKind::IdKeyMissing)
                })?;
                if let JsonValue::String(s) = id {
                    ensure!(
                        !seen.contains(s.as_str()),
                        FieldError::BadRecordSetDefault(BadRecordSetDefaultKind::IdKeyDupe),
                    );
                    seen.insert(s);
                } else {
                    // We could probably allow numbers...
                    throw!(FieldError::BadRecordSetDefault(
                        BadRecordSetDefaultKind::IdKeyInvalidType
                    ));
                }
            }
        }
        Ok(FieldType::RecordSet {
            default: common.default.clone(),
            id_key: id_key.into(),
            prefer_deletions,
        })
    }

    fn check_number_bounds<T: Copy + PartialOrd + BoundedNum>(
        &self,
        field: &RawFieldType,
        min: &Option<T>,
        max: &Option<T>,
        if_oob: Option<IfOutOfBounds>,
        default: &Option<T>, // f: &RawFieldType
    ) -> Result<(), FieldError> {
        ensure!(
            min.map_or(true, |v| v.sane_value()),
            FieldError::BadNumBounds,
        );
        ensure!(
            max.map_or(true, |v| v.sane_value()),
            FieldError::BadNumBounds,
        );
        if min.is_some() || max.is_some() {
            ensure!(if_oob.is_some(), FieldError::NoBoundsCheckInfo);
        }
        ensure!(
            !matches!((min, max), (Some(lo), Some(hi)) if hi < lo),
            FieldError::BadNumBounds,
        );
        if max.is_some() {
            ensure!(
                field.get_merge() != Some(ParsedMerge::TakeSum),
                FieldError::MergeTakeSumNoMax,
            );
        }

        if let Some(d) = default {
            let min = min.unwrap_or(T::min_max_defaults().0);
            let max = max.unwrap_or(T::min_max_defaults().1);
            ensure!(min <= *d && *d <= max, FieldError::BadNumDefault);
        }
        Ok(())
    }
}

// way to avoid having to duplicate the f64 bound handing stuff for i64
trait BoundedNum: Sized {
    fn sane_value(self) -> bool;
    fn min_max_defaults() -> (Self, Self);
}

impl BoundedNum for f64 {
    fn sane_value(self) -> bool {
        !self.is_nan() && !self.is_infinite()
    }
    fn min_max_defaults() -> (Self, Self) {
        (std::f64::NEG_INFINITY, std::f64::INFINITY)
    }
}

impl BoundedNum for i64 {
    fn sane_value(self) -> bool {
        true
    }
    fn min_max_defaults() -> (Self, Self) {
        (std::i64::MIN, std::i64::MAX)
    }
}

fn is_valid_field_ident(s: &str) -> bool {
    !s.is_empty()
        && s.len() < 128
        && s.is_ascii()
        && s.bytes()
            .all(|b| b == b'$' || crate::util::is_base64url_byte(b))
}

fn valid_origin_only_url(u: &Url) -> bool {
    !u.has_authority()
        && !u.cannot_be_a_base()
        && u.path() == "/"
        && u.query().is_none()
        && u.fragment().is_none()
}

#[derive(Debug, Clone, PartialEq)]
struct TypeRestriction {
    can_dedupe_on: bool,
    valid_composite_member: bool,
    forces_merge_strat: bool,
}

impl TypeRestriction {
    fn new(can_dedupe_on: bool, valid_composite_member: bool, forces_merge_strat: bool) -> Self {
        Self {
            can_dedupe_on,
            valid_composite_member,
            forces_merge_strat,
        }
    }
    fn permit_all() -> Self {
        Self::new(true, true, false)
    }

    fn forbid_all() -> Self {
        Self::new(false, false, true)
    }

    fn for_kind(k: FieldKind) -> Self {
        match k {
            FieldKind::Untyped => TypeRestriction::permit_all(),
            FieldKind::Text => TypeRestriction::permit_all(),
            FieldKind::Url => TypeRestriction::permit_all(),
            FieldKind::Integer => TypeRestriction::new(false, true, false),
            FieldKind::Timestamp => TypeRestriction::new(false, true, false),
            FieldKind::Real => TypeRestriction::new(false, true, false),
            FieldKind::Boolean => TypeRestriction::permit_all(),

            FieldKind::OwnGuid => TypeRestriction::forbid_all(),
            FieldKind::UntypedMap => TypeRestriction::forbid_all(),
            FieldKind::RecordSet => TypeRestriction::forbid_all(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum ParsedMerge {
    #[serde(rename = "take_newest")]
    TakeNewest,
    #[serde(rename = "prefer_remote")]
    PreferRemote,
    #[serde(rename = "duplicate")]
    Duplicate,
    #[serde(rename = "take_min")]
    TakeMin,
    #[serde(rename = "take_max")]
    TakeMax,
    #[serde(rename = "take_sum")]
    TakeSum,
    #[serde(rename = "prefer_false")]
    PreferFalse,
    #[serde(rename = "prefer_true")]
    PreferTrue,
}

impl std::fmt::Display for ParsedMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ParsedMerge::TakeNewest => f.write_str("take_newest"),
            ParsedMerge::PreferRemote => f.write_str("prefer_remote"),
            ParsedMerge::Duplicate => f.write_str("duplicate"),
            ParsedMerge::TakeMin => f.write_str("take_min"),
            ParsedMerge::TakeMax => f.write_str("take_max"),
            ParsedMerge::TakeSum => f.write_str("take_sum"),
            ParsedMerge::PreferFalse => f.write_str("prefer_false"),
            ParsedMerge::PreferTrue => f.write_str("prefer_true"),
        }
    }
}

impl ParsedMerge {
    fn to_untyped_merge(self, f: &RawFieldType) -> Option<UntypedMerge> {
        if f.composite_root().is_some() {
            return Some(UntypedMerge::CompositeMember);
        }
        match self {
            ParsedMerge::TakeNewest => Some(UntypedMerge::TakeNewest),
            ParsedMerge::PreferRemote => Some(UntypedMerge::PreferRemote),
            ParsedMerge::Duplicate => Some(UntypedMerge::Duplicate),
            _ => None,
        }
    }

    fn to_text_merge(self, f: &RawFieldType) -> Option<TextMerge> {
        Some(TextMerge::Untyped(self.to_untyped_merge(f)?))
    }

    fn to_number_merge(self, f: &RawFieldType) -> Option<NumberMerge> {
        if let Some(u) = self.to_untyped_merge(f) {
            Some(NumberMerge::Untyped(u))
        } else {
            match self {
                ParsedMerge::TakeMin => Some(NumberMerge::TakeMin),
                ParsedMerge::TakeMax => Some(NumberMerge::TakeMax),
                ParsedMerge::TakeSum => Some(NumberMerge::TakeSum),
                _ => None,
            }
        }
    }

    fn to_timestamp_merge(self, f: &RawFieldType) -> Option<TimestampMerge> {
        if let Some(u) = self.to_untyped_merge(f) {
            Some(TimestampMerge::Untyped(u))
        } else {
            match self {
                ParsedMerge::TakeMin => Some(TimestampMerge::TakeMin),
                ParsedMerge::TakeMax => Some(TimestampMerge::TakeMax),
                _ => None,
            }
        }
    }

    fn to_boolean_merge(self, f: &RawFieldType) -> Option<BooleanMerge> {
        if let Some(u) = self.to_untyped_merge(f) {
            Some(BooleanMerge::Untyped(u))
        } else {
            match self {
                ParsedMerge::PreferTrue => Some(BooleanMerge::PreferTrue),
                ParsedMerge::PreferFalse => Some(BooleanMerge::PreferFalse),
                _ => None,
            }
        }
    }
}
