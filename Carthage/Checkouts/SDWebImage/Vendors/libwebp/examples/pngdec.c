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

#include "./pngdec.h"

#ifdef HAVE_CONFIG_H
#include "webp/config.h"
#endif

#include <stdio.h>

#ifdef WEBP_HAVE_PNG
#include <png.h>
#include <setjmp.h>   // note: this must be included *after* png.h
#include <stdlib.h>
#include <string.h>

#include "webp/encode.h"
#include "./metadata.h"

static void PNGAPI error_function(png_structp png, png_const_charp error) {
  if (error != NULL) fprintf(stderr, "libpng error: %s\n", error);
  longjmp(png_jmpbuf(png), 1);
}

// Converts the NULL terminated 'hexstring' which contains 2-byte character
// representations of hex values to raw data.
// 'hexstring' may contain values consisting of [A-F][a-f][0-9] in pairs,
// e.g., 7af2..., separated by any number of newlines.
// 'expected_length' is the anticipated processed size.
// On success the raw buffer is returned with its length equivalent to
// 'expected_length'. NULL is returned if the processed length is less than
// 'expected_length' or any character aside from those above is encountered.
// The returned buffer must be freed by the caller.
static uint8_t* HexStringToBytes(const char* hexstring,
                                 size_t expected_length) {
  const char* src = hexstring;
  size_t actual_length = 0;
  uint8_t* const raw_data = (uint8_t*)malloc(expected_length);
  uint8_t* dst;

  if (raw_data == NULL) return NULL;

  for (dst = raw_data; actual_length < expected_length && *src != '\0'; ++src) {
    char* end;
    char val[3];
    if (*src == '\n') continue;
    val[0] = *src++;
    val[1] = *src;
    val[2] = '\0';
    *dst++ = (uint8_t)strtol(val, &end, 16);
    if (end != val + 2) break;
    ++actual_length;
  }

  if (actual_length != expected_length) {
    free(raw_data);
    return NULL;
  }
  return raw_data;
}

static int ProcessRawProfile(const char* profile, size_t profile_len,
                             MetadataPayload* const payload) {
  const char* src = profile;
  char* end;
  int expected_length;

  if (profile == NULL || profile_len == 0) return 0;

  // ImageMagick formats 'raw profiles' as
  // '\n<name>\n<length>(%8lu)\n<hex payload>\n'.
  if (*src != '\n') {
    fprintf(stderr, "Malformed raw profile, expected '\\n' got '\\x%.2X'\n",
            *src);
    return 0;
  }
  ++src;
  // skip the profile name and extract the length.
  while (*src != '\0' && *src++ != '\n') {}
  expected_length = (int)strtol(src, &end, 10);
  if (*end != '\n') {
    fprintf(stderr, "Malformed raw profile, expected '\\n' got '\\x%.2X'\n",
            *end);
    return 0;
  }
  ++end;

  // 'end' now points to the profile payload.
  payload->bytes = HexStringToBytes(end, expected_length);
  if (payload->bytes == NULL) return 0;
  payload->size = expected_length;
  return 1;
}

static const struct {
  const char* name;
  int (*process)(const char* profile, size_t profile_len,
                 MetadataPayload* const payload);
  size_t storage_offset;
} kPNGMetadataMap[] = {
  // http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/PNG.html#TextualData
  // See also: ExifTool on CPAN.
  { "Raw profile type exif", ProcessRawProfile, METADATA_OFFSET(exif) },
  { "Raw profile type xmp",  ProcessRawProfile, METADATA_OFFSET(xmp) },
  // Exiftool puts exif data in APP1 chunk, too.
  { "Raw profile type APP1", ProcessRawProfile, METADATA_OFFSET(exif) },
  // XMP Specification Part 3, Section 3 #PNG
  { "XML:com.adobe.xmp",     MetadataCopy,      METADATA_OFFSET(xmp) },
  { NULL, NULL, 0 },
};

// Looks for metadata at both the beginning and end of the PNG file, giving
// preference to the head.
// Returns true on success. The caller must use MetadataFree() on 'metadata' in
// all cases.
static int ExtractMetadataFromPNG(png_structp png,
                                  png_infop const head_info,
                                  png_infop const end_info,
                                  Metadata* const metadata) {
  int p;

  for (p = 0; p < 2; ++p)  {
    png_infop const info = (p == 0) ? head_info : end_info;
    png_textp text = NULL;
    const int num = png_get_text(png, info, &text, NULL);
    int i;
    // Look for EXIF / XMP metadata.
    for (i = 0; i < num; ++i, ++text) {
      int j;
      for (j = 0; kPNGMetadataMap[j].name != NULL; ++j) {
        if (!strcmp(text->key, kPNGMetadataMap[j].name)) {
          MetadataPayload* const payload =
              (MetadataPayload*)((uint8_t*)metadata +
                                 kPNGMetadataMap[j].storage_offset);
          png_size_t text_length;
          switch (text->compression) {
#ifdef PNG_iTXt_SUPPORTED
            case PNG_ITXT_COMPRESSION_NONE:
            case PNG_ITXT_COMPRESSION_zTXt:
              text_length = text->itxt_length;
              break;
#endif
            case PNG_TEXT_COMPRESSION_NONE:
            case PNG_TEXT_COMPRESSION_zTXt:
            default:
              text_length = text->text_length;
              break;
          }
          if (payload->bytes != NULL) {
            fprintf(stderr, "Ignoring additional '%s'\n", text->key);
          } else if (!kPNGMetadataMap[j].process(text->text, text_length,
                                                 payload)) {
            fprintf(stderr, "Failed to process: '%s'\n", text->key);
            return 0;
          }
          break;
        }
      }
    }
    // Look for an ICC profile.
    {
      png_charp name;
      int comp_type;
#if ((PNG_LIBPNG_VER_MAJOR << 8) | PNG_LIBPNG_VER_MINOR << 0) < \
    ((1 << 8) | (5 << 0))
      png_charp profile;
#else  // >= libpng 1.5.0
      png_bytep profile;
#endif
      png_uint_32 len;

      if (png_get_iCCP(png, info,
                       &name, &comp_type, &profile, &len) == PNG_INFO_iCCP) {
        if (!MetadataCopy((const char*)profile, len, &metadata->iccp)) return 0;
      }
    }
  }

  return 1;
}

int ReadPNG(FILE* in_file, WebPPicture* const pic, int keep_alpha,
            Metadata* const metadata) {
  volatile png_structp png;
  volatile png_infop info = NULL;
  volatile png_infop end_info = NULL;
  int color_type, bit_depth, interlaced;
  int has_alpha;
  int num_passes;
  int p;
  int ok = 0;
  png_uint_32 width, height, y;
  int stride;
  uint8_t* volatile rgb = NULL;

  png = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
  if (png == NULL) {
    goto End;
  }

  png_set_error_fn(png, 0, error_function, NULL);
  if (setjmp(png_jmpbuf(png))) {
 Error:
    MetadataFree(metadata);
    goto End;
  }

  info = png_create_info_struct(png);
  if (info == NULL) goto Error;
  end_info = png_create_info_struct(png);
  if (end_info == NULL) goto Error;

  png_init_io(png, in_file);
  png_read_info(png, info);
  if (!png_get_IHDR(png, info,
                    &width, &height, &bit_depth, &color_type, &interlaced,
                    NULL, NULL)) goto Error;

  png_set_strip_16(png);
  png_set_packing(png);
  if (color_type == PNG_COLOR_TYPE_PALETTE) {
    png_set_palette_to_rgb(png);
  }
  if (color_type == PNG_COLOR_TYPE_GRAY ||
      color_type == PNG_COLOR_TYPE_GRAY_ALPHA) {
    if (bit_depth < 8) {
      png_set_expand_gray_1_2_4_to_8(png);
    }
    png_set_gray_to_rgb(png);
  }
  if (png_get_valid(png, info, PNG_INFO_tRNS)) {
    png_set_tRNS_to_alpha(png);
    has_alpha = 1;
  } else {
    has_alpha = !!(color_type & PNG_COLOR_MASK_ALPHA);
  }

  if (!keep_alpha) {
    png_set_strip_alpha(png);
    has_alpha = 0;
  }

  num_passes = png_set_interlace_handling(png);
  png_read_update_info(png, info);
  stride = (has_alpha ? 4 : 3) * width * sizeof(*rgb);
  rgb = (uint8_t*)malloc(stride * height);
  if (rgb == NULL) goto Error;
  for (p = 0; p < num_passes; ++p) {
    for (y = 0; y < height; ++y) {
      png_bytep row = (png_bytep)(rgb + y * stride);
      png_read_rows(png, &row, NULL, 1);
    }
  }
  png_read_end(png, end_info);

  if (metadata != NULL &&
      !ExtractMetadataFromPNG(png, info, end_info, metadata)) {
    fprintf(stderr, "Error extracting PNG metadata!\n");
    goto Error;
  }

  pic->width = width;
  pic->height = height;
  pic->use_argb = 1;
  ok = has_alpha ? WebPPictureImportRGBA(pic, rgb, stride)
                 : WebPPictureImportRGB(pic, rgb, stride);

  if (!ok) {
    goto Error;
  }

 End:
  if (png != NULL) {
    png_destroy_read_struct((png_structpp)&png,
                            (png_infopp)&info, (png_infopp)&end_info);
  }
  free(rgb);
  return ok;
}
#else  // !WEBP_HAVE_PNG
int ReadPNG(FILE* in_file, struct WebPPicture* const pic, int keep_alpha,
            struct Metadata* const metadata) {
  (void)in_file;
  (void)pic;
  (void)keep_alpha;
  (void)metadata;
  fprintf(stderr, "PNG support not compiled. Please install the libpng "
          "development package before building.\n");
  return 0;
}
#endif  // WEBP_HAVE_PNG

// -----------------------------------------------------------------------------
