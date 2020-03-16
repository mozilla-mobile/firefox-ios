/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

// Helps manage "interruptable" things across our various crates.

use failure::Fail;

// Note that in the future it might make sense to also add a trait for
// an Interruptable, but we don't need this abstraction now and it's unclear
// if we ever will.

/// Represents the state of something that may be interrupted. Decoupled from
/// the interrupt mechanics so that things which want to check if they have been
/// interrupted are simpler.
pub trait Interruptee {
    fn was_interrupted(&self) -> bool;

    fn err_if_interrupted(&self) -> std::result::Result<(), Interrupted> {
        if self.was_interrupted() {
            return Err(Interrupted);
        }
        Ok(())
    }
}

/// A convenience implementation, should only be used in tests.
pub struct NeverInterrupts;

impl Interruptee for NeverInterrupts {
    #[inline]
    fn was_interrupted(&self) -> bool {
        false
    }
}

/// The error returned by err_if_interrupted.
#[derive(Debug, Fail, Clone, PartialEq)]
#[fail(display = "The operation was interrupted.")]
pub struct Interrupted;
