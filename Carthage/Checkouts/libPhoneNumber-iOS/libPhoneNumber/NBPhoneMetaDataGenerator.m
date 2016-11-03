//
//  NBPhoneMetaDataGenerator.m
//  libPhoneNumber
//
//

#import "NBPhoneMetaDataGenerator.h"
#import "NBPhoneMetaData.h"

@interface NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index;
@end

@implementation NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index {
    @synchronized(self) {
        if (index >= [self count]) return nil;
        id res = [self objectAtIndex:index];
        if (res == nil || (NSNull*)res == [NSNull null]) {
            return nil;
        }
        return res;
    }
}
@end

#define kNBSRCDirectoryName @"src"

#define INDENT_TAB @"    "
#define STR_VAL(val) [self stringForSourceCode:val]
#define NUM_VAL(val) [self numberForSourceCode:val]

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";


@implementation NBPhoneMetaDataGenerator


- (id)init
{
    self = [super init];
    
    if (self)
    {
    }
    
    return self;
}






- (void)generateMetadataClasses
{
    NSDictionary *realMetadata = [self generateMetaData];
    NSDictionary *testMetadata = [self generateMetaDataWithTest];
    
    @try {
        NSURL *dataPathURL= [NSURL fileURLWithPath: [self getSRCDirectoryPath]];
        NSError *error = nil;
        BOOL success = [dataPathURL setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [dataPathURL lastPathComponent], error);
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:[dataPathURL path]]) {
            BOOL sucess = [[NSFileManager defaultManager] createDirectoryAtURL:dataPathURL withIntermediateDirectories:NO attributes:nil error:&error];
            if(!sucess) {
                 NSLog(@"[%@] ERROR: attempting to write create MyFolder directory", [self class]);
            }
        }
        
        NSDictionary *mappedRealData = [self mappingObject:realMetadata];
        NSDictionary *mappedTestData = [self mappingObject:testMetadata];
        
        [self createClassWithDictionary:mappedRealData name:@"NBMetadataCore" isTestData:NO];
        [self createClassWithDictionary:mappedTestData name:@"NBMetadataCoreTest" isTestData:YES];
    } @catch (NSException *exception) {
        NSLog(@"Error for creating metadata classes : %@", exception.reason);
    }
}


- (void)createClassWithDictionary:(NSDictionary*)data name:(NSString*)name isTestData:(BOOL)isTest
{
    NSString *dataPath = [self getSRCDirectoryPath];
    
    NSString *codeStringHeader = [self generateSourceCodeWith:data name:name type:0 isTestData:isTest];
    NSString *codeStringSource = [self generateSourceCodeWith:data name:name type:1 isTestData:isTest];
    NSString *headerFilePath = [NSString stringWithFormat:@"%@/%@.h", dataPath, name];
    NSString *sourceFilePath = [NSString stringWithFormat:@"%@/%@.m", dataPath, name];
    NSData *dataToWrite = [codeStringHeader dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL successCreate = [[NSFileManager defaultManager] createFileAtPath:headerFilePath contents:dataToWrite attributes:nil];
    dataToWrite = [codeStringSource dataUsingEncoding:NSUTF8StringEncoding];
    successCreate = successCreate && [[NSFileManager defaultManager] createFileAtPath:sourceFilePath contents:dataToWrite attributes:nil];
    
    NSString *codeMapStringHeader = [self generateMappingSourceCodeWith:data name:name type:0 isTestData:isTest];
    NSString *codeMapStringSource = [self generateMappingSourceCodeWith:data name:name type:1 isTestData:isTest];
    NSString *headerMapFilePath = [NSString stringWithFormat:@"%@/%@Mapper.h", dataPath, name];
    NSString *sourceMapFilePath = [NSString stringWithFormat:@"%@/%@Mapper.m", dataPath, name];
    NSData *mapToWrite = [codeMapStringHeader dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL successMapCreate = [[NSFileManager defaultManager] createFileAtPath:headerMapFilePath contents:mapToWrite attributes:nil];
    mapToWrite = [codeMapStringSource dataUsingEncoding:NSUTF8StringEncoding];
    successMapCreate = successMapCreate && [[NSFileManager defaultManager] createFileAtPath:sourceMapFilePath contents:mapToWrite attributes:nil];
    
    NSLog(@"Create [%@] file to...\n%@", successCreate && successMapCreate?@"success":@"fail", dataPath);
}

- (NSDictionary *)mappingObject:(NSDictionary *)parsedJSONData {
    NSMutableDictionary *resMedata = [[NSMutableDictionary alloc] init];
    NSDictionary *countryCodeToRegionCodeMap = [parsedJSONData objectForKey:@"countryCodeToRegionCodeMap"];
    NSDictionary *countryToMetadata = [parsedJSONData objectForKey:@"countryToMetadata"];
    NSLog(@"- countryCodeToRegionCodeMap count [%zu]", (unsigned long)[countryCodeToRegionCodeMap count]);
    NSLog(@"- countryToMetadata          count [%zu]", (unsigned long)[countryToMetadata count]);
    
    [resMedata setObject:countryCodeToRegionCodeMap forKey:@"countryCodeToRegionCodeMap"];
    [resMedata setObject:countryToMetadata forKey:@"countryToMetadata"];
    
    return resMedata;
}


- (NSString *)genRandStringLength:(int)len
{
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}


- (NSString*)indentTab:(int)depth
{
    NSMutableString *resTab = [[NSMutableString alloc] initWithString:@""];
    for (int i=0; i<depth; i++)
    {
        [resTab appendString:INDENT_TAB];
    }
    return resTab;
}


- (NSString *)getSRCDirectoryPath {
    NSString *documentsDirectory = [self documentsDirectory];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"src"];
    return dataPath;
}

- (NSString *)documentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}


- (NSDictionary *)generateMetaData
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneNumberMetaData" ofType:@"json"];
    return [self parseJSON:filePath];
}


- (NSDictionary *)generateMetaDataWithTest
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneNumberMetaDataForTesting" ofType:@"json"];
    return [self parseJSON:filePath];
}


- (NSDictionary *)parseJSON:(NSString*)filePath
{
    NSDictionary *jsonRes = nil;
    
    @try {
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
        NSError *error = nil;
        jsonRes = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@", exception.reason);
    }
    
    return jsonRes;
}


- (NSString *)generateSourceCodeWith:(NSDictionary*)data name:(NSString*)name type:(int)type isTestData:(BOOL)isTest
{
    NSString *classPrefix = isTest ? @"NBPhoneMetadataTest" : @"NBPhoneMetadata";
    
    NSMutableString *contents = [[NSMutableString alloc] init];
    
    NSDictionary *metadata = [data objectForKey:@"countryToMetadata"];
    
    if (type == 0) {
        NSArray *allKeys = metadata.allKeys;
        
        [contents appendString:@"#import <Foundation/Foundation.h>\n"];
        [contents appendString:@"#import \"NBPhoneMetaData.h\"\n\n"];
        
        for (NSString *key in allKeys) {
            NSString *className = [NSString stringWithFormat:@"%@%@", classPrefix, key];
            [contents appendFormat:@"@interface %@ : NBPhoneMetaData\n", className];
            [contents appendString:@"@end\n\n"];
        }
        
    } else if (type == 1) {
        NSArray *allKeys = metadata.allKeys;
        
        [contents appendFormat:@"#import \"%@.h\"\n", name];
        [contents appendString:@"#import \"NBPhoneNumberDefines.h\"\n"];
        [contents appendString:@"#import \"NBPhoneNumberDesc.h\"\n\n"];
        [contents appendString:@"#import \"NBNumberFormat.h\"\n\n"];
        
        for (NSString *key in allKeys) {
            NSArray *currentMetadata = [metadata objectForKey:key];
            NSString *className = [NSString stringWithFormat:@"%@%@", classPrefix, key];
            [contents appendFormat:@"@implementation %@\n", className];
            [contents appendString:@"- (id)init\n"];
            [contents appendString:@"{\n"];
            [contents appendString:@"    self = [super init];\n"];
            [contents appendString:@"    if (self) {\n"];
            
            /*  1 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:1] name:@"self.generalDesc"]];
            /*  2 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:2] name:@"self.fixedLine"]];
            /*  3 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:3] name:@"self.mobile"]];
            /*  4 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:4] name:@"self.tollFree"]];
            /*  5 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:5] name:@"self.premiumRate"]];
            /*  6 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:6] name:@"self.sharedCost"]];
            /*  7 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:7] name:@"self.personalNumber"]];
            /*  8 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:8] name:@"self.voip"]];
            
            /* 21 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:21] name:@"self.pager"]];
            /* 25 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:25] name:@"self.uan"]];
            /* 27 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:27] name:@"self.emergency"]];
            /* 28 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:28] name:@"self.voicemail"]];
            /* 24 */ [contents appendString:[self phoneNumberDescWithData:[currentMetadata safeObjectAtIndex:24] name:@"self.noInternationalDialling"]];
            /*  9 */ [contents appendFormat:@"        self.codeID = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:9])];
            /* 10 */ [contents appendFormat:@"        self.countryCode = %@;\n", NUM_VAL([currentMetadata safeObjectAtIndex:10])];
            /* 11 */ [contents appendFormat:@"        self.internationalPrefix = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:11])];
            /* 17 */ [contents appendFormat:@"        self.preferredInternationalPrefix = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:17])];
            /* 12 */ [contents appendFormat:@"        self.nationalPrefix = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:12])];
            /* 13 */ [contents appendFormat:@"        self.preferredExtnPrefix = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:13])];
            /* 15 */ [contents appendFormat:@"        self.nationalPrefixForParsing = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:15])];
            /* 16 */ [contents appendFormat:@"        self.nationalPrefixTransformRule = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:16])];
            /* 18 */ [contents appendFormat:@"        self.sameMobileAndFixedLinePattern = %@;\n", [[currentMetadata safeObjectAtIndex:18] boolValue] ? @"YES":@"NO"];
            /* 19 */ [contents appendString:[self phoneNumberFormatArrayWithData:[currentMetadata safeObjectAtIndex:19] name:@"self.numberFormats"]]; // NBNumberFormat array
            /* 20 */ [contents appendString:[self phoneNumberFormatArrayWithData:[currentMetadata safeObjectAtIndex:20] name:@"self.intlNumberFormats"]]; // NBNumberFormat array
            /* 22 */ [contents appendFormat:@"        self.mainCountryForCode = %@;\n", [[currentMetadata safeObjectAtIndex:22] boolValue] ? @"YES":@"NO"];
            /* 23 */ [contents appendFormat:@"        self.leadingDigits = %@;\n", STR_VAL([currentMetadata safeObjectAtIndex:23])];
            /* 26 */ [contents appendFormat:@"        self.leadingZeroPossible = %@;\n", [[currentMetadata safeObjectAtIndex:26] boolValue] ? @"YES":@"NO"];

            [contents appendString:@"    }\n"];
            [contents appendString:@"    return self;\n"];
            [contents appendString:@"}\n"];
            
            [contents appendString:@"@end\n\n"];
        }
    }
    
    return contents;
}


- (NSString *)generateMappingSourceCodeWith:(NSDictionary*)data name:(NSString*)name type:(int)type isTestData:(BOOL)isTest
{
    NSMutableString *contents = [[NSMutableString alloc] init];
    
    NSDictionary *mapCN2CCode = [data objectForKey:@"countryCodeToRegionCodeMap"];
    NSArray *allCallingCodeKey = mapCN2CCode.allKeys;
    
    if (type == 0) {
        [contents appendString:@"#import <Foundation/Foundation.h>\n\n"];
        [contents appendFormat:@"@interface %@Mapper : NSObject\n\n", name];
        [contents appendString:@"+ (NSArray *)ISOCodeFromCallingNumber:(NSString *)key;\n\n"];
        [contents appendString:@"@end\n\n"];
    } else if (type == 1) {
        [contents appendFormat:@"#import \"%@Mapper.h\"\n\n", name];
        
        [contents appendFormat:@"@implementation %@Mapper\n\n", name];
        [contents appendString:@"static NSMutableDictionary *kMapCCode2CN;\n\n"];
        [contents appendString:@"+ (NSArray *)ISOCodeFromCallingNumber:(NSString *)key\n"];
        [contents appendString:@"{\n"];
        [contents appendString:@"    static dispatch_once_t onceToken;\n"];
        [contents appendString:@"    dispatch_once(&onceToken, ^{\n"];
        [contents appendString:@"        kMapCCode2CN = [[NSMutableDictionary alloc] init];\n"];
        
        for (NSString *callingKey in allCallingCodeKey) {
            NSArray *countryCodeArray = [mapCN2CCode objectForKey:callingKey];
            [contents appendString:@"\n"];
            [contents appendFormat:@"        NSMutableArray *countryCode%@Array = [[NSMutableArray alloc] init];\n", callingKey];
            for (NSString *code in countryCodeArray) {
                [contents appendFormat:@"        [countryCode%@Array addObject:%@];\n", callingKey, STR_VAL(code)];
            }
            [contents appendFormat:@"        [kMapCCode2CN setObject:countryCode%@Array forKey:%@];\n", callingKey, STR_VAL(callingKey)];
        }
        [contents appendString:@"    });\n"];
        [contents appendString:@"    return [kMapCCode2CN objectForKey:key];\n"];
        [contents appendString:@"}\n\n"];
        [contents appendString:@"@end\n\n"];
    }
    
    return contents;
}


- (NSString *)stringForSourceCode:(id)value
{
    if (value && [value isKindOfClass:[NSString class]]) {
        value = [value stringByReplacingOccurrencesOfString:@"\\d" withString:@"\\\\d"];
        return [NSString stringWithFormat:@"@\"%@\"", value];
    }
    
    return @"nil";
}


- (NSString *)numberForSourceCode:(id)value
{
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"[NSNumber numberWithInteger:%@]", value];
    }
    return @"nil";
}


- (NSString *)phoneNumberDescWithData:(id)value name:(NSString *)varName
{
    NSMutableString *contents = [[NSMutableString alloc] init];
    
    NSString *initSentance = [self phoneNumberDescWithData:value];
    [contents appendFormat:@"        %@ = %@;\n", varName, initSentance];
    return contents;
}


- (NSString *)phoneNumberDescWithData:(id)value
{
    NSString *initSentance = [NSString stringWithFormat:@"[[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:%@ withPossibleNumberPattern:%@ withExample:%@]",
                              STR_VAL([value safeObjectAtIndex:2]), STR_VAL([value safeObjectAtIndex:3]), STR_VAL([value safeObjectAtIndex:6])];
    return initSentance;
}


- (NSString *)phoneNumberFormatWithData:(id)value name:(NSString *)varName
{
    NSMutableString *contents = [[NSMutableString alloc] init];
    
    NSString *cleanName = [[varName stringByReplacingOccurrencesOfString:@"." withString:@""] stringByReplacingOccurrencesOfString:@"self" withString:@""];
    NSString *arrayName = [NSString stringWithFormat:@"%@_patternArray", cleanName];
    
    if (value != nil && [value isKindOfClass:[NSArray class]]) {
        /* 1 */ NSString *pattern = [value safeObjectAtIndex:1];
        /* 2 */ NSString *format = [value safeObjectAtIndex:2];
        /* 4 */ NSString *nationalPrefixFormattingRule = [value safeObjectAtIndex:4];
        /* 6 */ BOOL nationalPrefixOptionalWhenFormatting = [[value safeObjectAtIndex:6] boolValue];
        /* 5 */ NSString *domesticCarrierCodeFormattingRule = [value safeObjectAtIndex:5];
    
        [contents appendFormat:@"\n        NSMutableArray *%@ = [[NSMutableArray alloc] init];\n", arrayName];
        
        /* 3 */ id tmpData = [value safeObjectAtIndex:3];
    
        if (tmpData != nil && [tmpData isKindOfClass:[NSArray class]]) {
            for (id numFormat in tmpData) {
                if ([numFormat isKindOfClass:[NSString class]]) {
                    [contents appendFormat:@"        [%@ addObject:%@];\n", arrayName, STR_VAL(numFormat)];
                } else {
                    [contents appendFormat:@"        [%@ addObject:%@];\n", arrayName, STR_VAL([numFormat stringValue])];
                }
            }
        }
        
        NSString *initSentance = [NSString stringWithFormat:@"        NBNumberFormat *%@ = [[NBNumberFormat alloc] initWithPattern:%@ withFormat:%@ withLeadingDigitsPatterns:%@ withNationalPrefixFormattingRule:%@ whenFormatting:%@ withDomesticCarrierCodeFormattingRule:%@];\n",
                                  varName, STR_VAL(pattern), STR_VAL(format), arrayName, STR_VAL(nationalPrefixFormattingRule),
                                  nationalPrefixOptionalWhenFormatting ? @"YES":@"NO", STR_VAL(domesticCarrierCodeFormattingRule)];
        
        [contents appendString:initSentance];
    }
    
    return contents;
}


- (NSString *)phoneNumberFormatArrayWithData:(id)value name:(NSString *)varName
{
    NSMutableString *contents = [[NSMutableString alloc] init];
    
    NSString *cleanName = [[varName stringByReplacingOccurrencesOfString:@"." withString:@""] stringByReplacingOccurrencesOfString:@"self" withString:@""];
    NSString *arrayName = [NSString stringWithFormat:@"%@_FormatArray", cleanName];
    
    [contents appendFormat:@"\n        NSMutableArray *%@ = [[NSMutableArray alloc] init];\n", arrayName];
    
    NSInteger index = 0;
    
    for (id data in value) {
        NSString *tmpVarName = [NSString stringWithFormat:@"%@%@", cleanName, @(index++)];
        NSString *initSentance = [self phoneNumberFormatWithData:data name:tmpVarName];
        [contents appendString:initSentance];
        [contents appendFormat:@"        [%@ addObject:%@];\n", arrayName, tmpVarName];
    }
    
    [contents appendFormat:@"        %@ = %@;\n", varName, arrayName];
    return contents;
}


@end
