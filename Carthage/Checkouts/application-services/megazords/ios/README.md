The iOS 'megazord' builds all the components into a single library. This is built as a static framework.

### Adding new components

- Update `base.xcconfig` HEADER_SEARCH_PATHS to search for headers in the added component
- Add any C bridging headers to the includes in  `MozillaAppServices.h`.
- drag and drop all the swift files from the new component into this project
- update `rust/Cargo.toml` and `rust/src/lib.rs` with the new ffi path
