/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Foundation;

@interface FSUtils : NSObject

/**
 *  Grabs all open file descriptions and returns them in a key-value dictionary where
 *  the key is the descriptor # and the value being the filename.
 *
 *  @return Dictionary of open file descriptors.
 */
+ (NSDictionary<NSNumber *, NSString *> * _Nonnull)openFileDescriptors;

@end
