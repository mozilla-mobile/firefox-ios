//
//  ADJPackageFields.m
//  adjust
//
//  Created by Pedro Filipe on 15/05/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "ADJPackageFields.h"

@implementation ADJPackageFields

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    // default values
    self.appToken = @"123456789012";
    self.clientSdk = @"ios4.5.0";
    self.suffix = @"";
    self.environment = @"sandbox";

    return self;
}

+ (ADJPackageFields *)fields {
    return [[ADJPackageFields alloc] init];
}

/*
- (id)initWithPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    self.activityPackage = activityPackage;

    return self;

}

+ (ADJPackageFields *)fieldsWithPackage:(ADJActivityPackage *)activityPackage {
    return [[ADJPackageFields alloc] initWithPackage:activityPackage];
}
*/
@end
