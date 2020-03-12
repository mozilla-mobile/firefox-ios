//
//  TestRobot.h
//  Calculator
//
//  Created by Justin Martin on 9/18/17.
//  Copyright © 2017 SSK Development. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TestRobot : NSObject <KIFTestActorDelegate>

- (instancetype)initWithTestCase:(KIFTestCase *)testCase;

#pragma mark - Unavailable

+ (instancetype)new  NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end
