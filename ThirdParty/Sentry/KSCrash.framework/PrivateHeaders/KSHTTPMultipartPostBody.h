//
//  KSHTTPMultipartPostBody.h
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
 * Builds a multipart MIME HTTP body.
 */
@interface KSHTTPMultipartPostBody: NSObject

/** The content-type identifier for this body. */
@property(nonatomic,readonly,retain) NSString* contentType;

/** Constructor.
 *
 * @return A new body.
 */
+ (KSHTTPMultipartPostBody*) body;

/** This body's data, encoded for sending in an HTTP request. */
- (NSData*) data;

/** Append a new data field to the body.
 *
 * @param data The data to append.
 *
 * @param name The field name.
 *
 * @param contentType The field's content-type (nil = omit).
 *
 * @param filename The field's filename (nil = omit).
 */
- (void) appendData:(NSData*) data
               name:(NSString*) name
        contentType:(NSString*) contentType
           filename:(NSString*) filename;

/** Append a new UTF-8 encoded string field to the body.
 *
 * @param string The string to append.
 *
 * @param name The field name.
 *
 * @param contentType The field's content-type (nil = omit).
 *
 * @param filename The field's filename (nil = omit).
 */
- (void) appendUTF8String:(NSString*) string
                     name:(NSString*) name
              contentType:(NSString*) contentType
                 filename:(NSString*) filename;

@end
