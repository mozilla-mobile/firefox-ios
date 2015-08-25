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

#include "./webpdec.h"

#include <stdio.h>
#include <stdlib.h>

#include "webp/decode.h"
#include "webp/encode.h"
#include "./example_util.h"
#include "./metadata.h"

int ReadWebP(const char* const in_file, WebPPicture* const pic,
             int keep_alpha, Metadata* const metadata) {
  int ok = 0;
  size_t data_size = 0;
  const uint8_t* data = NULL;
  VP8StatusCode status = VP8_STATUS_OK;
  WebPDecoderConfig config;
  WebPDecBuffer* const output_buffer = &config.output;
  WebPBitstreamFeatures* const bitstream = &config.input;

  // TODO(jzern): add Exif/XMP/ICC extraction.
  if (metadata != NULL) {
    fprintf(stderr, "Warning: metadata extraction from WebP is unsupported.\n");
  }

  if (!WebPInitDecoderConfig(&config)) {
    fprintf(stderr, "Library version mismatch!\n");
    return 0;
  }

  if (ExUtilLoadWebP(in_file, &data, &data_size, bitstream)) {
    const int has_alpha = keep_alpha && bitstream->has_alpha;
    output_buffer->colorspace = has_alpha ? MODE_RGBA : MODE_RGB;

    status = ExUtilDecodeWebP(data, data_size, 0, &config);
    if (status == VP8_STATUS_OK) {
      const uint8_t* const rgba = output_buffer->u.RGBA.rgba;
      const int stride = output_buffer->u.RGBA.stride;
      pic->width = output_buffer->width;
      pic->height = output_buffer->height;
      pic->use_argb = 1;
      ok = has_alpha ? WebPPictureImportRGBA(pic, rgba, stride)
                     : WebPPictureImportRGB(pic, rgba, stride);
    }
  }

  if (status != VP8_STATUS_OK) {
    ExUtilPrintWebPError(in_file, status);
  }

  free((void*)data);
  WebPFreeDecBuffer(output_buffer);
  return ok;
}

// -----------------------------------------------------------------------------
