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

#ifndef WEBP_EXAMPLES_EXAMPLE_UTIL_H_
#define WEBP_EXAMPLES_EXAMPLE_UTIL_H_

#include <stdio.h>
#include "webp/decode.h"

#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------------------------------------------
// String parsing

// Parses 'v' using strto(ul|l|d)(). If error is non-NULL, '*error' is set to
// true on failure while on success it is left unmodified to allow chaining of
// calls. An error is only printed on the first occurrence.
uint32_t ExUtilGetUInt(const char* const v, int base, int* const error);
int ExUtilGetInt(const char* const v, int base, int* const error);
float ExUtilGetFloat(const char* const v, int* const error);

//------------------------------------------------------------------------------
// File I/O

// Reopen file in binary (O_BINARY) mode.
// Returns 'file' on success, NULL otherwise.
FILE* ExUtilSetBinaryMode(FILE* file);

// Allocates storage for entire file 'file_name' and returns contents and size
// in 'data' and 'data_size'. Returns 1 on success, 0 otherwise. '*data' should
// be deleted using free().
// If 'file_name' is NULL or equal to "-", input is read from stdin by calling
// the function ExUtilReadFromStdin().
int ExUtilReadFile(const char* const file_name,
                   const uint8_t** data, size_t* data_size);

// Same as ExUtilReadFile(), but reads until EOF from stdin instead.
int ExUtilReadFromStdin(const uint8_t** data, size_t* data_size);

// Write a data segment into a file named 'file_name'. Returns true if ok.
// If 'file_name' is NULL or equal to "-", output is written to stdout.
int ExUtilWriteFile(const char* const file_name,
                    const uint8_t* data, size_t data_size);

//------------------------------------------------------------------------------
// WebP decoding

// Prints an informative error message regarding decode failure of 'in_file'.
// 'status' is treated as a VP8StatusCode and if valid will be printed as a
// text string.
void ExUtilPrintWebPError(const char* const in_file, int status);

// Reads a WebP from 'in_file', returning the contents and size in 'data' and
// 'data_size'. If not NULL, 'bitstream' is populated using WebPGetFeatures().
// Returns true on success.
int ExUtilLoadWebP(const char* const in_file,
                   const uint8_t** data, size_t* data_size,
                   WebPBitstreamFeatures* bitstream);

// Decodes the WebP contained in 'data'.
// 'config' is a structure previously initialized by WebPInitDecoderConfig().
// 'config->output' should have the desired colorspace selected. 'verbose' will
// cause decode timing to be reported.
// Returns the decoder status. On success 'config->output' will contain the
// decoded picture.
VP8StatusCode ExUtilDecodeWebP(const uint8_t* const data, size_t data_size,
                               int verbose, WebPDecoderConfig* const config);

// Same as ExUtilDecodeWebP(), but using the incremental decoder.
VP8StatusCode ExUtilDecodeWebPIncremental(
    const uint8_t* const data, size_t data_size,
    int verbose, WebPDecoderConfig* const config);

#ifdef __cplusplus
}    // extern "C"
#endif

#endif  // WEBP_EXAMPLES_EXAMPLE_UTIL_H_
