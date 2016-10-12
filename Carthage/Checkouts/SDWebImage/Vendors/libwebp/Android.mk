LOCAL_PATH := $(call my-dir)

WEBP_CFLAGS := -Wall -DANDROID -DHAVE_MALLOC_H -DHAVE_PTHREAD -DWEBP_USE_THREAD

ifeq ($(APP_OPTIM),release)
  WEBP_CFLAGS += -finline-functions -ffast-math \
                 -ffunction-sections -fdata-sections
  ifeq ($(findstring clang,$(NDK_TOOLCHAIN_VERSION)),)
    WEBP_CFLAGS += -frename-registers -s
  endif
endif

ifneq ($(findstring armeabi-v7a, $(TARGET_ARCH_ABI)),)
  # Setting LOCAL_ARM_NEON will enable -mfpu=neon which may cause illegal
  # instructions to be generated for armv7a code. Instead target the neon code
  # specifically.
  NEON := c.neon
else
  NEON := c
endif

dec_srcs := \
    src/dec/alpha.c \
    src/dec/buffer.c \
    src/dec/frame.c \
    src/dec/idec.c \
    src/dec/io.c \
    src/dec/quant.c \
    src/dec/tree.c \
    src/dec/vp8.c \
    src/dec/vp8l.c \
    src/dec/webp.c \

demux_srcs := \
    src/demux/demux.c \

dsp_dec_srcs := \
    src/dsp/alpha_processing.c \
    src/dsp/alpha_processing_sse2.c \
    src/dsp/cpu.c \
    src/dsp/dec.c \
    src/dsp/dec_clip_tables.c \
    src/dsp/dec_mips32.c \
    src/dsp/dec_neon.$(NEON) \
    src/dsp/dec_sse2.c \
    src/dsp/lossless.c \
    src/dsp/lossless_mips32.c \
    src/dsp/lossless_neon.$(NEON) \
    src/dsp/lossless_sse2.c \
    src/dsp/upsampling.c \
    src/dsp/upsampling_neon.$(NEON) \
    src/dsp/upsampling_sse2.c \
    src/dsp/yuv.c \
    src/dsp/yuv_mips32.c \
    src/dsp/yuv_sse2.c \

dsp_enc_srcs := \
    src/dsp/enc.c \
    src/dsp/enc_avx2.c \
    src/dsp/enc_mips32.c \
    src/dsp/enc_neon.$(NEON) \
    src/dsp/enc_sse2.c \

enc_srcs := \
    src/enc/alpha.c \
    src/enc/analysis.c \
    src/enc/backward_references.c \
    src/enc/config.c \
    src/enc/cost.c \
    src/enc/filter.c \
    src/enc/frame.c \
    src/enc/histogram.c \
    src/enc/iterator.c \
    src/enc/picture.c \
    src/enc/picture_csp.c \
    src/enc/picture_psnr.c \
    src/enc/picture_rescale.c \
    src/enc/picture_tools.c \
    src/enc/quant.c \
    src/enc/syntax.c \
    src/enc/token.c \
    src/enc/tree.c \
    src/enc/vp8l.c \
    src/enc/webpenc.c \

mux_srcs := \
    src/mux/muxedit.c \
    src/mux/muxinternal.c \
    src/mux/muxread.c \

utils_dec_srcs := \
    src/utils/bit_reader.c \
    src/utils/color_cache.c \
    src/utils/filters.c \
    src/utils/huffman.c \
    src/utils/quant_levels_dec.c \
    src/utils/random.c \
    src/utils/rescaler.c \
    src/utils/thread.c \
    src/utils/utils.c \

utils_enc_srcs := \
    src/utils/bit_writer.c \
    src/utils/huffman_encode.c \
    src/utils/quant_levels.c \

################################################################################
# libwebpdecoder

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    $(dec_srcs) \
    $(dsp_dec_srcs) \
    $(utils_dec_srcs) \

LOCAL_CFLAGS := $(WEBP_CFLAGS)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/src

# prefer arm over thumb mode for performance gains
LOCAL_ARM_MODE := arm

LOCAL_STATIC_LIBRARIES := cpufeatures

LOCAL_MODULE := webpdecoder_static

include $(BUILD_STATIC_LIBRARY)

ifeq ($(ENABLE_SHARED),1)
include $(CLEAR_VARS)

LOCAL_WHOLE_STATIC_LIBRARIES := webpdecoder_static

LOCAL_MODULE := webpdecoder

include $(BUILD_SHARED_LIBRARY)
endif  # ENABLE_SHARED=1

################################################################################
# libwebp

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    $(dsp_enc_srcs) \
    $(enc_srcs) \
    $(utils_enc_srcs) \

LOCAL_CFLAGS := $(WEBP_CFLAGS)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/src

# prefer arm over thumb mode for performance gains
LOCAL_ARM_MODE := arm

LOCAL_WHOLE_STATIC_LIBRARIES := webpdecoder_static

LOCAL_MODULE := webp

ifeq ($(ENABLE_SHARED),1)
  include $(BUILD_SHARED_LIBRARY)
else
  include $(BUILD_STATIC_LIBRARY)
endif

################################################################################
# libwebpdemux

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(demux_srcs)

LOCAL_CFLAGS := $(WEBP_CFLAGS)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/src

# prefer arm over thumb mode for performance gains
LOCAL_ARM_MODE := arm

LOCAL_MODULE := webpdemux

ifeq ($(ENABLE_SHARED),1)
  LOCAL_SHARED_LIBRARIES := webp
  include $(BUILD_SHARED_LIBRARY)
else
  LOCAL_STATIC_LIBRARIES := webp
  include $(BUILD_STATIC_LIBRARY)
endif

################################################################################
# libwebpmux

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(mux_srcs)

LOCAL_CFLAGS := $(WEBP_CFLAGS)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/src

# prefer arm over thumb mode for performance gains
LOCAL_ARM_MODE := arm

LOCAL_MODULE := webpmux

ifeq ($(ENABLE_SHARED),1)
  LOCAL_SHARED_LIBRARIES := webp
  include $(BUILD_SHARED_LIBRARY)
else
  LOCAL_STATIC_LIBRARIES := webp
  include $(BUILD_STATIC_LIBRARY)
endif

################################################################################

include $(LOCAL_PATH)/examples/Android.mk

$(call import-module,android/cpufeatures)
