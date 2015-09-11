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

#include <assert.h>
#include <stdio.h>

#include "utils/utils.h"
#include "webp/encode.h"
#include "./gif2webp_util.h"

#define DELTA_INFINITY      1ULL << 32
#define KEYFRAME_NONE       -1

//------------------------------------------------------------------------------
// Helper utilities.

static void ClearRectangle(WebPPicture* const picture,
                           int left, int top, int width, int height) {
  int j;
  for (j = top; j < top + height; ++j) {
    uint32_t* const dst = picture->argb + j * picture->argb_stride;
    int i;
    for (i = left; i < left + width; ++i) {
      dst[i] = WEBP_UTIL_TRANSPARENT_COLOR;
    }
  }
}

void WebPUtilClearPic(WebPPicture* const picture,
                      const WebPFrameRect* const rect) {
  if (rect != NULL) {
    ClearRectangle(picture, rect->x_offset, rect->y_offset,
                   rect->width, rect->height);
  } else {
    ClearRectangle(picture, 0, 0, picture->width, picture->height);
  }
}

// TODO: Also used in picture.c. Move to a common location?
// Copy width x height pixels from 'src' to 'dst' honoring the strides.
static void CopyPlane(const uint8_t* src, int src_stride,
                      uint8_t* dst, int dst_stride, int width, int height) {
  while (height-- > 0) {
    memcpy(dst, src, width);
    src += src_stride;
    dst += dst_stride;
  }
}

// Copy pixels from 'src' to 'dst' honoring strides. 'src' and 'dst' are assumed
// to be already allocated.
static void CopyPixels(const WebPPicture* const src, WebPPicture* const dst) {
  assert(src->width == dst->width && src->height == dst->height);
  CopyPlane((uint8_t*)src->argb, 4 * src->argb_stride, (uint8_t*)dst->argb,
            4 * dst->argb_stride, 4 * src->width, src->height);
}

// Given 'src' picture and its frame rectangle 'rect', blend it into 'dst'.
static void BlendPixels(const WebPPicture* const src,
                        const WebPFrameRect* const rect,
                        WebPPicture* const dst) {
  int j;
  assert(src->width == dst->width && src->height == dst->height);
  for (j = rect->y_offset; j < rect->y_offset + rect->height; ++j) {
    int i;
    for (i = rect->x_offset; i < rect->x_offset + rect->width; ++i) {
      const uint32_t src_pixel = src->argb[j * src->argb_stride + i];
      const int src_alpha = src_pixel >> 24;
      if (src_alpha != 0) {
        dst->argb[j * dst->argb_stride + i] = src_pixel;
      }
    }
  }
}

// Returns true if 'length' number of pixels in 'src' and 'dst' are identical,
// assuming the given step sizes between pixels.
static WEBP_INLINE int ComparePixels(const uint32_t* src, int src_step,
                                     const uint32_t* dst, int dst_step,
                                     int length) {
  assert(length > 0);
  while (length-- > 0) {
    if (*src != *dst) {
      return 0;
    }
    src += src_step;
    dst += dst_step;
  }
  return 1;
}

// Assumes that an initial valid guess of change rectangle 'rect' is passed.
static void MinimizeChangeRectangle(const WebPPicture* const src,
                                    const WebPPicture* const dst,
                                    WebPFrameRect* const rect) {
  int i, j;
  // Sanity checks.
  assert(src->width == dst->width && src->height == dst->height);
  assert(rect->x_offset + rect->width <= dst->width);
  assert(rect->y_offset + rect->height <= dst->height);

  // Left boundary.
  for (i = rect->x_offset; i < rect->x_offset + rect->width; ++i) {
    const uint32_t* const src_argb =
        &src->argb[rect->y_offset * src->argb_stride + i];
    const uint32_t* const dst_argb =
        &dst->argb[rect->y_offset * dst->argb_stride + i];
    if (ComparePixels(src_argb, src->argb_stride, dst_argb, dst->argb_stride,
                      rect->height)) {
      --rect->width;  // Redundant column.
      ++rect->x_offset;
    } else {
      break;
    }
  }
  if (rect->width == 0) goto End;

  // Right boundary.
  for (i = rect->x_offset + rect->width - 1; i >= rect->x_offset; --i) {
    const uint32_t* const src_argb =
        &src->argb[rect->y_offset * src->argb_stride + i];
    const uint32_t* const dst_argb =
        &dst->argb[rect->y_offset * dst->argb_stride + i];
    if (ComparePixels(src_argb, src->argb_stride, dst_argb, dst->argb_stride,
                      rect->height)) {
      --rect->width;  // Redundant column.
    } else {
      break;
    }
  }
  if (rect->width == 0) goto End;

  // Top boundary.
  for (j = rect->y_offset; j < rect->y_offset + rect->height; ++j) {
    const uint32_t* const src_argb =
        &src->argb[j * src->argb_stride + rect->x_offset];
    const uint32_t* const dst_argb =
        &dst->argb[j * dst->argb_stride + rect->x_offset];
    if (ComparePixels(src_argb, 1, dst_argb, 1, rect->width)) {
      --rect->height;  // Redundant row.
      ++rect->y_offset;
    } else {
      break;
    }
  }
  if (rect->height == 0) goto End;

  // Bottom boundary.
  for (j = rect->y_offset + rect->height - 1; j >= rect->y_offset; --j) {
    const uint32_t* const src_argb =
        &src->argb[j * src->argb_stride + rect->x_offset];
    const uint32_t* const dst_argb =
        &dst->argb[j * dst->argb_stride + rect->x_offset];
    if (ComparePixels(src_argb, 1, dst_argb, 1, rect->width)) {
      --rect->height;  // Redundant row.
    } else {
      break;
    }
  }
  if (rect->height == 0) goto End;

  if (rect->width == 0 || rect->height == 0) {
 End:
    // TODO(later): This rare case can happen for a bad GIF. In such a case, the
    // frame should not be encoded at all and the duration of prev frame should
    // be increased instead. For now, we just create a 1x1 frame at zero offset.
    rect->x_offset = 0;
    rect->y_offset = 0;
    rect->width = 1;
    rect->height = 1;
  }
}

// For pixels in 'rect', replace those pixels in 'dst' that are same as 'src' by
// transparent pixels.
static void IncreaseTransparency(const WebPPicture* const src,
                                 const WebPFrameRect* const rect,
                                 WebPPicture* const dst) {
  int i, j;
  assert(src != NULL && dst != NULL && rect != NULL);
  assert(src->width == dst->width && src->height == dst->height);
  for (j = rect->y_offset; j < rect->y_offset + rect->height; ++j) {
    const uint32_t* const psrc = src->argb + j * src->argb_stride;
    uint32_t* const pdst = dst->argb + j * dst->argb_stride;
    for (i = rect->x_offset; i < rect->x_offset + rect->width; ++i) {
      if (psrc[i] == pdst[i]) {
        pdst[i] = WEBP_UTIL_TRANSPARENT_COLOR;
      }
    }
  }
}

// Replace similar blocks of pixels by a 'see-through' transparent block
// with uniform average color.
static void FlattenSimilarBlocks(const WebPPicture* const src,
                                 const WebPFrameRect* const rect,
                                 WebPPicture* const dst) {
  int i, j;
  const int block_size = 8;
  const int y_start = (rect->y_offset + block_size) & ~(block_size - 1);
  const int y_end = (rect->y_offset + rect->height) & ~(block_size - 1);
  const int x_start = (rect->x_offset + block_size) & ~(block_size - 1);
  const int x_end = (rect->x_offset + rect->width) & ~(block_size - 1);
  assert(src != NULL && dst != NULL && rect != NULL);
  assert(src->width == dst->width && src->height == dst->height);
  assert((block_size & (block_size - 1)) == 0);  // must be a power of 2
  // Iterate over each block and count similar pixels.
  for (j = y_start; j < y_end; j += block_size) {
    for (i = x_start; i < x_end; i += block_size) {
      int cnt = 0;
      int avg_r = 0, avg_g = 0, avg_b = 0;
      int x, y;
      const uint32_t* const psrc = src->argb + j * src->argb_stride + i;
      uint32_t* const pdst = dst->argb + j * dst->argb_stride + i;
      for (y = 0; y < block_size; ++y) {
        for (x = 0; x < block_size; ++x) {
          const uint32_t src_pixel = psrc[x + y * src->argb_stride];
          const int alpha = src_pixel >> 24;
          if (alpha == 0xff &&
              src_pixel == pdst[x + y * dst->argb_stride]) {
              ++cnt;
              avg_r += (src_pixel >> 16) & 0xff;
              avg_g += (src_pixel >>  8) & 0xff;
              avg_b += (src_pixel >>  0) & 0xff;
          }
        }
      }
      // If we have a fully similar block, we replace it with an
      // average transparent block. This compresses better in lossy mode.
      if (cnt == block_size * block_size) {
        const uint32_t color = (0x00          << 24) |
                               ((avg_r / cnt) << 16) |
                               ((avg_g / cnt) <<  8) |
                               ((avg_b / cnt) <<  0);
        for (y = 0; y < block_size; ++y) {
          for (x = 0; x < block_size; ++x) {
            pdst[x + y * dst->argb_stride] = color;
          }
        }
      }
    }
  }
}

//------------------------------------------------------------------------------
// Encoded frame.

// Used to store two candidates of encoded data for an animation frame. One of
// the two will be chosen later.
typedef struct {
  WebPMuxFrameInfo sub_frame;  // Encoded frame rectangle.
  WebPMuxFrameInfo key_frame;  // Encoded frame if it was converted to keyframe.
  int is_key_frame;            // True if 'key_frame' has been chosen.
} EncodedFrame;

// Release the data contained by 'encoded_frame'.
static void FrameRelease(EncodedFrame* const encoded_frame) {
  if (encoded_frame != NULL) {
    WebPDataClear(&encoded_frame->sub_frame.bitstream);
    WebPDataClear(&encoded_frame->key_frame.bitstream);
    memset(encoded_frame, 0, sizeof(*encoded_frame));
  }
}

//------------------------------------------------------------------------------
// Frame cache.

// Used to store encoded frames that haven't been output yet.
struct WebPFrameCache {
  EncodedFrame* encoded_frames;  // Array of encoded frames.
  size_t size;               // Number of allocated data elements.
  size_t start;              // Start index.
  size_t count;              // Number of valid data elements.
  int flush_count;           // If >0, ‘flush_count’ frames starting from
                             // 'start' are ready to be added to mux.
  int64_t best_delta;        // min(canvas size - frame size) over the frames.
                             // Can be negative in certain cases due to
                             // transparent pixels in a frame.
  int keyframe;              // Index of selected keyframe relative to 'start'.

  size_t kmin;                   // Min distance between key frames.
  size_t kmax;                   // Max distance between key frames.
  size_t count_since_key_frame;  // Frames seen since the last key frame.
  int allow_mixed;           // If true, each frame can be lossy or lossless.

  WebPFrameRect prev_orig_rect;  // Previous input (e.g. GIF) frame rectangle.
  WebPFrameRect prev_webp_rect;  // Previous WebP frame rectangle.
  FrameDisposeMethod prev_orig_dispose;  // Previous input dispose method.
  int prev_candidate_undecided;  // True if sub-frame vs keyframe decision
                                 // hasn't been made for the previous frame yet.

  WebPPicture curr_canvas;           // Current canvas (NOT disposed).
  WebPPicture curr_canvas_tmp;       // Temporary storage for current canvas.
  WebPPicture prev_canvas;           // Previous canvas (NOT disposed).
  WebPPicture prev_canvas_disposed;  // Previous canvas disposed to background.
  WebPPicture prev_to_prev_canvas_disposed;  // Previous to previous canvas
                                             // (disposed as per its original
                                             // dispose method).
  int is_first_frame;        // True if no frames have been added to the cache
                             // since WebPFrameCacheNew().
};

// Reset the counters in the cache struct. Doesn't touch 'cache->encoded_frames'
// and 'cache->size'.
static void CacheReset(WebPFrameCache* const cache) {
  cache->start = 0;
  cache->count = 0;
  cache->flush_count = 0;
  cache->best_delta = DELTA_INFINITY;
  cache->keyframe = KEYFRAME_NONE;
}

WebPFrameCache* WebPFrameCacheNew(int width, int height,
                                  size_t kmin, size_t kmax, int allow_mixed) {
  WebPFrameCache* cache = (WebPFrameCache*)WebPSafeCalloc(1, sizeof(*cache));
  if (cache == NULL) return NULL;
  CacheReset(cache);
  // sanity init, so we can call WebPFrameCacheDelete():
  cache->encoded_frames = NULL;

  cache->prev_candidate_undecided = 0;
  cache->is_first_frame = 1;

  // Picture buffers.
  if (!WebPPictureInit(&cache->curr_canvas) ||
      !WebPPictureInit(&cache->curr_canvas_tmp) ||
      !WebPPictureInit(&cache->prev_canvas) ||
      !WebPPictureInit(&cache->prev_canvas_disposed) ||
      !WebPPictureInit(&cache->prev_to_prev_canvas_disposed)) {
    return NULL;
  }
  cache->curr_canvas.width = width;
  cache->curr_canvas.height = height;
  cache->curr_canvas.use_argb = 1;
  if (!WebPPictureAlloc(&cache->curr_canvas) ||
      !WebPPictureCopy(&cache->curr_canvas, &cache->curr_canvas_tmp) ||
      !WebPPictureCopy(&cache->curr_canvas, &cache->prev_canvas) ||
      !WebPPictureCopy(&cache->curr_canvas, &cache->prev_canvas_disposed) ||
      !WebPPictureCopy(&cache->curr_canvas,
                       &cache->prev_to_prev_canvas_disposed)) {
    goto Err;
  }
  WebPUtilClearPic(&cache->prev_canvas, NULL);
  WebPUtilClearPic(&cache->prev_canvas_disposed, NULL);
  WebPUtilClearPic(&cache->prev_to_prev_canvas_disposed, NULL);

  // Cache data.
  cache->allow_mixed = allow_mixed;
  cache->kmin = kmin;
  cache->kmax = kmax;
  cache->count_since_key_frame = 0;
  assert(kmax > kmin);
  cache->size = kmax - kmin + 1;  // One extra storage for previous frame.
  cache->encoded_frames = (EncodedFrame*)WebPSafeCalloc(
      cache->size, sizeof(*cache->encoded_frames));
  if (cache->encoded_frames == NULL) goto Err;

  return cache;  // All OK.

 Err:
  WebPFrameCacheDelete(cache);
  return NULL;
}

void WebPFrameCacheDelete(WebPFrameCache* const cache) {
  if (cache != NULL) {
    if (cache->encoded_frames != NULL) {
      size_t i;
      for (i = 0; i < cache->size; ++i) {
        FrameRelease(&cache->encoded_frames[i]);
      }
      WebPSafeFree(cache->encoded_frames);
    }
    WebPPictureFree(&cache->curr_canvas);
    WebPPictureFree(&cache->curr_canvas_tmp);
    WebPPictureFree(&cache->prev_canvas);
    WebPPictureFree(&cache->prev_canvas_disposed);
    WebPPictureFree(&cache->prev_to_prev_canvas_disposed);
    WebPSafeFree(cache);
  }
}

static int EncodeFrame(const WebPConfig* const config, WebPPicture* const pic,
                       WebPMemoryWriter* const memory) {
  pic->use_argb = 1;
  pic->writer = WebPMemoryWrite;
  pic->custom_ptr = memory;
  if (!WebPEncode(config, pic)) {
    return 0;
  }
  return 1;
}

static void GetEncodedData(const WebPMemoryWriter* const memory,
                           WebPData* const encoded_data) {
  encoded_data->bytes = memory->mem;
  encoded_data->size  = memory->size;
}

#define MIN_COLORS_LOSSY     31  // Don't try lossy below this threshold.
#define MAX_COLORS_LOSSLESS 194  // Don't try lossless above this threshold.
#define MAX_COLOR_COUNT     256  // Power of 2 greater than MAX_COLORS_LOSSLESS.
#define HASH_SIZE (MAX_COLOR_COUNT * 4)
#define HASH_RIGHT_SHIFT     22  // 32 - log2(HASH_SIZE).

// TODO(urvang): Also used in enc/vp8l.c. Move to utils.
// If the number of colors in the 'pic' is at least MAX_COLOR_COUNT, return
// MAX_COLOR_COUNT. Otherwise, return the exact number of colors in the 'pic'.
static int GetColorCount(const WebPPicture* const pic) {
  int x, y;
  int num_colors = 0;
  uint8_t in_use[HASH_SIZE] = { 0 };
  uint32_t colors[HASH_SIZE];
  static const uint32_t kHashMul = 0x1e35a7bd;
  const uint32_t* argb = pic->argb;
  const int width = pic->width;
  const int height = pic->height;
  uint32_t last_pix = ~argb[0];   // so we're sure that last_pix != argb[0]

  for (y = 0; y < height; ++y) {
    for (x = 0; x < width; ++x) {
      int key;
      if (argb[x] == last_pix) {
        continue;
      }
      last_pix = argb[x];
      key = (kHashMul * last_pix) >> HASH_RIGHT_SHIFT;
      while (1) {
        if (!in_use[key]) {
          colors[key] = last_pix;
          in_use[key] = 1;
          ++num_colors;
          if (num_colors >= MAX_COLOR_COUNT) {
            return MAX_COLOR_COUNT;  // Exact count not needed.
          }
          break;
        } else if (colors[key] == last_pix) {
          break;  // The color is already there.
        } else {
          // Some other color sits here, so do linear conflict resolution.
          ++key;
          key &= (HASH_SIZE - 1);  // Key mask.
        }
      }
    }
    argb += pic->argb_stride;
  }
  return num_colors;
}

#undef MAX_COLOR_COUNT
#undef HASH_SIZE
#undef HASH_RIGHT_SHIFT

static void DisposeFrameRectangle(int dispose_method,
                                  const WebPFrameRect* const rect,
                                  const WebPPicture* const prev_canvas,
                                  WebPPicture* const curr_canvas) {
  assert(rect != NULL);
  if (dispose_method == FRAME_DISPOSE_BACKGROUND) {
    WebPUtilClearPic(curr_canvas, rect);
  } else if (dispose_method == FRAME_DISPOSE_RESTORE_PREVIOUS) {
    const int src_stride = prev_canvas->argb_stride;
    const uint32_t* const src =
        prev_canvas->argb + rect->x_offset + rect->y_offset * src_stride;
    const int dst_stride = curr_canvas->argb_stride;
    uint32_t* const dst =
        curr_canvas->argb + rect->x_offset + rect->y_offset * dst_stride;
    assert(prev_canvas != NULL);
    CopyPlane((uint8_t*)src, 4 * src_stride, (uint8_t*)dst, 4 * dst_stride,
              4 * rect->width, rect->height);
  }
}

// Snap rectangle to even offsets (and adjust dimensions if needed).
static WEBP_INLINE void SnapToEvenOffsets(WebPFrameRect* const rect) {
  rect->width += (rect->x_offset & 1);
  rect->height += (rect->y_offset & 1);
  rect->x_offset &= ~1;
  rect->y_offset &= ~1;
}

// Given previous and current canvas, picks the optimal rectangle for the
// current frame.
// The initial guess for 'rect' will be 'orig_rect' if is non-NULL, otherwise
// the initial guess will be the full canvas.
static int GetSubRect(const WebPPicture* const prev_canvas,
                      const WebPPicture* const curr_canvas,
                      const WebPFrameRect* const orig_rect, int is_key_frame,
                      WebPFrameRect* const rect, WebPPicture* const sub_frame) {
  if (orig_rect != NULL) {
    *rect = *orig_rect;
  } else {
    rect->x_offset = 0;
    rect->y_offset = 0;
    rect->width = curr_canvas->width;
    rect->height = curr_canvas->height;
  }
  if (!is_key_frame) {  // Optimize frame rectangle.
    MinimizeChangeRectangle(prev_canvas, curr_canvas, rect);
  }
  SnapToEvenOffsets(rect);

  return WebPPictureView(curr_canvas, rect->x_offset, rect->y_offset,
                         rect->width, rect->height, sub_frame);
}

static int IsBlendingPossible(const WebPPicture* const src,
                              const WebPPicture* const dst,
                              const WebPFrameRect* const rect) {
  int i, j;
  assert(src->width == dst->width && src->height == dst->height);
  assert(rect->x_offset + rect->width <= dst->width);
  assert(rect->y_offset + rect->height <= dst->height);
  for (j = rect->y_offset; j < rect->y_offset + rect->height; ++j) {
    for (i = rect->x_offset; i < rect->x_offset + rect->width; ++i) {
      const uint32_t src_pixel = src->argb[j * src->argb_stride + i];
      const uint32_t dst_pixel = dst->argb[j * dst->argb_stride + i];
      const uint32_t dst_alpha = dst_pixel >> 24;
      if (dst_alpha != 0xff && src_pixel != dst_pixel) {
        // In this case, if we use blending, we can't attain the desired
        // 'dst_pixel' value for this pixel. So, blending is not possible.
        return 0;
      }
    }
  }
  return 1;
}

static int RectArea(const WebPFrameRect* const rect) {
  return rect->width * rect->height;
}

// Struct representing a candidate encoded frame including its metadata.
typedef struct {
  WebPMemoryWriter  mem;
  WebPMuxFrameInfo  info;
  WebPFrameRect     rect;
  int               evaluate;  // True if this candidate should be evaluated.
} Candidate;

// Generates a candidate encoded frame given a picture and metadata.
static WebPEncodingError EncodeCandidate(WebPPicture* const sub_frame,
                                         const WebPFrameRect* const rect,
                                         const WebPConfig* const config,
                                         int use_blending, int duration,
                                         Candidate* const candidate) {
  WebPEncodingError error_code = VP8_ENC_OK;
  assert(candidate != NULL);
  memset(candidate, 0, sizeof(*candidate));

  // Set frame rect and info.
  candidate->rect = *rect;
  candidate->info.id = WEBP_CHUNK_ANMF;
  candidate->info.x_offset = rect->x_offset;
  candidate->info.y_offset = rect->y_offset;
  candidate->info.dispose_method = WEBP_MUX_DISPOSE_NONE;  // Set later.
  candidate->info.blend_method =
      use_blending ? WEBP_MUX_BLEND : WEBP_MUX_NO_BLEND;
  candidate->info.duration = duration;

  // Encode picture.
  WebPMemoryWriterInit(&candidate->mem);

  if (!EncodeFrame(config, sub_frame, &candidate->mem)) {
    error_code = sub_frame->error_code;
    goto Err;
  }

  candidate->evaluate = 1;
  return error_code;

 Err:
#if WEBP_ENCODER_ABI_VERSION > 0x0203
  WebPMemoryWriterClear(&candidate->mem);
#else
  free(candidate->mem.mem);
  memset(&candidate->mem, 0, sizeof(candidate->mem));
#endif
  return error_code;
}

// Returns cached frame at given 'position' index.
static EncodedFrame* CacheGetFrame(const WebPFrameCache* const cache,
                                   size_t position) {
  assert(cache->start + position < cache->size);
  return &cache->encoded_frames[cache->start + position];
}

// Sets dispose method of the previous frame to be 'dispose_method'.
static void SetPreviousDisposeMethod(WebPFrameCache* const cache,
                                     WebPMuxAnimDispose dispose_method) {
  const size_t position = cache->count - 2;
  EncodedFrame* const prev_enc_frame = CacheGetFrame(cache, position);
  assert(cache->count >= 2);  // As current and previous frames are in cache.

  if (cache->prev_candidate_undecided) {
    assert(dispose_method == WEBP_MUX_DISPOSE_NONE);
    prev_enc_frame->sub_frame.dispose_method = dispose_method;
    prev_enc_frame->key_frame.dispose_method = dispose_method;
  } else {
    WebPMuxFrameInfo* const prev_info = prev_enc_frame->is_key_frame
                                        ? &prev_enc_frame->key_frame
                                        : &prev_enc_frame->sub_frame;
    prev_info->dispose_method = dispose_method;
  }
}

enum {
  LL_DISP_NONE = 0,
  LL_DISP_BG,
  LOSSY_DISP_NONE,
  LOSSY_DISP_BG,
  CANDIDATE_COUNT
};

// Generates candidates for a given dispose method given pre-filled 'rect'
// and 'sub_frame'.
static WebPEncodingError GenerateCandidates(
    WebPFrameCache* const cache, Candidate candidates[CANDIDATE_COUNT],
    WebPMuxAnimDispose dispose_method, int is_lossless, int is_key_frame,
    const WebPFrameRect* const rect, WebPPicture* sub_frame, int duration,
    const WebPConfig* const config_ll, const WebPConfig* const config_lossy) {
  WebPEncodingError error_code = VP8_ENC_OK;
  const int is_dispose_none = (dispose_method == WEBP_MUX_DISPOSE_NONE);
  Candidate* const candidate_ll =
      is_dispose_none ? &candidates[LL_DISP_NONE] : &candidates[LL_DISP_BG];
  Candidate* const candidate_lossy = is_dispose_none
                                     ? &candidates[LOSSY_DISP_NONE]
                                     : &candidates[LOSSY_DISP_BG];
  WebPPicture* const curr_canvas = &cache->curr_canvas;
  WebPPicture* const curr_canvas_tmp = &cache->curr_canvas_tmp;
  const WebPPicture* const prev_canvas =
      is_dispose_none ? &cache->prev_canvas : &cache->prev_canvas_disposed;
  const int use_blending =
      !is_key_frame &&
      IsBlendingPossible(prev_canvas, curr_canvas, rect);
  int curr_canvas_saved = 0;  // If 'curr_canvas' is saved in 'curr_canvas_tmp'.

  // Pick candidates to be tried.
  if (!cache->allow_mixed) {
    candidate_ll->evaluate = is_lossless;
    candidate_lossy->evaluate = !is_lossless;
  } else {  // Use a heuristic for trying lossless and/or lossy compression.
    const int num_colors = GetColorCount(sub_frame);
    candidate_ll->evaluate = (num_colors < MAX_COLORS_LOSSLESS);
    candidate_lossy->evaluate = (num_colors >= MIN_COLORS_LOSSY);
  }

  // Generate candidates.
  if (candidate_ll->evaluate) {
    if (use_blending) {
      CopyPixels(curr_canvas, curr_canvas_tmp);  // save
      curr_canvas_saved = 1;
      IncreaseTransparency(prev_canvas, rect, curr_canvas);
    }
    error_code = EncodeCandidate(sub_frame, rect, config_ll, use_blending,
                                 duration, candidate_ll);
    if (error_code != VP8_ENC_OK) return error_code;
    if (use_blending) {
      CopyPixels(curr_canvas_tmp, curr_canvas);  // restore
    }
  }
  if (candidate_lossy->evaluate) {
    if (!is_key_frame) {
      // For lossy compression of a frame, it's better to:
      // * Replace transparent pixels of 'curr' with actual RGB values,
      //   whenever possible, and
      // * Replace similar blocks of pixels by a transparent block.
      if (!curr_canvas_saved) {  // save if not already done so.
        CopyPixels(curr_canvas, curr_canvas_tmp);
      }
      FlattenSimilarBlocks(prev_canvas, rect, curr_canvas);
    }
    error_code = EncodeCandidate(sub_frame, rect, config_lossy, use_blending,
                                 duration, candidate_lossy);
    if (error_code != VP8_ENC_OK) return error_code;
    if (!is_key_frame) {
      CopyPixels(curr_canvas_tmp, curr_canvas);  // restore
    }
  }
  return error_code;
}

// Pick the candidate encoded frame with smallest size and release other
// candidates.
// TODO(later): Perhaps a rough SSIM/PSNR produced by the encoder should
// also be a criteria, in addition to sizes.
static void PickBestCandidate(WebPFrameCache* const cache,
                              Candidate* const candidates, int is_key_frame,
                              EncodedFrame* const encoded_frame) {
  int i;
  int best_idx = -1;
  size_t best_size = ~0;
  for (i = 0; i < CANDIDATE_COUNT; ++i) {
    if (candidates[i].evaluate) {
      const size_t candidate_size = candidates[i].mem.size;
      if (candidate_size < best_size) {
        best_idx = i;
        best_size = candidate_size;
      }
    }
  }
  assert(best_idx != -1);
  for (i = 0; i < CANDIDATE_COUNT; ++i) {
    if (candidates[i].evaluate) {
      if (i == best_idx) {
        WebPMuxFrameInfo* const dst = is_key_frame
                                      ? &encoded_frame->key_frame
                                      : &encoded_frame->sub_frame;
        *dst = candidates[i].info;
        GetEncodedData(&candidates[i].mem, &dst->bitstream);
        if (!is_key_frame) {
          // Note: Previous dispose method only matters for non-keyframes.
          // Also, we don't want to modify previous dispose method that was
          // selected when a non key-frame was assumed.
          const WebPMuxAnimDispose prev_dispose_method =
              (best_idx == LL_DISP_NONE || best_idx == LOSSY_DISP_NONE)
                  ? WEBP_MUX_DISPOSE_NONE
                  : WEBP_MUX_DISPOSE_BACKGROUND;
          SetPreviousDisposeMethod(cache, prev_dispose_method);
        }
        cache->prev_webp_rect = candidates[i].rect;  // save for next frame.
      } else {
#if WEBP_ENCODER_ABI_VERSION > 0x0203
        WebPMemoryWriterClear(&candidates[i].mem);
#else
        free(candidates[i].mem.mem);
        memset(&candidates[i].mem, 0, sizeof(candidates[i].mem));
#endif
        candidates[i].evaluate = 0;
      }
    }
  }
}

// Depending on the configuration, tries different compressions
// (lossy/lossless), dispose methods, blending methods etc to encode the current
// frame and outputs the best one in 'encoded_frame'.
static WebPEncodingError SetFrame(WebPFrameCache* const cache,
                                  const WebPConfig* const config, int duration,
                                  const WebPFrameRect* const orig_rect,
                                  int is_key_frame,
                                  EncodedFrame* const encoded_frame) {
  int i;
  WebPEncodingError error_code = VP8_ENC_OK;
  WebPPicture* const curr_canvas = &cache->curr_canvas;
  const WebPPicture* const prev_canvas = &cache->prev_canvas;
  WebPPicture* const prev_canvas_disposed = &cache->prev_canvas_disposed;
  Candidate candidates[CANDIDATE_COUNT];
  const int is_lossless = config->lossless;

  int try_dispose_none = 1;  // Default.
  WebPFrameRect rect_none;
  WebPPicture sub_frame_none;

  // If current frame is a key-frame, dispose method of previous frame doesn't
  // matter, so we don't try dispose to background.
  // Also, if keyframe insertion is on, and previous frame could be picked as
  // either a sub-frame or a keyframe, then we can't be sure about what frame
  // rectangle would be disposed. In that case too, we don't try dispose to
  // background.
  const int dispose_bg_possible =
      !is_key_frame && !cache->prev_candidate_undecided;
  int try_dispose_bg = 0;  // Default.
  WebPFrameRect rect_bg;
  WebPPicture sub_frame_bg;

  WebPConfig config_ll = *config;
  WebPConfig config_lossy = *config;
  config_ll.lossless = 1;
  config_lossy.lossless = 0;

  if (!WebPPictureInit(&sub_frame_none) || !WebPPictureInit(&sub_frame_bg)) {
    return VP8_ENC_ERROR_INVALID_CONFIGURATION;
  }

  for (i = 0; i < CANDIDATE_COUNT; ++i) {
    candidates[i].evaluate = 0;
  }

  // Change-rectangle assuming previous frame was DISPOSE_NONE.
  GetSubRect(prev_canvas, curr_canvas, orig_rect, is_key_frame,
             &rect_none, &sub_frame_none);

  if (dispose_bg_possible) {
    // Change-rectangle assuming previous frame was DISPOSE_BACKGROUND.
    CopyPixels(prev_canvas, prev_canvas_disposed);
    DisposeFrameRectangle(WEBP_MUX_DISPOSE_BACKGROUND, &cache->prev_webp_rect,
                          NULL, prev_canvas_disposed);
    GetSubRect(prev_canvas_disposed, curr_canvas, orig_rect, is_key_frame,
               &rect_bg, &sub_frame_bg);

    if (RectArea(&rect_bg) < RectArea(&rect_none)) {
      try_dispose_bg = 1;  // Pick DISPOSE_BACKGROUND.
      try_dispose_none = 0;
    }
  }

  if (try_dispose_none) {
    error_code = GenerateCandidates(
        cache, candidates, WEBP_MUX_DISPOSE_NONE, is_lossless, is_key_frame,
        &rect_none, &sub_frame_none, duration, &config_ll, &config_lossy);
    if (error_code != VP8_ENC_OK) goto Err;
  }

  if (try_dispose_bg) {
    assert(!cache->is_first_frame);
    assert(dispose_bg_possible);
    error_code =
        GenerateCandidates(cache, candidates, WEBP_MUX_DISPOSE_BACKGROUND,
                           is_lossless, is_key_frame, &rect_bg, &sub_frame_bg,
                           duration, &config_ll, &config_lossy);
    if (error_code != VP8_ENC_OK) goto Err;
  }

  PickBestCandidate(cache, candidates, is_key_frame, encoded_frame);

  goto End;

 Err:
  for (i = 0; i < CANDIDATE_COUNT; ++i) {
    if (candidates[i].evaluate) {
#if WEBP_ENCODER_ABI_VERSION > 0x0203
      WebPMemoryWriterClear(&candidates[i].mem);
#else
      free(candidates[i].mem.mem);
      memset(&candidates[i].mem, 0, sizeof(candidates[i].mem));
#endif
    }
  }

 End:
  WebPPictureFree(&sub_frame_none);
  WebPPictureFree(&sub_frame_bg);
  return error_code;
}

#undef MIN_COLORS_LOSSY
#undef MAX_COLORS_LOSSLESS

// Calculate the penalty incurred if we encode given frame as a key frame
// instead of a sub-frame.
static int64_t KeyFramePenalty(const EncodedFrame* const encoded_frame) {
  return ((int64_t)encoded_frame->key_frame.bitstream.size -
          encoded_frame->sub_frame.bitstream.size);
}

int WebPFrameCacheAddFrame(WebPFrameCache* const cache,
                           const WebPConfig* const config,
                           const WebPFrameRect* const orig_rect_ptr,
                           FrameDisposeMethod orig_dispose_method,
                           int duration, WebPPicture* const frame) {
  // Initialize.
  int ok = 0;
  WebPEncodingError error_code = VP8_ENC_OK;
  WebPPicture* const curr_canvas = &cache->curr_canvas;
  WebPPicture* const prev_canvas = &cache->prev_canvas;
  WebPPicture* const prev_to_prev_canvas_disposed =
      &cache->prev_to_prev_canvas_disposed;
  WebPPicture* const prev_canvas_disposed = &cache->prev_canvas_disposed;
  const size_t position = cache->count;
  EncodedFrame* const encoded_frame = CacheGetFrame(cache, position);
  WebPFrameRect orig_rect;
  assert(position < cache->size);

  if (frame == NULL) {
    return 0;
  }

  // As we are encoding (part of) 'curr_canvas', and not 'frame' directly, make
  // sure the progress is still reported back.
  curr_canvas->progress_hook = frame->progress_hook;
  curr_canvas->user_data = frame->user_data;
  curr_canvas->stats = frame->stats;

  if (orig_rect_ptr == NULL) {
    orig_rect.width = frame->width;
    orig_rect.height = frame->height;
    orig_rect.x_offset = 0;
    orig_rect.y_offset = 0;
  } else {
    orig_rect = *orig_rect_ptr;
  }

  // Main frame addition.
  ++cache->count;

  if (cache->is_first_frame) {
    // 'curr_canvas' is same as 'frame'.
    CopyPixels(frame, curr_canvas);
    // Add this as a key frame.
    // Note: we use original rectangle as-is for the first frame.
    error_code =
        SetFrame(cache, config, duration, &orig_rect, 1, encoded_frame);
    if (error_code != VP8_ENC_OK) {
      goto End;
    }
    assert(position == 0 && cache->count == 1);
    encoded_frame->is_key_frame = 1;
    cache->flush_count = 0;
    cache->count_since_key_frame = 0;
    cache->prev_candidate_undecided = 0;
  } else {
    // Store previous to previous and previous canvases.
    CopyPixels(prev_canvas_disposed, prev_to_prev_canvas_disposed);
    CopyPixels(curr_canvas, prev_canvas);
    // Create curr_canvas:
    // * Start with disposed previous canvas.
    // * Then blend 'frame' onto it.
    DisposeFrameRectangle(cache->prev_orig_dispose, &cache->prev_orig_rect,
                          prev_to_prev_canvas_disposed, curr_canvas);
    CopyPixels(curr_canvas, prev_canvas_disposed);
    BlendPixels(frame, &orig_rect, curr_canvas);

    ++cache->count_since_key_frame;
    if (cache->count_since_key_frame <= cache->kmin) {
      // Add this as a frame rectangle.
      error_code = SetFrame(cache, config, duration, NULL, 0, encoded_frame);
      if (error_code != VP8_ENC_OK) {
        goto End;
      }
      encoded_frame->is_key_frame = 0;
      cache->flush_count = cache->count - 1;
      cache->prev_candidate_undecided = 0;
    } else {
      int64_t curr_delta;

      // Add frame rectangle to cache.
      error_code = SetFrame(cache, config, duration, NULL, 0, encoded_frame);
      if (error_code != VP8_ENC_OK) {
        goto End;
      }

      // Add key frame to cache, too.
      error_code = SetFrame(cache, config, duration, NULL, 1, encoded_frame);
      if (error_code != VP8_ENC_OK) goto End;

      // Analyze size difference of the two variants.
      curr_delta = KeyFramePenalty(encoded_frame);
      if (curr_delta <= cache->best_delta) {  // Pick this as keyframe.
        if (cache->keyframe != KEYFRAME_NONE) {
          EncodedFrame* const old_keyframe =
              CacheGetFrame(cache, cache->keyframe);
          assert(old_keyframe->is_key_frame);
          old_keyframe->is_key_frame = 0;
        }
        encoded_frame->is_key_frame = 1;
        cache->keyframe = position;
        cache->best_delta = curr_delta;
        cache->flush_count = cache->count - 1;  // We can flush previous frames.
      } else {
        encoded_frame->is_key_frame = 0;
      }
      if (cache->count_since_key_frame == cache->kmax) {
        cache->flush_count = cache->count - 1;
        cache->count_since_key_frame = 0;
      }
      cache->prev_candidate_undecided = 1;
    }
    // Recalculate prev_canvas_disposed (as it might have been modified).
    CopyPixels(prev_canvas, prev_canvas_disposed);
    DisposeFrameRectangle(cache->prev_orig_dispose, &cache->prev_orig_rect,
                          prev_to_prev_canvas_disposed, prev_canvas_disposed);
  }

  // Dispose the 'frame'.
  DisposeFrameRectangle(orig_dispose_method, &orig_rect, prev_canvas_disposed,
                        frame);

  cache->is_first_frame = 0;
  cache->prev_orig_dispose = orig_dispose_method;
  cache->prev_orig_rect = orig_rect;
  ok = 1;

 End:
  if (!ok) {
    FrameRelease(encoded_frame);
    --cache->count;  // We reset the count, as the frame addition failed.
  }
  frame->error_code = error_code;   // report error_code
  assert(ok || error_code != VP8_ENC_OK);
  return ok;
}

WebPMuxError WebPFrameCacheFlush(WebPFrameCache* const cache, int verbose,
                                 WebPMux* const mux) {
  while (cache->flush_count > 0) {
    WebPMuxFrameInfo* info;
    WebPMuxError err;
    EncodedFrame* const curr = CacheGetFrame(cache, 0);
    // Pick frame or full canvas.
    if (curr->is_key_frame) {
      info = &curr->key_frame;
      if (cache->keyframe == 0) {
        cache->keyframe = KEYFRAME_NONE;
        cache->best_delta = DELTA_INFINITY;
      }
    } else {
      info = &curr->sub_frame;
    }
    // Add to mux.
    err = WebPMuxPushFrame(mux, info, 1);
    if (err != WEBP_MUX_OK) return err;
    if (verbose) {
      printf("Added frame. offset:%d,%d duration:%d dispose:%d blend:%d\n",
             info->x_offset, info->y_offset, info->duration,
             info->dispose_method, info->blend_method);
    }
    FrameRelease(curr);
    ++cache->start;
    --cache->flush_count;
    --cache->count;
    if (cache->keyframe != KEYFRAME_NONE) --cache->keyframe;
  }

  if (cache->count == 1 && cache->start != 0) {
    // Move cache->start to index 0.
    const int cache_start_tmp = (int)cache->start;
    EncodedFrame temp = cache->encoded_frames[0];
    cache->encoded_frames[0] = cache->encoded_frames[cache_start_tmp];
    cache->encoded_frames[cache_start_tmp] = temp;
    FrameRelease(&cache->encoded_frames[cache_start_tmp]);
    cache->start = 0;
  }
  return WEBP_MUX_OK;
}

WebPMuxError WebPFrameCacheFlushAll(WebPFrameCache* const cache, int verbose,
                                    WebPMux* const mux) {
  cache->flush_count = cache->count;  // Force flushing of all frames.
  return WebPFrameCacheFlush(cache, verbose, mux);
}

//------------------------------------------------------------------------------
