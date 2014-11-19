// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


@interface PrivateKey : NSObject

- (id) initWithJSONRepresentation: (NSDictionary*) object;

- (NSDictionary*) JSONRepresentation;

- (NSString*) algorithm;

- (NSData*) signMessageString: (NSString*) string encoding: (NSStringEncoding) encoding;
- (NSData*) signMessage: (NSData*) data;

@end
