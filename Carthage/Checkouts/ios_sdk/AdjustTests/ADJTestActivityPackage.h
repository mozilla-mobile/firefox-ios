//
//  ADJTestActivityPackage.h
//  adjust
//
//  Created by Pedro Filipe on 15/05/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJTest.h"
#import "ADJActivityPackage.h"
#import "ADJPackageFields.h"

@interface ADJTestActivityPackage : ADJTest

- (void)testPackageSession:(ADJActivityPackage *)package
                    fields:(ADJPackageFields *)fields
              sessionCount:(NSString*)sessionCount;

- (void)testEventSession:(ADJActivityPackage *)package
                  fields:(ADJPackageFields *)fields
              eventToken:(NSString*)eventToken;

- (void)testClickPackage:(ADJActivityPackage *)package
                  fields:(ADJPackageFields *)fields
                  source:(NSString*)source;

- (void)testAttributionPackage:(ADJActivityPackage *)package
                        fields:(ADJPackageFields *)fields;

@end
