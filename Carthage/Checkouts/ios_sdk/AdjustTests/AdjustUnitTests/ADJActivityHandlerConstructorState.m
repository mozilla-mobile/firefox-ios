//
//  ADJActivityHandlerConstructorState.m
//  Adjust
//
//  Created by Pedro Filipe on 30/06/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJActivityHandlerConstructorState.h"

@implementation ADJActivityHandlerConstructorState

- (id)initWithConfig:(ADJConfig *)config {
    self = [super init];
    if (self == nil) return nil;

    self.config = config;

    // default values
    self.readActivityState = nil;
    self.readAttribution = nil;
    self.startEnabled = YES;
    self.isToUpdatePackages = NO;\

    return self;
}
@end
