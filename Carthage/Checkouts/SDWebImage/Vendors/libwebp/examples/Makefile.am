AM_CPPFLAGS = -I$(top_builddir)/src -I$(top_srcdir)/src

bin_PROGRAMS = dwebp cwebp
if BUILD_VWEBP
  bin_PROGRAMS += vwebp
endif
if WANT_MUX
  bin_PROGRAMS += webpmux
endif

if BUILD_GIF2WEBP
  bin_PROGRAMS += gif2webp
endif

noinst_LTLIBRARIES = libexampleutil.la

libexampleutil_la_SOURCES = example_util.c example_util.h stopwatch.h

dwebp_SOURCES = dwebp.c stopwatch.h
dwebp_CPPFLAGS  = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
dwebp_CPPFLAGS += $(JPEG_INCLUDES) $(PNG_INCLUDES)
dwebp_LDADD = libexampleutil.la $(PNG_LIBS) $(JPEG_LIBS)

cwebp_SOURCES  = cwebp.c metadata.c metadata.h stopwatch.h
cwebp_SOURCES += jpegdec.c jpegdec.h
cwebp_SOURCES += pngdec.c pngdec.h
cwebp_SOURCES += tiffdec.c tiffdec.h
cwebp_SOURCES += webpdec.c webpdec.h
cwebp_SOURCES += wicdec.c wicdec.h
cwebp_CPPFLAGS  = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
cwebp_CPPFLAGS += $(JPEG_INCLUDES) $(PNG_INCLUDES) $(TIFF_INCLUDES)
cwebp_LDADD  = libexampleutil.la ../src/libwebp.la
cwebp_LDADD += $(JPEG_LIBS) $(PNG_LIBS) $(TIFF_LIBS)

gif2webp_SOURCES = gif2webp.c gif2webp_util.c
gif2webp_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE) $(GIF_INCLUDES)
gif2webp_LDADD  = libexampleutil.la ../src/mux/libwebpmux.la ../src/libwebp.la
gif2webp_LDADD += $(GIF_LIBS)

webpmux_SOURCES = webpmux.c
webpmux_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
webpmux_LDADD = libexampleutil.la ../src/mux/libwebpmux.la ../src/libwebp.la

vwebp_SOURCES = vwebp.c
vwebp_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE) $(GL_INCLUDES)
vwebp_LDADD = libexampleutil.la ../src/demux/libwebpdemux.la $(GL_LIBS)

if BUILD_LIBWEBPDECODER
  dwebp_LDADD += ../src/libwebpdecoder.la
  vwebp_LDADD += ../src/libwebpdecoder.la
else
  dwebp_LDADD += ../src/libwebp.la
  vwebp_LDADD += ../src/libwebp.la
endif
