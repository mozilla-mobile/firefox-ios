// Copyright 2012 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
// PNG decode.

#ifndef WEBP_EXAMPLES_PNGDEC_H_
#define WEBP_EXAMPLES_PNGDEC_H_

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

struct Metadata;
struct WebPPicture;

// Reads a PNG from 'in_file', returning the decoded output in 'pic'.
// If 'keep_alpha' is true and the PNG has an alpha channel, the output is RGBA
// otherwise it will be RGB.
// Returns true on success.
int ReadPNG(FILE* in_file, struct WebPPicture* const pic, int keep_alpha,
            struct Metadata* const metadata);

#ifdef __cplusplus
}    // extern "C"
#endif

#endif  // WEBP_EXAMPLES_PNGDEC_H_
