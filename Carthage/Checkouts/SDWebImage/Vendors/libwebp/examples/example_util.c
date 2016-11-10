// Copyright 2012 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
//  Utility functions used by the example programs.
//

#include "./example_util.h"

#if defined(_WIN32)
#include <fcntl.h>   // for _O_BINARY
#include <io.h>      // for _setmode()
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "webp/decode.h"
#include "./stopwatch.h"

//------------------------------------------------------------------------------
// String parsing

uint32_t ExUtilGetUInt(const char* const v, int base, int* const error) {
  char* end = NULL;
  const uint32_t n = (v != NULL) ? (uint32_t)strtoul(v, &end, base) : 0u;
  if (end == v && error != NULL && !*error) {
    *error = 1;
    fprintf(stderr, "Error! '%s' is not an integer.\n",
            (v != NULL) ? v : "(null)");
  }
  return n;
}

int ExUtilGetInt(const char* const v, int base, int* const error) {
  return (int)ExUtilGetUInt(v, base, error);
}

float ExUtilGetFloat(const char* const v, int* const error) {
  char* end = NULL;
  const float f = (v != NULL) ? (float)strtod(v, &end) : 0.f;
  if (end == v && error != NULL && !*error) {
    *error = 1;
    fprintf(stderr, "Error! '%s' is not a floating point number.\n",
            (v != NULL) ? v : "(null)");
  }
  return f;
}

// -----------------------------------------------------------------------------
// File I/O

FILE* ExUtilSetBinaryMode(FILE* file) {
#if defined(_WIN32)
  if (_setmode(_fileno(file), _O_BINARY) == -1) {
    fprintf(stderr, "Failed to reopen file in O_BINARY mode.\n");
    return NULL;
  }
#endif
  return file;
}

int ExUtilReadFromStdin(const uint8_t** data, size_t* data_size) {
  static const size_t kBlockSize = 16384;  // default initial size
  size_t max_size = 0;
  size_t size = 0;
  uint8_t* input = NULL;

  if (data == NULL || data_size == NULL) return 0;
  *data = NULL;
  *data_size = 0;

  if (!ExUtilSetBinaryMode(stdin)) return 0;

  while (!feof(stdin)) {
    // We double the buffer size each time and read as much as possible.
    const size_t extra_size = (max_size == 0) ? kBlockSize : max_size;
    void* const new_data = realloc(input, max_size + extra_size);
    if (new_data == NULL) goto Error;
    input = (uint8_t*)new_data;
    max_size += extra_size;
    size += fread(input + size, 1, extra_size, stdin);
    if (size < max_size) break;
  }
  if (ferror(stdin)) goto Error;
  *data = input;
  *data_size = size;
  return 1;

 Error:
  free(input);
  fprintf(stderr, "Could not read from stdin\n");
  return 0;
}

int ExUtilReadFile(const char* const file_name,
                   const uint8_t** data, size_t* data_size) {
  int ok;
  void* file_data;
  size_t file_size;
  FILE* in;
  const int from_stdin = (file_name == NULL) || !strcmp(file_name, "-");

  if (from_stdin) return ExUtilReadFromStdin(data, data_size);

  if (data == NULL || data_size == NULL) return 0;
  *data = NULL;
  *data_size = 0;

  in = fopen(file_name, "rb");
  if (in == NULL) {
    fprintf(stderr, "cannot open input file '%s'\n", file_name);
    return 0;
  }
  fseek(in, 0, SEEK_END);
  file_size = ftell(in);
  fseek(in, 0, SEEK_SET);
  file_data = malloc(file_size);
  if (file_data == NULL) return 0;
  ok = (fread(file_data, file_size, 1, in) == 1);
  fclose(in);

  if (!ok) {
    fprintf(stderr, "Could not read %d bytes of data from file %s\n",
            (int)file_size, file_name);
    free(file_data);
    return 0;
  }
  *data = (uint8_t*)file_data;
  *data_size = file_size;
  return 1;
}

int ExUtilWriteFile(const char* const file_name,
                    const uint8_t* data, size_t data_size) {
  int ok;
  FILE* out;
  const int to_stdout = (file_name == NULL) || !strcmp(file_name, "-");

  if (data == NULL) {
    return 0;
  }
  out = to_stdout ? stdout : fopen(file_name, "wb");
  if (out == NULL) {
    fprintf(stderr, "Error! Cannot open output file '%s'\n", file_name);
    return 0;
  }
  ok = (fwrite(data, data_size, 1, out) == 1);
  if (out != stdout) fclose(out);
  return ok;
}

//------------------------------------------------------------------------------
// WebP decoding

static const char* const kStatusMessages[VP8_STATUS_NOT_ENOUGH_DATA + 1] = {
  "OK", "OUT_OF_MEMORY", "INVALID_PARAM", "BITSTREAM_ERROR",
  "UNSUPPORTED_FEATURE", "SUSPENDED", "USER_ABORT", "NOT_ENOUGH_DATA"
};

static void PrintAnimationWarning(const WebPDecoderConfig* const config) {
  if (config->input.has_animation) {
    fprintf(stderr,
            "Error! Decoding of an animated WebP file is not supported.\n"
            "       Use webpmux to extract the individual frames or\n"
            "       vwebp to view this image.\n");
  }
}

void ExUtilPrintWebPError(const char* const in_file, int status) {
  fprintf(stderr, "Decoding of %s failed.\n", in_file);
  fprintf(stderr, "Status: %d", status);
  if (status >= VP8_STATUS_OK && status <= VP8_STATUS_NOT_ENOUGH_DATA) {
    fprintf(stderr, "(%s)", kStatusMessages[status]);
  }
  fprintf(stderr, "\n");
}

int ExUtilLoadWebP(const char* const in_file,
                   const uint8_t** data, size_t* data_size,
                   WebPBitstreamFeatures* bitstream) {
  VP8StatusCode status;
  WebPBitstreamFeatures local_features;
  if (!ExUtilReadFile(in_file, data, data_size)) return 0;

  if (bitstream == NULL) {
    bitstream = &local_features;
  }

  status = WebPGetFeatures(*data, *data_size, bitstream);
  if (status != VP8_STATUS_OK) {
    free((void*)*data);
    *data = NULL;
    *data_size = 0;
    ExUtilPrintWebPError(in_file, status);
    return 0;
  }
  return 1;
}

//------------------------------------------------------------------------------

VP8StatusCode ExUtilDecodeWebP(const uint8_t* const data, size_t data_size,
                               int verbose, WebPDecoderConfig* const config) {
  Stopwatch stop_watch;
  VP8StatusCode status = VP8_STATUS_OK;
  if (config == NULL) return VP8_STATUS_INVALID_PARAM;

  PrintAnimationWarning(config);

  StopwatchReset(&stop_watch);

  // Decoding call.
  status = WebPDecode(data, data_size, config);

  if (verbose) {
    const double decode_time = StopwatchReadAndReset(&stop_watch);
    fprintf(stderr, "Time to decode picture: %.3fs\n", decode_time);
  }
  return status;
}

VP8StatusCode ExUtilDecodeWebPIncremental(
    const uint8_t* const data, size_t data_size,
    int verbose, WebPDecoderConfig* const config) {
  Stopwatch stop_watch;
  VP8StatusCode status = VP8_STATUS_OK;
  if (config == NULL) return VP8_STATUS_INVALID_PARAM;

  PrintAnimationWarning(config);

  StopwatchReset(&stop_watch);

  // Decoding call.
  {
    WebPIDecoder* const idec = WebPIDecode(data, data_size, config);
    if (idec == NULL) {
      fprintf(stderr, "Failed during WebPINewDecoder().\n");
      return VP8_STATUS_OUT_OF_MEMORY;
    } else {
      status = WebPIUpdate(idec, data, data_size);
      WebPIDelete(idec);
    }
  }

  if (verbose) {
    const double decode_time = StopwatchReadAndReset(&stop_watch);
    fprintf(stderr, "Time to decode picture: %.3fs\n", decode_time);
  }
  return status;
}

// -----------------------------------------------------------------------------
