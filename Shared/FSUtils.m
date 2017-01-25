/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "FSUtils.h"

#import <sys/types.h>
#import <fcntl.h>
#import <errno.h>
#import <sys/param.h>

@implementation FSUtils

+ (NSDictionary<NSNumber *, NSString *> * _Nonnull)openFileDescriptors
{
    int flags;
    int fd;
    char buf[MAXPATHLEN+1] ;
    int n = 1 ;
    NSMutableDictionary *dict = [@{} mutableCopy];

    for (fd = 0; fd < (int) FD_SETSIZE; fd++) {
        errno = 0;
        flags = fcntl(fd, F_GETFD, 0);
        if (flags == -1 && errno) {
            if (errno != EBADF) {
                return @{};
            } else {
                continue;
            }
        }
        fcntl(fd , F_GETPATH, buf ) ;

        dict[@(fd)] = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
        ++n ;
    }

    return dict;
}

@end

