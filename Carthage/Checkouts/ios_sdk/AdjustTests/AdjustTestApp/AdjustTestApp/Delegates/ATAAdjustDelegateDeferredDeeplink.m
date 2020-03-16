//
//  ATAAdjustDelegateDeferredDeeplink.m
//  AdjustTestApp
//
//  Created by Uglješa Erceg on 20.07.18.
//  Copyright © 2018 adjust. All rights reserved.
//

#import "ATAAdjustDelegateDeferredDeeplink.h"

@interface ATAAdjustDelegateDeferredDeeplink ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *basePath;
@property (nonatomic, assign) BOOL returnValue;

@end

@implementation ATAAdjustDelegateDeferredDeeplink

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary basePath:(NSString *)basePath andReturnValue:(BOOL)returnValue {
    self = [super init];

    if (nil == self) {
        return nil;
    }

    self.testLibrary = testLibrary;
    self.basePath = basePath;
    self.returnValue = returnValue;

    return self;
}

- (BOOL)adjustDeeplinkResponse:(nullable NSURL *)deeplink {
    NSLog(@"Deferred deep link callback called!");
    NSLog(@"Deep link: %@", deeplink);

    [self.testLibrary addInfoToSend:@"deeplink" value:[deeplink absoluteString]];
    [self.testLibrary sendInfoToServer:self.basePath];

    return self.returnValue;
}

@end
