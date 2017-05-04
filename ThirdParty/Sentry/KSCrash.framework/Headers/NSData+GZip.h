//
//  NSData+GZip.h
//
//  Created by Karl Stenerud on 2012-02-19.
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


#import <Foundation/Foundation.h>


/**
 * GNU zip/unzip support for NSData.
 */
@interface NSData (GZip)

/**
 * Gzip the data in this object (no header).
 *
 * @param compressionLevel The GZip compression level to use:
 *                         0 = no compression.
 *                         1 = best speed.
 *                         9 = best compression.
 *                        -1 = default.
 *
 * @param error (optional) Set to any error that occurs, or nil if no error.
 *              Pass nil to ignore.
 *
 * @return A new NSData with the gzipped contents of this object.
 */
- (NSData*) gzippedWithCompressionLevel:(int) compressionLevel
                                  error:(NSError**) error;

/**
 * Gunzip the data in this object (no header).
 *
 * @param error (optional) Set to any error that occurs, or nil if no error.
 *              Pass nil to ignore.
 *
 * @return A new NSData with the gunzipped contents of this object.
 */
- (NSData*) gunzippedWithError:(NSError**) error;

@end
