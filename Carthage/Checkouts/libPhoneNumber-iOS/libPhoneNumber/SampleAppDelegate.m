//
//  SampleAppDelegate.m
//  libPhoneNumber
//
//

#import "SampleAppDelegate.h"
#import "NBPhoneMetaDataGenerator.h"

@import libPhoneNumber;


@implementation SampleAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [self.window setRootViewController:[[UIViewController alloc] init]];
    
    // Generate metadata (do not use in release)
    NBPhoneMetaDataGenerator *generator = [[NBPhoneMetaDataGenerator alloc] init];
    [generator generateMetadataClasses];
    
    [self testWithRealData];
    //[self testWithGCD];
    [self testForGetSupportedRegions];
    
    return YES;
}


- (void)testForGetSupportedRegions
{
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSLog(@"%@", [phoneUtil getSupportedRegions]);
}


- (void)testWithRealData
{
    NBAsYouTypeFormatter *formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    
    NSLog(@"%@ (%@)", [formatter inputDigit:@"2"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"1"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"2"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    NSLog(@"%@ (%@)", [formatter inputDigit:@"5"], formatter.isSuccessfulFormatting ? @"Y":@"N");
    
    NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    NSLog(@"%@", [f inputDigit:@"6"]); // "6"
    NSLog(@"%@", [f inputDigit:@"5"]); // "65"
    NSLog(@"%@", [f inputDigit:@"0"]); // "650"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2"
    NSLog(@"%@", [f inputDigit:@"5"]); // "650 25"
    NSLog(@"%@", [f inputDigit:@"3"]); // "650 253"
    
    // Note this is how a US local number (without area code) should be formatted.
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2532"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 22"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 222"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 2222"
    // Can remove last digit
    NSLog(@"%@", [f removeLastDigit]); // "650 253 222"
    
    NSLog(@"%@", [f inputString:@"16502532222"]); // 1 650 253 2222
    
    // Unit test for isValidNumber is failing some valid numbers. #7
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    {
        NSError *error = nil;
        NBPhoneNumber *phoneNumberUS = [phoneUtil parse:@"(366) 522-8999" defaultRegion:@"US" error:&error];
        if (error) {
            NSLog(@"err [%@]", [error localizedDescription]);
        }
        NSLog(@"- isValidNumber [%@]", [phoneUtil isValidNumber:phoneNumberUS] ? @"YES" : @"NO");
        NSLog(@"- isPossibleNumber [%@]", [phoneUtil isPossibleNumber:phoneNumberUS error:&error] ? @"YES" : @"NO");
        NSLog(@"- getRegionCodeForNumber [%@]", [phoneUtil getRegionCodeForNumber:phoneNumberUS]);
    }
    
    NSLog(@"- - - - -");
    
    {
        NSError *error = nil;
        NBPhoneNumber *phoneNumberZZ = [phoneUtil parse:@"+84 74 883313" defaultRegion:NB_UNKNOWN_REGION error:&error];
        if (error) {
            NSLog(@"err [%@]", [error localizedDescription]);
        }
        NSLog(@"- isValidNumber [%@]", [phoneUtil isValidNumber:phoneNumberZZ] ? @"YES" : @"NO");
        NSLog(@"- isPossibleNumber [%@]", [phoneUtil isPossibleNumber:phoneNumberZZ error:&error] ? @"YES" : @"NO");
        NSLog(@"- getRegionCodeForNumber [%@]", [phoneUtil getRegionCodeForNumber:phoneNumberZZ]);
    }
    
    NSLog(@"- - - - - GB / +923406171134");
    
    // I can't validate pakistani numbers #58
    {
        NSError *error = nil;
        NBPhoneNumber *phoneNumberUS = [phoneUtil parse:@"+923406171134" defaultRegion:@"GB" error:&error];
        if (error) {
            NSLog(@"err [%@]", [error localizedDescription]);
        }
        NSLog(@"- isValidNumber [%@]", [phoneUtil isValidNumber:phoneNumberUS] ? @"YES" : @"NO");
        NSLog(@"- isPossibleNumber [%@]", [phoneUtil isPossibleNumber:phoneNumberUS error:&error] ? @"YES" : @"NO");
        NSLog(@"- getRegionCodeForNumber [%@]", [phoneUtil getRegionCodeForNumber:phoneNumberUS]);
    }
    
    // finnish phone number don't get recognised #59
    {
        NSString *nationalNumber = @"";
        NSNumber *countryCode = [phoneUtil extractCountryCode:@"+358401493292" nationalNumber:&nationalNumber];
        NSLog(@"- %@ %@", countryCode, nationalNumber);
        
        NBPhoneNumber *phonePN = [phoneUtil parse:@"+358401493292" defaultRegion:@"FIN" error:nil];
        NSLog(@"- %@", [phoneUtil format:phonePN numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil]);
    }
    
    NSLog(@"-------------- customTest");
    
    NSError *anError = nil;
    
    NBPhoneNumber *myNumber = [phoneUtil parse:@"6766077303" defaultRegion:@"AT" error:&anError];
    if (anError == nil)
    {
        NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
        NSLog(@"E164          : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError]);
        NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&anError]);
        NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&anError]);
        NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatRFC3966 error:&anError]);
    }
    else
    {
        NSLog(@"Error : %@", [anError localizedDescription]);
    }
    
    NSLog (@"extractCountryCode [%ld]", (unsigned long)[phoneUtil extractCountryCode:@"823213123123" nationalNumber:nil]);
    NSString *res = nil;
    NSNumber *dRes = [phoneUtil extractCountryCode:@"823213123123" nationalNumber:&res];
    NSLog (@"extractCountryCode [%@] [%@]", dRes, res);
}


- (NSString *)stringWithRandomNumber
{
    NSString *numbers = @"0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:11];
    
    for (int i=0; i<12; i++) {
        [randomString appendFormat: @"%C", [numbers characterAtIndex: arc4random() % [numbers length]]];
    }
    
    return randomString;
}


- (NSString *)randomRegion
{
    NBMetadataHelper *aHelper = [[NBMetadataHelper alloc] init];
    NSDictionary *metadata = [[aHelper getAllMetadata] objectAtIndex:(arc4random() % [aHelper getAllMetadata].count)];
    if (metadata) {
        NSString *region = [metadata objectForKey:@"code"];
        if (region) {
            return region;
        }
    }
    
    return nil;
}


- (void)testForMultithread
{
    NBPhoneNumberUtil *aUtil = [[NBPhoneNumberUtil alloc] init];
    NSString *testRegion = [self randomRegion];
    
    if (!testRegion) {
        return;
    }
    
    NSLog(@"- START [%@]", testRegion);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        
        for (int i=0; i<10000; i++) {
            NBPhoneNumber *phoneNumber = [aUtil parse:[self stringWithRandomNumber] defaultRegion:testRegion error:&error];
            if (error && ![error.domain isEqualToString:@"INVALID_COUNTRY_CODE"]) {
                NSLog(@"error [%@]", [error localizedDescription]);
            }
            
            if (!error) {
                error = nil;
                [aUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&error];
            }
            error = nil;
        }
        
        NSLog(@"OK [%@]", testRegion);
    });
}


- (void)testWithGCD
{
    for (int i = 0; i<100; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self testForMultithread];
        });
    }
}


- (void)testForExtraDatas
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    NSArray *arrayData = [helper getAllMetadata];
    if (arrayData && arrayData.count > 0) {
        NSLog(@"Log sample metadata [%@]", [arrayData firstObject]);
    } else {
        NSLog(@"Fail to extract meta data");
    }
}

- (void)testCarrierRegion
{
    NSLog(@"testCarrierRegion %@", [self getPhoneNumberFormatted:@"1234567890"]);
}


- (NSString *)getPhoneNumberFormatted:(NSString *)phoneNumber
{
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSString *retValue;
    NBPhoneNumber *phoneNumberFormatted = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:nil];
    retValue = [phoneUtil format:phoneNumberFormatted numberFormat:NBEPhoneNumberFormatRFC3966 error:nil];
    return retValue;
}


// FIXME: This unit test ALWAYS FAIL ... until google libPhoneNumber fix this issue
- (void)testAustriaNationalNumberParsing
{
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NSError *anError = nil;
    
    NSString *internationalNumberForInput = @"436606545646";
    NSString *nationalNumberForExpect = @"6606545646";
    NSString *defaultRegion = @"AT";
    
    NBPhoneNumber *phoneNumber = [phoneUtil parse:internationalNumberForInput defaultRegion:defaultRegion error:&anError];
    NSString *nationalNumberForActual = [NSString stringWithFormat:@"%@", phoneNumber.nationalNumber];
    
    // ALWAYS FAIL need fix "google libPhoneNumber"
    NSLog(nationalNumberForExpect, nationalNumberForActual);
    
}


- (void)testForiOS7
{
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:@"0174 2340XXX" defaultRegion:@"DE" error:&anError];
    if (anError == nil) {
        NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
        NSLog(@"E164          : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError]);
        NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&anError]);
        NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&anError]);
        NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatRFC3966 error:&anError]);
    } else {
        NSLog(@"Error : %@", [anError localizedDescription]);
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
