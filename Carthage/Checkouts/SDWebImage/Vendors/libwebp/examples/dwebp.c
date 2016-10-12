// Copyright 2010 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
//  Command-line tool for decoding a WebP image.
//
// Author: Skal (pascal.massimino@gmail.com)

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_CONFIG_H
#include "webp/config.h"
#endif

#ifdef WEBP_HAVE_PNG
#include <png.h>
#include <setjmp.h>   // note: this must be included *after* png.h
#endif

#ifdef HAVE_WINCODEC_H
#ifdef __MINGW32__
#define INITGUID  // Without this GUIDs are declared extern and fail to link
#endif
#define CINTERFACE
#define COBJMACROS
#define _WIN32_IE 0x500  // Workaround bug in shlwapi.h when compiling C++
                         // code with COBJMACROS.
#include <ole2.h>  // CreateStreamOnHGlobal()
#include <shlwapi.h>
#include <windows.h>
#include <wincodec.h>
#endif

#include "webp/decode.h"
#include "./example_util.h"
#include "./stopwatch.h"

static int verbose = 0;
#ifndef WEBP_DLL
#ifdef __cplusplus
extern "C" {
#endif

extern void* VP8GetCPUInfo;   // opaque forward declaration.

#ifdef __cplusplus
}    // extern "C"
#endif
#endif  // WEBP_DLL

//------------------------------------------------------------------------------

// Output types
typedef enum {
  PNG = 0,
  PAM,
  PPM,
  PGM,
  BMP,
  TIFF,
  YUV,
  ALPHA_PLANE_ONLY  // this is for experimenting only
} OutputFileFormat;

#ifdef HAVE_WINCODEC_H

#define IFS(fn)                                                     \
  do {                                                              \
    if (SUCCEEDED(hr)) {                                            \
      hr = (fn);                                                    \
      if (FAILED(hr)) fprintf(stderr, #fn " failed %08lx\n", hr);   \
    }                                                               \
  } while (0)

#ifdef __cplusplus
#define MAKE_REFGUID(x) (x)
#else
#define MAKE_REFGUID(x) &(x)
#endif

static HRESULT CreateOutputStream(const char* out_file_name,
                                  int write_to_mem, IStream** stream) {
  HRESULT hr = S_OK;
  if (write_to_mem) {
    // Output to a memory buffer. This is freed when 'stream' is released.
    IFS(CreateStreamOnHGlobal(NULL, TRUE, stream));
  } else {
    IFS(SHCreateStreamOnFileA(out_file_name, STGM_WRITE | STGM_CREATE, stream));
  }
  if (FAILED(hr)) {
    fprintf(stderr, "Error opening output file %s (%08lx)\n",
            out_file_name, hr);
  }
  return hr;
}

static HRESULT WriteUsingWIC(const char* out_file_name, int use_stdout,
                             REFGUID container_guid,
                             uint8_t* rgb, int stride,
                             uint32_t width, uint32_t height, int has_alpha) {
  HRESULT hr = S_OK;
  IWICImagingFactory* factory = NULL;
  IWICBitmapFrameEncode* frame = NULL;
  IWICBitmapEncoder* encoder = NULL;
  IStream* stream = NULL;
  WICPixelFormatGUID pixel_format = has_alpha ? GUID_WICPixelFormat32bppBGRA
                                              : GUID_WICPixelFormat24bppBGR;

  IFS(CoInitialize(NULL));
  IFS(CoCreateInstance(MAKE_REFGUID(CLSID_WICImagingFactory), NULL,
                       CLSCTX_INPROC_SERVER,
                       MAKE_REFGUID(IID_IWICImagingFactory),
                       (LPVOID*)&factory));
  if (hr == REGDB_E_CLASSNOTREG) {
    fprintf(stderr,
            "Couldn't access Windows Imaging Component (are you running "
            "Windows XP SP3 or newer?). PNG support not available. "
            "Use -ppm or -pgm for available PPM and PGM formats.\n");
  }
  IFS(CreateOutputStream(out_file_name, use_stdout, &stream));
  IFS(IWICImagingFactory_CreateEncoder(factory, container_guid, NULL,
                                       &encoder));
  IFS(IWICBitmapEncoder_Initialize(encoder, stream,
                                   WICBitmapEncoderNoCache));
  IFS(IWICBitmapEncoder_CreateNewFrame(encoder, &frame, NULL));
  IFS(IWICBitmapFrameEncode_Initialize(frame, NULL));
  IFS(IWICBitmapFrameEncode_SetSize(frame, width, height));
  IFS(IWICBitmapFrameEncode_SetPixelFormat(frame, &pixel_format));
  IFS(IWICBitmapFrameEncode_WritePixels(frame, height, stride,
                                        height * stride, rgb));
  IFS(IWICBitmapFrameEncode_Commit(frame));
  IFS(IWICBitmapEncoder_Commit(encoder));

  if (SUCCEEDED(hr) && use_stdout) {
    HGLOBAL image;
    IFS(GetHGlobalFromStream(stream, &image));
    if (SUCCEEDED(hr)) {
      HANDLE std_output = GetStdHandle(STD_OUTPUT_HANDLE);
      DWORD mode;
      const BOOL update_mode = GetConsoleMode(std_output, &mode);
      const void* const image_mem = GlobalLock(image);
      DWORD bytes_written = 0;

      // Clear output processing if necessary, then output the image.
      if (update_mode) SetConsoleMode(std_output, 0);
      if (!WriteFile(std_output, image_mem, (DWORD)GlobalSize(image),
                     &bytes_written, NULL) ||
          bytes_written != GlobalSize(image)) {
        hr = E_FAIL;
      }
      if (update_mode) SetConsoleMode(std_output, mode);
      GlobalUnlock(image);
    }
  }

  if (frame != NULL) IUnknown_Release(frame);
  if (encoder != NULL) IUnknown_Release(encoder);
  if (factory != NULL) IUnknown_Release(factory);
  if (stream != NULL) IUnknown_Release(stream);
  return hr;
}

static int WritePNG(const char* out_file_name, int use_stdout,
                    const WebPDecBuffer* const buffer) {
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  uint8_t* const rgb = buffer->u.RGBA.rgba;
  const int stride = buffer->u.RGBA.stride;
  const int has_alpha = (buffer->colorspace == MODE_BGRA);

  return SUCCEEDED(WriteUsingWIC(out_file_name, use_stdout,
                                 MAKE_REFGUID(GUID_ContainerFormatPng),
                                 rgb, stride, width, height, has_alpha));
}

#elif defined(WEBP_HAVE_PNG)    // !HAVE_WINCODEC_H
static void PNGAPI PNGErrorFunction(png_structp png, png_const_charp dummy) {
  (void)dummy;  // remove variable-unused warning
  longjmp(png_jmpbuf(png), 1);
}

static int WritePNG(FILE* out_file, const WebPDecBuffer* const buffer) {
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  uint8_t* const rgb = buffer->u.RGBA.rgba;
  const int stride = buffer->u.RGBA.stride;
  const int has_alpha = (buffer->colorspace == MODE_RGBA);
  volatile png_structp png;
  volatile png_infop info;
  png_uint_32 y;

  png = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                NULL, PNGErrorFunction, NULL);
  if (png == NULL) {
    return 0;
  }
  info = png_create_info_struct(png);
  if (info == NULL) {
    png_destroy_write_struct((png_structpp)&png, NULL);
    return 0;
  }
  if (setjmp(png_jmpbuf(png))) {
    png_destroy_write_struct((png_structpp)&png, (png_infopp)&info);
    return 0;
  }
  png_init_io(png, out_file);
  png_set_IHDR(png, info, width, height, 8,
               has_alpha ? PNG_COLOR_TYPE_RGBA : PNG_COLOR_TYPE_RGB,
               PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
               PNG_FILTER_TYPE_DEFAULT);
  png_write_info(png, info);
  for (y = 0; y < height; ++y) {
    png_bytep row = rgb + y * stride;
    png_write_rows(png, &row, 1);
  }
  png_write_end(png, info);
  png_destroy_write_struct((png_structpp)&png, (png_infopp)&info);
  return 1;
}
#else    // !HAVE_WINCODEC_H && !WEBP_HAVE_PNG
static int WritePNG(FILE* out_file, const WebPDecBuffer* const buffer) {
  (void)out_file;
  (void)buffer;
  fprintf(stderr, "PNG support not compiled. Please install the libpng "
          "development package before building.\n");
  fprintf(stderr, "You can run with -ppm flag to decode in PPM format.\n");
  return 0;
}
#endif

static int WritePPM(FILE* fout, const WebPDecBuffer* const buffer, int alpha) {
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  const uint8_t* const rgb = buffer->u.RGBA.rgba;
  const int stride = buffer->u.RGBA.stride;
  const size_t bytes_per_px = alpha ? 4 : 3;
  uint32_t y;

  if (alpha) {
    fprintf(fout, "P7\nWIDTH %u\nHEIGHT %u\nDEPTH 4\nMAXVAL 255\n"
                  "TUPLTYPE RGB_ALPHA\nENDHDR\n", width, height);
  } else {
    fprintf(fout, "P6\n%u %u\n255\n", width, height);
  }
  for (y = 0; y < height; ++y) {
    if (fwrite(rgb + y * stride, width, bytes_per_px, fout) != bytes_per_px) {
      return 0;
    }
  }
  return 1;
}

static void PutLE16(uint8_t* const dst, uint32_t value) {
  dst[0] = (value >> 0) & 0xff;
  dst[1] = (value >> 8) & 0xff;
}

static void PutLE32(uint8_t* const dst, uint32_t value) {
  PutLE16(dst + 0, (value >>  0) & 0xffff);
  PutLE16(dst + 2, (value >> 16) & 0xffff);
}

#define BMP_HEADER_SIZE 54
static int WriteBMP(FILE* fout, const WebPDecBuffer* const buffer) {
  const int has_alpha = (buffer->colorspace != MODE_BGR);
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  const uint8_t* const rgba = buffer->u.RGBA.rgba;
  const int stride = buffer->u.RGBA.stride;
  const uint32_t bytes_per_px = has_alpha ? 4 : 3;
  uint32_t y;
  const uint32_t line_size = bytes_per_px * width;
  const uint32_t bmp_stride = (line_size + 3) & ~3;   // pad to 4
  const uint32_t total_size = bmp_stride * height + BMP_HEADER_SIZE;
  uint8_t bmp_header[BMP_HEADER_SIZE] = { 0 };

  // bitmap file header
  PutLE16(bmp_header + 0, 0x4d42);                // signature 'BM'
  PutLE32(bmp_header + 2, total_size);            // size including header
  PutLE32(bmp_header + 6, 0);                     // reserved
  PutLE32(bmp_header + 10, BMP_HEADER_SIZE);      // offset to pixel array
  // bitmap info header
  PutLE32(bmp_header + 14, 40);                   // DIB header size
  PutLE32(bmp_header + 18, width);                // dimensions
  PutLE32(bmp_header + 22, -(int)height);         // vertical flip!
  PutLE16(bmp_header + 26, 1);                    // number of planes
  PutLE16(bmp_header + 28, bytes_per_px * 8);     // bits per pixel
  PutLE32(bmp_header + 30, 0);                    // no compression (BI_RGB)
  PutLE32(bmp_header + 34, 0);                    // image size (dummy)
  PutLE32(bmp_header + 38, 2400);                 // x pixels/meter
  PutLE32(bmp_header + 42, 2400);                 // y pixels/meter
  PutLE32(bmp_header + 46, 0);                    // number of palette colors
  PutLE32(bmp_header + 50, 0);                    // important color count

  // TODO(skal): color profile

  // write header
  if (fwrite(bmp_header, sizeof(bmp_header), 1, fout) != 1) {
    return 0;
  }

  // write pixel array
  for (y = 0; y < height; ++y) {
    if (fwrite(rgba + y * stride, line_size, 1, fout) != 1) {
      return 0;
    }
    // write padding zeroes
    if (bmp_stride != line_size) {
      const uint8_t zeroes[3] = { 0 };
      if (fwrite(zeroes, bmp_stride - line_size, 1, fout) != 1) {
        return 0;
      }
    }
  }
  return 1;
}
#undef BMP_HEADER_SIZE

#define NUM_IFD_ENTRIES 15
#define EXTRA_DATA_SIZE 16
// 10b for signature/header + n * 12b entries + 4b for IFD terminator:
#define EXTRA_DATA_OFFSET (10 + 12 * NUM_IFD_ENTRIES + 4)
#define TIFF_HEADER_SIZE (EXTRA_DATA_OFFSET + EXTRA_DATA_SIZE)

static int WriteTIFF(FILE* fout, const WebPDecBuffer* const buffer) {
  const int has_alpha = (buffer->colorspace != MODE_RGB);
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  const uint8_t* const rgba = buffer->u.RGBA.rgba;
  const int stride = buffer->u.RGBA.stride;
  const uint8_t bytes_per_px = has_alpha ? 4 : 3;
  // For non-alpha case, we omit tag 0x152 (ExtraSamples).
  const uint8_t num_ifd_entries = has_alpha ? NUM_IFD_ENTRIES
                                            : NUM_IFD_ENTRIES - 1;
  uint8_t tiff_header[TIFF_HEADER_SIZE] = {
    0x49, 0x49, 0x2a, 0x00,   // little endian signature
    8, 0, 0, 0,               // offset to the unique IFD that follows
    // IFD (offset = 8). Entries must be written in increasing tag order.
    num_ifd_entries, 0,       // Number of entries in the IFD (12 bytes each).
    0x00, 0x01, 3, 0, 1, 0, 0, 0, 0, 0, 0, 0,    //  10: Width  (TBD)
    0x01, 0x01, 3, 0, 1, 0, 0, 0, 0, 0, 0, 0,    //  22: Height (TBD)
    0x02, 0x01, 3, 0, bytes_per_px, 0, 0, 0,     //  34: BitsPerSample: 8888
        EXTRA_DATA_OFFSET + 0, 0, 0, 0,
    0x03, 0x01, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0,    //  46: Compression: none
    0x06, 0x01, 3, 0, 1, 0, 0, 0, 2, 0, 0, 0,    //  58: Photometric: RGB
    0x11, 0x01, 4, 0, 1, 0, 0, 0,                //  70: Strips offset:
        TIFF_HEADER_SIZE, 0, 0, 0,               //      data follows header
    0x12, 0x01, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0,    //  82: Orientation: topleft
    0x15, 0x01, 3, 0, 1, 0, 0, 0,                //  94: SamplesPerPixels
        bytes_per_px, 0, 0, 0,
    0x16, 0x01, 3, 0, 1, 0, 0, 0, 0, 0, 0, 0,    // 106: Rows per strip (TBD)
    0x17, 0x01, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0,    // 118: StripByteCount (TBD)
    0x1a, 0x01, 5, 0, 1, 0, 0, 0,                // 130: X-resolution
        EXTRA_DATA_OFFSET + 8, 0, 0, 0,
    0x1b, 0x01, 5, 0, 1, 0, 0, 0,                // 142: Y-resolution
        EXTRA_DATA_OFFSET + 8, 0, 0, 0,
    0x1c, 0x01, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0,    // 154: PlanarConfiguration
    0x28, 0x01, 3, 0, 1, 0, 0, 0, 2, 0, 0, 0,    // 166: ResolutionUnit (inch)
    0x52, 0x01, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0,    // 178: ExtraSamples: rgbA
    0, 0, 0, 0,                                  // 190: IFD terminator
    // EXTRA_DATA_OFFSET:
    8, 0, 8, 0, 8, 0, 8, 0,      // BitsPerSample
    72, 0, 0, 0, 1, 0, 0, 0      // 72 pixels/inch, for X/Y-resolution
  };
  uint32_t y;

  // Fill placeholders in IFD:
  PutLE32(tiff_header + 10 + 8, width);
  PutLE32(tiff_header + 22 + 8, height);
  PutLE32(tiff_header + 106 + 8, height);
  PutLE32(tiff_header + 118 + 8, width * bytes_per_px * height);
  if (!has_alpha) PutLE32(tiff_header + 178, 0);  // IFD terminator

  // write header
  if (fwrite(tiff_header, sizeof(tiff_header), 1, fout) != 1) {
    return 0;
  }
  // write pixel values
  for (y = 0; y < height; ++y) {
    if (fwrite(rgba + y * stride, bytes_per_px, width, fout) != width) {
      return 0;
    }
  }

  return 1;
}

#undef TIFF_HEADER_SIZE
#undef EXTRA_DATA_OFFSET
#undef EXTRA_DATA_SIZE
#undef NUM_IFD_ENTRIES

static int WriteAlphaPlane(FILE* fout, const WebPDecBuffer* const buffer) {
  const uint32_t width = buffer->width;
  const uint32_t height = buffer->height;
  const uint8_t* const a = buffer->u.YUVA.a;
  const int a_stride = buffer->u.YUVA.a_stride;
  uint32_t y;
  assert(a != NULL);
  fprintf(fout, "P5\n%u %u\n255\n", width, height);
  for (y = 0; y < height; ++y) {
    if (fwrite(a + y * a_stride, width, 1, fout) != 1) {
      return 0;
    }
  }
  return 1;
}

// format=PGM: save a grayscale PGM file using the IMC4 layout
// (http://www.fourcc.org/yuv.php#IMC4). This is a very convenient format for
// viewing the samples, esp. for odd dimensions.
// format=YUV: just save the Y/U/V/A planes sequentially without header.
static int WritePGMOrYUV(FILE* fout, const WebPDecBuffer* const buffer,
                         OutputFileFormat format) {
  const int width = buffer->width;
  const int height = buffer->height;
  const WebPYUVABuffer* const yuv = &buffer->u.YUVA;
  int ok = 1;
  int y;
  const int pad = (format == YUV) ? 0 : 1;
  const int uv_width = (width + 1) / 2;
  const int uv_height = (height + 1) / 2;
  const int out_stride = (width + pad) & ~pad;
  const int a_height = yuv->a ? height : 0;
  if (format == PGM) {
    fprintf(fout, "P5\n%d %d\n255\n",
            out_stride, height + uv_height + a_height);
  }
  for (y = 0; ok && y < height; ++y) {
    ok &= (fwrite(yuv->y + y * yuv->y_stride, width, 1, fout) == 1);
    if (format == PGM) {
      if (width & 1) fputc(0, fout);    // padding byte
    }
  }
  if (format == PGM) {   // IMC4 layout
    for (y = 0; ok && y < uv_height; ++y) {
      ok &= (fwrite(yuv->u + y * yuv->u_stride, uv_width, 1, fout) == 1);
      ok &= (fwrite(yuv->v + y * yuv->v_stride, uv_width, 1, fout) == 1);
    }
  } else {
    for (y = 0; ok && y < uv_height; ++y) {
      ok &= (fwrite(yuv->u + y * yuv->u_stride, uv_width, 1, fout) == 1);
    }
    for (y = 0; ok && y < uv_height; ++y) {
      ok &= (fwrite(yuv->v + y * yuv->v_stride, uv_width, 1, fout) == 1);
    }
  }
  for (y = 0; ok && y < a_height; ++y) {
    ok &= (fwrite(yuv->a + y * yuv->a_stride, width, 1, fout) == 1);
    if (format == PGM) {
      if (width & 1) fputc(0, fout);    // padding byte
    }
  }
  return ok;
}

static int SaveOutput(const WebPDecBuffer* const buffer,
                      OutputFileFormat format, const char* const out_file) {
  FILE* fout = NULL;
  int needs_open_file = 1;
  const int use_stdout = !strcmp(out_file, "-");
  int ok = 1;
  Stopwatch stop_watch;

  if (verbose) {
    StopwatchReset(&stop_watch);
  }

#ifdef HAVE_WINCODEC_H
  needs_open_file = (format != PNG);
#endif

  if (needs_open_file) {
    fout = use_stdout ? ExUtilSetBinaryMode(stdout) : fopen(out_file, "wb");
    if (fout == NULL) {
      fprintf(stderr, "Error opening output file %s\n", out_file);
      return 0;
    }
  }

  if (format == PNG) {
#ifdef HAVE_WINCODEC_H
    ok &= WritePNG(out_file, use_stdout, buffer);
#else
    ok &= WritePNG(fout, buffer);
#endif
  } else if (format == PAM) {
    ok &= WritePPM(fout, buffer, 1);
  } else if (format == PPM) {
    ok &= WritePPM(fout, buffer, 0);
  } else if (format == BMP) {
    ok &= WriteBMP(fout, buffer);
  } else if (format == TIFF) {
    ok &= WriteTIFF(fout, buffer);
  } else if (format == PGM || format == YUV) {
    ok &= WritePGMOrYUV(fout, buffer, format);
  } else if (format == ALPHA_PLANE_ONLY) {
    ok &= WriteAlphaPlane(fout, buffer);
  }
  if (fout != NULL && fout != stdout) {
    fclose(fout);
  }
  if (ok) {
    if (use_stdout) {
      fprintf(stderr, "Saved to stdout\n");
    } else {
      fprintf(stderr, "Saved file %s\n", out_file);
    }
    if (verbose) {
      const double write_time = StopwatchReadAndReset(&stop_watch);
      fprintf(stderr, "Time to write output: %.3fs\n", write_time);
    }
  } else {
    if (use_stdout) {
      fprintf(stderr, "Error writing to stdout !!\n");
    } else {
      fprintf(stderr, "Error writing file %s !!\n", out_file);
    }
  }
  return ok;
}

static void Help(void) {
  printf("Usage: dwebp in_file [options] [-o out_file]\n\n"
         "Decodes the WebP image file to PNG format [Default]\n"
         "Use following options to convert into alternate image formats:\n"
         "  -pam ......... save the raw RGBA samples as a color PAM\n"
         "  -ppm ......... save the raw RGB samples as a color PPM\n"
         "  -bmp ......... save as uncompressed BMP format\n"
         "  -tiff ........ save as uncompressed TIFF format\n"
         "  -pgm ......... save the raw YUV samples as a grayscale PGM\n"
         "                 file with IMC4 layout\n"
         "  -yuv ......... save the raw YUV samples in flat layout\n"
         "\n"
         " Other options are:\n"
         "  -version  .... print version number and exit\n"
         "  -nofancy ..... don't use the fancy YUV420 upscaler\n"
         "  -nofilter .... disable in-loop filtering\n"
         "  -nodither .... disable dithering\n"
         "  -dither <d> .. dithering strength (in 0..100)\n"
#if WEBP_DECODER_ABI_VERSION > 0x0204
         "  -alpha_dither  use alpha-plane dithering if needed\n"
#endif
         "  -mt .......... use multi-threading\n"
         "  -crop <x> <y> <w> <h> ... crop output with the given rectangle\n"
         "  -scale <w> <h> .......... scale the output (*after* any cropping)\n"
#if WEBP_DECODER_ABI_VERSION > 0x0203
         "  -flip ........ flip the output vertically\n"
#endif
         "  -alpha ....... only save the alpha plane\n"
         "  -incremental . use incremental decoding (useful for tests)\n"
         "  -h     ....... this help message\n"
         "  -v     ....... verbose (e.g. print encoding/decoding times)\n"
#ifndef WEBP_DLL
         "  -noasm ....... disable all assembly optimizations\n"
#endif
        );
}

static const char* const kFormatType[] = {
  "unspecified", "lossy", "lossless"
};

int main(int argc, const char *argv[]) {
  int ok = 0;
  const char *in_file = NULL;
  const char *out_file = NULL;

  WebPDecoderConfig config;
  WebPDecBuffer* const output_buffer = &config.output;
  WebPBitstreamFeatures* const bitstream = &config.input;
  OutputFileFormat format = PNG;
  int incremental = 0;
  int c;

  if (!WebPInitDecoderConfig(&config)) {
    fprintf(stderr, "Library version mismatch!\n");
    return -1;
  }

  for (c = 1; c < argc; ++c) {
    int parse_error = 0;
    if (!strcmp(argv[c], "-h") || !strcmp(argv[c], "-help")) {
      Help();
      return 0;
    } else if (!strcmp(argv[c], "-o") && c < argc - 1) {
      out_file = argv[++c];
    } else if (!strcmp(argv[c], "-alpha")) {
      format = ALPHA_PLANE_ONLY;
    } else if (!strcmp(argv[c], "-nofancy")) {
      config.options.no_fancy_upsampling = 1;
    } else if (!strcmp(argv[c], "-nofilter")) {
      config.options.bypass_filtering = 1;
    } else if (!strcmp(argv[c], "-pam")) {
      format = PAM;
    } else if (!strcmp(argv[c], "-ppm")) {
      format = PPM;
    } else if (!strcmp(argv[c], "-bmp")) {
      format = BMP;
    } else if (!strcmp(argv[c], "-tiff")) {
      format = TIFF;
    } else if (!strcmp(argv[c], "-version")) {
      const int version = WebPGetDecoderVersion();
      printf("%d.%d.%d\n",
             (version >> 16) & 0xff, (version >> 8) & 0xff, version & 0xff);
      return 0;
    } else if (!strcmp(argv[c], "-pgm")) {
      format = PGM;
    } else if (!strcmp(argv[c], "-yuv")) {
      format = YUV;
    } else if (!strcmp(argv[c], "-mt")) {
      config.options.use_threads = 1;
#if WEBP_DECODER_ABI_VERSION > 0x0204
    } else if (!strcmp(argv[c], "-alpha_dither")) {
      config.options.alpha_dithering_strength = 100;
#endif
    } else if (!strcmp(argv[c], "-nodither")) {
      config.options.dithering_strength = 0;
    } else if (!strcmp(argv[c], "-dither") && c < argc - 1) {
      config.options.dithering_strength =
          ExUtilGetInt(argv[++c], 0, &parse_error);
    } else if (!strcmp(argv[c], "-crop") && c < argc - 4) {
      config.options.use_cropping = 1;
      config.options.crop_left   = ExUtilGetInt(argv[++c], 0, &parse_error);
      config.options.crop_top    = ExUtilGetInt(argv[++c], 0, &parse_error);
      config.options.crop_width  = ExUtilGetInt(argv[++c], 0, &parse_error);
      config.options.crop_height = ExUtilGetInt(argv[++c], 0, &parse_error);
    } else if (!strcmp(argv[c], "-scale") && c < argc - 2) {
      config.options.use_scaling = 1;
      config.options.scaled_width  = ExUtilGetInt(argv[++c], 0, &parse_error);
      config.options.scaled_height = ExUtilGetInt(argv[++c], 0, &parse_error);
#if WEBP_DECODER_ABI_VERSION > 0x0203
    } else if (!strcmp(argv[c], "-flip")) {
      config.options.flip = 1;
#endif
    } else if (!strcmp(argv[c], "-v")) {
      verbose = 1;
#ifndef WEBP_DLL
    } else if (!strcmp(argv[c], "-noasm")) {
      VP8GetCPUInfo = NULL;
#endif
    } else if (!strcmp(argv[c], "-incremental")) {
      incremental = 1;
    } else if (!strcmp(argv[c], "--")) {
      if (c < argc - 1) in_file = argv[++c];
      break;
    } else if (argv[c][0] == '-') {
      fprintf(stderr, "Unknown option '%s'\n", argv[c]);
      Help();
      return -1;
    } else {
      in_file = argv[c];
    }

    if (parse_error) {
      Help();
      return -1;
    }
  }

  if (in_file == NULL) {
    fprintf(stderr, "missing input file!!\n");
    Help();
    return -1;
  }

  {
    VP8StatusCode status = VP8_STATUS_OK;
    size_t data_size = 0;
    const uint8_t* data = NULL;
    if (!ExUtilLoadWebP(in_file, &data, &data_size, bitstream)) {
      return -1;
    }

    switch (format) {
      case PNG:
#ifdef HAVE_WINCODEC_H
        output_buffer->colorspace = bitstream->has_alpha ? MODE_BGRA : MODE_BGR;
#else
        output_buffer->colorspace = bitstream->has_alpha ? MODE_RGBA : MODE_RGB;
#endif
        break;
      case PAM:
        output_buffer->colorspace = MODE_RGBA;
        break;
      case PPM:
        output_buffer->colorspace = MODE_RGB;  // drops alpha for PPM
        break;
      case BMP:
        output_buffer->colorspace = bitstream->has_alpha ? MODE_BGRA : MODE_BGR;
        break;
      case TIFF:    // note: force pre-multiplied alpha
        output_buffer->colorspace =
            bitstream->has_alpha ? MODE_rgbA : MODE_RGB;
        break;
      case PGM:
      case YUV:
        output_buffer->colorspace = bitstream->has_alpha ? MODE_YUVA : MODE_YUV;
        break;
      case ALPHA_PLANE_ONLY:
        output_buffer->colorspace = MODE_YUVA;
        break;
      default:
        free((void*)data);
        return -1;
    }

    if (incremental) {
      status = ExUtilDecodeWebPIncremental(data, data_size, verbose, &config);
    } else {
      status = ExUtilDecodeWebP(data, data_size, verbose, &config);
    }

    free((void*)data);
    ok = (status == VP8_STATUS_OK);
    if (!ok) {
      ExUtilPrintWebPError(in_file, status);
      goto Exit;
    }
  }

  if (out_file != NULL) {
    fprintf(stderr, "Decoded %s. Dimensions: %d x %d %s. Format: %s. "
                    "Now saving...\n",
            in_file, output_buffer->width, output_buffer->height,
            bitstream->has_alpha ? " (with alpha)" : "",
            kFormatType[bitstream->format]);
    ok = SaveOutput(output_buffer, format, out_file);
  } else {
    fprintf(stderr, "File %s can be decoded "
                    "(dimensions: %d x %d %s. Format: %s).\n",
            in_file, output_buffer->width, output_buffer->height,
            bitstream->has_alpha ? " (with alpha)" : "",
            kFormatType[bitstream->format]);
    fprintf(stderr, "Nothing written; "
                    "use -o flag to save the result as e.g. PNG.\n");
  }
 Exit:
  WebPFreeDecBuffer(output_buffer);
  return ok ? 0 : -1;
}

//------------------------------------------------------------------------------
