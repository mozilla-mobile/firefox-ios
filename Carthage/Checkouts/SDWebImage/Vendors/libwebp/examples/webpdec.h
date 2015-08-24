// Copyright 2014 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
// WebP decode.

#ifndef WEBP_EXAMPLES_WEBPDEC_H_
#define WEBP_EXAMPLES_WEBPDEC_H_

#ifdef __cplusplus
extern "C" {
#endif

struct Metadata;
struct WebPPicture;

// Reads a WebP from 'in_file', returning the decoded output in 'pic'.
// If 'keep_alpha' is true and the WebP has an alpha channel, the output is
// RGBA otherwise it will be RGB.
// Returns true on success.
int ReadWebP(const char* const in_file, struct WebPPicture* const pic,
             int keep_alpha, struct Metadata* const metadata);

#ifdef __cplusplus
}    // extern "C"
#endif

#endif  // WEBP_EXAMPLES_WEBPDEC_H_
