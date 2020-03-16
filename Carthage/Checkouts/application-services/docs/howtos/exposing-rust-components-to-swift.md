# Exposing Rust to Swift on iOS

* add the new FFI header include to MozillaAppServices.h. Optionally, one can add the new FFI header to the files in the project, but don't add it to the build target.
* add the search path to the HEADER_SEARCH_PATHS in the base.xcconfig for the project to the location of the new FFI header
* update Cargo.toml
* update lib.rs
