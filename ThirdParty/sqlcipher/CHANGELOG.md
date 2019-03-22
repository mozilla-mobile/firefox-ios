# SQLCipher Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]

## [3.4.2] - 2017-12-21
### Added
- Added support for building with LibreSSL

### Changed
- Merge upstream SQLite 3.20.1
- Text strings for `SQLITE_ERROR` and `SQLITE_NOTADB` changed to match upstream SQLite
- Remove static modifier for codec password functions
- Page alignment for `mlock`
- Fix segfault in `sqlcipher_cipher_ctx_cmp` during rekey operation
- Fix `sqlcipher_export` and `cipher_migrate` when tracing API in use
- Validate codec page size when setting
- Guard OpenSSL initialization and cleanup routines
- Allow additional linker options to be passed via command line for Windows platforms

## [3.4.1] - 2016-12-28
### Added
- Added support for OpenSSL 1.1.0

### Changed
- Merged upstream SQLite 3.15.2

## [3.4.0] - 2016-04-05
### Added
- Added `PRAGMA cipher_provider_version`

### Changed
- Merged upstream SQLite 3.11.0

### Deprecated
- Deprecated `PRAGMA cipher` command

## [3.3.1] - 2015-07-13
### Changed
- Merge upstream SQLite 3.8.10.2
- Fixed segfault when provided an invalid cipher name
- Check for codec context when performing `PRAGMA cipher_store_pass`
- Remove extraneous null check in `PRAGMA cipher_migrate`

## [3.3.0] - 2015-03-25
### Added
- Added FIPS API calls within the OpenSSL crypto provider
- `PRAGMA cipher_default_page_size` - support for attaching non-default page sizes

### Changed
- Merged upstream SQLite 3.8.8.3

## [3.2.0] - 2014-09-30
### Added
- Added `PRAGMA cipher_store_pass`

### Changed
- Merged upstream SQLite 3.8.6
- Renmed README to README.md

## [3.1.0] - 2014-04-23
### Added
- Added `PRAGMA cipher_profile`

### Changed
- Merged upstream SQLite 3.8.4.3

## [3.0.1] - 2013-12-06
### Added
- Added `PRAGMA cipher_add_random` to source external entropy

### Changed
- Fix `PRAGMA cipher_migrate` to handle passphrases longer than 64 characters & raw keys
- Improvements to the libtomcrypt provider

## [3.0.0] - 2013-11-05
### Added
- Added `PRAGMA cipher_migrate` to migrate older database file formats

### Changed
- Merged upstream SQLite 3.8.0.2
- Remove usage of VirtualLock/Unlock on WinRT and Windows Phone
- Ignore HMAC read during Btree file copy
- Fix lib naming for pkg-config
- Use _v2 version of `sqlite3_key` and `sqlite3_rekey`
- Update xcodeproj file

### Security
- Change KDF iteration length from 4,000 to 64,000

[unreleased]: https://github.com/sqlcipher/sqlcipher/compare/v3.4.2...prerelease
[3.4.2]: https://github.com/sqlcipher/sqlcipher/compare/v3.4.1...v3.4.2
[3.4.1]: https://github.com/sqlcipher/sqlcipher/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/sqlcipher/sqlcipher/compare/v3.3.1...v3.4.0
[3.3.1]: https://github.com/sqlcipher/sqlcipher/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/sqlcipher/sqlcipher/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/sqlcipher/sqlcipher/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/sqlcipher/sqlcipher/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/sqlcipher/sqlcipher/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/sqlcipher/sqlcipher/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/sqlcipher/sqlcipher/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/sqlcipher/sqlcipher/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/sqlcipher/sqlcipher/compare/v2.0.6...v2.1.0
[2.0.6]: https://github.com/sqlcipher/sqlcipher/compare/v2.0.5...v2.0.6
[2.0.5]: https://github.com/sqlcipher/sqlcipher/compare/v2.0.3...v2.0.5
[2.0.3]: https://github.com/sqlcipher/sqlcipher/compare/v2.0.0...v2.0.3
[2.0.0]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.10...v2.0.0
[1.1.10]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.9...v1.1.10
[1.1.9]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.8...v1.1.9
[1.1.8]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.7...v1.1.8
[1.1.7]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.6...v1.1.7
[1.1.6]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.1...v1.1.1
[1.1.1]: https://github.com/sqlcipher/sqlcipher/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sqlcipher/sqlcipher/compare/617ed01...v1.1.0
