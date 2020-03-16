/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use lazy_static::lazy_static;
use std::sync::{Once, RwLock};

use log::Log;

struct SettableLog {
    inner: RwLock<Option<Box<dyn Log>>>,
}

lazy_static! {
    static ref SETTABLE_LOG: SettableLog = SettableLog {
        inner: RwLock::new(None)
    };
}

impl SettableLog {
    fn set(&self, logger: Box<dyn Log>) {
        let mut write_lock = self.inner.write().unwrap();
        *write_lock = Some(logger);
    }

    fn unset(&self) {
        let mut write_lock = self.inner.write().unwrap();
        drop(write_lock.take());
    }
}

impl Log for SettableLog {
    fn enabled(&self, metadata: &log::Metadata<'_>) -> bool {
        let inner = self.inner.read().unwrap();
        if let Some(log) = &*inner {
            log.enabled(metadata)
        } else {
            false
        }
    }

    fn flush(&self) {
        let inner = self.inner.read().unwrap();
        if let Some(log) = &*inner {
            log.flush();
        }
    }

    fn log(&self, record: &log::Record<'_>) {
        let inner = self.inner.read().unwrap();
        if let Some(log) = &*inner {
            log.log(record);
        }
    }
}

pub fn init_once() {
    static INITIALIZER: Once = Once::new();
    INITIALIZER.call_once(|| {
        log::set_logger(&*SETTABLE_LOG).expect(
            "Failed to initialize SettableLog, other log implementation already initialized?",
        );
    });
}

pub fn set_logger(logger: Box<dyn Log>) {
    init_once();
    SETTABLE_LOG.set(logger);
}

pub fn unset_logger() {
    init_once();
    SETTABLE_LOG.unset();
}
