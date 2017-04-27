//
//  KSLogger.h
//
//  Created by Karl Stenerud on 11-06-25.
//
//  Copyright (c) 2011 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


/**
 * KSLogger
 * ========
 *
 * Prints log entries to the console consisting of:
 * - Level (Error, Warn, Info, Debug, Trace)
 * - File
 * - Line
 * - Function
 * - Message
 *
 * Allows setting the minimum logging level in the preprocessor.
 *
 * Works in C or Objective-C contexts, with or without ARC, using CLANG or GCC.
 *
 *
 * =====
 * USAGE
 * =====
 *
 * Set the log level in your "Preprocessor Macros" build setting. You may choose
 * TRACE, DEBUG, INFO, WARN, ERROR. If nothing is set, it defaults to INFO.
 *
 * Example: KSLogger_Level=WARN
 *
 * Anything below the level specified for KSLogger_Level will not be compiled
 * or printed.
 * 
 *
 * Next, include the header file:
 *
 * #include "KSLogger.h"
 *
 *
 * Next, call the logger functions from your code (using objective-c strings
 * in objective-C files and regular strings in regular C files):
 *
 * Code:
 *    KSLOG_ERROR(@"Some error message");
 *
 * Prints:
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21): -[SomeFunction]: Some error message 
 *
 * Code:
 *    KSLOG_INFO(@"Info about %@", someObject);
 *
 * Prints:
 *    2011-07-16 05:44:05.239 TestApp[4473:f803] INFO : SomeClass.m (20): -[SomeFunction]: Info about <NSObject: 0xb622840>
 *
 *
 * The "BASIC" versions of the macros behave exactly like NSLog() or printf(),
 * except they respect the KSLogger_Level setting:
 *
 * Code:
 *    KSLOGBASIC_ERROR(@"A basic log entry");
 *
 * Prints:
 *    2011-07-16 05:44:05.916 TestApp[4473:f803] A basic log entry
 *
 *
 * NOTE: In C files, use "" instead of @"" in the format field. Logging calls
 *       in C files do not print the NSLog preamble:
 *
 * Objective-C version:
 *    KSLOG_ERROR(@"Some error message");
 *
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21): -[SomeFunction]: Some error message
 *
 * C version:
 *    KSLOG_ERROR("Some error message");
 *
 *    ERROR: SomeClass.c (21): SomeFunction(): Some error message
 *
 *
 * =============
 * LOCAL LOGGING
 * =============
 *
 * You can control logging messages at the local file level using the
 * "KSLogger_LocalLevel" define. Note that it must be defined BEFORE
 * including KSLogger.h
 *
 * The KSLOG_XX() and KSLOGBASIC_XX() macros will print out based on the LOWER
 * of KSLogger_Level and KSLogger_LocalLevel, so if KSLogger_Level is DEBUG
 * and KSLogger_LocalLevel is TRACE, it will print all the way down to the trace
 * level for the local file where KSLogger_LocalLevel was defined, and to the
 * debug level everywhere else.
 *
 * Example:
 *
 * // KSLogger_LocalLevel, if defined, MUST come BEFORE including KSLogger.h
 * #define KSLogger_LocalLevel TRACE
 * #import "KSLogger.h"
 *
 *
 * ===============
 * IMPORTANT NOTES
 * ===============
 *
 * The C logger changes its behavior depending on the value of the preprocessor
 * define KSLogger_CBufferSize.
 *
 * If KSLogger_CBufferSize is > 0, the C logger will behave in an async-safe
 * manner, calling write() instead of printf(). Any log messages that exceed the
 * length specified by KSLogger_CBufferSize will be truncated.
 *
 * If KSLogger_CBufferSize == 0, the C logger will use printf(), and there will
 * be no limit on the log message length.
 *
 * KSLogger_CBufferSize can only be set as a preprocessor define, and will
 * default to 1024 if not specified during compilation.
 */


// ============================================================================
#pragma mark - (internal) -
// ============================================================================


#ifndef HDR_KSLogger_h
#define HDR_KSLogger_h

#ifdef __cplusplus
extern "C" {
#endif


#include <stdbool.h>


#ifdef __OBJC__

#import <CoreFoundation/CoreFoundation.h>

void i_kslog_logObjC(const char* level,
                     const char* file,
                     int line,
                     const char* function,
                     CFStringRef fmt, ...);

void i_kslog_logObjCBasic(CFStringRef fmt, ...);

#define i_KSLOG_FULL(LEVEL,FILE,LINE,FUNCTION,FMT,...) i_kslog_logObjC(LEVEL,FILE,LINE,FUNCTION,(__bridge CFStringRef)FMT,##__VA_ARGS__)
#define i_KSLOG_BASIC(FMT, ...) i_kslog_logObjCBasic((__bridge CFStringRef)FMT,##__VA_ARGS__)

#else // __OBJC__

void i_kslog_logC(const char* level,
                  const char* file,
                  int line,
                  const char* function,
                  const char* fmt, ...);

void i_kslog_logCBasic(const char* fmt, ...);

#define i_KSLOG_FULL i_kslog_logC
#define i_KSLOG_BASIC i_kslog_logCBasic

#endif // __OBJC__


/* Back up any existing defines by the same name */
#ifdef NONE
    #define KSLOG_BAK_NONE NONE
    #undef NONE
#endif
#ifdef ERROR
    #define KSLOG_BAK_ERROR ERROR
    #undef ERROR
#endif
#ifdef WARN
    #define KSLOG_BAK_WARN WARN
    #undef WARN
#endif
#ifdef INFO
    #define KSLOG_BAK_INFO INFO
    #undef INFO
#endif
#ifdef DEBUG
    #define KSLOG_BAK_DEBUG DEBUG
    #undef DEBUG
#endif
#ifdef TRACE
    #define KSLOG_BAK_TRACE TRACE
    #undef TRACE
#endif


#define KSLogger_Level_None   0
#define KSLogger_Level_Error 10
#define KSLogger_Level_Warn  20
#define KSLogger_Level_Info  30
#define KSLogger_Level_Debug 40
#define KSLogger_Level_Trace 50

#define NONE  KSLogger_Level_None
#define ERROR KSLogger_Level_Error
#define WARN  KSLogger_Level_Warn
#define INFO  KSLogger_Level_Info
#define DEBUG KSLogger_Level_Debug
#define TRACE KSLogger_Level_Trace


#ifndef KSLogger_Level
    #define KSLogger_Level KSLogger_Level_Info
#endif

#ifndef KSLogger_LocalLevel
    #define KSLogger_LocalLevel KSLogger_Level_None
#endif

#define a_KSLOG_FULL(LEVEL, FMT, ...) \
    i_KSLOG_FULL(LEVEL, \
                 __FILE__, \
                 __LINE__, \
                 __PRETTY_FUNCTION__, \
                 FMT, \
                 ##__VA_ARGS__)



// ============================================================================
#pragma mark - API -
// ============================================================================

/** Set the filename to log to.
 *
 * @param filename The file to write to (NULL = write to stdout).
 *
 * @param overwrite If true, overwrite the log file.
 */
bool kslog_setLogFilename(const char* filename, bool overwrite);

/** Clear the log file. */
bool kslog_clearLogFile();

/** Tests if the logger would print at the specified level.
 *
 * @param LEVEL The level to test for. One of:
 *            KSLogger_Level_Error,
 *            KSLogger_Level_Warn,
 *            KSLogger_Level_Info,
 *            KSLogger_Level_Debug,
 *            KSLogger_Level_Trace,
 *
 * @return TRUE if the logger would print at the specified level.
 */
#define KSLOG_PRINTS_AT_LEVEL(LEVEL) \
    (KSLogger_Level >= LEVEL || KSLogger_LocalLevel >= LEVEL)

/** Log a message regardless of the log settings.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#define KSLOG_ALWAYS(FMT, ...) a_KSLOG_FULL("FORCE", FMT, ##__VA_ARGS__)
#define KSLOGBASIC_ALWAYS(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)


/** Log an error.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if KSLOG_PRINTS_AT_LEVEL(KSLogger_Level_Error)
    #define KSLOG_ERROR(FMT, ...) a_KSLOG_FULL("ERROR", FMT, ##__VA_ARGS__)
    #define KSLOGBASIC_ERROR(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define KSLOG_ERROR(FMT, ...)
    #define KSLOGBASIC_ERROR(FMT, ...)
#endif

/** Log a warning.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if KSLOG_PRINTS_AT_LEVEL(KSLogger_Level_Warn)
    #define KSLOG_WARN(FMT, ...)  a_KSLOG_FULL("WARN ", FMT, ##__VA_ARGS__)
    #define KSLOGBASIC_WARN(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define KSLOG_WARN(FMT, ...)
    #define KSLOGBASIC_WARN(FMT, ...)
#endif

/** Log an info message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if KSLOG_PRINTS_AT_LEVEL(KSLogger_Level_Info)
    #define KSLOG_INFO(FMT, ...)  a_KSLOG_FULL("INFO ", FMT, ##__VA_ARGS__)
    #define KSLOGBASIC_INFO(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define KSLOG_INFO(FMT, ...)
    #define KSLOGBASIC_INFO(FMT, ...)
#endif

/** Log a debug message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if KSLOG_PRINTS_AT_LEVEL(KSLogger_Level_Debug)
    #define KSLOG_DEBUG(FMT, ...) a_KSLOG_FULL("DEBUG", FMT, ##__VA_ARGS__)
    #define KSLOGBASIC_DEBUG(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define KSLOG_DEBUG(FMT, ...)
    #define KSLOGBASIC_DEBUG(FMT, ...)
#endif

/** Log a trace message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if KSLOG_PRINTS_AT_LEVEL(KSLogger_Level_Trace)
    #define KSLOG_TRACE(FMT, ...) a_KSLOG_FULL("TRACE", FMT, ##__VA_ARGS__)
    #define KSLOGBASIC_TRACE(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define KSLOG_TRACE(FMT, ...)
    #define KSLOGBASIC_TRACE(FMT, ...)
#endif



// ============================================================================
#pragma mark - (internal) -
// ============================================================================

/* Put everything back to the way we found it. */
#undef ERROR
#ifdef KSLOG_BAK_ERROR
    #define ERROR KSLOG_BAK_ERROR
    #undef KSLOG_BAK_ERROR
#endif
#undef WARNING
#ifdef KSLOG_BAK_WARN
    #define WARNING KSLOG_BAK_WARN
    #undef KSLOG_BAK_WARN
#endif
#undef INFO
#ifdef KSLOG_BAK_INFO
    #define INFO KSLOG_BAK_INFO
    #undef KSLOG_BAK_INFO
#endif
#undef DEBUG
#ifdef KSLOG_BAK_DEBUG
    #define DEBUG KSLOG_BAK_DEBUG
    #undef KSLOG_BAK_DEBUG
#endif
#undef TRACE
#ifdef KSLOG_BAK_TRACE
    #define TRACE KSLOG_BAK_TRACE
    #undef KSLOG_BAK_TRACE
#endif


#ifdef __cplusplus
}
#endif

#endif // HDR_KSLogger_h
