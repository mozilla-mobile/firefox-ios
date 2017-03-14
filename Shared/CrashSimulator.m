/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "CrashSimulator.h"

@implementation CrashSimulator

+ (void)forceCrash
{
    @throw [[NSException alloc] initWithName:@"Simulated Crash" reason:@"This is a simulated crash." userInfo:nil];
}

@end
