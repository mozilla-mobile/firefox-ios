//
//  ADJRequestHandler.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-04.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "ADJRequestHandler.h"
#import "ADJPackageHandler.h"

@protocol ADJRequestHandler

- (id)initWithPackageHandler:(id<ADJPackageHandler>) packageHandler;

- (void)sendPackage:(ADJActivityPackage *)activityPackage;

@end


@interface ADJRequestHandler : NSObject <ADJRequestHandler>

+ (id<ADJRequestHandler>) handlerWithPackageHandler:(id<ADJPackageHandler>)packageHandler;

@end
