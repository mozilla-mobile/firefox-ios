/*
 * Author: Landon Fuller <landonf@plausible.coop>
 *
 * Copyright (c) 2012-2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * For external library integrators:
 *
 * Set this value to any valid C symbol prefix. This will automatically
 * prepend the given prefix to all external symbols in the library.
 *
 * This may be used to avoid symbol conflicts between multiple libraries
 * that may both incorporate PLCrashReporter.
 */
// #define PLCRASHREPORTER_PREFIX AcmeCo

#ifdef PLCRASHREPORTER_PREFIX

// We need two extra layers of indirection to make CPP substitute
// the PLCRASHREPORTER_PREFIX define.
#define PLNS_impl2(prefix, symbol) prefix ## symbol
#define PLNS_impl(prefix, symbol) PLNS_impl2(prefix, symbol)
#define PLNS(symbol) PLNS_impl(PLCRASHREPORTER_PREFIX, symbol)

#define PLCrashMachExceptionServer          PLNS(PLCrashMachExceptionServer)
#define PLCrashReport                       PLNS(PLCrashReport)
#define PLCrashReportApplicationInfo        PLNS(PLCrashReportApplicationInfo)
#define PLCrashReportBinaryImageInfo        PLNS(PLCrashReportBinaryImageInfo)
#define PLCrashReportExceptionInfo          PLNS(PLCrashReportExceptionInfo)
#define PLCrashReportMachExceptionInfo      PLNS(PLCrashReportMachExceptionInfo)
#define PLCrashReportMachineInfo            PLNS(PLCrashReportMachineInfo)
#define PLCrashReportProcessInfo            PLNS(PLCrashReportProcessInfo)
#define PLCrashReportProcessorInfo          PLNS(PLCrashReportProcessorInfo)
#define PLCrashReportRegisterInfo           PLNS(PLCrashReportRegisterInfo)
#define PLCrashReportSignalInfo             PLNS(PLCrashReportSignalInfo)
#define PLCrashReportStackFrameInfo         PLNS(PLCrashReportStackFrameInfo)
#define PLCrashReportSymbolInfo             PLNS(PLCrashReportSymbolInfo)
#define PLCrashReportSystemInfo             PLNS(PLCrashReportSystemInfo)
#define PLCrashReportTextFormatter          PLNS(PLCrashReportTextFormatter)
#define PLCrashReportThreadInfo             PLNS(PLCrashReportThreadInfo)
#define PLCrashReporter                     PLNS(PLCrashReporter)
#define PLCrashSignalHandler                PLNS(PLCrashSignalHandler)
#define PLCrashReportHostArchitecture       PLNS(PLCrashReportHostArchitecture)
#define PLCrashReportHostOperatingSystem    PLNS(PLCrashReportHostOperatingSystem)
#define PLCrashReporterErrorDomain          PLNS(PLCrashReporterErrorDomain)
#define PLCrashReporterException            PLNS(PLCrashReporterException)
#define PLCrashHostInfo                     PLNS(PLCrashHostInfo)
#define PLCrashMachExceptionPort            PLNS(PLCrashMachExceptionPort)
#define PLCrashMachExceptionPortSet         PLNS(PLCrashMachExceptionPortSet)
#define PLCrashProcessInfo                  PLNS(PLCrashProcessInfo)
#define PLCrashReporterConfig               PLNS(PLCrashReporterConfig)
#define PLCrashUncaughtExceptionHandler     PLNS(PLCrashUncaughtExceptionHandler)
#define PLCrashMachExceptionForward         PLNS(PLCrashMachExceptionForward)
#define PLCrashSignalHandlerForward         PLNS(PLCrashSignalHandlerForward)
#define plcrash_signal_handler              PLNS(plcrash_signal_handler)

#endif
