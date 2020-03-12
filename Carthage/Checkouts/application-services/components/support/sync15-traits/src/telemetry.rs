/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! Manage recording sync telemetry. Assumes some external telemetry
//! library/code which manages submitting.

use std::collections::HashMap;
use std::time;

use serde::{ser, Serialize, Serializer};

// A test helper, used by the many test modules below.
#[cfg(test)]
fn assert_json<T: ?Sized>(v: &T, expected: serde_json::Value)
where
    T: serde::Serialize,
{
    assert_eq!(
        serde_json::to_value(&v).expect("should get a value"),
        expected
    );
}

/// What we record for 'when' and 'took' in a telemetry record.
#[derive(Debug, Serialize)]
struct WhenTook {
    when: f64,
    #[serde(skip_serializing_if = "crate::skip_if_default")]
    took: u64,
}

/// What we track while recording 'when' and 'took. It serializes as a WhenTook,
/// except when .finished() hasn't been called, in which case it panics.
#[derive(Debug)]
enum Stopwatch {
    Started(time::SystemTime, time::Instant),
    Finished(WhenTook),
}

impl Default for Stopwatch {
    fn default() -> Self {
        Stopwatch::new()
    }
}

impl Stopwatch {
    fn new() -> Self {
        Stopwatch::Started(time::SystemTime::now(), time::Instant::now())
    }

    // For tests we don't want real timestamps because we test against literals.
    #[cfg(test)]
    fn finished(&self) -> Self {
        Stopwatch::Finished(WhenTook { when: 0.0, took: 0 })
    }

    #[cfg(not(test))]
    fn finished(&self) -> Self {
        match self {
            Stopwatch::Started(st, si) => {
                let std = st.duration_since(time::UNIX_EPOCH).unwrap_or_default();
                let when = std.as_secs() as f64; // we don't want sub-sec accuracy. Do we need to write a float?

                let sid = si.elapsed();
                let took = sid.as_secs() * 1000 + (u64::from(sid.subsec_nanos()) / 1_000_000);
                Stopwatch::Finished(WhenTook { when, took })
            }
            _ => {
                unreachable!("can't finish twice");
            }
        }
    }
}

impl Serialize for Stopwatch {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            Stopwatch::Started(_, _) => Err(ser::Error::custom("StopWatch has not been finished")),
            Stopwatch::Finished(c) => c.serialize(serializer),
        }
    }
}

#[cfg(test)]
mod stopwatch_tests {
    use super::*;

    // A wrapper struct because we flatten - this struct should serialize with
    // 'when' and 'took' keys (but with no 'sw'.)
    #[derive(Debug, Serialize)]
    struct WT {
        #[serde(flatten)]
        sw: Stopwatch,
    }

    #[test]
    fn test_not_finished() {
        let wt = WT {
            sw: Stopwatch::new(),
        };
        serde_json::to_string(&wt).expect_err("unfinished stopwatch should fail");
    }

    #[test]
    fn test() {
        assert_json(
            &WT {
                sw: Stopwatch::Finished(WhenTook { when: 1.0, took: 1 }),
            },
            serde_json::json!({"when": 1.0, "took": 1}),
        );
        assert_json(
            &WT {
                sw: Stopwatch::Finished(WhenTook { when: 1.0, took: 0 }),
            },
            serde_json::json!({"when": 1.0}),
        );
    }
}

/// A generic "Event" - suitable for all kinds of pings (although this module
/// only cares about the sync ping)
#[derive(Debug, Serialize)]
pub struct Event {
    // We use static str references as we expect values to be literals.
    object: &'static str,

    method: &'static str,

    // Maybe "value" should be a string?
    #[serde(skip_serializing_if = "Option::is_none")]
    value: Option<&'static str>,

    // we expect the keys to be literals but values are real strings.
    #[serde(skip_serializing_if = "Option::is_none")]
    extra: Option<HashMap<&'static str, String>>,
}

impl Event {
    pub fn new(object: &'static str, method: &'static str) -> Self {
        assert!(object.len() <= 20);
        assert!(method.len() <= 20);
        Self {
            object,
            method,
            value: None,
            extra: None,
        }
    }

    pub fn value(mut self, v: &'static str) -> Self {
        assert!(v.len() <= 80);
        self.value = Some(v);
        self
    }

    pub fn extra(mut self, key: &'static str, val: String) -> Self {
        assert!(key.len() <= 15);
        assert!(val.len() <= 85);
        match self.extra {
            None => self.extra = Some(HashMap::new()),
            Some(ref e) => assert!(e.len() < 10),
        }
        self.extra.as_mut().unwrap().insert(key, val);
        self
    }
}

#[cfg(test)]
mod test_events {
    use super::*;

    #[test]
    #[should_panic]
    fn test_invalid_length_ctor() {
        Event::new("A very long object value", "Method");
    }

    #[test]
    #[should_panic]
    fn test_invalid_length_extra_key() {
        Event::new("O", "M").extra("A very long key value", "v".to_string());
    }

    #[test]
    #[should_panic]
    fn test_invalid_length_extra_val() {
        let l = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
                abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        Event::new("O", "M").extra("k", l.to_string());
    }

    #[test]
    #[should_panic]
    fn test_too_many_extras() {
        let l = "abcdefghijk";
        let mut e = Event::new("Object", "Method");
        for i in 0..l.len() {
            e = e.extra(&l[i..=i], "v".to_string());
        }
    }

    #[test]
    fn test_json() {
        assert_json(
            &Event::new("Object", "Method").value("Value"),
            serde_json::json!({"object": "Object", "method": "Method", "value": "Value"}),
        );

        assert_json(
            &Event::new("Object", "Method").extra("one", "one".to_string()),
            serde_json::json!({"object": "Object",
             "method": "Method",
             "extra": {"one": "one"}
            }),
        )
    }
}

/// A Sync failure.
#[derive(Debug, Serialize)]
#[serde(tag = "name")]
pub enum SyncFailure {
    #[serde(rename = "shutdownerror")]
    Shutdown,

    #[serde(rename = "othererror")]
    Other { error: String },

    #[serde(rename = "unexpectederror")]
    Unexpected { error: String },

    #[serde(rename = "autherror")]
    Auth { from: &'static str },

    #[serde(rename = "httperror")]
    Http { code: u16 },
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn reprs() {
        assert_json(
            &SyncFailure::Shutdown,
            serde_json::json!({"name": "shutdownerror"}),
        );

        assert_json(
            &SyncFailure::Other {
                error: "dunno".to_string(),
            },
            serde_json::json!({"name": "othererror", "error": "dunno"}),
        );

        assert_json(
            &SyncFailure::Unexpected {
                error: "dunno".to_string(),
            },
            serde_json::json!({"name": "unexpectederror", "error": "dunno"}),
        );

        assert_json(
            &SyncFailure::Auth { from: "FxA" },
            serde_json::json!({"name": "autherror", "from": "FxA"}),
        );

        assert_json(
            &SyncFailure::Http { code: 500 },
            serde_json::json!({"name": "httperror", "code": 500}),
        );
    }
}

/// Incoming record for an engine's sync
#[derive(Debug, Default, Serialize)]
pub struct EngineIncoming {
    #[serde(skip_serializing_if = "crate::skip_if_default")]
    applied: u32,

    #[serde(skip_serializing_if = "crate::skip_if_default")]
    failed: u32,

    #[serde(rename = "newFailed")]
    #[serde(skip_serializing_if = "crate::skip_if_default")]
    new_failed: u32,

    #[serde(skip_serializing_if = "crate::skip_if_default")]
    reconciled: u32,
}

impl EngineIncoming {
    pub fn new() -> Self {
        Self {
            ..Default::default()
        }
    }

    // A helper used via skip_serializing_if
    fn is_empty(inc: &Option<Self>) -> bool {
        match inc {
            Some(a) => a.applied == 0 && a.failed == 0 && a.new_failed == 0 && a.reconciled == 0,
            None => true,
        }
    }

    /// Increment the value of `applied` by `n`.
    #[inline]
    pub fn applied(&mut self, n: u32) {
        self.applied += n;
    }

    /// Increment the value of `failed` by `n`.
    #[inline]
    pub fn failed(&mut self, n: u32) {
        self.failed += n;
    }

    /// Increment the value of `new_failed` by `n`.
    #[inline]
    pub fn new_failed(&mut self, n: u32) {
        self.new_failed += n;
    }

    /// Increment the value of `reconciled` by `n`.
    #[inline]
    pub fn reconciled(&mut self, n: u32) {
        self.reconciled += n;
    }

    /// Get the value of `applied`. Mostly useful for testing.
    #[inline]
    pub fn get_applied(&self) -> u32 {
        self.applied
    }

    /// Get the value of `failed`. Mostly useful for testing.
    #[inline]
    pub fn get_failed(&self) -> u32 {
        self.failed
    }

    /// Get the value of `new_failed`. Mostly useful for testing.
    #[inline]
    pub fn get_new_failed(&self) -> u32 {
        self.new_failed
    }

    /// Get the value of `reconciled`. Mostly useful for testing.
    #[inline]
    pub fn get_reconciled(&self) -> u32 {
        self.reconciled
    }
}

/// Outgoing record for an engine's sync
#[derive(Debug, Default, Serialize)]
pub struct EngineOutgoing {
    #[serde(skip_serializing_if = "crate::skip_if_default")]
    sent: usize,

    #[serde(skip_serializing_if = "crate::skip_if_default")]
    failed: usize,
}

impl EngineOutgoing {
    pub fn new() -> Self {
        EngineOutgoing {
            ..Default::default()
        }
    }

    #[inline]
    pub fn sent(&mut self, n: usize) {
        self.sent += n;
    }

    #[inline]
    pub fn failed(&mut self, n: usize) {
        self.failed += n;
    }
}

/// One engine's sync.
#[derive(Debug, Serialize)]
pub struct Engine {
    name: String,

    #[serde(flatten)]
    when_took: Stopwatch,

    #[serde(skip_serializing_if = "EngineIncoming::is_empty")]
    incoming: Option<EngineIncoming>,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    outgoing: Vec<EngineOutgoing>, // one for each batch posted.

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "failureReason")]
    failure: Option<SyncFailure>,

    #[serde(skip_serializing_if = "Option::is_none")]
    validation: Option<Validation>,
}

impl Engine {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            when_took: Stopwatch::new(),
            incoming: None,
            outgoing: Vec::new(),
            failure: None,
            validation: None,
        }
    }

    pub fn incoming(&mut self, inc: EngineIncoming) {
        assert!(self.incoming.is_none());
        self.incoming = Some(inc);
    }

    pub fn outgoing(&mut self, out: EngineOutgoing) {
        self.outgoing.push(out);
    }

    pub fn failure(&mut self, err: impl Into<SyncFailure>) {
        // Currently we take the first error, under the assumption that the
        // first is the most important and all others stem from that.
        let failure = err.into();
        if self.failure.is_none() {
            self.failure = Some(failure);
        } else {
            log::warn!(
                "engine already has recorded a failure of {:?} - ignoring {:?}",
                &self.failure,
                &failure
            );
        }
    }

    pub fn validation(&mut self, v: Validation) {
        assert!(self.validation.is_none());
        self.validation = Some(v);
    }

    fn finished(&mut self) {
        self.when_took = self.when_took.finished();
    }
}

#[derive(Debug, Default, Serialize)]
pub struct Validation {
    version: u32,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    problems: Vec<Problem>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "failureReason")]
    failure: Option<SyncFailure>,
}

impl Validation {
    pub fn with_version(version: u32) -> Validation {
        Validation {
            version,
            ..Validation::default()
        }
    }

    pub fn problem(&mut self, name: &'static str, count: usize) -> &mut Self {
        if count > 0 {
            self.problems.push(Problem { name, count });
        }
        self
    }
}

#[derive(Debug, Default, Serialize)]
pub struct Problem {
    name: &'static str,
    #[serde(skip_serializing_if = "crate::skip_if_default")]
    count: usize,
}

#[cfg(test)]
mod engine_tests {
    use super::*;

    #[test]
    fn test_engine() {
        let mut e = Engine::new("test_engine");
        e.finished();
        assert_json(&e, serde_json::json!({"name": "test_engine", "when": 0.0}));
    }

    #[test]
    fn test_engine_not_finished() {
        let e = Engine::new("test_engine");
        serde_json::to_value(&e).expect_err("unfinished stopwatch should fail");
    }

    #[test]
    fn test_incoming() {
        let mut i = EngineIncoming::new();
        i.applied(1);
        i.failed(2);
        let mut e = Engine::new("TestEngine");
        e.incoming(i);
        e.finished();
        assert_json(
            &e,
            serde_json::json!({"name": "TestEngine", "when": 0.0, "incoming": {"applied": 1, "failed": 2}}),
        );
    }

    #[test]
    fn test_outgoing() {
        let mut o = EngineOutgoing::new();
        o.sent(2);
        o.failed(1);
        let mut e = Engine::new("TestEngine");
        e.outgoing(o);
        e.finished();
        assert_json(
            &e,
            serde_json::json!({"name": "TestEngine", "when": 0.0, "outgoing": [{"sent": 2, "failed": 1}]}),
        );
    }

    #[test]
    fn test_failure() {
        let mut e = Engine::new("TestEngine");
        e.failure(SyncFailure::Http { code: 500 });
        e.finished();
        assert_json(
            &e,
            serde_json::json!({"name": "TestEngine",
             "when": 0.0,
             "failureReason": {"name": "httperror", "code": 500}
            }),
        );
    }

    #[test]
    fn test_raw() {
        let mut e = Engine::new("TestEngine");
        let mut inc = EngineIncoming::new();
        inc.applied(10);
        e.incoming(inc);
        let mut out = EngineOutgoing::new();
        out.sent(1);
        e.outgoing(out);
        e.failure(SyncFailure::Http { code: 500 });
        e.finished();

        assert_eq!(e.outgoing.len(), 1);
        assert_eq!(e.incoming.as_ref().unwrap().applied, 10);
        assert_eq!(e.outgoing[0].sent, 1);
        assert!(e.failure.is_some());
        serde_json::to_string(&e).expect("should get json");
    }
}

/// A single sync. May have many engines, may have its own failure.
#[derive(Debug, Serialize, Default)]
pub struct SyncTelemetry {
    #[serde(flatten)]
    when_took: Stopwatch,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    engines: Vec<Engine>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "failureReason")]
    failure: Option<SyncFailure>,
}

impl SyncTelemetry {
    pub fn new() -> Self {
        Default::default()
    }

    pub fn engine(&mut self, mut e: Engine) {
        e.finished();
        self.engines.push(e);
    }

    pub fn failure(&mut self, failure: SyncFailure) {
        assert!(self.failure.is_none());
        self.failure = Some(failure);
    }

    // Note that unlike other 'finished' methods, this isn't private - someone
    // needs to explicitly call this before handling the json payload to
    // whatever ends up submitting it.
    pub fn finished(&mut self) {
        self.when_took = self.when_took.finished();
    }
}

#[cfg(test)]
mod sync_tests {
    use super::*;

    #[test]
    fn test_accum() {
        let mut s = SyncTelemetry::new();
        let mut inc = EngineIncoming::new();
        inc.applied(10);
        let mut e = Engine::new("test_engine");
        e.incoming(inc);
        e.failure(SyncFailure::Http { code: 500 });
        e.finished();
        s.engine(e);
        s.finished();

        assert_json(
            &s,
            serde_json::json!({
                "when": 0.0,
                "engines": [{
                    "name":"test_engine",
                    "when":0.0,
                    "incoming": {
                        "applied": 10
                    },
                    "failureReason": {
                        "name": "httperror",
                        "code": 500
                    }
                }]
            }),
        );
    }

    #[test]
    fn test_multi_engine() {
        let mut inc_e1 = EngineIncoming::new();
        inc_e1.applied(1);
        let mut e1 = Engine::new("test_engine");
        e1.incoming(inc_e1);

        let mut inc_e2 = EngineIncoming::new();
        inc_e2.failed(1);
        let mut e2 = Engine::new("test_engine_2");
        e2.incoming(inc_e2);
        let mut out_e2 = EngineOutgoing::new();
        out_e2.sent(1);
        e2.outgoing(out_e2);

        let mut s = SyncTelemetry::new();
        s.engine(e1);
        s.engine(e2);
        s.failure(SyncFailure::Http { code: 500 });
        s.finished();
        assert_json(
            &s,
            serde_json::json!({
                "when": 0.0,
                "engines": [{
                    "name": "test_engine",
                    "when": 0.0,
                    "incoming": {
                        "applied": 1
                    }
                },{
                    "name": "test_engine_2",
                    "when": 0.0,
                    "incoming": {
                        "failed": 1
                    },
                    "outgoing": [{
                        "sent": 1
                    }]
                }],
                "failureReason": {
                    "name": "httperror",
                    "code": 500
                }
            }),
        );
    }
}

/// The Sync ping payload, as documented at
/// https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/sync-ping.html.
/// May have many syncs, may have many events. However, due to the architecture
/// of apps which use these components, this payload is almost certainly not
/// suitable for submitting directly. For example, we will always return a
/// payload with exactly 1 sync, and it will not know certain other fields
/// in the payload, such as the *hashed* FxA device ID (see
/// https://searchfox.org/mozilla-central/rev/c3ebaf6de2d481c262c04bb9657eaf76bf47e2ac/services/sync/modules/browserid_identity.js#185
/// for an example of how the device ID is constructed). The intention is that
/// consumers of this will use this to create a "real" payload - eg, accumulating
/// until some threshold number of syncs is reached, and contributing
/// additional data which only the consumer knows.
#[derive(Debug, Serialize, Default)]
pub struct SyncTelemetryPing {
    version: u32,

    uid: Option<String>,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    events: Vec<Event>,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    syncs: Vec<SyncTelemetry>,
}

impl SyncTelemetryPing {
    pub fn new() -> Self {
        Self {
            version: 1,
            ..Default::default()
        }
    }

    pub fn uid(&mut self, uid: String) {
        if let Some(ref existing) = self.uid {
            if *existing != uid {
                log::warn!("existing uid ${} being replaced by {}", existing, uid);
            }
        }
        self.uid = Some(uid);
    }

    pub fn sync(&mut self, mut s: SyncTelemetry) {
        s.finished();
        self.syncs.push(s);
    }

    pub fn event(&mut self, e: Event) {
        self.events.push(e);
    }
}

ffi_support::implement_into_ffi_by_json!(SyncTelemetryPing);

#[cfg(test)]
mod ping_tests {
    use super::*;
    #[test]
    fn test_ping() {
        let engine = Engine::new("test");
        let mut s = SyncTelemetry::new();
        s.engine(engine);
        let mut p = SyncTelemetryPing::new();
        p.uid("user-id".into());
        p.sync(s);
        let event = Event::new("foo", "bar");
        p.event(event);
        assert_json(
            &p,
            serde_json::json!({
                "events": [{
                    "method": "bar", "object": "foo"
                }],
                "syncs": [{
                    "engines": [{
                        "name": "test", "when": 0.0
                    }],
                    "when": 0.0
                }],
                "uid": "user-id",
                "version": 1
            }),
        );
    }
}
