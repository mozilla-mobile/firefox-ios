//
//  SentrySwizzleTests.m
//  Sentry
//
//  Created by Daniel Griesser on 06/06/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentrySwizzle.h"

#pragma mark - HELPER CLASSES -

@interface SentryTestsLog : NSObject
+ (void)log:(NSString *)string;

+ (void)clear;

+ (BOOL)is:(NSString *)compareString;

+ (NSString *)logString;
@end

@implementation SentryTestsLog

static NSMutableString *_logString = nil;

+ (void)log:(NSString *)string {
    if (!_logString) {
        _logString = [NSMutableString new];
    }
    [_logString appendString:string];
    NSLog(@"%@", string);
}

+ (void)clear {
    _logString = [NSMutableString new];
}

+ (BOOL)is:(NSString *)compareString {
    return [compareString isEqualToString:_logString];
}

+ (NSString *)logString {
    return _logString;
}

@end

#define ASSERT_LOG_IS(STRING) XCTAssertTrue([SentryTestsLog is:STRING], @"LOG IS @\"%@\" INSTEAD",[SentryTestsLog logString])
#define CLEAR_LOG() ([SentryTestsLog clear])
#define SentryTestsLog(STRING) [SentryTestsLog log:STRING]

@interface SentrySwizzleTestClass_A : NSObject
@end

@implementation SentrySwizzleTestClass_A
- (int)calc:(int)num {
    return num;
}

- (BOOL)methodReturningBOOL {
    return YES;
};
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (void)methodWithArgument:(id)arg {
};
#pragma GCC diagnostic pop
- (void)methodForAlwaysSwizzling {
};

- (void)methodForSwizzlingOncePerClass {
};

- (void)methodForSwizzlingOncePerClassOrSuperClasses {
};

- (NSString *)string {
    return @"ABC";
}

+ (NSNumber *)sumFloat:(float)floatSummand withDouble:(double)doubleSummand {
    return @(floatSummand + doubleSummand);
}
@end

@interface SentrySwizzleTestClass_B : SentrySwizzleTestClass_A
@end

@implementation SentrySwizzleTestClass_B
@end

@interface SentrySwizzleTestClass_C : SentrySwizzleTestClass_B
@end

@implementation SentrySwizzleTestClass_C

- (void)dealloc {
    SentryTestsLog(@"C-");
};

- (int)calc:(int)num {
    return [super calc:num] * 3;
}
@end

@interface SentrySwizzleTestClass_D : SentrySwizzleTestClass_C
@end

@implementation SentrySwizzleTestClass_D
@end

@interface SentrySwizzleTestClass_D2 : SentrySwizzleTestClass_C
@end

@implementation SentrySwizzleTestClass_D2
@end

#pragma mark - HELPER FUNCTIONS -

static void swizzleVoidMethod(Class classToSwizzle,
        SEL selector,
        dispatch_block_t blockBefore,
        SentrySwizzleMode mode,
        const void *key) {
    SentrySwizzleInstanceMethod(classToSwizzle,
            selector,
            SentrySWReturnType(
            void),
            SentrySWArguments(),
            SentrySWReplacement(
                    {
                            blockBefore();
                            SentrySWCallOriginal();
                    }), mode, key);
}

static void swizzleDealloc(Class classToSwizzle, dispatch_block_t blockBefore) {
    SEL selector = NSSelectorFromString(@"dealloc");
    swizzleVoidMethod(classToSwizzle, selector, blockBefore, SentrySwizzleModeAlways, NULL);
}

static void swizzleNumber(Class classToSwizzle, int(^transformationBlock)(int)) {
    SentrySwizzleInstanceMethod(classToSwizzle,
            @selector(calc:),
            SentrySWReturnType(
            int),
            SentrySWArguments(
            int num),
            SentrySWReplacement(
                    {
                            int res = SentrySWCallOriginal(num);
                            return transformationBlock(res);
                    }), SentrySwizzleModeAlways, NULL);
}

@interface SentrySwizzleTests : XCTestCase

@end

@implementation SentrySwizzleTests

+ (void)setUp {
    [self swizzleDeallocs];
    [self swizzleCalc];
}

- (void)setUp {
    [super setUp];
    CLEAR_LOG();
}

+ (void)swizzleDeallocs {
    // 1) Swizzling a class that does not implement the method...
    swizzleDealloc([SentrySwizzleTestClass_D class], ^{
        SentryTestsLog(@"d-");
    });
    // ...should not break swizzling of its superclass.
    swizzleDealloc([SentrySwizzleTestClass_C class], ^{
        SentryTestsLog(@"c-");
    });
    // 2) Swizzling a class that does not implement the method
    // should not affect classes with the same superclass.
    swizzleDealloc([SentrySwizzleTestClass_D2 class], ^{
        SentryTestsLog(@"d2-");
    });

    // 3) We should be able to swizzle classes several times...
    swizzleDealloc([SentrySwizzleTestClass_D class], ^{
        SentryTestsLog(@"d'-");
    });
    // ...and nothing should be breaked up.
    swizzleDealloc([SentrySwizzleTestClass_C class], ^{
        SentryTestsLog(@"c'-");
    });

    // 4) Swizzling a class inherited from NSObject and does not
    // implementing the method.
    swizzleDealloc([SentrySwizzleTestClass_A class], ^{
        SentryTestsLog(@"a");
    });
}

- (void)testDeallocSwizzling {
    @autoreleasepool {
        id object = [SentrySwizzleTestClass_D new];
        object = nil;
    }
    ASSERT_LOG_IS(@"d'-d-c'-c-C-a");
}

#pragma mark - Calc: Swizzling

+ (void)swizzleCalc {

    swizzleNumber([SentrySwizzleTestClass_C class], ^int(int num) {
        return num + 17;
    });

    swizzleNumber([SentrySwizzleTestClass_D class], ^int(int num) {
        return num * 11;
    });
    swizzleNumber([SentrySwizzleTestClass_C class], ^int(int num) {
        return num * 5;
    });
    swizzleNumber([SentrySwizzleTestClass_D class], ^int(int num) {
        return num - 20;
    });

    swizzleNumber([SentrySwizzleTestClass_A class], ^int(int num) {
        return num * -1;
    });
}

- (void)testCalcSwizzling {
    SentrySwizzleTestClass_D *object = [SentrySwizzleTestClass_D new];
    int res = [object calc:2];
    XCTAssertTrue(res == ((2 * (-1) * 3) + 17) * 5 * 11 - 20, @"%d", res);
}

#pragma mark - String Swizzling

- (void)testStringSwizzling {
    SEL selector = @selector(string);
    SentrySwizzleTestClass_A *a = [SentrySwizzleTestClass_A new];

    SentrySwizzleInstanceMethod([a class],
            selector,
            SentrySWReturnType(NSString * ),
            SentrySWArguments(),
            SentrySWReplacement(
                    {
                            NSString * res = SentrySWCallOriginal();
                            return[res stringByAppendingString:@"DEF"];
                    }), SentrySwizzleModeAlways, NULL);

    XCTAssertTrue([[a string] isEqualToString:@"ABCDEF"]);
}

#pragma mark - Class Swizzling

- (void)testClassSwizzling {
    SentrySwizzleClassMethod([SentrySwizzleTestClass_B class],
            @selector(sumFloat:withDouble:),
            SentrySWReturnType(NSNumber * ),
            SentrySWArguments(
            float floatSummand,
            double doubleSummand),
            SentrySWReplacement(
                    {
                            NSNumber * result = SentrySWCallOriginal(floatSummand, doubleSummand);
                            return @([result doubleValue]* 2.);
                    }));
    
    XCTAssertEqualObjects(@(2.), [SentrySwizzleTestClass_A sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [SentrySwizzleTestClass_B sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [SentrySwizzleTestClass_C sumFloat:0.5 withDouble:1.5]);
}

#pragma mark - Test Assertions
#if !defined(NS_BLOCK_ASSERTIONS)

- (void)testThrowsOnSwizzlingNonexistentMethod {
    SEL selector = NSSelectorFromString(@"nonexistent");
    SentrySwizzleImpFactoryBlock factoryBlock = ^id(SentrySwizzleInfo *swizzleInfo) {
        return ^(__unsafe_unretained id self) {
            void (*originalIMP)(__unsafe_unretained id, SEL);
            originalIMP = (__typeof(originalIMP)) [swizzleInfo getOriginalImplementation];
            originalIMP(self, selector);
        };
    };
    XCTAssertThrows([SentrySwizzle
            swizzleInstanceMethod:selector
                          inClass:[SentrySwizzleTestClass_A class]
                    newImpFactory:factoryBlock
                             mode:SentrySwizzleModeAlways
                              key:NULL]);
}

#endif

#pragma mark - Mode tests

- (void)testAlwaysSwizzlingMode {
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([SentrySwizzleTestClass_A class],
                @selector(methodForAlwaysSwizzling), ^{
                    SentryTestsLog(@"A");
                },
                SentrySwizzleModeAlways,
                NULL);
        swizzleVoidMethod([SentrySwizzleTestClass_B class],
                @selector(methodForAlwaysSwizzling), ^{
                    SentryTestsLog(@"B");
                },
                SentrySwizzleModeAlways,
                NULL);
    }

    SentrySwizzleTestClass_B *object = [SentrySwizzleTestClass_B new];
    [object methodForAlwaysSwizzling];
    ASSERT_LOG_IS(@"BBBAAA");
}

- (void)testSwizzleOncePerClassMode {
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([SentrySwizzleTestClass_A class],
                @selector(methodForSwizzlingOncePerClass), ^{
                    SentryTestsLog(@"A");
                },
                SentrySwizzleModeOncePerClass,
                key);
        swizzleVoidMethod([SentrySwizzleTestClass_B class],
                @selector(methodForSwizzlingOncePerClass), ^{
                    SentryTestsLog(@"B");
                },
                SentrySwizzleModeOncePerClass,
                key);
    }
    SentrySwizzleTestClass_B *object = [SentrySwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClass];
    ASSERT_LOG_IS(@"BA");
}

- (void)testSwizzleOncePerClassOrSuperClassesMode {
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([SentrySwizzleTestClass_A class],
                @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{
                    SentryTestsLog(@"A");
                },
                SentrySwizzleModeOncePerClassAndSuperclasses,
                key);
        swizzleVoidMethod([SentrySwizzleTestClass_B class],
                @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{
                    SentryTestsLog(@"B");
                },
                SentrySwizzleModeOncePerClassAndSuperclasses,
                key);
    }
    SentrySwizzleTestClass_B *object = [SentrySwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClassOrSuperClasses];
    ASSERT_LOG_IS(@"A");
}

@end
