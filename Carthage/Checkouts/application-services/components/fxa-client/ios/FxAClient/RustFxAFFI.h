/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#pragma once
#include <stdint.h>
#include <Foundation/NSObjCRuntime.h>

/*
 * This file contains headers for all of the structs and functions that map directly to the functions
 * defined in fxa-client/src/ffi.rs, fxa-client/ffi/src/lib.rs, and components/support/ffi/src/error.rs.
 *
 * The C in this file is specifically formatted to be used with Objective C and Swift and contains
 * macros and flags that will not be recognised by other C based languages.
 */

/*
  Error codes reported by the fxa-client library, from fxa-client/src/ffi.rs
 */
typedef enum FxAErrorCode {
    FxA_InternalPanic = -1,
    FxA_NoError = 0,
    FxA_Other = 1,
    FxA_AuthenticationError = 2,
    FxA_NetworkError = 3,
} FxAErrorCode;

/*
 A mapping of the ExternError repr(C) Rust struct, from components/support/ffi/src/error.rs.
 */
typedef struct FxAError {
    FxAErrorCode code;
    char *_Nullable message;
} FxAError;

/*
 A mapping of the ByteBuffer repr(C) Rust struct, from components/support/ffi/src/lib.rs.
 */
typedef struct FxARustBuffer {
    int64_t len;
    uint8_t *_Nullable data;
} FxARustBuffer;

typedef uint64_t FirefoxAccountHandle;

char *_Nullable fxa_begin_oauth_flow(FirefoxAccountHandle handle,
                                     const char *_Nonnull scopes,
                                     FxAError *_Nonnull out);

char *_Nullable fxa_begin_pairing_flow(FirefoxAccountHandle handle,
                                       const char *_Nonnull pairing_url,
                                       const char *_Nonnull scopes,
                                       FxAError *_Nonnull out);

void fxa_complete_oauth_flow(FirefoxAccountHandle handle,
                             const char *_Nonnull code,
                             const char *_Nonnull state,
                             FxAError *_Nonnull out);

FxARustBuffer fxa_get_access_token(FirefoxAccountHandle handle,
                                   const char *_Nonnull scope,
                                   FxAError *_Nonnull out);

char *_Nullable fxa_get_session_token(FirefoxAccountHandle handle,
                                      FxAError *_Nonnull out);

void fxa_clear_access_token_cache(FirefoxAccountHandle handle,
                                  FxAError *_Nonnull out);

void fxa_handle_session_token_change(FirefoxAccountHandle handle,
                                     const char *_Nonnull new_session_token,
                                     FxAError *_Nonnull out);

void fxa_disconnect(FirefoxAccountHandle handle,
                    FxAError *_Nonnull out);

FxARustBuffer fxa_check_authorization_status(FirefoxAccountHandle handle,
                                             FxAError *_Nonnull out);

FirefoxAccountHandle fxa_from_json(const char *_Nonnull json,
                                   FxAError *_Nonnull out);

char *_Nullable fxa_to_json(FirefoxAccountHandle handle,
                            FxAError *_Nonnull out);

FirefoxAccountHandle fxa_new(const char *_Nonnull content_base,
                             const char *_Nonnull client_id,
                             const char *_Nonnull redirect_uri,
                             FxAError *_Nonnull out);

FxARustBuffer fxa_profile(FirefoxAccountHandle handle,
                          bool ignore_cache,
                          FxAError *_Nonnull out);

FxARustBuffer fxa_get_devices(FirefoxAccountHandle handle,
                              FxAError *_Nonnull out);

FxARustBuffer fxa_poll_device_commands(FirefoxAccountHandle handle,
                                       FxAError *_Nonnull out);

FxARustBuffer fxa_handle_push_message(FirefoxAccountHandle handle,
                                      const char *_Nonnull payload,
                                      FxAError *_Nonnull out);

void fxa_send_tab(FirefoxAccountHandle handle,
                  const char *_Nonnull targetId,
                  const char *_Nonnull title,
                  const char *_Nonnull url,
                  FxAError *_Nonnull out);

void fxa_set_device_name(FirefoxAccountHandle handle,
                         const char *_Nonnull displayName,
                         FxAError *_Nonnull out);

void fxa_set_push_subscription(FirefoxAccountHandle handle,
                               const char *_Nonnull endpoint,
                               const char *_Nonnull publicKey,
                               const char *_Nonnull authKey,
                               FxAError *_Nonnull out);

void fxa_initialize_device(FirefoxAccountHandle handle,
                           const char *_Nonnull name,
                           int32_t device_type,
                           uint8_t const *_Nonnull capabilities_ptr,
                           int32_t capabilities_len,
                           FxAError *_Nonnull out);

void fxa_ensure_capabilities(FirefoxAccountHandle handle,
                             uint8_t const *_Nonnull capabilities_ptr,
                             int32_t capabilities_len,
                             FxAError *_Nonnull out);

char *_Nullable fxa_migrate_from_session_token(FirefoxAccountHandle handle,
                                               const char *_Nonnull sessionToken,
                                               const char *_Nonnull kSync,
                                               const char *_Nonnull kXCS,
                                               uint8_t copySessionToken,
                                               FxAError *_Nonnull out);

char *_Nullable fxa_retry_migrate_from_session_token(FirefoxAccountHandle handle,
                                                     FxAError *_Nonnull out);

uint8_t fxa_is_in_migration_state(FirefoxAccountHandle handle,
                                  FxAError *_Nonnull out);

char *_Nullable fxa_get_token_server_endpoint_url(FirefoxAccountHandle handle,
                                                  FxAError *_Nonnull out);

char *_Nullable fxa_get_connection_success_url(FirefoxAccountHandle handle,
                                               FxAError *_Nonnull out);

char *_Nullable fxa_get_manage_account_url(FirefoxAccountHandle handle,
                                           const char *_Nonnull entrypoint,
                                           FxAError *_Nonnull out);

char *_Nullable fxa_get_manage_devices_url(FirefoxAccountHandle handle,
                                           const char *_Nonnull entrypoint,
                                           FxAError *_Nonnull out);

void fxa_str_free(char *_Nullable ptr);
void fxa_free(FirefoxAccountHandle h, FxAError *_Nonnull out);
void fxa_bytebuffer_free(FxARustBuffer buffer);
