/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This shouldn't exist, but does because if something isn't going to link
//! against `nss` but has an `nss`-enabled `sqlcipher` turned on (for example,
//! by a `cargo` feature activated by something else in the workspace).
//! it might need to issue link commands for NSS.
//!
//! It essentially contains the non-bindgen part of nss_sys's build.rs.

use std::{
    env,
    ffi::OsString,
    path::{Path, PathBuf},
};

#[derive(Clone, Copy, PartialEq, Debug)]
pub enum LinkingKind {
    Dynamic { folded_libs: bool },
    Static,
}

#[derive(Debug, PartialEq, Clone)]
pub struct NoNssDir;

pub fn link_nss() -> Result<(PathBuf, PathBuf), NoNssDir> {
    let (lib_dir, include_dir) = get_nss()?;
    println!(
        "cargo:rustc-link-search=native={}",
        lib_dir.to_string_lossy()
    );
    println!("cargo:include={}", include_dir.to_string_lossy());
    let kind = determine_kind();
    link_nss_libs(kind);
    Ok((lib_dir, include_dir))
}

fn get_nss() -> Result<(PathBuf, PathBuf), NoNssDir> {
    let nss_dir = env("NSS_DIR").ok_or(NoNssDir)?;
    let nss_dir = Path::new(&nss_dir);
    let lib_dir = nss_dir.join("lib");
    let include_dir = nss_dir.join("include");
    Ok((lib_dir, include_dir))
}

fn determine_kind() -> LinkingKind {
    if env_flag("NSS_STATIC") {
        LinkingKind::Static
    } else {
        let folded_libs = env_flag("NSS_USE_FOLDED_LIBS");
        LinkingKind::Dynamic { folded_libs }
    }
}

fn link_nss_libs(kind: LinkingKind) {
    let libs = get_nss_libs(kind);
    // Emit -L flags
    let kind_str = match kind {
        LinkingKind::Dynamic { .. } => "dylib",
        LinkingKind::Static => "static",
    };
    for lib in libs {
        println!("cargo:rustc-link-lib={}={}", kind_str, lib);
    }
}

fn get_nss_libs(kind: LinkingKind) -> Vec<&'static str> {
    match kind {
        LinkingKind::Static => {
            let mut static_libs = vec![
                "certdb",
                "certhi",
                "cryptohi",
                "freebl_static",
                "hw-acc-crypto",
                "nspr4",
                "nss_static",
                "nssb",
                "nssdev",
                "nsspki",
                "nssutil",
                "pk11wrap_static",
                "plc4",
                "plds4",
                "softokn_static",
            ];
            // Hardware specific libs.
            let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap();
            let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
            // https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#159-168
            if target_arch == "x86_64" || target_arch == "x86" {
                static_libs.push("gcm-aes-x86_c_lib");
            } else if target_arch == "aarch64" {
                static_libs.push("gcm-aes-aarch64_c_lib");
            }
            // https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#224-233
            if ((target_os == "android" || target_os == "linux") && target_arch == "x86_64")
                || target_os == "windows"
            {
                static_libs.push("intel-gcm-wrap_c_lib");
                // https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#43-47
                if (target_os == "android" || target_os == "linux") && target_arch == "x86_64" {
                    static_libs.push("intel-gcm-s_lib");
                }
            }
            static_libs
        }
        LinkingKind::Dynamic { folded_libs } => {
            let mut dylibs = vec!["freebl3", "nss3", "nssckbi", "softokn3"];
            if !folded_libs {
                dylibs.append(&mut vec!["nspr4", "nssutil3", "plc4", "plds4"]);
            }
            dylibs
        }
    }
}

pub fn env(name: &str) -> Option<OsString> {
    println!("cargo:rerun-if-env-changed={}", name);
    env::var_os(name)
}

pub fn env_str(name: &str) -> Option<String> {
    println!("cargo:rerun-if-env-changed={}", name);
    env::var(name).ok()
}

pub fn env_flag(name: &str) -> bool {
    match env_str(name).as_ref().map(String::as_ref) {
        Some("1") => true,
        Some("0") => false,
        Some(s) => {
            println!(
                "cargo:warning=unknown value for environment var {:?}: {:?}. Ignoring",
                name, s
            );
            false
        }
        None => false,
    }
}
