/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use bindgen::Builder;
use serde_derive::Deserialize;
use std::{env, fs, path::PathBuf, process::Command};
use toml;

use nss_build_common::*;

const BINDINGS_CONFIG: &str = "bindings.toml";

// This is the format of a single section of the configuration file.
#[derive(Deserialize)]
struct Bindings {
    // The .h header files to generate from.
    headers: Vec<String>,
    // functions that are explicitly included
    functions: Option<Vec<String>>,
    // types that are explicitly included
    types: Option<Vec<String>>,
    // (un-used) functions that are explicitly included
    // functions: Option<Vec<String>>,
    // variables (and `#define`s) that are explicitly included
    variables: Option<Vec<String>>,
    // types that should be explicitly marked as opaque
    opaque: Option<Vec<String>>,
    // enumerations that are turned into a module (without this, the enum is
    // mapped using the default, which means that the individual values are
    // formed with an underscore as <enum_type>_<enum_value_name>).
    enums: Option<Vec<String>>,

    // Any item that is specifically excluded; if none of the types, functions,
    // or variables fields are specified, everything defined will be mapped,
    // so this can be used to limit that.
    exclude: Option<Vec<String>>,
}

const DEFAULT_ANDROID_NDK_API_VERSION: &str = "21";

// Set the CLANG_PATH env variable to point to the right clang for the NDK in question.
// Note that this basically needs to be done first thing in main.
fn maybe_setup_ndk_clang_path() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").ok();
    if target_os.as_ref().map_or(false, |x| x == "android") {
        let mut buf = PathBuf::from(env("ANDROID_NDK_ROOT").unwrap());
        let ndk_api = env_str("ANDROID_NDK_API_VERSION")
            .unwrap_or_else(|| DEFAULT_ANDROID_NDK_API_VERSION.to_owned());

        if ndk_api.is_empty() {
            println!("cargo:warning=ANDROID_NDK_API_VERSION is unset. Trying unprefixed");
        }
        let mut target = env::var("TARGET").unwrap();
        if target == "armv7-linux-androideabi" {
            // See https://developer.android.com/ndk/guides/other_build_systems
            // for information on why this is weird and different (or at least,
            // confirmation that it's supposed to be that way...)
            target = "armv7a-linux-androideabi".to_owned();
        }
        for &path in &["toolchains", "llvm", "prebuilt", android_host_tag(), "bin"] {
            buf.push(path);
        }
        buf.push(format!("{}{}-clang", target, ndk_api));
        env::set_var("CLANG_PATH", buf);
    }
}

fn main() {
    // Note: this has to be first!
    maybe_setup_ndk_clang_path();
    // 1. NSS linking.
    let (_, include_dir) = link_nss().expect("To build nss_sys, NSS_DIR must be set!");
    // 2. Bindings.
    let config_file = PathBuf::from(BINDINGS_CONFIG);
    println!("cargo:rerun-if-changed={}", config_file.to_str().unwrap());
    let config = fs::read_to_string(config_file).expect("unable to read binding configuration");
    let bindings: Bindings = toml::from_str(&config).unwrap();
    build_bindings(&bindings, &include_dir.join("nss"));
}

fn build_bindings(bindings: &Bindings, include_dir: &PathBuf) {
    let out = PathBuf::from(env::var("OUT_DIR").unwrap()).join("nss_bindings.rs");
    let mut builder = Builder::default().generate_comments(false);

    for h in bindings.headers.iter().cloned() {
        builder = builder.header(include_dir.join(h).to_str().unwrap());
    }

    // Fix our cross-compilation include directories.
    builder = fix_include_dirs(builder);

    // Apply the configuration.
    let empty: Vec<String> = vec![];
    for v in bindings.types.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.whitelist_type(v);
    }
    for v in bindings.functions.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.whitelist_function(v);
    }
    for v in bindings.variables.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.whitelist_var(v);
    }
    for v in bindings.exclude.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.blacklist_item(v);
    }
    for v in bindings.opaque.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.opaque_type(v);
    }
    for v in bindings.enums.as_ref().unwrap_or_else(|| &empty).iter() {
        builder = builder.constified_enum_module(v);
    }

    let bindings = builder.generate().expect("unable to generate bindings");
    bindings
        .write_to_file(out)
        .expect("couldn't write bindings");
}

fn fix_include_dirs(mut builder: Builder) -> Builder {
    let target_os = env::var("CARGO_CFG_TARGET_OS");
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH");
    match target_os.as_ref().map(|x| &**x) {
        Ok("macos") => {
            // Cheap and dirty way to detect that we are cross-compiling.
            if env::var_os("CI").is_some() {
                builder = builder
                    .detect_include_paths(false)
                    .clang_arg("-isysroot/tmp/MacOSX10.11.sdk");
            }
        }
        Ok("windows") => {
            if env::var_os("CI").is_some() {
                builder = builder.clang_arg("-D_M_X64");
            }
        }
        Ok("ios") => {
            let sdk_root;
            match target_arch.as_ref().map(|x| &**x).unwrap() {
                "aarch64" => {
                    sdk_root = get_ios_sdk_root("iphoneos");
                    builder = builder.clang_arg("--target=arm64-apple-ios") // See https://github.com/rust-lang/rust-bindgen/issues/1211
                }
                "x86_64" => {
                    sdk_root = get_ios_sdk_root("iphonesimulator");
                }
                _ => panic!("Unknown iOS architecture."),
            }
            builder = builder
                .detect_include_paths(false)
                .clang_arg(format!("-isysroot{}", &sdk_root));
        }
        _ => {}
    }
    builder
}

fn android_host_tag() -> &'static str {
    // cfg! target_os actually refers to the host environment in this case (build script).
    #[cfg(target_os = "macos")]
    return "darwin-x86_64";
    #[cfg(target_os = "linux")]
    return "linux-x86_64";
    #[cfg(target_os = "windows")]
    return "windows-x86_64";
}

fn get_ios_sdk_root(sdk_name: &str) -> String {
    let output = Command::new("xcrun")
        .arg("--show-sdk-path")
        .arg("-sdk")
        .arg(sdk_name)
        .output()
        .unwrap();
    if output.status.success() {
        String::from_utf8(output.stdout).unwrap().trim().to_string()
    } else {
        panic!("Could not get iOS SDK root!")
    }
}
