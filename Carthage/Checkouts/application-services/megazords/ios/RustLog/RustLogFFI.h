/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#pragma once
#include <stdint.h>
#include <Foundation/NSObjCRuntime.h>

typedef struct RcLogError {
    int32_t code;
    char *_Nullable message;
} RcLogError;

typedef void RustLogCallback(int32_t level,
                             char const *_Nullable tag,
                             char const *_Nonnull msg);

typedef struct RustLogAdapter RustLogAdapter;

RustLogAdapter *_Nullable rc_log_adapter_create(RustLogCallback *_Nonnull callback,
                                                RcLogError *_Nonnull out_err);

void rc_log_adapter_set_max_level(int32_t max_level,
                                  RcLogError *_Nonnull out_err);

void rc_log_adapter_destroy(RustLogAdapter *_Nonnull to_destroy);

void rc_log_adapter_test__log_msg(char const *_Nonnull msg);

// Only use for Error strings!
void rc_log_adapter_destroy_string(char *_Nonnull msg);
