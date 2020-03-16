//
//  ADJActivityHandlerConstructorState.h
//  Adjust
//
//  Created by Pedro Filipe on 30/06/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADJConfig.h"

@interface ADJActivityHandlerConstructorState : NSObject

@property (nonatomic, strong) ADJConfig * config;
@property (nonatomic, copy) NSString * readActivityState;
@property (nonatomic, copy) NSString * readAttribution;
@property (nonatomic, assign) BOOL startEnabled;
@property (nonatomic, strong) NSArray * sessionParametersActionsArray;
@property (nonatomic, assign) BOOL isToUpdatePackages;

- (id)initWithConfig:(ADJConfig *)config;
@end
