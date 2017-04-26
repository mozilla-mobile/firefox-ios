//
//  KSCrashReportFilterGZip.h
//
//  Created by Karl Stenerud on 2012-05-10.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
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


#import "KSCrashReportFilter.h"


/** Gzip compresses reports.
 *
 * Input: NSData
 * Output: NSData
 */
@interface KSCrashReportFilterGZipCompress : NSObject <KSCrashReportFilter>

/** Constructor.
 *
 * @param compressionLevel 0 = none, 9 = best, -1 = default
 */
+ (KSCrashReportFilterGZipCompress*) filterWithCompressionLevel:(int) compressionLevel;

- (id) initWithCompressionLevel:(int) compressionLevel;

@end

/** Gzip decompresses reports.
 *
 * Input: NSData
 * Output: NSData
 */
@interface KSCrashReportFilterGZipDecompress : NSObject <KSCrashReportFilter>

+ (KSCrashReportFilterGZipDecompress*) filter;

@end
