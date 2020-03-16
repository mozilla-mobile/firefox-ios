/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::record_types::MetaGlobalRecord;
use crate::state::PersistedGlobalState;
use crate::CollSyncIds;
use serde_json::Value;

/// Given a string persisted as our old GlobalState V1 struct, extract out
/// the sync IDs for the collection, plus a string which should be used as the
/// new "global persisted state" (which holds the declined engines).
/// Returns (None, None) in early error cases (eg, invalid JSON, wrong schema
/// version etc). Otherwise, you can expect the returned global state to be
/// Some, even if the CollSyncIds is None (which can happen if the engine is
/// missing, or flagged for reset)
pub fn extract_v1_state(
    state: Option<String>,
    collection: &'static str,
) -> (Option<CollSyncIds>, Option<String>) {
    let state = match state {
        Some(s) => s,
        None => return (None, None),
    };
    let j: serde_json::Value = match serde_json::from_str(&state) {
        Ok(j) => j,
        Err(_) => return (None, None),
    };
    if Some("V1") != j.get("schema_version").and_then(Value::as_str) {
        return (None, None);
    }

    let empty = Vec::<serde_json::Value>::new();
    // Get the global and payload out so we can obtain declined first.
    let global = match j.get("global").and_then(Value::as_object) {
        None => return (None, None),
        Some(v) => v,
    };
    // payload is itself a string holding json - so re-parse.
    let meta_global = match global["payload"]
        .as_str()
        .and_then(|s| serde_json::from_str::<MetaGlobalRecord>(s).ok())
    {
        Some(p) => p,
        None => return (None, None),
    };
    let pgs = PersistedGlobalState::V2 {
        declined: Some(meta_global.declined),
    };
    let new_global_state = serde_json::to_string(&pgs).ok();

    // See if the collection needs a reset.
    for change in j
        .get("engine_state_changes")
        .and_then(Value::as_array)
        .unwrap_or(&empty)
    {
        if change.as_str() == Some("ResetAll") {
            return (None, new_global_state);
        }
        // other resets we care about are objects - `"Reset":name` and
        // `"ResetAllExcept":[name, name]`
        if let Some(change_ob) = change.as_object() {
            if change_ob.get("Reset").and_then(Value::as_str) == Some(collection) {
                // this engine is reset.
                return (None, new_global_state);
            }
            if let Some(except_array) = change_ob.get("ResetAllExcept").and_then(Value::as_array) {
                // We have what appears to be a valid list of exceptions to reset.
                // If every one lists an engine that isn't us, we are being reset.
                if except_array
                    .iter()
                    .filter_map(Value::as_str)
                    .all(|s| s != collection)
                {
                    return (None, new_global_state);
                }
            }
        }
    }

    // Try and find the sync guids in the global payload.
    let gsid = meta_global.sync_id;
    let ids = meta_global.engines.get(collection).map(|coll| CollSyncIds {
        global: gsid,
        coll: coll.sync_id.clone(),
    });
    (ids, new_global_state)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Test our destructuring of the old persisted global state.

    fn get_state_with_engine_changes_and_declined(changes: &str, declined: &str) -> String {
        // This is a copy of the V1 persisted state.
        // Note some things have been omitted or trimmed from what's actually persisted
        // (eg, top-level "config" is removed, "collections" is removed (that's only timestamps)
        // hmac keys have array elts removed, global/payload has engines removed, etc)
        // Note also that all `{` and `}` have been doubled for use in format!(),
        // which we use to patch-in engine_state_changes.
        format!(
            r#"{{
            "schema_version":"V1",
            "global":{{
                "id":"global",
                "collection":"",
                "payload":"{{\"syncID\":\"qZKAMjhyV6Ti\",\"storageVersion\":5,\"engines\":{{\"addresses\":{{\"version\":1,\"syncID\":\"8M-HfX6dm-pD\"}},\"bookmarks\":{{\"version\":2,\"syncID\":\"AVXtnKkH5OTi\"}}}},\"declined\":[{declined}]}}"
            }},
            "keys":{{"timestamp":1548214240.34,"default":{{"enc_key":[36,76],"mac_key":[222,241]}},"collections":{{}}}},
            "engine_state_changes":[
                {changes}
            ]
        }}"#,
            changes = changes,
            declined = declined
        )
    }

    fn get_state_with_engine_changes(changes: &str) -> String {
        get_state_with_engine_changes_and_declined(changes, "")
    }

    fn make_csids(global: &str, coll: &str) -> Option<CollSyncIds> {
        Some(CollSyncIds {
            global: global.into(),
            coll: coll.into(),
        })
    }

    fn extract_v1_ids_only(state: Option<String>, collection: &'static str) -> Option<CollSyncIds> {
        let (sync_ids, new_state) = extract_v1_state(state, collection);
        // tests which use this never have declined, so make sure our
        // state reflects that.
        let expected_state = serde_json::to_string(&PersistedGlobalState::V2 {
            declined: Some(Vec::<String>::new()),
        })
        .expect("should stringify");
        assert_eq!(new_state, Some(expected_state));
        sync_ids
    }

    #[test]
    fn test_extract_state_simple() {
        let s = get_state_with_engine_changes("");
        assert_eq!(
            extract_v1_ids_only(Some(s.clone()), "addresses"),
            make_csids("qZKAMjhyV6Ti", "8M-HfX6dm-pD")
        );
        assert_eq!(
            extract_v1_ids_only(Some(s), "bookmarks"),
            make_csids("qZKAMjhyV6Ti", "AVXtnKkH5OTi")
        );
    }

    #[test]
    fn test_extract_state_simple_with_declined() {
        // Note that 'declined' is stringified json, hence the extra back-slashes.
        let s = get_state_with_engine_changes_and_declined("", "\\\"foo\\\"");
        let expected_state = serde_json::to_string(&PersistedGlobalState::V2 {
            declined: Some(vec!["foo".to_string()]),
        })
        .unwrap();
        assert_eq!(
            extract_v1_state(Some(s), "addresses"),
            (
                make_csids("qZKAMjhyV6Ti", "8M-HfX6dm-pD"),
                Some(expected_state)
            )
        );
    }

    #[test]
    fn test_extract_with_engine_reset_all() {
        let s = get_state_with_engine_changes("\"ResetAll\"");
        assert_eq!(extract_v1_ids_only(Some(s), "addresses"), None);
    }

    #[test]
    fn test_extract_with_engine_reset() {
        let s = get_state_with_engine_changes("{\"Reset\" : \"addresses\"}");
        assert_eq!(extract_v1_ids_only(Some(s.clone()), "addresses"), None);
        // bookmarks wasn't reset.
        assert_eq!(
            extract_v1_ids_only(Some(s), "bookmarks"),
            make_csids("qZKAMjhyV6Ti", "AVXtnKkH5OTi")
        );
    }

    #[test]
    fn test_extract_with_engine_reset_except() {
        let s = get_state_with_engine_changes("{\"ResetAllExcept\" : [\"addresses\"]}");
        // addresses is the exception
        assert_eq!(
            extract_v1_ids_only(Some(s.clone()), "addresses"),
            make_csids("qZKAMjhyV6Ti", "8M-HfX6dm-pD")
        );
        // bookmarks was reset.
        assert_eq!(extract_v1_ids_only(Some(s), "bookmarks"), None);
    }
}
