//
//  FixtureHelpers.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "FixtureHelpers.h"

@implementation FixtureHelpers

+ (id) dataFromPListFixtureNamed:(NSString *)fixtureName
{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *resource = [testBundle pathForResource:fixtureName ofType:@"plist"];
    NSData *plistData = [NSData dataWithContentsOfFile:resource];
    
    return [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
}

+ (id) dataFromJSONFixtureNamed:(NSString *)fixtureName
{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *resource = [testBundle pathForResource:fixtureName ofType:@"json"];
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:resource];
    [inputStream open];
    
    return [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:nil];
}

@end

@implementation XCTest (FixtureHelpers)

- (id) dataFromJSONFixture;
{
    NSString *className = NSStringFromClass([self class]);
    className = [className stringByReplacingOccurrencesOfString:@"Import" withString:@""];
    className = [className stringByReplacingOccurrencesOfString:@"Spec" withString:@""];
    className = [className stringByReplacingOccurrencesOfString:@"Tests" withString:@""];
    return [FixtureHelpers dataFromJSONFixtureNamed:className];
}

@end
