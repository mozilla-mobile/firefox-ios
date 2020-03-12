/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use ffi_support::implement_into_ffi_by_pointer;
use interrupt::Interruptee;
use rusqlite::InterruptHandle;
use std::sync::{
    atomic::{AtomicUsize, Ordering},
    Arc,
};

// SeqCst is overkill for much of this, but whatever.

/// A Sync+Send type which can be used allow someone to interrupt an
/// operation, even if it happens while rust code (and not SQL) is
/// executing.
pub struct SqlInterruptHandle {
    db_handle: InterruptHandle,
    interrupt_counter: Arc<AtomicUsize>,
}

impl SqlInterruptHandle {
    pub fn new(
        db_handle: InterruptHandle,
        interrupt_counter: Arc<AtomicUsize>,
    ) -> SqlInterruptHandle {
        SqlInterruptHandle {
            db_handle,
            interrupt_counter,
        }
    }

    pub fn interrupt(&self) {
        self.interrupt_counter.fetch_add(1, Ordering::SeqCst);
        self.db_handle.interrupt();
    }
}

implement_into_ffi_by_pointer!(SqlInterruptHandle);

/// A helper that can be used to determine if an interrupt request has come in while
/// the object lives. This is used to avoid a case where we aren't running any
/// queries when the request to stop comes in, but we're still not done (for example,
/// maybe we've run some of the autocomplete matchers, and are about to start
/// running the others. If we rely solely on sqlite3_interrupt(), we'd miss
/// the message that we should stop).
#[derive(Debug)]
pub struct SqlInterruptScope {
    // The value of the interrupt counter when the scope began
    start_value: usize,
    // This could be &'conn AtomicUsize, but it would prevent the connection
    // from being mutably borrowed for no real reason...
    ptr: Arc<AtomicUsize>,
}

impl SqlInterruptScope {
    #[inline]
    pub fn new(ptr: Arc<AtomicUsize>) -> Self {
        let start_value = ptr.load(Ordering::SeqCst);
        Self { start_value, ptr }
    }
    /// Add this as an inherent method to reduce the amount of things users have to bring in.
    #[inline]
    pub fn err_if_interrupted(&self) -> Result<(), interrupt::Interrupted> {
        <Self as Interruptee>::err_if_interrupted(self)
    }
}

impl Interruptee for SqlInterruptScope {
    #[inline]
    fn was_interrupted(&self) -> bool {
        self.ptr.load(Ordering::SeqCst) != self.start_value
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_sync_send() {
        fn is_sync<T: Sync>() {}
        fn is_send<T: Send>() {}
        // Make sure this compiles
        is_sync::<SqlInterruptHandle>();
        is_send::<SqlInterruptHandle>();
    }
}
