#import "SwrveFileManagement.h"

@implementation SwrveFileManagement

#pragma mark - Application data management

+ (NSString *) applicationSupportPath {
    
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DebugLog(@"Error Creating an Application Support Directory %@", error.localizedDescription);
        } else {
            DebugLog(@"Successfully Created Directory: %@", appSupportDir);
        }
    }
    return appSupportDir;
}

@end
