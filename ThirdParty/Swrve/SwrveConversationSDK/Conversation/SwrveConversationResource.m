#import "SwrveConversationResource.h"
#import <Foundation/Foundation.h>

@implementation SwrveConversationResource

+(UIImage *) imageFromBundleNamed:(NSString *)imageName {
    // Keep old location behaviour - the VGConversationKit bundle,
    // add new behaviour - the ConverserResources folder,
    // and add a fallback of just the main bundle.
    //
    NSString *resources = [[NSBundle bundleForClass:self] resourcePath];
    
    NSArray *searchPaths = [NSArray arrayWithObjects:
                            [resources stringByAppendingPathComponent:@"VGConversationKit.bundle"],
                            [resources stringByAppendingPathComponent:@"ConverserResources"],
                            resources,
                            nil];
    
    NSString *shortName, *extension = [imageName pathExtension];
    
    if(extension && extension.length != 0) {
        shortName = [imageName stringByDeletingPathExtension];
    } else {
        shortName = imageName;
    }
    
    // Go through the search paths, looking for cvsr_ prefixed names to
    // prevent clashes with customer resources
    UIImage *img = [self searchPaths:searchPaths forImageNamed:shortName withPrefix:@"cvsr_"];
    if (img == nil) {
        // If no cvsr_ prefixed names, just go for no prefix, could be an
        // older set of resources
        img = [self searchPaths:searchPaths forImageNamed:shortName withPrefix:@""];
    }
    return img;
}

+(UIImage*) searchPaths:(NSArray*)paths forImageNamed:(NSString*)name withPrefix:(NSString*)prefix {
    NSString *fullname;
    
    if([UIScreen mainScreen].scale >= 2.0) {
        fullname = [[NSString stringWithFormat:@"%@%@%@", prefix, name, @"@2x"] stringByAppendingPathExtension:@"png"];
    } else {
        fullname = [[NSString stringWithFormat:@"%@%@", prefix, name] stringByAppendingPathExtension:@"png"];
    }
    
    UIImage * img = nil;
    for (NSUInteger i=0; !img && (i < paths.count); i++) {
        NSString *f = [[paths objectAtIndex:i] stringByAppendingPathComponent:fullname];
        img = [UIImage imageWithContentsOfFile:f];
    }
    
    return img;
}

@end
