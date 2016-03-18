// Copyright 2011 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
//  Simple command-line to create a WebP container file and to extract or strip
//  relevant data from the container file.
//
// Authors: Vikas (vikaas.arora@gmail.com),
//          Urvang (urvang@google.com)

/*  Usage examples:

  Create container WebP file:
    webpmux -frame anim_1.webp +100+10+10   \
            -frame anim_2.webp +100+25+25+1 \
            -frame anim_3.webp +100+50+50+1 \
            -frame anim_4.webp +100         \
            -loop 10 -bgcolor 128,255,255,255 \
            -o out_animation_container.webp

    webpmux -set icc image_profile.icc in.webp -o out_icc_container.webp
    webpmux -set exif image_metadata.exif in.webp -o out_exif_container.webp
    webpmux -set xmp image_metadata.xmp in.webp -o out_xmp_container.webp

  Extract relevant data from WebP container file:
    webpmux -get frgm n in.webp -o out_fragment.webp
    webpmux -get frame n in.webp -o out_frame.webp
    webpmux -get icc in.webp -o image_profile.icc
    webpmux -get exif in.webp -o image_metadata.exif
    webpmux -get xmp in.webp -o image_metadata.xmp

  Strip data from WebP Container file:
    webpmux -strip icc in.webp -o out.webp
    webpmux -strip exif in.webp -o out.webp
    webpmux -strip xmp in.webp -o out.webp

  Misc:
    webpmux -info in.webp
    webpmux [ -h | -help ]
    webpmux -version
*/

#ifdef HAVE_CONFIG_H
#include "webp/config.h"
#endif

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "webp/decode.h"
#include "webp/mux.h"
#include "./example_util.h"

//------------------------------------------------------------------------------
// Config object to parse command-line arguments.

typedef enum {
  NIL_ACTION = 0,
  ACTION_GET,
  ACTION_SET,
  ACTION_STRIP,
  ACTION_INFO,
  ACTION_HELP
} ActionType;

typedef enum {
  NIL_SUBTYPE = 0,
  SUBTYPE_ANMF,
  SUBTYPE_LOOP,
  SUBTYPE_BGCOLOR
} FeatureSubType;

typedef struct {
  FeatureSubType subtype_;
  const char* filename_;
  const char* params_;
} FeatureArg;

typedef enum {
  NIL_FEATURE = 0,
  FEATURE_EXIF,
  FEATURE_XMP,
  FEATURE_ICCP,
  FEATURE_ANMF,
  FEATURE_FRGM,
  LAST_FEATURE
} FeatureType;

static const char* const kFourccList[LAST_FEATURE] = {
  NULL, "EXIF", "XMP ", "ICCP", "ANMF", "FRGM"
};

static const char* const kDescriptions[LAST_FEATURE] = {
  NULL, "EXIF metadata", "XMP metadata", "ICC profile",
  "Animation frame", "Image fragment"
};

typedef struct {
  FeatureType type_;
  FeatureArg* args_;
  int arg_count_;
} Feature;

typedef struct {
  ActionType action_type_;
  const char* input_;
  const char* output_;
  Feature feature_;
} WebPMuxConfig;

//------------------------------------------------------------------------------
// Helper functions.

static int CountOccurrences(const char* arglist[], int list_length,
                            const char* arg) {
  int i;
  int num_occurences = 0;

  for (i = 0; i < list_length; ++i) {
    if (!strcmp(arglist[i], arg)) {
      ++num_occurences;
    }
  }
  return num_occurences;
}

static const char* const kErrorMessages[-WEBP_MUX_NOT_ENOUGH_DATA + 1] = {
  "WEBP_MUX_NOT_FOUND", "WEBP_MUX_INVALID_ARGUMENT", "WEBP_MUX_BAD_DATA",
  "WEBP_MUX_MEMORY_ERROR", "WEBP_MUX_NOT_ENOUGH_DATA"
};

static const char* ErrorString(WebPMuxError err) {
  assert(err <= WEBP_MUX_NOT_FOUND && err >= WEBP_MUX_NOT_ENOUGH_DATA);
  return kErrorMessages[-err];
}

#define RETURN_IF_ERROR(ERR_MSG)                                     \
  if (err != WEBP_MUX_OK) {                                          \
    fprintf(stderr, ERR_MSG);                                        \
    return err;                                                      \
  }

#define RETURN_IF_ERROR3(ERR_MSG, FORMAT_STR1, FORMAT_STR2)          \
  if (err != WEBP_MUX_OK) {                                          \
    fprintf(stderr, ERR_MSG, FORMAT_STR1, FORMAT_STR2);              \
    return err;                                                      \
  }

#define ERROR_GOTO1(ERR_MSG, LABEL)                                  \
  do {                                                               \
    fprintf(stderr, ERR_MSG);                                        \
    ok = 0;                                                          \
    goto LABEL;                                                      \
  } while (0)

#define ERROR_GOTO2(ERR_MSG, FORMAT_STR, LABEL)                      \
  do {                                                               \
    fprintf(stderr, ERR_MSG, FORMAT_STR);                            \
    ok = 0;                                                          \
    goto LABEL;                                                      \
  } while (0)

#define ERROR_GOTO3(ERR_MSG, FORMAT_STR1, FORMAT_STR2, LABEL)        \
  do {                                                               \
    fprintf(stderr, ERR_MSG, FORMAT_STR1, FORMAT_STR2);              \
    ok = 0;                                                          \
    goto LABEL;                                                      \
  } while (0)

static WebPMuxError DisplayInfo(const WebPMux* mux) {
  int width, height;
  uint32_t flag;

  WebPMuxError err = WebPMuxGetCanvasSize(mux, &width, &height);
  assert(err == WEBP_MUX_OK);  // As WebPMuxCreate() was successful earlier.
  printf("Canvas size: %d x %d\n", width, height);

  err = WebPMuxGetFeatures(mux, &flag);
#ifndef WEBP_EXPERIMENTAL_FEATURES
  if (flag & FRAGMENTS_FLAG) err = WEBP_MUX_INVALID_ARGUMENT;
#endif
  RETURN_IF_ERROR("Failed to retrieve features\n");

  if (flag == 0) {
    fprintf(stderr, "No features present.\n");
    return err;
  }

  // Print the features present.
  printf("Features present:");
  if (flag & ANIMATION_FLAG) printf(" animation");
  if (flag & FRAGMENTS_FLAG) printf(" image fragments");
  if (flag & ICCP_FLAG)      printf(" ICC profile");
  if (flag & EXIF_FLAG)      printf(" EXIF metadata");
  if (flag & XMP_FLAG)       printf(" XMP metadata");
  if (flag & ALPHA_FLAG)     printf(" transparency");
  printf("\n");

  if ((flag & ANIMATION_FLAG) || (flag & FRAGMENTS_FLAG)) {
    const int is_anim = !!(flag & ANIMATION_FLAG);
    const WebPChunkId id = is_anim ? WEBP_CHUNK_ANMF : WEBP_CHUNK_FRGM;
    const char* const type_str = is_anim ? "frame" : "fragment";
    int nFrames;

    if (is_anim) {
      WebPMuxAnimParams params;
      err = WebPMuxGetAnimationParams(mux, &params);
      assert(err == WEBP_MUX_OK);
      printf("Background color : 0x%.8X  Loop Count : %d\n",
             params.bgcolor, params.loop_count);
    }

    err = WebPMuxNumChunks(mux, id, &nFrames);
    assert(err == WEBP_MUX_OK);

    printf("Number of %ss: %d\n", type_str, nFrames);
    if (nFrames > 0) {
      int i;
      printf("No.: width height alpha x_offset y_offset ");
      if (is_anim) printf("duration   dispose blend ");
      printf("image_size\n");
      for (i = 1; i <= nFrames; i++) {
        WebPMuxFrameInfo frame;
        err = WebPMuxGetFrame(mux, i, &frame);
        if (err == WEBP_MUX_OK) {
          WebPBitstreamFeatures features;
          const VP8StatusCode status = WebPGetFeatures(
              frame.bitstream.bytes, frame.bitstream.size, &features);
          assert(status == VP8_STATUS_OK);  // Checked by WebPMuxCreate().
          (void)status;
          printf("%3d: %5d %5d %5s %8d %8d ", i, features.width,
                 features.height, features.has_alpha ? "yes" : "no",
                 frame.x_offset, frame.y_offset);
          if (is_anim) {
            const char* const dispose =
                (frame.dispose_method == WEBP_MUX_DISPOSE_NONE) ? "none"
                                                                : "background";
            const char* const blend =
                (frame.blend_method == WEBP_MUX_BLEND) ? "yes" : "no";
            printf("%8d %10s %5s ", frame.duration, dispose, blend);
          }
          printf("%10d\n", (int)frame.bitstream.size);
        }
        WebPDataClear(&frame.bitstream);
        RETURN_IF_ERROR3("Failed to retrieve %s#%d\n", type_str, i);
      }
    }
  }

  if (flag & ICCP_FLAG) {
    WebPData icc_profile;
    err = WebPMuxGetChunk(mux, "ICCP", &icc_profile);
    assert(err == WEBP_MUX_OK);
    printf("Size of the ICC profile data: %d\n", (int)icc_profile.size);
  }

  if (flag & EXIF_FLAG) {
    WebPData exif;
    err = WebPMuxGetChunk(mux, "EXIF", &exif);
    assert(err == WEBP_MUX_OK);
    printf("Size of the EXIF metadata: %d\n", (int)exif.size);
  }

  if (flag & XMP_FLAG) {
    WebPData xmp;
    err = WebPMuxGetChunk(mux, "XMP ", &xmp);
    assert(err == WEBP_MUX_OK);
    printf("Size of the XMP metadata: %d\n", (int)xmp.size);
  }

  if ((flag & ALPHA_FLAG) && !(flag & (ANIMATION_FLAG | FRAGMENTS_FLAG))) {
    WebPMuxFrameInfo image;
    err = WebPMuxGetFrame(mux, 1, &image);
    if (err == WEBP_MUX_OK) {
      printf("Size of the image (with alpha): %d\n", (int)image.bitstream.size);
    }
    WebPDataClear(&image.bitstream);
    RETURN_IF_ERROR("Failed to retrieve the image\n");
  }

  return WEBP_MUX_OK;
}

static void PrintHelp(void) {
  printf("Usage: webpmux -get GET_OPTIONS INPUT -o OUTPUT\n");
  printf("       webpmux -set SET_OPTIONS INPUT -o OUTPUT\n");
  printf("       webpmux -strip STRIP_OPTIONS INPUT -o OUTPUT\n");
#ifdef WEBP_EXPERIMENTAL_FEATURES
  printf("       webpmux -frgm FRAGMENT_OPTIONS [-frgm...] -o OUTPUT\n");
#endif
  printf("       webpmux -frame FRAME_OPTIONS [-frame...] [-loop LOOP_COUNT]"
         "\n");
  printf("               [-bgcolor BACKGROUND_COLOR] -o OUTPUT\n");
  printf("       webpmux -info INPUT\n");
  printf("       webpmux [-h|-help]\n");
  printf("       webpmux -version\n");

  printf("\n");
  printf("GET_OPTIONS:\n");
  printf(" Extract relevant data:\n");
  printf("   icc       get ICC profile\n");
  printf("   exif      get EXIF metadata\n");
  printf("   xmp       get XMP metadata\n");
#ifdef WEBP_EXPERIMENTAL_FEATURES
  printf("   frgm n    get nth fragment\n");
#endif
  printf("   frame n   get nth frame\n");

  printf("\n");
  printf("SET_OPTIONS:\n");
  printf(" Set color profile/metadata:\n");
  printf("   icc  file.icc     set ICC profile\n");
  printf("   exif file.exif    set EXIF metadata\n");
  printf("   xmp  file.xmp     set XMP metadata\n");
  printf("   where:    'file.icc' contains the ICC profile to be set,\n");
  printf("             'file.exif' contains the EXIF metadata to be set\n");
  printf("             'file.xmp' contains the XMP metadata to be set\n");

  printf("\n");
  printf("STRIP_OPTIONS:\n");
  printf(" Strip color profile/metadata:\n");
  printf("   icc       strip ICC profile\n");
  printf("   exif      strip EXIF metadata\n");
  printf("   xmp       strip XMP metadata\n");

#ifdef WEBP_EXPERIMENTAL_FEATURES
  printf("\n");
  printf("FRAGMENT_OPTIONS(i):\n");
  printf(" Create fragmented image:\n");
  printf("   file_i +xi+yi\n");
  printf("   where:    'file_i' is the i'th fragment (WebP format),\n");
  printf("             'xi','yi' specify the image offset for this fragment"
         "\n");
#endif

  printf("\n");
  printf("FRAME_OPTIONS(i):\n");
  printf(" Create animation:\n");
  printf("   file_i +di+[xi+yi[+mi[bi]]]\n");
  printf("   where:    'file_i' is the i'th animation frame (WebP format),\n");
  printf("             'di' is the pause duration before next frame,\n");
  printf("             'xi','yi' specify the image offset for this frame,\n");
  printf("             'mi' is the dispose method for this frame (0 or 1),\n");
  printf("             'bi' is the blending method for this frame (+b or -b)"
         "\n");

  printf("\n");
  printf("LOOP_COUNT:\n");
  printf(" Number of times to repeat the animation.\n");
  printf(" Valid range is 0 to 65535 [Default: 0 (infinite)].\n");

  printf("\n");
  printf("BACKGROUND_COLOR:\n");
  printf(" Background color of the canvas.\n");
  printf("  A,R,G,B\n");
  printf("  where:    'A', 'R', 'G' and 'B' are integers in the range 0 to 255 "
         "specifying\n");
  printf("            the Alpha, Red, Green and Blue component values "
         "respectively\n");
  printf("            [Default: 255,255,255,255]\n");

  printf("\nINPUT & OUTPUT are in WebP format.\n");

  printf("\nNote: The nature of EXIF, XMP and ICC data is not checked");
  printf(" and is assumed to be\nvalid.\n");
}

static void WarnAboutOddOffset(const WebPMuxFrameInfo* const info) {
  if ((info->x_offset | info->y_offset) & 1) {
    fprintf(stderr, "Warning: odd offsets will be snapped to even values"
            " (%d, %d) -> (%d, %d)\n", info->x_offset, info->y_offset,
            info->x_offset & ~1, info->y_offset & ~1);
  }
}

static int ReadFileToWebPData(const char* const filename,
                              WebPData* const webp_data) {
  const uint8_t* data;
  size_t size;
  if (!ExUtilReadFile(filename, &data, &size)) return 0;
  webp_data->bytes = data;
  webp_data->size = size;
  return 1;
}

static int CreateMux(const char* const filename, WebPMux** mux) {
  WebPData bitstream;
  assert(mux != NULL);
  if (!ReadFileToWebPData(filename, &bitstream)) return 0;
  *mux = WebPMuxCreate(&bitstream, 1);
  free((void*)bitstream.bytes);
  if (*mux != NULL) return 1;
  fprintf(stderr, "Failed to create mux object from file %s.\n", filename);
  return 0;
}

static int WriteData(const char* filename, const WebPData* const webpdata) {
  int ok = 0;
  FILE* fout = strcmp(filename, "-") ? fopen(filename, "wb")
                                     : ExUtilSetBinaryMode(stdout);
  if (fout == NULL) {
    fprintf(stderr, "Error opening output WebP file %s!\n", filename);
    return 0;
  }
  if (fwrite(webpdata->bytes, webpdata->size, 1, fout) != 1) {
    fprintf(stderr, "Error writing file %s!\n", filename);
  } else {
    fprintf(stderr, "Saved file %s (%d bytes)\n",
            filename, (int)webpdata->size);
    ok = 1;
  }
  if (fout != stdout) fclose(fout);
  return ok;
}

static int WriteWebP(WebPMux* const mux, const char* filename) {
  int ok;
  WebPData webp_data;
  const WebPMuxError err = WebPMuxAssemble(mux, &webp_data);
  if (err != WEBP_MUX_OK) {
    fprintf(stderr, "Error (%s) assembling the WebP file.\n", ErrorString(err));
    return 0;
  }
  ok = WriteData(filename, &webp_data);
  WebPDataClear(&webp_data);
  return ok;
}

static int ParseFrameArgs(const char* args, WebPMuxFrameInfo* const info) {
  int dispose_method, dummy;
  char plus_minus, blend_method;
  const int num_args = sscanf(args, "+%d+%d+%d+%d%c%c+%d", &info->duration,
                              &info->x_offset, &info->y_offset, &dispose_method,
                              &plus_minus, &blend_method, &dummy);
  switch (num_args) {
    case 1:
      info->x_offset = info->y_offset = 0;  // fall through
    case 3:
      dispose_method = 0;  // fall through
    case 4:
      plus_minus = '+';
      blend_method = 'b';  // fall through
    case 6:
      break;
    case 2:
    case 5:
    default:
      return 0;
  }

  WarnAboutOddOffset(info);

  // Note: The sanity of the following conversion is checked by
  // WebPMuxPushFrame().
  info->dispose_method = (WebPMuxAnimDispose)dispose_method;

  if (blend_method != 'b') return 0;
  if (plus_minus != '-' && plus_minus != '+') return 0;
  info->blend_method =
      (plus_minus == '+') ? WEBP_MUX_BLEND : WEBP_MUX_NO_BLEND;
  return 1;
}

static int ParseFragmentArgs(const char* args, WebPMuxFrameInfo* const info) {
  const int ok =
      (sscanf(args, "+%d+%d", &info->x_offset, &info->y_offset) == 2);
  if (ok) WarnAboutOddOffset(info);
  return ok;
}

static int ParseBgcolorArgs(const char* args, uint32_t* const bgcolor) {
  uint32_t a, r, g, b;
  if (sscanf(args, "%u,%u,%u,%u", &a, &r, &g, &b) != 4) return 0;
  if (a >= 256 || r >= 256 || g >= 256 || b >= 256) return 0;
  *bgcolor = (a << 24) | (r << 16) | (g << 8) | (b << 0);
  return 1;
}

//------------------------------------------------------------------------------
// Clean-up.

static void DeleteConfig(WebPMuxConfig* config) {
  if (config != NULL) {
    free(config->feature_.args_);
    memset(config, 0, sizeof(*config));
  }
}

//------------------------------------------------------------------------------
// Parsing.

// Basic syntactic checks on the command-line arguments.
// Returns 1 on valid, 0 otherwise.
// Also fills up num_feature_args to be number of feature arguments given.
// (e.g. if there are 4 '-frame's and 1 '-loop', then num_feature_args = 5).
static int ValidateCommandLine(int argc, const char* argv[],
                               int* num_feature_args) {
  int num_frame_args;
  int num_frgm_args;
  int num_loop_args;
  int num_bgcolor_args;
  int ok = 1;

  assert(num_feature_args != NULL);
  *num_feature_args = 0;

  // Simple checks.
  if (CountOccurrences(argv, argc, "-get") > 1) {
    ERROR_GOTO1("ERROR: Multiple '-get' arguments specified.\n", ErrValidate);
  }
  if (CountOccurrences(argv, argc, "-set") > 1) {
    ERROR_GOTO1("ERROR: Multiple '-set' arguments specified.\n", ErrValidate);
  }
  if (CountOccurrences(argv, argc, "-strip") > 1) {
    ERROR_GOTO1("ERROR: Multiple '-strip' arguments specified.\n", ErrValidate);
  }
  if (CountOccurrences(argv, argc, "-info") > 1) {
    ERROR_GOTO1("ERROR: Multiple '-info' arguments specified.\n", ErrValidate);
  }
  if (CountOccurrences(argv, argc, "-o") > 1) {
    ERROR_GOTO1("ERROR: Multiple output files specified.\n", ErrValidate);
  }

  // Compound checks.
  num_frame_args = CountOccurrences(argv, argc, "-frame");
  num_frgm_args = CountOccurrences(argv, argc, "-frgm");
  num_loop_args = CountOccurrences(argv, argc, "-loop");
  num_bgcolor_args = CountOccurrences(argv, argc, "-bgcolor");

  if (num_loop_args > 1) {
    ERROR_GOTO1("ERROR: Multiple loop counts specified.\n", ErrValidate);
  }
  if (num_bgcolor_args > 1) {
    ERROR_GOTO1("ERROR: Multiple background colors specified.\n", ErrValidate);
  }

  if ((num_frame_args == 0) && (num_loop_args + num_bgcolor_args > 0)) {
    ERROR_GOTO1("ERROR: Loop count and background color are relevant only in "
                "case of animation.\n", ErrValidate);
  }
  if (num_frame_args > 0 && num_frgm_args > 0) {
    ERROR_GOTO1("ERROR: Only one of frames & fragments can be specified at a "
                "time.\n", ErrValidate);
  }

  assert(ok == 1);
  if (num_frame_args == 0 && num_frgm_args == 0) {
    // Single argument ('set' action for ICCP/EXIF/XMP, OR a 'get' action).
    *num_feature_args = 1;
  } else {
    // Multiple arguments ('set' action for animation or fragmented image).
    if (num_frame_args > 0) {
      *num_feature_args = num_frame_args + num_loop_args + num_bgcolor_args;
    } else {
      *num_feature_args = num_frgm_args;
    }
  }

 ErrValidate:
  return ok;
}

#define ACTION_IS_NIL (config->action_type_ == NIL_ACTION)

#define FEATURETYPE_IS_NIL (feature->type_ == NIL_FEATURE)

#define CHECK_NUM_ARGS_LESS(NUM, LABEL)                                  \
  if (argc < i + (NUM)) {                                                \
    fprintf(stderr, "ERROR: Too few arguments for '%s'.\n", argv[i]);    \
    goto LABEL;                                                          \
  }

#define CHECK_NUM_ARGS_NOT_EQUAL(NUM, LABEL)                             \
  if (argc != i + (NUM)) {                                               \
    fprintf(stderr, "ERROR: Too many arguments for '%s'.\n", argv[i]);   \
    goto LABEL;                                                          \
  }

// Parses command-line arguments to fill up config object. Also performs some
// semantic checks.
static int ParseCommandLine(int argc, const char* argv[],
                            WebPMuxConfig* config) {
  int i = 0;
  int feature_arg_index = 0;
  int ok = 1;

  while (i < argc) {
    Feature* const feature = &config->feature_;
    FeatureArg* const arg = &feature->args_[feature_arg_index];
    if (argv[i][0] == '-') {  // One of the action types or output.
      if (!strcmp(argv[i], "-set")) {
        if (ACTION_IS_NIL) {
          config->action_type_ = ACTION_SET;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        ++i;
      } else if (!strcmp(argv[i], "-get")) {
        if (ACTION_IS_NIL) {
          config->action_type_ = ACTION_GET;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        ++i;
      } else if (!strcmp(argv[i], "-strip")) {
        if (ACTION_IS_NIL) {
          config->action_type_ = ACTION_STRIP;
          feature->arg_count_ = 0;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        ++i;
      } else if (!strcmp(argv[i], "-frame")) {
        CHECK_NUM_ARGS_LESS(3, ErrParse);
        if (ACTION_IS_NIL || config->action_type_ == ACTION_SET) {
          config->action_type_ = ACTION_SET;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        if (FEATURETYPE_IS_NIL || feature->type_ == FEATURE_ANMF) {
          feature->type_ = FEATURE_ANMF;
        } else {
          ERROR_GOTO1("ERROR: Multiple features specified.\n", ErrParse);
        }
        arg->subtype_ = SUBTYPE_ANMF;
        arg->filename_ = argv[i + 1];
        arg->params_ = argv[i + 2];
        ++feature_arg_index;
        i += 3;
      } else if (!strcmp(argv[i], "-loop") || !strcmp(argv[i], "-bgcolor")) {
        CHECK_NUM_ARGS_LESS(2, ErrParse);
        if (ACTION_IS_NIL || config->action_type_ == ACTION_SET) {
          config->action_type_ = ACTION_SET;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        if (FEATURETYPE_IS_NIL || feature->type_ == FEATURE_ANMF) {
          feature->type_ = FEATURE_ANMF;
        } else {
          ERROR_GOTO1("ERROR: Multiple features specified.\n", ErrParse);
        }
        arg->subtype_ =
            !strcmp(argv[i], "-loop") ? SUBTYPE_LOOP : SUBTYPE_BGCOLOR;
        arg->params_ = argv[i + 1];
        ++feature_arg_index;
        i += 2;
#ifdef WEBP_EXPERIMENTAL_FEATURES
      } else if (!strcmp(argv[i], "-frgm")) {
        CHECK_NUM_ARGS_LESS(3, ErrParse);
        if (ACTION_IS_NIL || config->action_type_ == ACTION_SET) {
          config->action_type_ = ACTION_SET;
        } else {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        }
        if (FEATURETYPE_IS_NIL || feature->type_ == FEATURE_FRGM) {
          feature->type_ = FEATURE_FRGM;
        } else {
          ERROR_GOTO1("ERROR: Multiple features specified.\n", ErrParse);
        }
        arg->filename_ = argv[i + 1];
        arg->params_ = argv[i + 2];
        ++feature_arg_index;
        i += 3;
#endif
      } else if (!strcmp(argv[i], "-o")) {
        CHECK_NUM_ARGS_LESS(2, ErrParse);
        config->output_ = argv[i + 1];
        i += 2;
      } else if (!strcmp(argv[i], "-info")) {
        CHECK_NUM_ARGS_NOT_EQUAL(2, ErrParse);
        if (config->action_type_ != NIL_ACTION) {
          ERROR_GOTO1("ERROR: Multiple actions specified.\n", ErrParse);
        } else {
          config->action_type_ = ACTION_INFO;
          feature->arg_count_ = 0;
          config->input_ = argv[i + 1];
        }
        i += 2;
      } else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "-help")) {
        PrintHelp();
        DeleteConfig(config);
        exit(0);
      } else if (!strcmp(argv[i], "-version")) {
        const int version = WebPGetMuxVersion();
        printf("%d.%d.%d\n",
               (version >> 16) & 0xff, (version >> 8) & 0xff, version & 0xff);
        DeleteConfig(config);
        exit(0);
      } else if (!strcmp(argv[i], "--")) {
        if (i < argc - 1) {
          ++i;
          if (config->input_ == NULL) {
            config->input_ = argv[i];
          } else {
            ERROR_GOTO2("ERROR at '%s': Multiple input files specified.\n",
                        argv[i], ErrParse);
          }
        }
        break;
      } else {
        ERROR_GOTO2("ERROR: Unknown option: '%s'.\n", argv[i], ErrParse);
      }
    } else {  // One of the feature types or input.
      if (ACTION_IS_NIL) {
        ERROR_GOTO1("ERROR: Action must be specified before other arguments.\n",
                    ErrParse);
      }
      if (!strcmp(argv[i], "icc") || !strcmp(argv[i], "exif") ||
          !strcmp(argv[i], "xmp")) {
        if (FEATURETYPE_IS_NIL) {
          feature->type_ = (!strcmp(argv[i], "icc")) ? FEATURE_ICCP :
              (!strcmp(argv[i], "exif")) ? FEATURE_EXIF : FEATURE_XMP;
        } else {
          ERROR_GOTO1("ERROR: Multiple features specified.\n", ErrParse);
        }
        if (config->action_type_ == ACTION_SET) {
          CHECK_NUM_ARGS_LESS(2, ErrParse);
          arg->filename_ = argv[i + 1];
          ++feature_arg_index;
          i += 2;
        } else {
          ++i;
        }
#ifdef WEBP_EXPERIMENTAL_FEATURES
      } else if ((!strcmp(argv[i], "frame") ||
                  !strcmp(argv[i], "frgm")) &&
#else
      } else if (!strcmp(argv[i], "frame") &&
#endif
                  (config->action_type_ == ACTION_GET)) {
        CHECK_NUM_ARGS_LESS(2, ErrParse);
        feature->type_ = (!strcmp(argv[i], "frame")) ? FEATURE_ANMF :
            FEATURE_FRGM;
        arg->params_ = argv[i + 1];
        ++feature_arg_index;
        i += 2;
      } else {  // Assume input file.
        if (config->input_ == NULL) {
          config->input_ = argv[i];
        } else {
          ERROR_GOTO2("ERROR at '%s': Multiple input files specified.\n",
                      argv[i], ErrParse);
        }
        ++i;
      }
    }
  }
 ErrParse:
  return ok;
}

// Additional checks after config is filled.
static int ValidateConfig(WebPMuxConfig* config) {
  int ok = 1;
  Feature* const feature = &config->feature_;

  // Action.
  if (ACTION_IS_NIL) {
    ERROR_GOTO1("ERROR: No action specified.\n", ErrValidate2);
  }

  // Feature type.
  if (FEATURETYPE_IS_NIL && config->action_type_ != ACTION_INFO) {
    ERROR_GOTO1("ERROR: No feature specified.\n", ErrValidate2);
  }

  // Input file.
  if (config->input_ == NULL) {
    if (config->action_type_ != ACTION_SET) {
      ERROR_GOTO1("ERROR: No input file specified.\n", ErrValidate2);
    } else if (feature->type_ != FEATURE_ANMF &&
               feature->type_ != FEATURE_FRGM) {
      ERROR_GOTO1("ERROR: No input file specified.\n", ErrValidate2);
    }
  }

  // Output file.
  if (config->output_ == NULL && config->action_type_ != ACTION_INFO) {
    ERROR_GOTO1("ERROR: No output file specified.\n", ErrValidate2);
  }

 ErrValidate2:
  return ok;
}

// Create config object from command-line arguments.
static int InitializeConfig(int argc, const char* argv[],
                            WebPMuxConfig* config) {
  int num_feature_args = 0;
  int ok = 1;

  assert(config != NULL);
  memset(config, 0, sizeof(*config));

  // Validate command-line arguments.
  if (!ValidateCommandLine(argc, argv, &num_feature_args)) {
    ERROR_GOTO1("Exiting due to command-line parsing error.\n", Err1);
  }

  config->feature_.arg_count_ = num_feature_args;
  config->feature_.args_ =
      (FeatureArg*)calloc(num_feature_args, sizeof(*config->feature_.args_));
  if (config->feature_.args_ == NULL) {
    ERROR_GOTO1("ERROR: Memory allocation error.\n", Err1);
  }

  // Parse command-line.
  if (!ParseCommandLine(argc, argv, config) || !ValidateConfig(config)) {
    ERROR_GOTO1("Exiting due to command-line parsing error.\n", Err1);
  }

 Err1:
  return ok;
}

#undef ACTION_IS_NIL
#undef FEATURETYPE_IS_NIL
#undef CHECK_NUM_ARGS_LESS
#undef CHECK_NUM_ARGS_MORE

//------------------------------------------------------------------------------
// Processing.

static int GetFrameFragment(const WebPMux* mux,
                            const WebPMuxConfig* config, int is_frame) {
  WebPMuxError err = WEBP_MUX_OK;
  WebPMux* mux_single = NULL;
  long num = 0;
  int ok = 1;
  int parse_error = 0;
  const WebPChunkId id = is_frame ? WEBP_CHUNK_ANMF : WEBP_CHUNK_FRGM;
  WebPMuxFrameInfo info;
  WebPDataInit(&info.bitstream);

  num = ExUtilGetInt(config->feature_.args_[0].params_, 10, &parse_error);
  if (num < 0) {
    ERROR_GOTO1("ERROR: Frame/Fragment index must be non-negative.\n", ErrGet);
  }
  if (parse_error) goto ErrGet;

  err = WebPMuxGetFrame(mux, num, &info);
  if (err == WEBP_MUX_OK && info.id != id) err = WEBP_MUX_NOT_FOUND;
  if (err != WEBP_MUX_OK) {
    ERROR_GOTO3("ERROR (%s): Could not get frame %ld.\n",
                ErrorString(err), num, ErrGet);
  }

  mux_single = WebPMuxNew();
  if (mux_single == NULL) {
    err = WEBP_MUX_MEMORY_ERROR;
    ERROR_GOTO2("ERROR (%s): Could not allocate a mux object.\n",
                ErrorString(err), ErrGet);
  }
  err = WebPMuxSetImage(mux_single, &info.bitstream, 1);
  if (err != WEBP_MUX_OK) {
    ERROR_GOTO2("ERROR (%s): Could not create single image mux object.\n",
                ErrorString(err), ErrGet);
  }

  ok = WriteWebP(mux_single, config->output_);

 ErrGet:
  WebPDataClear(&info.bitstream);
  WebPMuxDelete(mux_single);
  return ok && !parse_error;
}

// Read and process config.
static int Process(const WebPMuxConfig* config) {
  WebPMux* mux = NULL;
  WebPData chunk;
  WebPMuxError err = WEBP_MUX_OK;
  int ok = 1;
  const Feature* const feature = &config->feature_;

  switch (config->action_type_) {
    case ACTION_GET: {
      ok = CreateMux(config->input_, &mux);
      if (!ok) goto Err2;
      switch (feature->type_) {
        case FEATURE_ANMF:
        case FEATURE_FRGM:
          ok = GetFrameFragment(mux, config,
                                (feature->type_ == FEATURE_ANMF) ? 1 : 0);
          break;

        case FEATURE_ICCP:
        case FEATURE_EXIF:
        case FEATURE_XMP:
          err = WebPMuxGetChunk(mux, kFourccList[feature->type_], &chunk);
          if (err != WEBP_MUX_OK) {
            ERROR_GOTO3("ERROR (%s): Could not get the %s.\n",
                        ErrorString(err), kDescriptions[feature->type_], Err2);
          }
          ok = WriteData(config->output_, &chunk);
          break;

        default:
          ERROR_GOTO1("ERROR: Invalid feature for action 'get'.\n", Err2);
          break;
      }
      break;
    }
    case ACTION_SET: {
      switch (feature->type_) {
        case FEATURE_ANMF: {
          int i;
          WebPMuxAnimParams params = { 0xFFFFFFFF, 0 };
          mux = WebPMuxNew();
          if (mux == NULL) {
            ERROR_GOTO2("ERROR (%s): Could not allocate a mux object.\n",
                        ErrorString(WEBP_MUX_MEMORY_ERROR), Err2);
          }
          for (i = 0; i < feature->arg_count_; ++i) {
            switch (feature->args_[i].subtype_) {
              case SUBTYPE_BGCOLOR: {
                uint32_t bgcolor;
                ok = ParseBgcolorArgs(feature->args_[i].params_, &bgcolor);
                if (!ok) {
                  ERROR_GOTO1("ERROR: Could not parse the background color \n",
                              Err2);
                }
                params.bgcolor = bgcolor;
                break;
              }
              case SUBTYPE_LOOP: {
                int parse_error = 0;
                const int loop_count =
                    ExUtilGetInt(feature->args_[i].params_, 10, &parse_error);
                if (loop_count < 0 || loop_count > 65535) {
                  // Note: This is only a 'necessary' condition for loop_count
                  // to be valid. The 'sufficient' conditioned in checked in
                  // WebPMuxSetAnimationParams() method called later.
                  ERROR_GOTO1("ERROR: Loop count must be in the range 0 to "
                              "65535.\n", Err2);
                }
                ok = !parse_error;
                if (!ok) goto Err2;
                params.loop_count = loop_count;
                break;
              }
              case SUBTYPE_ANMF: {
                WebPMuxFrameInfo frame;
                frame.id = WEBP_CHUNK_ANMF;
                ok = ReadFileToWebPData(feature->args_[i].filename_,
                                        &frame.bitstream);
                if (!ok) goto Err2;
                ok = ParseFrameArgs(feature->args_[i].params_, &frame);
                if (!ok) {
                  WebPDataClear(&frame.bitstream);
                  ERROR_GOTO1("ERROR: Could not parse frame properties.\n",
                              Err2);
                }
                err = WebPMuxPushFrame(mux, &frame, 1);
                WebPDataClear(&frame.bitstream);
                if (err != WEBP_MUX_OK) {
                  ERROR_GOTO3("ERROR (%s): Could not add a frame at index %d."
                              "\n", ErrorString(err), i, Err2);
                }
                break;
              }
              default: {
                ERROR_GOTO1("ERROR: Invalid subtype for 'frame'", Err2);
                break;
              }
            }
          }
          err = WebPMuxSetAnimationParams(mux, &params);
          if (err != WEBP_MUX_OK) {
            ERROR_GOTO2("ERROR (%s): Could not set animation parameters.\n",
                        ErrorString(err), Err2);
          }
          break;
        }

        case FEATURE_FRGM: {
          int i;
          mux = WebPMuxNew();
          if (mux == NULL) {
            ERROR_GOTO2("ERROR (%s): Could not allocate a mux object.\n",
                        ErrorString(WEBP_MUX_MEMORY_ERROR), Err2);
          }
          for (i = 0; i < feature->arg_count_; ++i) {
            WebPMuxFrameInfo frgm;
            frgm.id = WEBP_CHUNK_FRGM;
            ok = ReadFileToWebPData(feature->args_[i].filename_,
                                    &frgm.bitstream);
            if (!ok) goto Err2;
            ok = ParseFragmentArgs(feature->args_[i].params_, &frgm);
            if (!ok) {
              WebPDataClear(&frgm.bitstream);
              ERROR_GOTO1("ERROR: Could not parse fragment properties.\n",
                          Err2);
            }
            err = WebPMuxPushFrame(mux, &frgm, 1);
            WebPDataClear(&frgm.bitstream);
            if (err != WEBP_MUX_OK) {
              ERROR_GOTO3("ERROR (%s): Could not add a fragment at index %d.\n",
                          ErrorString(err), i, Err2);
            }
          }
          break;
        }

        case FEATURE_ICCP:
        case FEATURE_EXIF:
        case FEATURE_XMP: {
          ok = CreateMux(config->input_, &mux);
          if (!ok) goto Err2;
          ok = ReadFileToWebPData(feature->args_[0].filename_, &chunk);
          if (!ok) goto Err2;
          err = WebPMuxSetChunk(mux, kFourccList[feature->type_], &chunk, 1);
          free((void*)chunk.bytes);
          if (err != WEBP_MUX_OK) {
            ERROR_GOTO3("ERROR (%s): Could not set the %s.\n",
                        ErrorString(err), kDescriptions[feature->type_], Err2);
          }
          break;
        }
        default: {
          ERROR_GOTO1("ERROR: Invalid feature for action 'set'.\n", Err2);
          break;
        }
      }
      ok = WriteWebP(mux, config->output_);
      break;
    }
    case ACTION_STRIP: {
      ok = CreateMux(config->input_, &mux);
      if (!ok) goto Err2;
      if (feature->type_ == FEATURE_ICCP || feature->type_ == FEATURE_EXIF ||
          feature->type_ == FEATURE_XMP) {
        err = WebPMuxDeleteChunk(mux, kFourccList[feature->type_]);
        if (err != WEBP_MUX_OK) {
          ERROR_GOTO3("ERROR (%s): Could not strip the %s.\n",
                      ErrorString(err), kDescriptions[feature->type_], Err2);
        }
      } else {
        ERROR_GOTO1("ERROR: Invalid feature for action 'strip'.\n", Err2);
        break;
      }
      ok = WriteWebP(mux, config->output_);
      break;
    }
    case ACTION_INFO: {
      ok = CreateMux(config->input_, &mux);
      if (!ok) goto Err2;
      ok = (DisplayInfo(mux) == WEBP_MUX_OK);
      break;
    }
    default: {
      assert(0);  // Invalid action.
      break;
    }
  }

 Err2:
  WebPMuxDelete(mux);
  return ok;
}

//------------------------------------------------------------------------------
// Main.

int main(int argc, const char* argv[]) {
  WebPMuxConfig config;
  int ok = InitializeConfig(argc - 1, argv + 1, &config);
  if (ok) {
    ok = Process(&config);
  } else {
    PrintHelp();
  }
  DeleteConfig(&config);
  return !ok;
}

//------------------------------------------------------------------------------
