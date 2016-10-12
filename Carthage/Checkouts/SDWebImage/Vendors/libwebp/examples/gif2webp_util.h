// Copyright 2013 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
//  Helper structs and methods for gif2webp tool.
//
// Author: Urvang (urvang@google.com)

#ifndef WEBP_EXAMPLES_GIF2WEBP_UTIL_H_
#define WEBP_EXAMPLES_GIF2WEBP_UTIL_H_

#include <stdlib.h>

#include "webp/mux.h"

#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------------------------------------------
// Helper utilities.

#define WEBP_UTIL_TRANSPARENT_COLOR 0x00ffffff

struct WebPPicture;

// Includes all disposal methods, even the ones not supported by WebP bitstream.
typedef enum FrameDisposeMethod {
  FRAME_DISPOSE_NONE,
  FRAME_DISPOSE_BACKGROUND,
  FRAME_DISPOSE_RESTORE_PREVIOUS
} FrameDisposeMethod;

typedef struct {
  int x_offset, y_offset, width, height;
} WebPFrameRect;

// Clear pixels in 'picture' within given 'rect' to transparent color.
void WebPUtilClearPic(struct WebPPicture* const picture,
                      const WebPFrameRect* const rect);

//------------------------------------------------------------------------------
// Frame cache.

typedef struct WebPFrameCache WebPFrameCache;

// Given the minimum distance between key frames 'kmin' and maximum distance
// between key frames 'kmax', returns an appropriately allocated cache object.
// If 'allow_mixed' is true, the subsequent calls to WebPFrameCacheAddFrame()
// will heuristically pick lossy or lossless compression for each frame.
// Use WebPFrameCacheDelete() to deallocate the 'cache'.
WebPFrameCache* WebPFrameCacheNew(int width, int height,
                                  size_t kmin, size_t kmax, int allow_mixed);

// Release all the frame data from 'cache' and free 'cache'.
void WebPFrameCacheDelete(WebPFrameCache* const cache);

// Given an image described by 'frame', 'rect', 'dispose_method' and 'duration',
// optimize it for WebP, encode it and add it to 'cache'. 'rect' can be NULL.
// This takes care of frame disposal too, according to 'dispose_method'.
// Returns false in case of error (and sets frame->error_code accordingly).
int WebPFrameCacheAddFrame(WebPFrameCache* const cache,
                           const WebPConfig* const config,
                           const WebPFrameRect* const rect,
                           FrameDisposeMethod dispose_method, int duration,
                           WebPPicture* const frame);

// Flush the *ready* frames from cache and add them to 'mux'. If 'verbose' is
// true, prints the information about these frames.
WebPMuxError WebPFrameCacheFlush(WebPFrameCache* const cache, int verbose,
                                 WebPMux* const mux);

// Similar to 'WebPFrameCacheFlushFrames()', but flushes *all* the frames.
WebPMuxError WebPFrameCacheFlushAll(WebPFrameCache* const cache, int verbose,
                                    WebPMux* const mux);

//------------------------------------------------------------------------------

#ifdef __cplusplus
}    // extern "C"
#endif

#endif  // WEBP_EXAMPLES_GIF2WEBP_UTIL_H_
