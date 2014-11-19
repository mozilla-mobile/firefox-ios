// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#import <Foundation/Foundation.h>

@interface NSData (KeyDerivation)

- (NSData*) deriveHKDFSHA256KeyWithSalt: (NSData*) salt contextInfo: (NSData*) contextInfo length: (NSUInteger) length;
- (NSData*) derivePBKDF2HMACSHA256KeyWithSalt: (NSData*) salt iterations: (NSUInteger) iterations length: (NSUInteger) length;
- (NSData*) deriveSCryptKeyWithSalt: (NSData*) salt n: (uint32_t) n r: (uint32_t) r p: (uint32_t) p length: (NSUInteger) length;

@end
