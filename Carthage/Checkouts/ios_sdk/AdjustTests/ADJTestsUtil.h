//
//  ADJTestsUtil.h
//  Adjust
//
//  Created by Pedro Filipe on 12/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJLoggerMock.h"
#import "ADJActivityPackage.h"
#import "Adjust.h"

@interface ADJTestsUtil : NSObject <AdjustDelegate>

- (id)initWithLoggerMock:(ADJLoggerMock *)loggerMock;

+ (NSString *)getFilename:(NSString *)filename;
+ (BOOL)deleteFile:(NSString *)filename logger:(ADJLoggerMock *)loggerMock;
+ (ADJActivityPackage *)getUnknowPackage:(NSString*)suffix;
+ (ADJActivityPackage *)getClickPackage:(NSString*)suffix;

@end
