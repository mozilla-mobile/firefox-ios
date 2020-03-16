/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! Work around the fact that `sqlcipher` might get enabled by a cargo feature
//! another crate in teh workspace needs, without setting up nss. (This is a
//! gross hack).

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    // Ugh. This is really really dumb. We don't care about sqlcipher at all. really
    if nss_build_common::env_str("DEP_SQLITE3_LINK_TARGET") == Some("sqlcipher".into()) {
        // If NSS_DIR isn't set, we don't really care, ignore the Err case.
        let _ = nss_build_common::link_nss();
    }
}
