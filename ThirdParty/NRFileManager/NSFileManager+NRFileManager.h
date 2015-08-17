/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Created and contributed by Nikolai Ruhe
 * https://github.com/NikolaiRuhe/NRFoundation */

#import <Foundation/Foundation.h>


@interface NSFileManager (NRFileManager)

- (BOOL)nr_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error;

- (BOOL)moz_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)url forFilesPrefixedWith:(NSString *)prefix error:(NSError * __autoreleasing *)error;

@end

