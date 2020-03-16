/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#pragma once

#include <stdint.h>

typedef uint64_t PlacesAPIHandle;
typedef uint64_t PlacesConnectionHandle;

typedef enum PlacesErrorCode {
    Places_Panic = -1,
    Places_NoError = 0,
    Places_UnexpectedError = 1,
    Places_UrlParseError = 2,
    Places_DatabaseBusy = 3,
    Places_DatabaseInterrupted = 4,
    Places_Corrupt = 5,

    Places_InvalidPlace_InvalidParent = 64 + 0,
    Places_InvalidPlace_NoSuchItem = 64 + 1,
    Places_InvalidPlace_UrlTooLong = 64 + 2,
    Places_InvalidPlace_IllegalChange = 64 + 3,
    Places_InvalidPlace_CannotUpdateRoot = 64 + 4,
} PlacesErrorCode;

typedef struct PlacesRustError {
    PlacesErrorCode code;
    char *_Nullable message;
} PlacesRustError;

typedef struct PlacesRustBuffer {
    int64_t len;
    uint8_t *_Nullable data;
} PlacesRustBuffer;

typedef struct RawPlacesInterruptHandle RawPlacesInterruptHandle;

// Not a named enum because we need int32_t ABI in `places_connection_new`,
// and using a named enum would be `int` (which usually is 32 bits these
// days, but it's not guaranteed)
enum {
    PlacesConn_ReadOnly = 1,
    PlacesConn_ReadWrite = 2,
    // Not exposed.
    // PlacesConn_Sync = 3,
};

PlacesAPIHandle places_api_new(const char *_Nonnull db_path,
                               PlacesRustError *_Nonnull out_err);


PlacesConnectionHandle places_connection_new(PlacesAPIHandle handle,
                                             int32_t type,
                                             PlacesRustError *_Nonnull out_err);

// MARK: History APIs

void places_note_observation(PlacesConnectionHandle handle,
                             const char *_Nonnull observation_json,
                             PlacesRustError *_Nonnull out_err);

char *_Nullable places_query_autocomplete(PlacesConnectionHandle handle,
                                          const char *_Nonnull search,
                                          int32_t limit,
                                          PlacesRustError *_Nonnull out_err);

char *_Nullable places_match_url(PlacesConnectionHandle handle,
                                 const char *_Nonnull search,
                                 PlacesRustError *_Nonnull out_err);

void places_bookmarks_import_from_ios(PlacesAPIHandle handle,
                                      const char *_Nonnull db_path,
                                      PlacesRustError *_Nonnull out_err);

// XXX we should move this to protobufs rather than port it to swift.
// char *_Nullable places_get_visited(PlacesConnectionHandle handle,
//                                    char const *_Nonnull const *_Nonnull urls,
//                                    int32_t urls_len,
//                                    uint8_t *_Nonnull results,
//                                    int32_t results_len,
//                                    PlacesRustError *_Nonnull out_err);

char *_Nullable places_get_visited_urls_in_range(PlacesConnectionHandle handle,
                                                 int64_t start,
                                                 int64_t end,
                                                 uint8_t include_remote,
                                                 PlacesRustError *_Nonnull out_err);

RawPlacesInterruptHandle *_Nullable places_new_interrupt_handle(PlacesConnectionHandle handle,
                                                                PlacesRustError *_Nonnull out_err);

void places_interrupt(RawPlacesInterruptHandle *_Nonnull interrupt,
                      PlacesRustError *_Nonnull out_err);

void places_delete_place(PlacesConnectionHandle handle,
                         const char *_Nonnull place_url,
                         PlacesRustError *_Nonnull out_err);

void places_delete_visit(PlacesConnectionHandle handle,
                         const char *_Nonnull place_url,
                         int64_t visit_timestamp,
                         PlacesRustError *_Nonnull out_err);

void places_delete_visits_between(PlacesConnectionHandle handle,
                                  int64_t start,
                                  int64_t end,
                                  PlacesRustError *_Nonnull out_err);

void places_wipe_local(PlacesConnectionHandle handle,
                       PlacesRustError *_Nonnull out_err);

void places_run_maintenance(PlacesConnectionHandle handle,
                            PlacesRustError *_Nonnull out_err);

void places_prune_destructively(PlacesConnectionHandle handle,
                                PlacesRustError *_Nonnull out_err);

void places_delete_everything(PlacesConnectionHandle handle,
                              PlacesRustError *_Nonnull out_err);

PlacesRustBuffer places_get_visit_infos(PlacesConnectionHandle handle,
                                        int64_t start_date,
                                        int64_t end_date,
                                        int32_t exclude_types,
                                        PlacesRustError *_Nonnull out_err);

void places_reset(PlacesAPIHandle handle,
                  PlacesRustError *_Nonnull out_err);

char *_Nonnull sync15_history_sync(PlacesAPIHandle handle,
                                   char const *_Nonnull key_id,
                                   char const *_Nonnull access_token,
                                   char const *_Nonnull sync_key,
                                   char const *_Nonnull tokenserver_url,
                                   PlacesRustError *_Nonnull out_err);

char *_Nonnull sync15_bookmarks_sync(PlacesAPIHandle handle,
                                     char const *_Nonnull key_id,
                                     char const *_Nonnull access_token,
                                     char const *_Nonnull sync_key,
                                     char const *_Nonnull tokenserver_url,
                                     PlacesRustError *_Nonnull out_err);

RawPlacesInterruptHandle *_Nullable
places_new_sync_conn_interrupt_handle(PlacesAPIHandle handle,
                                      PlacesRustError *_Nonnull out_err);

// MARK: Bookmarks APIs

PlacesRustBuffer bookmarks_get_by_guid(PlacesConnectionHandle handle,
                                       char const *_Nonnull guid,
                                       uint8_t getDirectChildren,
                                       PlacesRustError *_Nonnull out_err);

PlacesRustBuffer bookmarks_get_all_with_url(PlacesConnectionHandle handle,
                                            char const *_Nonnull url,
                                            PlacesRustError *_Nonnull out_err);

char *_Nullable bookmarks_get_url_for_keyword(PlacesConnectionHandle handle,
                                              char const *_Nonnull keyword,
                                              PlacesRustError *_Nonnull out_err);

PlacesRustBuffer bookmarks_search(PlacesConnectionHandle handle,
                                  char const *_Nonnull query,
                                  int32_t limit,
                                  PlacesRustError *_Nonnull out_err);

PlacesRustBuffer bookmarks_get_recent(PlacesConnectionHandle handle,
                                      int32_t limit,
                                      PlacesRustError *_Nonnull out_err);

PlacesRustBuffer bookmarks_get_tree(PlacesConnectionHandle handle,
                                    char const *_Nullable root_guid,
                                    PlacesRustError *_Nonnull out_err);

char *_Nullable bookmarks_insert(PlacesConnectionHandle handle,
                                 uint8_t const *_Nonnull data,
                                 int32_t len,
                                 PlacesRustError *_Nonnull out_err);

void bookmarks_update(PlacesConnectionHandle handle,
                      uint8_t const *_Nonnull data,
                      int32_t len,
                      PlacesRustError *_Nonnull out_err);

uint8_t bookmarks_delete(PlacesConnectionHandle handle,
                         char const *_Nonnull guid_to_delete,
                         PlacesRustError *_Nonnull out_err);

void bookmarks_reset(PlacesAPIHandle handle,
                     PlacesRustError *_Nonnull out_err);

// MARK: memory/lifecycle management

void places_api_return_write_conn(PlacesAPIHandle api,
                                  PlacesConnectionHandle conn,
                                  PlacesRustError *_Nonnull out_err);

void places_destroy_bytebuffer(PlacesRustBuffer bb);

void places_destroy_string(char const *_Nonnull s);

void places_interrupt_handle_destroy(RawPlacesInterruptHandle *_Nonnull handle);

void places_connection_destroy(PlacesConnectionHandle conn,
                               PlacesRustError *_Nonnull out_err);

void places_api_destroy(PlacesAPIHandle api,
                        PlacesRustError *_Nonnull out_err);
