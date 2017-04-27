//
//  KSHTTPRequestSender.h
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
 * Sends HTTP requests via the global dispatch queue, informing the caller of
 * success, failure, or errors via blocks.
 */
@interface KSHTTPRequestSender : NSObject

/** Constructor.
 */
+ (KSHTTPRequestSender*) sender;

/** Send an HTTP request.
 * The request gets sent via the global dispatch queue using default priority.
 * Result blocks will be invoked on the main thread.
 *
 * @param request The request to send.
 *
 * @param successBlock Gets executed when the request completes successfully.
 *
 * @param failureBlock Gets executed if the request fails or receives an HTTP
 *                     response indicating failure.
 *
 * @param errorBlock Gets executed if an error prevents the request from being
 *                   sent or an invalid (non-HTTP) response is received.
 */
- (void) sendRequest:(NSURLRequest*) request
           onSuccess:(void(^)(NSHTTPURLResponse* response, NSData* data)) successBlock
           onFailure:(void(^)(NSHTTPURLResponse* response, NSData* data)) failureBlock
             onError:(void(^)(NSError* error)) errorBlock;

@end
