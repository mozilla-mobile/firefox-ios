// Copyright 2012 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
// Rescaling functions
//
// Author: Skal (pascal.massimino@gmail.com)

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "./rescaler.h"
#include "../dsp/dsp.h"

//------------------------------------------------------------------------------
// Implementations of critical functions ImportRow / ExportRow

// Import a row of data and save its contribution in the rescaler.
// 'channel' denotes the channel number to be imported. 'Expand' corresponds to
// the wrk->x_expand case. Otherwise, 'Shrink' is to be used.
typedef void (*WebPRescalerImportRowFunc)(WebPRescaler* const wrk,
                                          const uint8_t* src);
static WebPRescalerImportRowFunc WebPRescalerImportRowExpand;
static WebPRescalerImportRowFunc WebPRescalerImportRowShrink;

// Export one row (starting at x_out position) from rescaler.
// 'Expand' corresponds to the wrk->y_expand case.
// Otherwise 'Shrink' is to be used
typedef void (*WebPRescalerExportRowFunc)(WebPRescaler* const wrk);
static WebPRescalerExportRowFunc WebPRescalerExportRowExpand;
static WebPRescalerExportRowFunc WebPRescalerExportRowShrink;

#define WEBP_RESCALER_RFIX 32   // fixed-point precision for multiplies
#define WEBP_RESCALER_ONE (1ull << WEBP_RESCALER_RFIX)
#define WEBP_RESCALER_FRAC(x, y) \
    ((uint32_t)(((uint64_t)(x) << WEBP_RESCALER_RFIX) / (y)))
#define ROUNDER (WEBP_RESCALER_ONE >> 1)
#define MULT_FIX(x, y) (((uint64_t)(x) * (y) + ROUNDER) >> WEBP_RESCALER_RFIX)

static void ImportRowExpandC(WebPRescaler* const wrk, const uint8_t* src) {
  const int x_stride = wrk->num_channels;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  int channel;
  assert(!WebPRescalerInputDone(wrk));
  assert(wrk->x_expand);
  for (channel = 0; channel < x_stride; ++channel) {
    int x_in = channel;
    int x_out = channel;
    // simple bilinear interpolation
    int accum = wrk->x_add;
    int left = src[x_in];
    int right = (wrk->src_width > 1) ? src[x_in + x_stride] : left;
    x_in += x_stride;
    while (1) {
      wrk->frow[x_out] = right * wrk->x_add + (left - right) * accum;
      x_out += x_stride;
      if (x_out >= x_out_max) break;
      accum -= wrk->x_sub;
      if (accum < 0) {
        left = right;
        x_in += x_stride;
        assert(x_in < wrk->src_width * x_stride);
        right = src[x_in];
        accum += wrk->x_add;
      }
    }
    assert(wrk->x_sub == 0 /* <- special case for src_width=1 */ || accum == 0);
  }
}

static void ImportRowShrinkC(WebPRescaler* const wrk, const uint8_t* src) {
  const int x_stride = wrk->num_channels;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  int channel;
  assert(!WebPRescalerInputDone(wrk));
  assert(!wrk->x_expand);
  for (channel = 0; channel < x_stride; ++channel) {
    int x_in = channel;
    int x_out = channel;
    uint32_t sum = 0;
    int accum = 0;
    while (x_out < x_out_max) {
      uint32_t base = 0;
      accum += wrk->x_add;
      while (accum > 0) {
        accum -= wrk->x_sub;
        assert(x_in < wrk->src_width * x_stride);
        base = src[x_in];
        sum += base;
        x_in += x_stride;
      }
      {        // Emit next horizontal pixel.
        const rescaler_t frac = base * (-accum);
        wrk->frow[x_out] = sum * wrk->x_sub - frac;
        // fresh fractional start for next pixel
        sum = (int)MULT_FIX(frac, wrk->fx_scale);
      }
      x_out += x_stride;
    }
    assert(accum == 0);
  }
}

//------------------------------------------------------------------------------
// Row export

static void ExportRowExpandC(WebPRescaler* const wrk) {
  int x_out;
  uint8_t* const dst = wrk->dst;
  rescaler_t* const irow = wrk->irow;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  const rescaler_t* const frow = wrk->frow;
  assert(!WebPRescalerOutputDone(wrk));
  assert(wrk->y_accum <= 0);
  assert(wrk->y_expand);
  assert(wrk->y_sub != 0);
  if (wrk->y_accum == 0) {
    for (x_out = 0; x_out < x_out_max; ++x_out) {
      const uint32_t J = frow[x_out];
      const int v = (int)MULT_FIX(J, wrk->fy_scale);
      assert(v >= 0 && v <= 255);
      dst[x_out] = v;
    }
  } else {
    const uint32_t B = WEBP_RESCALER_FRAC(-wrk->y_accum, wrk->y_sub);
    const uint32_t A = (uint32_t)(WEBP_RESCALER_ONE - B);
    for (x_out = 0; x_out < x_out_max; ++x_out) {
      const uint64_t I = (uint64_t)A * frow[x_out]
                       + (uint64_t)B * irow[x_out];
      const uint32_t J = (uint32_t)((I + ROUNDER) >> WEBP_RESCALER_RFIX);
      const int v = (int)MULT_FIX(J, wrk->fy_scale);
      assert(v >= 0 && v <= 255);
      dst[x_out] = v;
    }
  }
}

static void ExportRowShrinkC(WebPRescaler* const wrk) {
  int x_out;
  uint8_t* const dst = wrk->dst;
  rescaler_t* const irow = wrk->irow;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  const rescaler_t* const frow = wrk->frow;
  const uint32_t yscale = wrk->fy_scale * (-wrk->y_accum);
  assert(!WebPRescalerOutputDone(wrk));
  assert(wrk->y_accum <= 0);
  assert(!wrk->y_expand);
  if (yscale) {
    for (x_out = 0; x_out < x_out_max; ++x_out) {
      const uint32_t frac = (uint32_t)MULT_FIX(frow[x_out], yscale);
      const int v = (int)MULT_FIX(irow[x_out] - frac, wrk->fxy_scale);
      assert(v >= 0 && v <= 255);
      dst[x_out] = v;
      irow[x_out] = frac;   // new fractional start
    }
  } else {
    for (x_out = 0; x_out < x_out_max; ++x_out) {
      const int v = (int)MULT_FIX(irow[x_out], wrk->fxy_scale);
      assert(v >= 0 && v <= 255);
      dst[x_out] = v;
      irow[x_out] = 0;
    }
  }
}

//------------------------------------------------------------------------------
// Main entry calls

void WebPRescalerImportRow(WebPRescaler* const wrk, const uint8_t* src) {
  assert(!WebPRescalerInputDone(wrk));
  if (!wrk->x_expand) {
    WebPRescalerImportRowShrink(wrk, src);
  } else {
    WebPRescalerImportRowExpand(wrk, src);
  }
}

void WebPRescalerExportRow(WebPRescaler* const wrk) {
  if (wrk->y_accum <= 0) {
    assert(!WebPRescalerOutputDone(wrk));
    if (wrk->y_expand) {
      WebPRescalerExportRowExpand(wrk);
    } else if (wrk->fxy_scale) {
      WebPRescalerExportRowShrink(wrk);
    } else {  // very special case for src = dst = 1x1
      int i;
      assert(wrk->src_width == 1 && wrk->dst_width <= 2);
      assert(wrk->src_height == 1 && wrk->dst_height == 1);
      for (i = 0; i < wrk->num_channels * wrk->dst_width; ++i) {
        wrk->dst[i] = wrk->irow[i];
        wrk->irow[i] = 0;
      }
    }
    wrk->y_accum += wrk->y_add;
    wrk->dst += wrk->dst_stride;
    ++wrk->dst_y;
  }
}

//------------------------------------------------------------------------------
// MIPS version

#if defined(WEBP_USE_MIPS32)

static void ImportRowShrinkMIPS(WebPRescaler* const wrk, const uint8_t* src) {
  const int x_stride = wrk->num_channels;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  const int fx_scale = wrk->fx_scale;
  const int x_add = wrk->x_add;
  const int x_sub = wrk->x_sub;
  const int x_stride1 = x_stride << 2;
  int channel;
  assert(!wrk->x_expand);
  assert(!WebPRescalerInputDone(wrk));

  for (channel = 0; channel < x_stride; ++channel) {
    const uint8_t* src1 = src + channel;
    rescaler_t* frow = wrk->frow + channel;
    int temp1, temp2, temp3;
    int base, frac, sum;
    int accum, accum1;
    int loop_c = x_out_max - channel;

    __asm__ volatile (
      "li     %[temp1],   0x8000                    \n\t"
      "li     %[temp2],   0x10000                   \n\t"
      "li     %[sum],     0                         \n\t"
      "li     %[accum],   0                         \n\t"
    "1:                                             \n\t"
      "addu   %[accum],   %[accum],   %[x_add]      \n\t"
      "li     %[base],    0                         \n\t"
      "blez   %[accum],   3f                        \n\t"
    "2:                                             \n\t"
      "lbu    %[base],    0(%[src1])                \n\t"
      "subu   %[accum],   %[accum],   %[x_sub]      \n\t"
      "addu   %[src1],    %[src1],    %[x_stride]   \n\t"
      "addu   %[sum],     %[sum],     %[base]       \n\t"
      "bgtz   %[accum],   2b                        \n\t"
    "3:                                             \n\t"
      "negu   %[accum1],  %[accum]                  \n\t"
      "mul    %[frac],    %[base],    %[accum1]     \n\t"
      "mul    %[temp3],   %[sum],     %[x_sub]      \n\t"
      "subu   %[loop_c],  %[loop_c],  %[x_stride]   \n\t"
      "mult   %[temp1],   %[temp2]                  \n\t"
      "maddu  %[frac],    %[fx_scale]               \n\t"
      "mfhi   %[sum]                                \n\t"
      "subu   %[temp3],   %[temp3],   %[frac]       \n\t"
      "sw     %[temp3],   0(%[frow])                \n\t"
      "addu   %[frow],    %[frow],    %[x_stride1]  \n\t"
      "bgtz   %[loop_c],  1b                        \n\t"
      : [accum]"=&r"(accum), [src1]"+r"(src1), [temp3]"=&r"(temp3),
        [sum]"=&r"(sum), [base]"=&r"(base), [frac]"=&r"(frac),
        [frow]"+r"(frow), [accum1]"=&r"(accum1),
        [temp2]"=&r"(temp2), [temp1]"=&r"(temp1)
      : [x_stride]"r"(x_stride), [fx_scale]"r"(fx_scale),
        [x_sub]"r"(x_sub), [x_add]"r"(x_add),
        [loop_c]"r"(loop_c), [x_stride1]"r"(x_stride1)
      : "memory", "hi", "lo"
    );
    assert(accum == 0);
  }
}

static void ImportRowExpandMIPS(WebPRescaler* const wrk, const uint8_t* src) {
  const int x_stride = wrk->num_channels;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  const int x_add = wrk->x_add;
  const int x_sub = wrk->x_sub;
  const int src_width = wrk->src_width;
  const int x_stride1 = x_stride << 2;
  int channel;
  assert(wrk->x_expand);
  assert(!WebPRescalerInputDone(wrk));

  for (channel = 0; channel < x_stride; ++channel) {
    const uint8_t* src1 = src + channel;
    rescaler_t* frow = wrk->frow + channel;
    int temp1, temp2, temp3, temp4;
    int frac;
    int accum;
    int x_out = channel;

    __asm__ volatile (
      "addiu  %[temp3],   %[src_width], -1            \n\t"
      "lbu    %[temp2],   0(%[src1])                  \n\t"
      "addu   %[src1],    %[src1],      %[x_stride]   \n\t"
      "bgtz   %[temp3],   0f                          \n\t"
      "addiu  %[temp1],   %[temp2],     0             \n\t"
      "b      3f                                      \n\t"
    "0:                                               \n\t"
      "lbu    %[temp1],   0(%[src1])                  \n\t"
    "3:                                               \n\t"
      "addiu  %[accum],   %[x_add],     0             \n\t"
    "1:                                               \n\t"
      "subu   %[temp3],   %[temp2],     %[temp1]      \n\t"
      "mul    %[temp3],   %[temp3],     %[accum]      \n\t"
      "mul    %[temp4],   %[temp1],     %[x_add]      \n\t"
      "addu   %[temp3],   %[temp4],     %[temp3]      \n\t"
      "sw     %[temp3],   0(%[frow])                  \n\t"
      "addu   %[frow],    %[frow],      %[x_stride1]  \n\t"
      "addu   %[x_out],   %[x_out],     %[x_stride]   \n\t"
      "subu   %[temp3],   %[x_out],     %[x_out_max]  \n\t"
      "bgez   %[temp3],   2f                          \n\t"
      "subu   %[accum],   %[accum],     %[x_sub]      \n\t"
      "bgez   %[accum],   4f                          \n\t"
      "addiu  %[temp2],   %[temp1],     0             \n\t"
      "addu   %[src1],    %[src1],      %[x_stride]   \n\t"
      "lbu    %[temp1],   0(%[src1])                  \n\t"
      "addu   %[accum],   %[accum],     %[x_add]      \n\t"
    "4:                                               \n\t"
      "b      1b                                      \n\t"
    "2:                                               \n\t"
      : [src1]"+r"(src1), [accum]"=&r"(accum), [temp1]"=&r"(temp1),
        [temp2]"=&r"(temp2), [temp3]"=&r"(temp3), [temp4]"=&r"(temp4),
        [x_out]"+r"(x_out), [frac]"=&r"(frac), [frow]"+r"(frow)
      : [x_stride]"r"(x_stride), [x_add]"r"(x_add), [x_sub]"r"(x_sub),
        [x_stride1]"r"(x_stride1), [src_width]"r"(src_width),
        [x_out_max]"r"(x_out_max)
      : "memory", "hi", "lo"
    );
    assert(wrk->x_sub == 0 /* <- special case for src_width=1 */ || accum == 0);
  }
}

//------------------------------------------------------------------------------
// Row export

static void ExportRowExpandMIPS(WebPRescaler* const wrk) {
  uint8_t* dst = wrk->dst;
  rescaler_t* irow = wrk->irow;
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  const rescaler_t* frow = wrk->frow;
  int temp0, temp1, temp3, temp4, temp5, loop_end;
  const int temp2 = (int)wrk->fy_scale;
  const int temp6 = x_out_max << 2;
  assert(!WebPRescalerOutputDone(wrk));
  assert(wrk->y_accum <= 0);
  assert(wrk->y_expand);
  assert(wrk->y_sub != 0);
  if (wrk->y_accum == 0) {
    __asm__ volatile (
      "li       %[temp3],    0x10000                    \n\t"
      "li       %[temp4],    0x8000                     \n\t"
      "addu     %[loop_end], %[frow],     %[temp6]      \n\t"
    "1:                                                 \n\t"
      "lw       %[temp0],    0(%[frow])                 \n\t"
      "addiu    %[dst],      %[dst],      1             \n\t"
      "addiu    %[frow],     %[frow],     4             \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "maddu    %[temp0],    %[temp2]                   \n\t"
      "mfhi     %[temp5]                                \n\t"
      "sb       %[temp5],    -1(%[dst])                 \n\t"
      "bne      %[frow],     %[loop_end], 1b            \n\t"
      : [temp0]"=&r"(temp0), [temp1]"=&r"(temp1), [temp3]"=&r"(temp3),
        [temp4]"=&r"(temp4), [temp5]"=&r"(temp5), [frow]"+r"(frow),
        [dst]"+r"(dst), [loop_end]"=&r"(loop_end)
      : [temp2]"r"(temp2), [temp6]"r"(temp6)
      : "memory", "hi", "lo"
    );
  } else {
    const uint32_t B = WEBP_RESCALER_FRAC(-wrk->y_accum, wrk->y_sub);
    const uint32_t A = (uint32_t)(WEBP_RESCALER_ONE - B);
    __asm__ volatile (
      "li       %[temp3],    0x10000                    \n\t"
      "li       %[temp4],    0x8000                     \n\t"
      "addu     %[loop_end], %[frow],     %[temp6]      \n\t"
    "1:                                                 \n\t"
      "lw       %[temp0],    0(%[frow])                 \n\t"
      "lw       %[temp1],    0(%[irow])                 \n\t"
      "addiu    %[dst],      %[dst],      1             \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "maddu    %[A],        %[temp0]                   \n\t"
      "maddu    %[B],        %[temp1]                   \n\t"
      "addiu    %[frow],     %[frow],     4             \n\t"
      "addiu    %[irow],     %[irow],     4             \n\t"
      "mfhi     %[temp5]                                \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "maddu    %[temp5],    %[temp2]                   \n\t"
      "mfhi     %[temp5]                                \n\t"
      "sb       %[temp5],    -1(%[dst])                 \n\t"
      "bne      %[frow],     %[loop_end], 1b            \n\t"
      : [temp0]"=&r"(temp0), [temp1]"=&r"(temp1), [temp3]"=&r"(temp3),
        [temp4]"=&r"(temp4), [temp5]"=&r"(temp5), [frow]"+r"(frow),
        [irow]"+r"(irow), [dst]"+r"(dst), [loop_end]"=&r"(loop_end)
      : [temp2]"r"(temp2), [temp6]"r"(temp6), [A]"r"(A), [B]"r"(B)
      : "memory", "hi", "lo"
    );
  }
}

static void ExportRowShrinkMIPS(WebPRescaler* const wrk) {
  const int x_out_max = wrk->dst_width * wrk->num_channels;
  uint8_t* dst = wrk->dst;
  rescaler_t* irow = wrk->irow;
  const rescaler_t* frow = wrk->frow;
  const int yscale = wrk->fy_scale * (-wrk->y_accum);
  int temp0, temp1, temp3, temp4, temp5, loop_end;
  const int temp2 = (int)wrk->fxy_scale;
  const int temp6 = x_out_max << 2;

  assert(!WebPRescalerOutputDone(wrk));
  assert(wrk->y_accum <= 0);
  assert(!wrk->y_expand);
  assert(wrk->fxy_scale != 0);
  if (yscale) {
    __asm__ volatile (
      "li       %[temp3],    0x10000                    \n\t"
      "li       %[temp4],    0x8000                     \n\t"
      "addu     %[loop_end], %[frow],     %[temp6]      \n\t"
    "1:                                                 \n\t"
      "lw       %[temp0],    0(%[frow])                 \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "addiu    %[frow],     %[frow],     4             \n\t"
      "maddu    %[temp0],    %[yscale]                  \n\t"
      "mfhi     %[temp1]                                \n\t"
      "lw       %[temp0],    0(%[irow])                 \n\t"
      "addiu    %[dst],      %[dst],      1             \n\t"
      "addiu    %[irow],     %[irow],     4             \n\t"
      "subu     %[temp0],    %[temp0],    %[temp1]      \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "maddu    %[temp0],    %[temp2]                   \n\t"
      "mfhi     %[temp5]                                \n\t"
      "sw       %[temp1],    -4(%[irow])                \n\t"
      "sb       %[temp5],    -1(%[dst])                 \n\t"
      "bne      %[frow],     %[loop_end], 1b            \n\t"
      : [temp0]"=&r"(temp0), [temp1]"=&r"(temp1), [temp3]"=&r"(temp3),
        [temp4]"=&r"(temp4), [temp5]"=&r"(temp5), [frow]"+r"(frow),
        [irow]"+r"(irow), [dst]"+r"(dst), [loop_end]"=&r"(loop_end)
      : [temp2]"r"(temp2), [yscale]"r"(yscale), [temp6]"r"(temp6)
      : "memory", "hi", "lo"
    );
  } else {
    __asm__ volatile (
      "li       %[temp3],    0x10000                    \n\t"
      "li       %[temp4],    0x8000                     \n\t"
      "addu     %[loop_end], %[irow],     %[temp6]      \n\t"
    "1:                                                 \n\t"
      "lw       %[temp0],    0(%[irow])                 \n\t"
      "addiu    %[dst],      %[dst],      1             \n\t"
      "addiu    %[irow],     %[irow],     4             \n\t"
      "mult     %[temp3],    %[temp4]                   \n\t"
      "maddu    %[temp0],    %[temp2]                   \n\t"
      "mfhi     %[temp5]                                \n\t"
      "sw       $zero,       -4(%[irow])                \n\t"
      "sb       %[temp5],    -1(%[dst])                 \n\t"
      "bne      %[irow],     %[loop_end], 1b            \n\t"
      : [temp0]"=&r"(temp0), [temp1]"=&r"(temp1), [temp3]"=&r"(temp3),
        [temp4]"=&r"(temp4), [temp5]"=&r"(temp5), [irow]"+r"(irow),
        [dst]"+r"(dst), [loop_end]"=&r"(loop_end)
      : [temp2]"r"(temp2), [temp6]"r"(temp6)
      : "memory", "hi", "lo"
    );
  }
}

#endif   // WEBP_USE_MIPS32

//------------------------------------------------------------------------------

void WebPRescalerInit(WebPRescaler* const wrk, int src_width, int src_height,
                      uint8_t* const dst,
                      int dst_width, int dst_height, int dst_stride,
                      int num_channels, rescaler_t* const work) {
  const int x_add = src_width, x_sub = dst_width;
  const int y_add = src_height, y_sub = dst_height;
  wrk->x_expand = (src_width < dst_width);
  wrk->y_expand = (src_height < dst_height);
  wrk->src_width = src_width;
  wrk->src_height = src_height;
  wrk->dst_width = dst_width;
  wrk->dst_height = dst_height;
  wrk->src_y = 0;
  wrk->dst_y = 0;
  wrk->dst = dst;
  wrk->dst_stride = dst_stride;
  wrk->num_channels = num_channels;

  // for 'x_expand', we use bilinear interpolation
  wrk->x_add = wrk->x_expand ? (x_sub - 1) : x_add;
  wrk->x_sub = wrk->x_expand ? (x_add - 1) : x_sub;
  if (!wrk->x_expand) {  // fx_scale is not used otherwise
    wrk->fx_scale = WEBP_RESCALER_FRAC(1, wrk->x_sub);
  }
  // vertical scaling parameters
  wrk->y_add = wrk->y_expand ? y_add - 1 : y_add;
  wrk->y_sub = wrk->y_expand ? y_sub - 1 : y_sub;
  wrk->y_accum = wrk->y_expand ? wrk->y_sub : wrk->y_add;
  if (!wrk->y_expand) {
    // this is WEBP_RESCALER_FRAC(dst_height, x_add * y_add) without the cast.
    const uint64_t ratio =
        (uint64_t)dst_height * WEBP_RESCALER_ONE / (wrk->x_add * wrk->y_add);
    if (ratio != (uint32_t)ratio) {
      // We can't represent the ratio with the current fixed-point precision.
      // => We special-case fxy_scale = 0, in WebPRescalerExportRow().
      wrk->fxy_scale = 0;
    } else {
      wrk->fxy_scale = (uint32_t)ratio;
    }
    wrk->fy_scale = WEBP_RESCALER_FRAC(1, wrk->y_sub);
  } else {
    wrk->fy_scale = WEBP_RESCALER_FRAC(1, wrk->x_add);
    // wrk->fxy_scale is unused here.
  }
  wrk->irow = work;
  wrk->frow = work + num_channels * dst_width;
  memset(work, 0, 2 * dst_width * num_channels * sizeof(*work));

  if (WebPRescalerImportRowExpand == NULL) {
    WebPRescalerImportRowExpand = ImportRowExpandC;
    WebPRescalerImportRowShrink = ImportRowShrinkC;
    WebPRescalerExportRowExpand = ExportRowExpandC;
    WebPRescalerExportRowShrink = ExportRowShrinkC;
    if (VP8GetCPUInfo != NULL) {
#if defined(WEBP_USE_MIPS32)
      if (VP8GetCPUInfo(kMIPS32)) {
        WebPRescalerImportRowExpand = ImportRowExpandMIPS;
        WebPRescalerImportRowShrink = ImportRowShrinkMIPS;
        WebPRescalerExportRowExpand = ExportRowExpandMIPS;
        WebPRescalerExportRowShrink = ExportRowShrinkMIPS;
      }
#endif
    }
  }
}

#undef MULT_FIX
#undef WEBP_RESCALER_RFIX
#undef WEBP_RESCALER_ONE
#undef WEBP_RESCALER_FRAC
#undef ROUNDER

//------------------------------------------------------------------------------
// all-in-one calls

int WebPRescaleNeededLines(const WebPRescaler* const wrk, int max_num_lines) {
  const int num_lines = (wrk->y_accum + wrk->y_sub - 1) / wrk->y_sub;
  return (num_lines > max_num_lines) ? max_num_lines : num_lines;
}

int WebPRescalerImport(WebPRescaler* const wrk, int num_lines,
                       const uint8_t* src, int src_stride) {
  int total_imported = 0;
  while (total_imported < num_lines && !WebPRescalerHasPendingOutput(wrk)) {
    if (wrk->y_expand) {
      rescaler_t* const tmp = wrk->irow;
      wrk->irow = wrk->frow;
      wrk->frow = tmp;
    }
    WebPRescalerImportRow(wrk, src);
    if (!wrk->y_expand) {     // Accumulate the contribution of the new row.
      int x;
      for (x = 0; x < wrk->num_channels * wrk->dst_width; ++x) {
        wrk->irow[x] += wrk->frow[x];
      }
    }
    ++wrk->src_y;
    src += src_stride;
    ++total_imported;
    wrk->y_accum -= wrk->y_sub;
  }
  return total_imported;
}

int WebPRescalerExport(WebPRescaler* const rescaler) {
  int total_exported = 0;
  while (WebPRescalerHasPendingOutput(rescaler)) {
    WebPRescalerExportRow(rescaler);
    ++total_exported;
  }
  return total_exported;
}

//------------------------------------------------------------------------------
