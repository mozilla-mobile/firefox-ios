//
//  FunctionalTests+ObjC.m
//  Quick
//
//  Created by Brian Ivan Gesiak on 6/11/14.
//  Copyright (c) 2014 Brian Ivan Gesiak. All rights reserved.
//

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>


QuickSharedExampleGroupsBegin(FunctionalTestsObjCSharedExampleGroups)

qck_sharedExamples(@"a truthy value", ^(QCKDSLSharedExampleContext context) {
    __block NSNumber *value = nil;
    qck_beforeEach(^{
        value = context()[@"value"];
    });

    qck_it(@"is true", ^{
        expect(value).to(beTruthy());
    });
});

QuickSharedExampleGroupsEnd


static BOOL beforeSuiteExecuted_afterSuiteNotYetExecuted = NO;


QuickSpecBegin(FunctionalTestsObjC)

qck_beforeSuite(^{
    beforeSuiteExecuted_afterSuiteNotYetExecuted = YES;
});

qck_afterSuite(^{
    beforeSuiteExecuted_afterSuiteNotYetExecuted = NO;
});

qck_describe(@"a describe block", ^{
    qck_it(@"contains an it block", ^{
        expect(@(beforeSuiteExecuted_afterSuiteNotYetExecuted)).to(beTruthy());
    });

    qck_itBehavesLike(@"a truthy value", ^{ return @{ @"value": @YES }; });

    qck_pending(@"a pending block", ^{
        qck_it(@"contains a failing it block", ^{
            expect(@NO).to(beTruthy());
        });
    });
    
    qck_xdescribe(@"a pending (shorthand) describe block", ^{
        qck_it(@"contains a failing it block", ^{
            expect(@NO).to(beTruthy());
        });
    });
    
    qck_xcontext(@"a pending (shorthand) context block", ^{
        qck_it(@"contains a failing it block", ^{
            expect(@NO).to(beTruthy());
        });
    });
    
    qck_xit(@"contains a pending (shorthand) it block", ^{
        expect(@NO).to(beTruthy());
    });
});

QuickSpecEnd
