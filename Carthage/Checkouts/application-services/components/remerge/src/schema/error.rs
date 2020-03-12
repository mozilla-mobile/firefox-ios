/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::desc::*;
use super::json::ParsedMerge;
use super::merge_kinds::*;
use failure::Fail;

#[derive(Debug, Clone, Fail)]
pub enum FieldError {
    #[fail(display = "Record field names must be ascii, nonempty, and contain [a-zA-Z0-9_$]")]
    InvalidName,

    #[fail(
        display = "Merge strategy '{:?}' and type '{:?}' are not compatible.",
        merge, ty
    )]
    IllegalMergeForType { ty: FieldKind, merge: ParsedMerge },

    #[fail(display = "Composite fields may not specify a merge strategy")]
    CompositeFieldMergeStrat,

    #[fail(display = "Cannot find composite_root '{}'", _0)]
    UnknownCompositeRoot(String),

    #[fail(display = "Field of type '{}' may not be part of dedupe_on", _0)]
    BadTypeInDedupeOn(FieldKind),

    #[fail(display = "Invalid merge strategy for composite root: {}", _0)]
    CompositeRootInvalidMergeStrat(ParsedMerge),

    #[fail(display = "Fields of type '{}' may not specify a merge strategy", _0)]
    TypeForbidsMergeStrat(FieldKind),

    #[fail(display = "Fields of type '{}' may not be part of a composite", _0)]
    TypeNotComposite(FieldKind),

    #[fail(display = "\"deprecated\" and \"required\" may not both be true on a field")]
    DeprecatedRequiredConflict,

    #[fail(display = "Missing `if_out_of_bounds` on bounded number")]
    NoBoundsCheckInfo,

    #[fail(display = "Bounded number max/min are not finite, or 'max' value is less than 'min'.")]
    BadNumBounds,

    #[fail(display = "Default value for bounded number is not inside the bounds")]
    BadNumDefault,

    #[fail(display = "Composite roots may not have numeric clamping (discard is allowed)")]
    NumberClampOnCompositeRoot,

    #[fail(display = "A field's composite root cannot be part of a composite")]
    CompositeRecursion,

    #[fail(
        display = "Invalid URL \"{}\" as default value of `url` field: {}",
        _0, _1
    )]
    BadDefaultUrl(String, url::ParseError),

    #[fail(
        display = "is_origin URL field has default value of \"{}\", which isn't an origin",
        _0
    )]
    BadDefaultOrigin(String),

    #[fail(
        display = "Semantic timestamp '{}' must use the '{}' merge strategy (got '{}').",
        sem, want, got
    )]
    BadMergeForTimestampSemantic {
        sem: TimestampSemantic,
        want: TimestampMerge,
        got: TimestampMerge,
    },

    // There are a few cases here, it doesn't feel worth it to merge them
    // somehow.
    #[fail(display = "record_set has illegal default value: {}", _0)]
    BadRecordSetDefault(BadRecordSetDefaultKind),

    #[fail(display = "merge strategy 'take_sum' forbids specifying a 'max' value")]
    MergeTakeSumNoMax,

    #[fail(
        display = "Illegal default timestamp. Must be after the release of the first web browser"
    )]
    DefaultTimestampTooOld,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum BadRecordSetDefaultKind {
    IdKeyMissing,
    IdKeyDupe,
    IdKeyInvalidType,
}

impl std::fmt::Display for BadRecordSetDefaultKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use BadRecordSetDefaultKind::*;
        match self {
            IdKeyMissing => f.write_str("contains an item without an id_key"),
            IdKeyDupe => f.write_str("contains an item with a duplicate id_key"),
            IdKeyInvalidType => f.write_str(
                "contains an item with an id_key with an invalid type (must be a string)",
            ),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SemverProp {
    Version,
    RequiredVersion,
}

impl std::fmt::Display for SemverProp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use SemverProp::*;
        match self {
            Version => f.write_str("version"),
            RequiredVersion => f.write_str("required_version"),
        }
    }
}

#[derive(Debug, Fail)]
pub enum SchemaError {
    #[fail(display = "Schema format error: {}", _0)]
    FormatError(#[fail(cause)] serde_json::Error),

    #[fail(display = "Cannot parse format_version: {}", _0)]
    WrongFormatVersion(usize),

    #[fail(
        display = "Failed to parse semantic version string {:?} from property '{}': {}",
        got, prop, err
    )]
    VersionParseFailed {
        prop: SemverProp,
        got: String,
        #[fail(cause)]
        err: semver::SemVerError,
    },

    #[fail(
        display = "Failed to parse semantic version requirement {:?} from property '{}': {}",
        got, prop, err
    )]
    VersionReqParseFailed {
        prop: SemverProp,
        got: String,
        #[fail(cause)]
        err: semver::ReqParseError,
    },

    #[fail(
        display = "Schema required_version '{}' and version '{}' are not compatible.",
        _0, _1
    )]
    LocalRequiredVersionNotCompatible(semver::VersionReq, semver::Version),

    #[fail(
        display = "Remerge feature {} is required but not supported locally",
        _0
    )]
    MissingRemergeFeature(String),
    #[fail(
        display = "Remerge feature {} is required but not listed in remerge_features_used",
        _0
    )]
    UndeclaredFeatureRequired(String),

    #[fail(display = "Duplicate field: {}", _0)]
    DuplicateField(String),

    #[fail(display = "Field '{}': {}", _0, _1)]
    FieldError(String, #[fail(cause)] FieldError),

    #[fail(
        display = "Composite root '{}' has an illegal type / merge combination",
        _0
    )]
    IllegalCompositeRoot(String),

    #[fail(
        display = "A record with a non-empty dedupe_on list may not use the `duplicate` merge strategy"
    )]
    DedupeOnWithDuplicateField,

    #[fail(display = "Unknown field in dedupe_on: {}", _0)]
    UnknownDedupeOnField(String),

    #[fail(display = "Deprecated field in dedupe_on: {}", _0)]
    DeprecatedFieldDedupeOn(String),

    #[fail(display = "Only part of a composite field appears in dedupe_on")]
    PartialCompositeDedupeOn,

    #[fail(display = "Legacy collections must have an `OwnId` field.")]
    LegacyMissingId,

    #[fail(display = "Only one field with the 'updated_at' timestamp semantic is allowed")]
    MultipleUpdateAt,

    #[fail(display = "Only one 'own_guid' field is allowd")]
    MultipleOwnGuid,

    #[fail(display = "Remote schema missing 'remerge_features_used'")]
    RemoteMissingRemergeFeaturesUsed,

    #[fail(
        display = "'required_remerge_version' specified locally (as \"{}\"), but it's greater than our actual version \"{}\"",
        _0, _1
    )]
    LocalRemergeVersionFailsLocalRequired(semver::VersionReq, semver::Version),

    #[fail(display = "'remerge_version' can not be specified locally.")]
    LocalRemergeVersionSpecified,

    #[fail(
        display = "Locked out of remote schema since our remerge_version \"{}\" is not compatible with requirement \"{}\"",
        version, req
    )]
    LocalRemergeVersionFailsRemoteRequired {
        version: semver::Version,
        req: semver::VersionReq,
    },

    #[fail(
        display = "Remote remerge_version \"{}\" is not compatible with its own listed requirement \"{}\"",
        version, req
    )]
    RemoteRemergeVersionFailsOwnRequirement {
        version: semver::Version,
        req: semver::VersionReq,
    },
}

pub type SchemaResult<T> = std::result::Result<T, SchemaError>;
