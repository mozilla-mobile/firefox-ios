//
//  NBPhoneNumberUtil.m
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumberDefines.h"
#import "NBPhoneNumber.h"
#import "NBNumberFormat.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneMetaData.h"
#import "NBMetadataHelper.h"
#import <math.h>

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif


#pragma mark - NBPhoneNumberUtil interface -

@interface NBPhoneNumberUtil ()

@property (nonatomic, strong) NSLock *entireStringCacheLock;
@property (nonatomic, strong) NSMutableDictionary *entireStringRegexCache;

@property (nonatomic, strong) NSLock *lockPatternCache;
@property (nonatomic, strong) NSMutableDictionary *regexPatternCache;

@property (nonatomic, strong, readwrite) NSMutableDictionary *i18nNumberFormat;
@property (nonatomic, strong, readwrite) NSMutableDictionary *i18nPhoneNumberDesc;
@property (nonatomic, strong, readwrite) NSMutableDictionary *i18nPhoneMetadata;

@property (nonatomic, strong) NSRegularExpression *PLUS_CHARS_PATTERN;
@property (nonatomic, strong) NSRegularExpression *CAPTURING_DIGIT_PATTERN;
@property (nonatomic, strong) NSRegularExpression *VALID_ALPHA_PHONE_PATTERN;

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
@property (nonatomic, readonly) CTTelephonyNetworkInfo *telephonyNetworkInfo;
#endif

@end


@implementation NBPhoneNumberUtil

#pragma mark - Static Int variables -
const static NSUInteger NANPA_COUNTRY_CODE_ = 1;
const static int MIN_LENGTH_FOR_NSN_ = 2;
const static int MAX_LENGTH_FOR_NSN_ = 16;
const static int MAX_LENGTH_COUNTRY_CODE_ = 3;
const static int MAX_INPUT_STRING_LENGTH_ = 250;

#pragma mark - Static String variables -
static NSString *VALID_PUNCTUATION = @"-x‐-―−ー－-／ ­​⁠　()（）［］.\\[\\]/~⁓∼～";

static NSString *INVALID_COUNTRY_CODE_STR = @"Invalid country calling code";
static NSString *NOT_A_NUMBER_STR = @"The string supplied did not seem to be a phone number";
static NSString *TOO_SHORT_AFTER_IDD_STR = @"Phone number too short after IDD";
static NSString *TOO_SHORT_NSN_STR = @"The string supplied is too short to be a phone number";
static NSString *TOO_LONG_STR = @"The string supplied is too long to be a phone number";

static NSString *COLOMBIA_MOBILE_TO_FIXED_LINE_PREFIX = @"3";
static NSString *PLUS_SIGN = @"+";
static NSString *STAR_SIGN = @"*";
static NSString *RFC3966_EXTN_PREFIX = @";ext=";
static NSString *RFC3966_PREFIX = @"tel:";
static NSString *RFC3966_PHONE_CONTEXT = @";phone-context=";
static NSString *RFC3966_ISDN_SUBADDRESS = @";isub=";
static NSString *DEFAULT_EXTN_PREFIX = @" ext. ";
static NSString *VALID_ALPHA = @"A-Za-z";

#pragma mark - Static regular expression strings -
static NSString *NON_DIGITS_PATTERN = @"\\D+";
static NSString *CC_PATTERN = @"\\$CC";
static NSString *FIRST_GROUP_PATTERN = @"(\\$\\d)";
static NSString *FIRST_GROUP_ONLY_PREFIX_PATTERN = @"^\\(?\\$1\\)?";
static NSString *NP_PATTERN = @"\\$NP";
static NSString *FG_PATTERN = @"\\$FG";
static NSString *VALID_ALPHA_PHONE_PATTERN_STRING = @"(?:.*?[A-Za-z]){3}.*";

static NSString *UNIQUE_INTERNATIONAL_PREFIX = @"[\\d]+(?:[~\\u2053\\u223C\\uFF5E][\\d]+)?";

static NSString *LEADING_PLUS_CHARS_PATTERN;
static NSString *EXTN_PATTERN;
static NSString *SEPARATOR_PATTERN;
static NSString *VALID_PHONE_NUMBER_PATTERN;
static NSString *VALID_START_CHAR_PATTERN;
static NSString *UNWANTED_END_CHAR_PATTERN;
static NSString *SECOND_NUMBER_START_PATTERN;

static NSDictionary *ALPHA_MAPPINGS;
static NSDictionary *ALL_NORMALIZATION_MAPPINGS;
static NSDictionary *DIALLABLE_CHAR_MAPPINGS;
static NSDictionary *ALL_PLUS_NUMBER_GROUPING_SYMBOLS;

static NSDictionary *DIGIT_MAPPINGS;


#pragma mark - Deprecated methods

+ (NBPhoneNumberUtil *)sharedInstance
{
    static NBPhoneNumberUtil *sharedOnceInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedOnceInstance = [[self alloc] init]; });
    return sharedOnceInstance;
}


#pragma mark - NSError

- (NSError*)errorWithObject:(id)obj withDomain:(NSString *)domain
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:obj forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:domain code:0 userInfo:userInfo];
    return error;
}


- (NSRegularExpression *)entireRegularExpressionWithPattern:(NSString *)regexPattern
                                                    options:(NSRegularExpressionOptions)options
                                                      error:(NSError **)error
{
    [_entireStringCacheLock lock];
    
    @try {
        if (!_entireStringRegexCache) {
            _entireStringRegexCache = [[NSMutableDictionary alloc] init];
        }
        
        NSRegularExpression *regex = [_entireStringRegexCache objectForKey:regexPattern];
        if (! regex)
        {
            NSString *finalRegexString = regexPattern;
            if ([regexPattern rangeOfString:@"^"].location == NSNotFound) {
                finalRegexString = [NSString stringWithFormat:@"^(?:%@)$", regexPattern];
            }
            
            regex = [self regularExpressionWithPattern:finalRegexString options:0 error:error];
            [_entireStringRegexCache setObject:regex forKey:regexPattern];
        }
        
        return regex;
    }
    @finally {
        [_entireStringCacheLock unlock];
    }
}


- (NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError **)error
{
    [_lockPatternCache lock];
    
    @try {
        if (!_regexPatternCache) {
            _regexPatternCache = [[NSMutableDictionary alloc] init];
        }
        
        NSRegularExpression *regex = [_regexPatternCache objectForKey:pattern];
        if (!regex) {
            regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:error];
            [_regexPatternCache setObject:regex forKey:pattern];
        }
        return regex;
    }
    @finally {
        [_lockPatternCache unlock];
    }
}


- (NSMutableArray*)componentsSeparatedByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    NSString *replacedString = [self replaceStringByRegex:sourceString regex:pattern withTemplate:@"<SEP>"];
    NSMutableArray *resArray = [[replacedString componentsSeparatedByString:@"<SEP>"] mutableCopy];
    [resArray removeObject:@""];
    return resArray;
}


- (int)stringPositionByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    if (sourceString == nil || sourceString.length <= 0 || pattern == nil || pattern.length <= 0) {
        return -1;
    }
    
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [currentPattern matchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    
    int foundPosition = -1;
    
    if (matches.count > 0) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        return (int)match.range.location;
    }
    
    return foundPosition;
}


- (int)indexOfStringByString:(NSString *)sourceString target:(NSString *)targetString
{
    NSRange finded = [sourceString rangeOfString:targetString];
    if (finded.location != NSNotFound) {
        return (int)finded.location;
    }
    
    return -1;
}


- (NSString *)replaceFirstStringByRegex:(NSString *)sourceString regex:(NSString *)pattern withTemplate:(NSString *)templateString
{
    NSString *replacementResult = [sourceString copy];
    NSError *error = nil;
    
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSRange replaceRange = [currentPattern rangeOfFirstMatchInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    
    if (replaceRange.location != NSNotFound) {
        replacementResult = [currentPattern stringByReplacingMatchesInString:[sourceString mutableCopy] options:0
                                                                       range:replaceRange
                                                                withTemplate:templateString];
    }
    
    return replacementResult;
}


- (NSString *)replaceStringByRegex:(NSString *)sourceString regex:(NSString *)pattern withTemplate:(NSString *)templateString
{
    NSString *replacementResult = [sourceString copy];
    NSError *error = nil;
    
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [currentPattern matchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    
    if ([matches count] == 1) {
        NSRange replaceRange = [currentPattern rangeOfFirstMatchInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
        
        if (replaceRange.location != NSNotFound) {
            replacementResult = [currentPattern stringByReplacingMatchesInString:[sourceString mutableCopy] options:0
                                                                           range:replaceRange
                                                                    withTemplate:templateString];
        }
        return replacementResult;
    }
    
    if ([matches count] > 1) {
        replacementResult = [currentPattern stringByReplacingMatchesInString:[replacementResult mutableCopy] options:0
                                                                       range:NSMakeRange(0, sourceString.length) withTemplate:templateString];
        return replacementResult;
    }
    
    return replacementResult;
}


- (NSTextCheckingResult*)matcheFirstByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [currentPattern matchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    if ([matches count] > 0)
        return [matches objectAtIndex:0];
    return nil;
}


- (NSArray*)matchesByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [currentPattern matchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    return matches;
}


- (NSArray*)matchedStringByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    NSArray *matches = [self matchesByRegex:sourceString regex:pattern];
    NSMutableArray *matchString = [[NSMutableArray alloc] init];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *curString = [sourceString substringWithRange:match.range];
        [matchString addObject:curString];
    }
    
    return matchString;
}


- (BOOL)isStartingStringByRegex:(NSString *)sourceString regex:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [currentPattern matchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length)];
    
    for (NSTextCheckingResult *match in matches) {
        if (match.range.location == 0) {
            return YES;
        }
    }
    
    return NO;
}


- (NSString *)stringByReplacingOccurrencesString:(NSString *)sourceString withMap:(NSDictionary *)dicMap removeNonMatches:(BOOL)bRemove
{
    NSMutableString *targetString = [[NSMutableString alloc] initWithString:@""];
    
    for(unsigned int i=0; i<sourceString.length; i++)
    {
        unichar oneChar = [sourceString characterAtIndex:i];
        NSString *keyString = [NSString stringWithCharacters:&oneChar length:1];
        NSString *mappedValue = [dicMap objectForKey:keyString];
        if (mappedValue != nil) {
            [targetString appendString:mappedValue];
        } else {
            if (bRemove == NO) {
                [targetString appendString:keyString];
            }
        }
    }
    
    return targetString;
}


- (BOOL)isAllDigits:(NSString *)sourceString
{
    NSCharacterSet *nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [sourceString rangeOfCharacterFromSet:nonNumbers];
    return r.location == NSNotFound;
}


- (BOOL)isNumeric:(NSString *)sourceString
{
    NSScanner *sc = [NSScanner scannerWithString:sourceString];
    if ([sc scanFloat:NULL]) {
        return [sc isAtEnd];
    }
    return NO;
}


- (BOOL)isNaN:(NSString *)sourceString
{
    if ([self isNumeric:sourceString]) return NO;
    return YES;
}


- (NSString *)getNationalSignificantNumber:(NBPhoneNumber *)phoneNumber
{
    if (phoneNumber.italianLeadingZero) {
        return [NSString stringWithFormat:@"0%@", phoneNumber.nationalNumber];
    }
    
    return [phoneNumber.nationalNumber stringValue];
}


#pragma mark - Initializations -

- (id)init
{
    self = [super init];
    if (self)
    {
        _lockPatternCache = [[NSLock alloc] init];
        _entireStringCacheLock = [[NSLock alloc] init];
        
        [self initRegularExpressionSet];
        [self initNormalizationMappings];
    }
    
    return self;
}


- (void)initRegularExpressionSet
{
    NSString *EXTN_PATTERNS_FOR_PARSING = @"(?:;ext=([0-9０-９٠-٩۰-۹]{1,7})|[  \\t,]*(?:e?xt(?:ensi(?:ó?|ó))?n?|ｅ?ｘｔｎ?|[,xｘX#＃~～]|int|anexo|ｉｎｔ)[:\\.．]?[  \\t,-]*([0-9０-９٠-٩۰-۹]{1,7})#?|[- ]+([0-9０-９٠-٩۰-۹]{1,5})#)$";
    
    NSError *error = nil;
    
    if (!_PLUS_CHARS_PATTERN) {
        _PLUS_CHARS_PATTERN = [self regularExpressionWithPattern:[NSString stringWithFormat:@"[%@]+", NB_PLUS_CHARS] options:0 error:&error];
    }
    
    if (!LEADING_PLUS_CHARS_PATTERN) {
        LEADING_PLUS_CHARS_PATTERN = [NSString stringWithFormat:@"^[%@]+", NB_PLUS_CHARS];
    }
    
    if (!_CAPTURING_DIGIT_PATTERN) {
        _CAPTURING_DIGIT_PATTERN = [self regularExpressionWithPattern:[NSString stringWithFormat:@"([%@])", NB_VALID_DIGITS_STRING] options:0 error:&error];
    }
    
    if (!VALID_START_CHAR_PATTERN) {
        VALID_START_CHAR_PATTERN = [NSString stringWithFormat:@"[%@%@]", NB_PLUS_CHARS, NB_VALID_DIGITS_STRING];
    }
    
    if (!SECOND_NUMBER_START_PATTERN) {
        SECOND_NUMBER_START_PATTERN = @"[\\\\\\/] *x";
    }
    
    if (!_VALID_ALPHA_PHONE_PATTERN) {
        _VALID_ALPHA_PHONE_PATTERN = [self regularExpressionWithPattern:VALID_ALPHA_PHONE_PATTERN_STRING options:0 error:&error];
    }
    
    if (!UNWANTED_END_CHAR_PATTERN) {
        UNWANTED_END_CHAR_PATTERN = [NSString stringWithFormat:@"[^%@%@#]+$", NB_VALID_DIGITS_STRING, VALID_ALPHA];
    }
    
    if (!EXTN_PATTERN) {
        EXTN_PATTERN = [NSString stringWithFormat:@"(?:%@)$", EXTN_PATTERNS_FOR_PARSING];
    }
    
    if (!SEPARATOR_PATTERN) {
        SEPARATOR_PATTERN = [NSString stringWithFormat:@"[%@]+", VALID_PUNCTUATION];
    }
    
    if (!VALID_PHONE_NUMBER_PATTERN) {
        VALID_PHONE_NUMBER_PATTERN = @"^[0-9０-９٠-٩۰-۹]{2}$|^[+＋]*(?:[-x‐-―−ー－-／  ­​⁠　()（）［］.\\[\\]/~⁓∼～*]*[0-9０-９٠-٩۰-۹]){3,}[-x‐-―−ー－-／  ­​⁠　()（）［］.\\[\\]/~⁓∼～*A-Za-z0-9０-９٠-٩۰-۹]*(?:;ext=([0-9０-９٠-٩۰-۹]{1,7})|[  \\t,]*(?:e?xt(?:ensi(?:ó?|ó))?n?|ｅ?ｘｔｎ?|[,xｘ#＃~～]|int|anexo|ｉｎｔ)[:\\.．]?[  \\t,-]*([0-9０-９٠-٩۰-۹]{1,7})#?|[- ]+([0-9０-９٠-٩۰-۹]{1,5})#)?$";
    }
}

- (NSDictionary *)DIGIT_MAPPINGS
{
    if (!DIGIT_MAPPINGS) {
        DIGIT_MAPPINGS = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"0", @"0", @"1", @"1", @"2", @"2", @"3", @"3", @"4", @"4", @"5", @"5", @"6", @"6", @"7", @"7", @"8", @"8", @"9", @"9",
                          // Fullwidth digit 0 to 9
                          @"0", @"\uFF10", @"1", @"\uFF11", @"2", @"\uFF12", @"3", @"\uFF13", @"4", @"\uFF14", @"5", @"\uFF15", @"6", @"\uFF16", @"7", @"\uFF17", @"8", @"\uFF18", @"9", @"\uFF19",
                          // Arabic-indic digit 0 to 9
                          @"0", @"\u0660", @"1", @"\u0661", @"2", @"\u0662", @"3", @"\u0663", @"4", @"\u0664", @"5", @"\u0665", @"6", @"\u0666", @"7", @"\u0667", @"8", @"\u0668", @"9", @"\u0669",
                          // Eastern-Arabic digit 0 to 9
                          @"0", @"\u06F0", @"1", @"\u06F1",  @"2", @"\u06F2", @"3", @"\u06F3", @"4", @"\u06F4", @"5", @"\u06F5", @"6", @"\u06F6", @"7", @"\u06F7", @"8", @"\u06F8", @"9", @"\u06F9", nil];
    }
    return DIGIT_MAPPINGS;
}


- (void)initNormalizationMappings
{
    if (!DIALLABLE_CHAR_MAPPINGS) {
        DIALLABLE_CHAR_MAPPINGS = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"0", @"0", @"1", @"1", @"2", @"2", @"3", @"3", @"4", @"4", @"5", @"5", @"6", @"6", @"7", @"7", @"8", @"8", @"9", @"9",
                                   @"+", @"+", @"*", @"*", nil];
    }
    
    if (!ALPHA_MAPPINGS) {
        ALPHA_MAPPINGS = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"2", @"A", @"2", @"B", @"2", @"C", @"3", @"D", @"3", @"E", @"3", @"F", @"4", @"G", @"4", @"H", @"4", @"I", @"5", @"J",
                          @"5", @"K", @"5", @"L", @"6", @"M", @"6", @"N", @"6", @"O", @"7", @"P", @"7", @"Q", @"7", @"R", @"7", @"S", @"8", @"T",
                          @"8", @"U", @"8", @"V", @"9", @"W", @"9", @"X", @"9", @"Y", @"9", @"Z", nil];
    }
    
    if (!ALL_NORMALIZATION_MAPPINGS) {
        ALL_NORMALIZATION_MAPPINGS = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"0", @"0", @"1", @"1", @"2", @"2", @"3", @"3", @"4", @"4", @"5", @"5", @"6", @"6", @"7", @"7", @"8", @"8", @"9", @"9",
                                      // Fullwidth digit 0 to 9
                                      @"0", @"\uFF10", @"1", @"\uFF11", @"2", @"\uFF12", @"3", @"\uFF13", @"4", @"\uFF14", @"5", @"\uFF15", @"6", @"\uFF16", @"7", @"\uFF17", @"8", @"\uFF18", @"9", @"\uFF19",
                                      // Arabic-indic digit 0 to 9
                                      @"0", @"\u0660", @"1", @"\u0661", @"2", @"\u0662", @"3", @"\u0663", @"4", @"\u0664", @"5", @"\u0665", @"6", @"\u0666", @"7", @"\u0667", @"8", @"\u0668", @"9", @"\u0669",
                                      // Eastern-Arabic digit 0 to 9
                                      @"0", @"\u06F0", @"1", @"\u06F1",  @"2", @"\u06F2", @"3", @"\u06F3", @"4", @"\u06F4", @"5", @"\u06F5", @"6", @"\u06F6", @"7", @"\u06F7", @"8", @"\u06F8", @"9", @"\u06F9",
                                      @"2", @"A", @"2", @"B", @"2", @"C", @"3", @"D", @"3", @"E", @"3", @"F", @"4", @"G", @"4", @"H", @"4", @"I", @"5", @"J",
                                      @"5", @"K", @"5", @"L", @"6", @"M", @"6", @"N", @"6", @"O", @"7", @"P", @"7", @"Q", @"7", @"R", @"7", @"S", @"8", @"T",
                                      @"8", @"U", @"8", @"V", @"9", @"W", @"9", @"X", @"9", @"Y", @"9", @"Z", nil];
    }
    
    if (!ALL_PLUS_NUMBER_GROUPING_SYMBOLS) {
        ALL_PLUS_NUMBER_GROUPING_SYMBOLS = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"0", @"0", @"1", @"1", @"2", @"2", @"3", @"3", @"4", @"4", @"5", @"5", @"6", @"6", @"7", @"7", @"8", @"8", @"9", @"9",
                                            @"A", @"A", @"B", @"B", @"C", @"C", @"D", @"D", @"E", @"E", @"F", @"F", @"G", @"G", @"H", @"H", @"I", @"I", @"J", @"J",
                                            @"K", @"K", @"L", @"L", @"M", @"M", @"N", @"N", @"O", @"O", @"P", @"P", @"Q", @"Q", @"R", @"R", @"S", @"S", @"T", @"T",
                                            @"U", @"U", @"V", @"V", @"W", @"W", @"X", @"X", @"Y", @"Y", @"Z", @"Z", @"A", @"a", @"B", @"b", @"C", @"c", @"D", @"d",
                                            @"E", @"e", @"F", @"f", @"G", @"g", @"H", @"h", @"I", @"i", @"J", @"j", @"K", @"k", @"L", @"l", @"M", @"m", @"N", @"n",
                                            @"O", @"o", @"P", @"p", @"Q", @"q", @"R", @"r", @"S", @"s", @"T", @"t", @"U", @"u", @"V", @"v", @"W", @"w", @"X", @"x",
                                            @"Y", @"y", @"Z", @"z", @"-", @"-", @"-", @"\uFF0D", @"-", @"\u2010", @"-", @"\u2011", @"-", @"\u2012", @"-", @"\u2013", @"-", @"\u2014", @"-", @"\u2015",
                                            @"-", @"\u2212", @"/", @"/", @"/", @"\uFF0F", @" ", @" ", @" ", @"\u3000", @" ", @"\u2060", @".", @".", @".", @"\uFF0E", nil];
    }
}





#pragma mark - Metadata manager (phonenumberutil.js) functions -
/**
 * Attempts to extract a possible number from the string passed in. This
 * currently strips all leading characters that cannot be used to start a phone
 * number. Characters that can be used to start a phone number are defined in
 * the VALID_START_CHAR_PATTERN. If none of these characters are found in the
 * number passed in, an empty string is returned. This function also attempts to
 * strip off any alternative extensions or endings if two or more are present,
 * such as in the case of: (530) 583-6985 x302/x2303. The second extension here
 * makes this actually two phone numbers, (530) 583-6985 x302 and (530) 583-6985
 * x2303. We remove the second extension so that the first number is parsed
 * correctly.
 *
 * @param {string} number the string that might contain a phone number.
 * @return {string} the number, stripped of any non-phone-number prefix (such as
 *     'Tel:') or an empty string if no character used to start phone numbers
 *     (such as + or any digit) is found in the number.
 */
- (NSString *)extractPossibleNumber:(NSString *)number
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    number = [helper normalizeNonBreakingSpace:number];
    
    NSString *possibleNumber = @"";
    int start = [self stringPositionByRegex:number regex:VALID_START_CHAR_PATTERN];
    
    if (start >= 0)
    {
        possibleNumber = [number substringFromIndex:start];
        // Remove trailing non-alpha non-numerical characters.
        possibleNumber = [self replaceStringByRegex:possibleNumber regex:UNWANTED_END_CHAR_PATTERN withTemplate:@""];
        
        // Check for extra numbers at the end.
        int secondNumberStart = [self stringPositionByRegex:number regex:SECOND_NUMBER_START_PATTERN];
        if (secondNumberStart > 0)
        {
            possibleNumber = [possibleNumber substringWithRange:NSMakeRange(0, secondNumberStart - 1)];
        }
    }
    else
    {
        possibleNumber = @"";
    }
    
    return possibleNumber;
}


/**
 * Checks to see if the string of characters could possibly be a phone number at
 * all. At the moment, checks to see that the string begins with at least 2
 * digits, ignoring any punctuation commonly found in phone numbers. This method
 * does not require the number to be normalized in advance - but does assume
 * that leading non-number symbols have been removed, such as by the method
 * extractPossibleNumber.
 *
 * @param {string} number string to be checked for viability as a phone number.
 * @return {boolean} NO if the number could be a phone number of some sort,
 *     otherwise NO.
 */
- (BOOL)isViablePhoneNumber:(NSString *)phoneNumber
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    phoneNumber = [helper normalizeNonBreakingSpace:phoneNumber];
    
    if (phoneNumber.length < MIN_LENGTH_FOR_NSN_)
    {
        return NO;
    }
    
    return [self matchesEntirely:VALID_PHONE_NUMBER_PATTERN string:phoneNumber];
}


/**
 * Normalizes a string of characters representing a phone number. This performs
 * the following conversions:
 *   Punctuation is stripped.
 *   For ALPHA/VANITY numbers:
 *   Letters are converted to their numeric representation on a telephone
 *       keypad. The keypad used here is the one defined in ITU Recommendation
 *       E.161. This is only done if there are 3 or more letters in the number,
 *       to lessen the risk that such letters are typos.
 *   For other numbers:
 *   Wide-ascii digits are converted to normal ASCII (European) digits.
 *   Arabic-Indic numerals are converted to European numerals.
 *   Spurious alpha characters are stripped.
 *
 * @param {string} number a string of characters representing a phone number.
 * @return {string} the normalized string version of the phone number.
 */
- (NSString *)normalizePhoneNumber:(NSString *)number
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    number = [helper normalizeNonBreakingSpace:number];
    
    if ([self matchesEntirely:VALID_ALPHA_PHONE_PATTERN_STRING string:number])
    {
        return [self normalizeHelper:number normalizationReplacements:ALL_NORMALIZATION_MAPPINGS removeNonMatches:true];
    }
    else
    {
        return [self normalizeDigitsOnly:number];
    }
    
    return nil;
}


/**
 * Normalizes a string of characters representing a phone number. This is a
 * wrapper for normalize(String number) but does in-place normalization of the
 * StringBuffer provided.
 *
 * @param {!goog.string.StringBuffer} number a StringBuffer of characters
 *     representing a phone number that will be normalized in place.
 * @private
 */

- (void)normalizeSB:(NSString **)number
{
    if (number == NULL) {
        return;
    }
    
    (*number) = [self normalizePhoneNumber:(*number)];
}


/**
 * Normalizes a string of characters representing a phone number. This converts
 * wide-ascii and arabic-indic numerals to European numerals, and strips
 * punctuation and alpha characters.
 *
 * @param {string} number a string of characters representing a phone number.
 * @return {string} the normalized string version of the phone number.
 */
- (NSString *)normalizeDigitsOnly:(NSString *)number
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    number = [helper normalizeNonBreakingSpace:number];
    
    return [self stringByReplacingOccurrencesString:number withMap:self.DIGIT_MAPPINGS removeNonMatches:YES];
}


/**
 * Converts all alpha characters in a number to their respective digits on a
 * keypad, but retains existing formatting. Also converts wide-ascii digits to
 * normal ascii digits, and converts Arabic-Indic numerals to European numerals.
 *
 * @param {string} number a string of characters representing a phone number.
 * @return {string} the normalized string version of the phone number.
 */
- (NSString *)convertAlphaCharactersInNumber:(NSString *)number
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    number = [helper normalizeNonBreakingSpace:number];
    return [self stringByReplacingOccurrencesString:number withMap:ALL_NORMALIZATION_MAPPINGS removeNonMatches:NO];
}


/**
 * Gets the length of the geographical area code from the
 * {@code national_number} field of the PhoneNumber object passed in, so that
 * clients could use it to split a national significant number into geographical
 * area code and subscriber number. It works in such a way that the resultant
 * subscriber number should be diallable, at least on some devices. An example
 * of how this could be used:
 *
 * <pre>
 * var phoneUtil = getInstance();
 * var number = phoneUtil.parse('16502530000', 'US');
 * var nationalSignificantNumber =
 *     phoneUtil.getNationalSignificantNumber(number);
 * var areaCode;
 * var subscriberNumber;
 *
 * var areaCodeLength = phoneUtil.getLengthOfGeographicalAreaCode(number);
 * if (areaCodeLength > 0) {
 *   areaCode = nationalSignificantNumber.substring(0, areaCodeLength);
 *   subscriberNumber = nationalSignificantNumber.substring(areaCodeLength);
 * } else {
 *   areaCode = '';
 *   subscriberNumber = nationalSignificantNumber;
 * }
 * </pre>
 *
 * N.B.: area code is a very ambiguous concept, so the I18N team generally
 * recommends against using it for most purposes, but recommends using the more
 * general {@code national_number} instead. Read the following carefully before
 * deciding to use this method:
 * <ul>
 *  <li> geographical area codes change over time, and this method honors those
 *    changes; therefore, it doesn't guarantee the stability of the result it
 *    produces.
 *  <li> subscriber numbers may not be diallable from all devices (notably
 *    mobile devices, which typically requires the full national_number to be
 *    dialled in most regions).
 *  <li> most non-geographical numbers have no area codes, including numbers
 *    from non-geographical entities.
 *  <li> some geographical numbers have no area codes.
 * </ul>
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the PhoneNumber object for
 *     which clients want to know the length of the area code.
 * @return {number} the length of area code of the PhoneNumber object passed in.
 */
- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber*)phoneNumber error:(NSError **)error
{
    int res = 0;
    @try {
        res = [self getLengthOfGeographicalAreaCode:phoneNumber];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
        }
    }
    return res;
}


- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber*)phoneNumber
{
    NSString *regionCode = [self getRegionCodeForNumber:phoneNumber];
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadata = [helper getMetadataForRegion:regionCode];
    
    if (metadata == nil) {
        return 0;
    }
    // If a country doesn't use a national prefix, and this number doesn't have
    // an Italian leading zero, we assume it is a closed dialling plan with no
    // area codes.
    if (metadata.nationalPrefix == nil && phoneNumber.italianLeadingZero == NO) {
        return 0;
    }
    
    if ([self isNumberGeographical:phoneNumber] == NO) {
        return 0;
    }
    
    return [self getLengthOfNationalDestinationCode:phoneNumber];
}


/**
 * Gets the length of the national destination code (NDC) from the PhoneNumber
 * object passed in, so that clients could use it to split a national
 * significant number into NDC and subscriber number. The NDC of a phone number
 * is normally the first group of digit(s) right after the country calling code
 * when the number is formatted in the international format, if there is a
 * subscriber number part that follows. An example of how this could be used:
 *
 * <pre>
 * var phoneUtil = getInstance();
 * var number = phoneUtil.parse('18002530000', 'US');
 * var nationalSignificantNumber =
 *     phoneUtil.getNationalSignificantNumber(number);
 * var nationalDestinationCode;
 * var subscriberNumber;
 *
 * var nationalDestinationCodeLength =
 *     phoneUtil.getLengthOfNationalDestinationCode(number);
 * if (nationalDestinationCodeLength > 0) {
 *   nationalDestinationCode =
 *       nationalSignificantNumber.substring(0, nationalDestinationCodeLength);
 *   subscriberNumber =
 *       nationalSignificantNumber.substring(nationalDestinationCodeLength);
 * } else {
 *   nationalDestinationCode = '';
 *   subscriberNumber = nationalSignificantNumber;
 * }
 * </pre>
 *
 * Refer to the unittests to see the difference between this function and
 * {@link #getLengthOfGeographicalAreaCode}.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the PhoneNumber object for
 *     which clients want to know the length of the NDC.
 * @return {number} the length of NDC of the PhoneNumber object passed in.
 */
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber*)phoneNumber error:(NSError **)error
{
    int res = 0;
    
    @try {
        res = [self getLengthOfNationalDestinationCode:phoneNumber];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
        }
    }
    
    return res;
}


- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber*)phoneNumber
{
    NBPhoneNumber *copiedProto = nil;
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    if ([NBMetadataHelper hasValue:phoneNumber.extension]) {
        copiedProto = [phoneNumber copy];
        copiedProto.extension = nil;
    } else {
        copiedProto = phoneNumber;
    }
    
    NSString *nationalSignificantNumber = [self format:copiedProto numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
    NSMutableArray *numberGroups = [[self componentsSeparatedByRegex:nationalSignificantNumber regex:NON_DIGITS_PATTERN] mutableCopy];
    
    // The pattern will start with '+COUNTRY_CODE ' so the first group will always
    // be the empty string (before the + symbol) and the second group will be the
    // country calling code. The third group will be area code if it is not the
    // last group.
    // NOTE: On IE the first group that is supposed to be the empty string does
    // not appear in the array of number groups... so make the result on non-IE
    // browsers to be that of IE.
    if ([numberGroups count] > 0 && ((NSString *)[numberGroups objectAtIndex:0]).length <= 0) {
        [numberGroups removeObjectAtIndex:0];
    }
    
    if ([numberGroups count] <= 2) {
        return 0;
    }
    
    NSArray *regionCodes = [helper regionCodeFromCountryCode:phoneNumber.countryCode];
    BOOL isExists = NO;
    
    for (NSString *regCode in regionCodes)
    {
        if ([regCode isEqualToString:@"AR"])
        {
            isExists = YES;
            break;
        }
    }
    
    if (isExists && [self getNumberType:phoneNumber] == NBEPhoneNumberTypeMOBILE)
    {
        // Argentinian mobile numbers, when formatted in the international format,
        // are in the form of +54 9 NDC XXXX.... As a result, we take the length of
        // the third group (NDC) and add 1 for the digit 9, which also forms part of
        // the national significant number.
        //
        // TODO: Investigate the possibility of better modeling the metadata to make
        // it easier to obtain the NDC.
        return (int)((NSString *)[numberGroups objectAtIndex:2]).length + 1;
    }
    
    return (int)((NSString *)[numberGroups objectAtIndex:1]).length;
}


/**
 * Normalizes a string of characters representing a phone number by replacing
 * all characters found in the accompanying map with the values therein, and
 * stripping all other characters if removeNonMatches is NO.
 *
 * @param {string} number a string of characters representing a phone number.
 * @param {!Object.<string, string>} normalizationReplacements a mapping of
 *     characters to what they should be replaced by in the normalized version
 *     of the phone number.
 * @param {boolean} removeNonMatches indicates whether characters that are not
 *     able to be replaced should be stripped from the number. If this is NO,
 *     they will be left unchanged in the number.
 * @return {string} the normalized string version of the phone number.
 * @private
 */
- (NSString *)normalizeHelper:(NSString *)sourceString normalizationReplacements:(NSDictionary*)normalizationReplacements
             removeNonMatches:(BOOL)removeNonMatches
{
    NSMutableString *normalizedNumber = [[NSMutableString alloc] init];
    unichar character = 0;
    NSString *newDigit = @"";
    unsigned int numberLength = (unsigned int)sourceString.length;
    
    for (unsigned int i = 0; i<numberLength; ++i)
    {
        character = [sourceString characterAtIndex:i];
        newDigit = [normalizationReplacements objectForKey:[[NSString stringWithFormat: @"%C", character] uppercaseString]];
        if (newDigit != nil)
        {
            [normalizedNumber appendString:newDigit];
        }
        else if (removeNonMatches == NO)
        {
            [normalizedNumber appendString:[NSString stringWithFormat: @"%C", character]];
        }
        // If neither of the above are NO, we remove this character.
        
        //NSLog(@"[%@]", normalizedNumber);
    }
    
    return normalizedNumber;
}


/**
 * Helper function to check if the national prefix formatting rule has the first
 * group only, i.e., does not start with the national prefix.
 *
 * @param {string} nationalPrefixFormattingRule The formatting rule for the
 *     national prefix.
 * @return {boolean} NO if the national prefix formatting rule has the first
 *     group only.
 */
- (BOOL)formattingRuleHasFirstGroupOnly:(NSString *)nationalPrefixFormattingRule
{
    BOOL hasFound = NO;
    if ([self stringPositionByRegex:nationalPrefixFormattingRule regex:FIRST_GROUP_ONLY_PREFIX_PATTERN] >= 0)
    {
        hasFound = YES;
    }
    
    return (([nationalPrefixFormattingRule length] == 0) || hasFound);
}


/**
 * Tests whether a phone number has a geographical association. It checks if
 * the number is associated to a certain region in the country where it belongs
 * to. Note that this doesn't verify if the number is actually in use.
 *
 * @param {i18n.phonenumbers.PhoneNumber} phoneNumber The phone number to test.
 * @return {boolean} NO if the phone number has a geographical association.
 * @private
 */
- (BOOL)isNumberGeographical:(NBPhoneNumber*)phoneNumber
{
    NBEPhoneNumberType numberType = [self getNumberType:phoneNumber];
    // TODO: Include mobile phone numbers from countries like Indonesia, which
    // has some mobile numbers that are geographical.
    return numberType == NBEPhoneNumberTypeFIXED_LINE || numberType == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE;
}


/**
 * Helper function to check region code is not unknown or nil.
 *
 * @param {?string} regionCode the ISO 3166-1 two-letter region code.
 * @return {boolean} NO if region code is valid.
 * @private
 */
- (BOOL)isValidRegionCode:(NSString *)regionCode
{
    // In Java we check whether the regionCode is contained in supportedRegions
    // that is built out of all the values of countryCallingCodeToRegionCodeMap
    // (countryCodeToRegionCodeMap in JS) minus REGION_CODE_FOR_NON_GEO_ENTITY.
    // In JS we check whether the regionCode is contained in the keys of
    // countryToMetadata but since for non-geographical country calling codes
    // (e.g. +800) we use the country calling codes instead of the region code as
    // key in the map we have to make sure regionCode is not a number to prevent
    // returning NO for non-geographical country calling codes.
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    return [NBMetadataHelper hasValue:regionCode] && [self isNaN:regionCode] && [helper getMetadataForRegion:regionCode.uppercaseString] != nil;
}


/**
 * Helper function to check the country calling code is valid.
 *
 * @param {number} countryCallingCode the country calling code.
 * @return {boolean} NO if country calling code code is valid.
 * @private
 */
- (BOOL)hasValidCountryCallingCode:(NSNumber*)countryCallingCode
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    id res = [helper regionCodeFromCountryCode:countryCallingCode];
    if (res != nil) {
        return YES;
    }
    
    return NO;
}


/**
 * Formats a phone number in the specified format using default rules. Note that
 * this does not promise to produce a phone number that the user can dial from
 * where they are - although we do format in either 'national' or
 * 'international' format depending on what the client asks for, we do not
 * currently support a more abbreviated format, such as for users in the same
 * 'area' who could potentially dial the number without area code. Note that if
 * the phone number has a country calling code of 0 or an otherwise invalid
 * country calling code, we cannot work out which formatting rules to apply so
 * we return the national significant number with no formatting applied.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @return {string} the formatted phone number.
 */
- (NSString *)format:(NBPhoneNumber*)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat error:(NSError**)error
{
    NSString *res = nil;
    @try {
        res = [self format:phoneNumber numberFormat:numberFormat];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}

- (NSString *)format:(NBPhoneNumber*)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    if ([phoneNumber.nationalNumber isEqualToNumber:@0] && [NBMetadataHelper hasValue:phoneNumber.rawInput]) {
        // Unparseable numbers that kept their raw input just use that.
        // This is the only case where a number can be formatted as E164 without a
        // leading '+' symbol (but the original number wasn't parseable anyway).
        // TODO: Consider removing the 'if' above so that unparseable strings
        // without raw input format to the empty string instead of "+00"
        /** @type {string} */
        NSString *rawInput = phoneNumber.rawInput;
        if ([NBMetadataHelper hasValue:rawInput]) {
            return rawInput;
        }
    }
    
    NSNumber *countryCallingCode = phoneNumber.countryCode;
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:phoneNumber];
    
    if (numberFormat == NBEPhoneNumberFormatE164)
    {
        // Early exit for E164 case (even if the country calling code is invalid)
        // since no formatting of the national number needs to be applied.
        // Extensions are not formatted.
        return [self prefixNumberWithCountryCallingCode:countryCallingCode phoneNumberFormat:NBEPhoneNumberFormatE164
                                formattedNationalNumber:nationalSignificantNumber formattedExtension:@""];
    }
    
    if ([self hasValidCountryCallingCode:countryCallingCode] == NO)
    {
        return nationalSignificantNumber;
    }
    
    // Note getRegionCodeForCountryCode() is used because formatting information
    // for regions which share a country calling code is contained by only one
    // region for performance reasons. For example, for NANPA regions it will be
    // contained in the metadata for US.
    NSArray *regionCodeArray = [helper regionCodeFromCountryCode:countryCallingCode];
    NSString *regionCode = [regionCodeArray objectAtIndex:0];
    
    // Metadata cannot be nil because the country calling code is valid (which
    // means that the region code cannot be ZZ and must be one of our supported
    // region codes).
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCallingCode regionCode:regionCode];
    NSString *formattedExtension = [self maybeGetFormattedExtension:phoneNumber metadata:metadata numberFormat:numberFormat];
    NSString *formattedNationalNumber = [self formatNsn:nationalSignificantNumber metadata:metadata phoneNumberFormat:numberFormat carrierCode:nil];
    
    return [self prefixNumberWithCountryCallingCode:countryCallingCode phoneNumberFormat:numberFormat
                            formattedNationalNumber:formattedNationalNumber formattedExtension:formattedExtension];
}


/**
 * Formats a phone number in the specified format using client-defined
 * formatting rules. Note that if the phone number has a country calling code of
 * zero or an otherwise invalid country calling code, we cannot work out things
 * like whether there should be a national prefix applied, or how to format
 * extensions, so we return the national significant number with no formatting
 * applied.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone  number to be
 *     formatted.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @param {Array.<i18n.phonenumbers.NumberFormat>} userDefinedFormats formatting
 *     rules specified by clients.
 * @return {string} the formatted phone number.
 */
- (NSString *)formatByPattern:(NBPhoneNumber*)number numberFormat:(NBEPhoneNumberFormat)numberFormat userDefinedFormats:(NSArray*)userDefinedFormats error:(NSError**)error
{
    NSString *res = nil;
    @try {
        res = [self formatByPattern:number numberFormat:numberFormat userDefinedFormats:userDefinedFormats];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}


- (NSString *)formatByPattern:(NBPhoneNumber*)number numberFormat:(NBEPhoneNumberFormat)numberFormat userDefinedFormats:(NSArray*)userDefinedFormats
{
    NSNumber *countryCallingCode = number.countryCode;
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:number];
    
    if ([self hasValidCountryCallingCode:countryCallingCode] == NO) {
        return nationalSignificantNumber;
    }
    
    // Note getRegionCodeForCountryCode() is used because formatting information
    // for regions which share a country calling code is contained by only one
    // region for performance reasons. For example, for NANPA regions it will be
    // contained in the metadata for US.
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *regionCodes = [helper regionCodeFromCountryCode:countryCallingCode];
    NSString *regionCode = nil;
    if (regionCodes != nil && regionCodes.count > 0) {
        regionCode = [regionCodes objectAtIndex:0];
    }
    
    // Metadata cannot be nil because the country calling code is valid
    /** @type {i18n.phonenumbers.PhoneMetadata} */
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCallingCode regionCode:regionCode];
    
    NSString *formattedNumber = @"";
    NBNumberFormat *formattingPattern = [self chooseFormattingPatternForNumber:userDefinedFormats
                                                                nationalNumber:nationalSignificantNumber];
    
    if (formattingPattern == nil) {
        // If no pattern above is matched, we format the number as a whole.
        formattedNumber = nationalSignificantNumber;
    } else {
        // Before we do a replacement of the national prefix pattern $NP with the
        // national prefix, we need to copy the rule so that subsequent replacements
        // for different numbers have the appropriate national prefix.
        NBNumberFormat *numFormatCopy = [formattingPattern copy];
        NSString *nationalPrefixFormattingRule = formattingPattern.nationalPrefixFormattingRule;
        
        if (nationalPrefixFormattingRule.length > 0) {
            NSString *nationalPrefix = metadata.nationalPrefix;
            if (nationalPrefix.length > 0) {
                // Replace $NP with national prefix and $FG with the first group ($1).
                nationalPrefixFormattingRule = [self replaceStringByRegex:nationalPrefixFormattingRule
                                                                    regex:NP_PATTERN withTemplate:nationalPrefix];
                nationalPrefixFormattingRule = [self replaceStringByRegex:nationalPrefixFormattingRule
                                                                    regex:FG_PATTERN withTemplate:@"\\$1"];
                numFormatCopy.nationalPrefixFormattingRule = nationalPrefixFormattingRule;
            } else {
                // We don't want to have a rule for how to format the national prefix if
                // there isn't one.
                numFormatCopy.nationalPrefixFormattingRule = @"";
            }
        }
        
        formattedNumber = [self formatNsnUsingPattern:nationalSignificantNumber
                                    formattingPattern:numFormatCopy numberFormat:numberFormat carrierCode:nil];
    }
    
    NSString *formattedExtension = [self maybeGetFormattedExtension:number metadata:metadata numberFormat:numberFormat];
    
    //NSLog(@"!@#  prefixNumberWithCountryCallingCode called [%@]", formattedExtension);
    return [self prefixNumberWithCountryCallingCode:countryCallingCode phoneNumberFormat:numberFormat
                            formattedNationalNumber:formattedNumber formattedExtension:formattedExtension];
}


/**
 * Formats a phone number in national format for dialing using the carrier as
 * specified in the {@code carrierCode}. The {@code carrierCode} will always be
 * used regardless of whether the phone number already has a preferred domestic
 * carrier code stored. If {@code carrierCode} contains an empty string, returns
 * the number in national format without any carrier code.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {string} carrierCode the carrier selection code to be used.
 * @return {string} the formatted phone number in national format for dialing
 *     using the carrier as specified in the {@code carrierCode}.
 */
- (NSString *)formatNationalNumberWithCarrierCode:(NBPhoneNumber*)number carrierCode:(NSString *)carrierCode error:(NSError **)error
{
    NSString *res = nil;
    @try {
        res = [self formatNationalNumberWithCarrierCode:number carrierCode:carrierCode];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
        }
    }
    return res;
}


- (NSString *)formatNationalNumberWithCarrierCode:(NBPhoneNumber*)number carrierCode:(NSString *)carrierCode
{
    NSNumber *countryCallingCode = number.countryCode;
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:number];
    
    if ([self hasValidCountryCallingCode:countryCallingCode] == NO) {
        return nationalSignificantNumber;
    }
    
    // Note getRegionCodeForCountryCode() is used because formatting information
    // for regions which share a country calling code is contained by only one
    // region for performance reasons. For example, for NANPA regions it will be
    // contained in the metadata for US.
    NSString *regionCode = [self getRegionCodeForCountryCode:countryCallingCode];
    // Metadata cannot be nil because the country calling code is valid.
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCallingCode regionCode:regionCode];
    NSString *formattedExtension = [self maybeGetFormattedExtension:number metadata:metadata numberFormat:NBEPhoneNumberFormatNATIONAL];
    NSString *formattedNationalNumber = [self formatNsn:nationalSignificantNumber metadata:metadata
                                      phoneNumberFormat:NBEPhoneNumberFormatNATIONAL carrierCode:carrierCode];
    return [self prefixNumberWithCountryCallingCode:countryCallingCode phoneNumberFormat:NBEPhoneNumberFormatNATIONAL
                            formattedNationalNumber:formattedNationalNumber formattedExtension:formattedExtension];
}


/**
 * @param {number} countryCallingCode
 * @param {?string} regionCode
 * @return {i18n.phonenumbers.PhoneMetadata}
 * @private
 */
- (NBPhoneMetaData*)getMetadataForRegionOrCallingCode:(NSNumber*)countryCallingCode regionCode:(NSString *)regionCode
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    return [NB_REGION_CODE_FOR_NON_GEO_ENTITY isEqualToString:regionCode] ?
    [helper getMetadataForNonGeographicalRegion:countryCallingCode] : [helper getMetadataForRegion:regionCode];
}


/**
 * Formats a phone number in national format for dialing using the carrier as
 * specified in the preferred_domestic_carrier_code field of the PhoneNumber
 * object passed in. If that is missing, use the {@code fallbackCarrierCode}
 * passed in instead. If there is no {@code preferred_domestic_carrier_code},
 * and the {@code fallbackCarrierCode} contains an empty string, return the
 * number in national format without any carrier code.
 *
 * <p>Use {@link #formatNationalNumberWithCarrierCode} instead if the carrier
 * code passed in should take precedence over the number's
 * {@code preferred_domestic_carrier_code} when formatting.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {string} fallbackCarrierCode the carrier selection code to be used, if
 *     none is found in the phone number itself.
 * @return {string} the formatted phone number in national format for dialing
 *     using the number's preferred_domestic_carrier_code, or the
 *     {@code fallbackCarrierCode} passed in if none is found.
 */
- (NSString *)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber*)number
                                       fallbackCarrierCode:(NSString *)fallbackCarrierCode error:(NSError **)error
{
    NSString *res = nil;
    @try {
        res = [self formatNationalNumberWithCarrierCode:number carrierCode:fallbackCarrierCode];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
        }
    }
    
    return res;
}


- (NSString *)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber*)number fallbackCarrierCode:(NSString *)fallbackCarrierCode
{
    NSString *domesticCarrierCode = number.preferredDomesticCarrierCode != nil ? number.preferredDomesticCarrierCode : fallbackCarrierCode;
    return [self formatNationalNumberWithCarrierCode:number carrierCode:domesticCarrierCode];
}


/**
 * Returns a number formatted in such a way that it can be dialed from a mobile
 * phone in a specific region. If the number cannot be reached from the region
 * (e.g. some countries block toll-free numbers from being called outside of the
 * country), the method returns an empty string.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {string} regionCallingFrom the region where the call is being placed.
 * @param {boolean} withFormatting whether the number should be returned with
 *     formatting symbols, such as spaces and dashes.
 * @return {string} the formatted phone number.
 */
- (NSString *)formatNumberForMobileDialing:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom withFormatting:(BOOL)withFormatting
                                     error:(NSError**)error
{
    NSString *res = nil;
    @try {
        res = [self formatNumberForMobileDialing:number regionCallingFrom:regionCallingFrom withFormatting:withFormatting];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}


- (NSString *)formatNumberForMobileDialing:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom withFormatting:(BOOL)withFormatting
{
    NSNumber *countryCallingCode = number.countryCode;
    
    if ([self hasValidCountryCallingCode:countryCallingCode] == NO) {
        return [NBMetadataHelper hasValue:number.rawInput] ? number.rawInput : @"";
    }
    
    NSString *formattedNumber = @"";
    // Clear the extension, as that part cannot normally be dialed together with
    // the main number.
    NBPhoneNumber *numberNoExt = [number copy];
    numberNoExt.extension = @"";
    
    NSString *regionCode = [self getRegionCodeForCountryCode:countryCallingCode];
    if ([regionCallingFrom isEqualToString:regionCode]) {
        NBEPhoneNumberType numberType = [self getNumberType:numberNoExt];
        BOOL isFixedLineOrMobile = (numberType == NBEPhoneNumberTypeFIXED_LINE) || (numberType == NBEPhoneNumberTypeMOBILE) ||
        (numberType == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE);
        // Carrier codes may be needed in some countries. We handle this here.
        if ([regionCode isEqualToString:@"CO"] && numberType == NBEPhoneNumberTypeFIXED_LINE) {
            formattedNumber = [self formatNationalNumberWithCarrierCode:numberNoExt
                                                            carrierCode:COLOMBIA_MOBILE_TO_FIXED_LINE_PREFIX];
        } else if ([regionCode isEqualToString:@"BR"] && isFixedLineOrMobile) {
            formattedNumber = [NBMetadataHelper hasValue:numberNoExt.preferredDomesticCarrierCode] ?
            [self formatNationalNumberWithPreferredCarrierCode:numberNoExt fallbackCarrierCode:@""] : @"";
            // Brazilian fixed line and mobile numbers need to be dialed with a
            // carrier code when called within Brazil. Without that, most of the
            // carriers won't connect the call. Because of that, we return an
            // empty string here.
        } else {
            // For NANPA countries, non-geographical countries, and Mexican fixed
            // line and mobile numbers, we output international format for numbersi
            // that can be dialed internationally as that always works.
            if ((countryCallingCode.unsignedIntegerValue == NANPA_COUNTRY_CODE_ ||
                 [regionCode isEqualToString:NB_REGION_CODE_FOR_NON_GEO_ENTITY] ||
                 // MX fixed line and mobile numbers should always be formatted in
                 // international format, even when dialed within MX. For national
                 // format to work, a carrier code needs to be used, and the correct
                 // carrier code depends on if the caller and callee are from the
                 // same local area. It is trickier to get that to work correctly than
                 // using international format, which is tested to work fine on all
                 // carriers.
                 ([regionCode isEqualToString:@"MX"] && isFixedLineOrMobile)) && [self canBeInternationallyDialled:numberNoExt]) {
                formattedNumber = [self format:numberNoExt numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
            } else {
                formattedNumber = [self format:numberNoExt numberFormat:NBEPhoneNumberFormatNATIONAL];
            }
        }
    } else if ([self canBeInternationallyDialled:numberNoExt]) {
        return withFormatting ? [self format:numberNoExt numberFormat:NBEPhoneNumberFormatINTERNATIONAL] :
            [self format:numberNoExt numberFormat:NBEPhoneNumberFormatE164];
    }
    
    return withFormatting ?
        formattedNumber : [self normalizeHelper:formattedNumber normalizationReplacements:DIALLABLE_CHAR_MAPPINGS removeNonMatches:YES];
}


/**
 * Formats a phone number for out-of-country dialing purposes. If no
 * regionCallingFrom is supplied, we format the number in its INTERNATIONAL
 * format. If the country calling code is the same as that of the region where
 * the number is from, then NATIONAL formatting will be applied.
 *
 * <p>If the number itself has a country calling code of zero or an otherwise
 * invalid country calling code, then we return the number with no formatting
 * applied.
 *
 * <p>Note this function takes care of the case for calling inside of NANPA and
 * between Russia and Kazakhstan (who share the same country calling code). In
 * those cases, no international prefix is used. For regions which have multiple
 * international prefixes, the number in its INTERNATIONAL format will be
 * returned instead.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {string} regionCallingFrom the region where the call is being placed.
 * @return {string} the formatted phone number.
 */
- (NSString *)formatOutOfCountryCallingNumber:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom error:(NSError**)error
{
    NSString *res = nil;
    @try {
        res = [self formatOutOfCountryCallingNumber:number regionCallingFrom:regionCallingFrom];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    
    return res;
}

- (NSString *)formatOutOfCountryCallingNumber:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom
{
    if ([self isValidRegionCode:regionCallingFrom] == NO) {
        return [self format:number numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
    }
    
    NSNumber *countryCallingCode = [number.countryCode copy];
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:number];
    
    if ([self hasValidCountryCallingCode:countryCallingCode] == NO) {
        return nationalSignificantNumber;
    }
    
    if (countryCallingCode.unsignedIntegerValue == NANPA_COUNTRY_CODE_) {
        if ([self isNANPACountry:regionCallingFrom]) {
            // For NANPA regions, return the national format for these regions but
            // prefix it with the country calling code.
            return [NSString stringWithFormat:@"%@ %@", countryCallingCode, [self format:number numberFormat:NBEPhoneNumberFormatNATIONAL]];
        }
    } else if ([countryCallingCode isEqualToNumber:[self getCountryCodeForValidRegion:regionCallingFrom error:nil]]) {
        // If regions share a country calling code, the country calling code need
        // not be dialled. This also applies when dialling within a region, so this
        // if clause covers both these cases. Technically this is the case for
        // dialling from La Reunion to other overseas departments of France (French
        // Guiana, Martinique, Guadeloupe), but not vice versa - so we don't cover
        // this edge case for now and for those cases return the version including
        // country calling code. Details here:
        // http://www.petitfute.com/voyage/225-info-pratiques-reunion
        return [self format:number numberFormat:NBEPhoneNumberFormatNATIONAL];
    }
    
    // Metadata cannot be nil because we checked 'isValidRegionCode()' above.
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadataForRegionCallingFrom = [helper getMetadataForRegion:regionCallingFrom];
    NSString *internationalPrefix = metadataForRegionCallingFrom.internationalPrefix;
    
    // For regions that have multiple international prefixes, the international
    // format of the number is returned, unless there is a preferred international
    // prefix.
    NSString *internationalPrefixForFormatting = @"";
    
    if ([self matchesEntirely:UNIQUE_INTERNATIONAL_PREFIX string:internationalPrefix]) {
        internationalPrefixForFormatting = internationalPrefix;
    } else if ([NBMetadataHelper hasValue:metadataForRegionCallingFrom.preferredInternationalPrefix]) {
        internationalPrefixForFormatting = metadataForRegionCallingFrom.preferredInternationalPrefix;
    }
    
    NSString *regionCode = [self getRegionCodeForCountryCode:countryCallingCode];
    // Metadata cannot be nil because the country calling code is valid.
    NBPhoneMetaData *metadataForRegion = [self getMetadataForRegionOrCallingCode:countryCallingCode regionCode:regionCode];
    NSString *formattedNationalNumber = [self formatNsn:nationalSignificantNumber metadata:metadataForRegion
                                      phoneNumberFormat:NBEPhoneNumberFormatINTERNATIONAL carrierCode:nil];
    NSString *formattedExtension = [self maybeGetFormattedExtension:number metadata:metadataForRegion numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
    
    NSString *hasLenth = [NSString stringWithFormat:@"%@ %@ %@%@", internationalPrefixForFormatting, countryCallingCode, formattedNationalNumber, formattedExtension];
    NSString *hasNotLength = [self prefixNumberWithCountryCallingCode:countryCallingCode phoneNumberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                              formattedNationalNumber:formattedNationalNumber formattedExtension:formattedExtension];
    
    return internationalPrefixForFormatting.length > 0 ? hasLenth:hasNotLength;
}


/**
 * A helper function that is used by format and formatByPattern.
 *
 * @param {number} countryCallingCode the country calling code.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @param {string} formattedNationalNumber
 * @param {string} formattedExtension
 * @return {string} the formatted phone number.
 * @private
 */
- (NSString *)prefixNumberWithCountryCallingCode:(NSNumber*)countryCallingCode phoneNumberFormat:(NBEPhoneNumberFormat)numberFormat
                         formattedNationalNumber:(NSString *)formattedNationalNumber
                              formattedExtension:(NSString *)formattedExtension
{
    switch (numberFormat)
    {
        case NBEPhoneNumberFormatE164:
            return [NSString stringWithFormat:@"+%@%@%@", countryCallingCode, formattedNationalNumber, formattedExtension];
        case NBEPhoneNumberFormatINTERNATIONAL:
            return [NSString stringWithFormat:@"+%@ %@%@", countryCallingCode, formattedNationalNumber, formattedExtension];
        case NBEPhoneNumberFormatRFC3966:
            return [NSString stringWithFormat:@"%@+%@-%@%@", RFC3966_PREFIX, countryCallingCode, formattedNationalNumber, formattedExtension];
        case NBEPhoneNumberFormatNATIONAL:
        default:
            return [NSString stringWithFormat:@"%@%@", formattedNationalNumber, formattedExtension];
    }
}


/**
 * Formats a phone number using the original phone number format that the number
 * is parsed from. The original format is embedded in the country_code_source
 * field of the PhoneNumber object passed in. If such information is missing,
 * the number will be formatted into the NATIONAL format by default. When the
 * number contains a leading zero and this is unexpected for this country, or we
 * don't have a formatting pattern for the number, the method returns the raw
 * input when it is available.
 *
 * Note this method guarantees no digit will be inserted, removed or modified as
 * a result of formatting.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number that needs to
 *     be formatted in its original number format.
 * @param {string} regionCallingFrom the region whose IDD needs to be prefixed
 *     if the original number has one.
 * @return {string} the formatted phone number in its original number format.
 */
- (NSString *)formatInOriginalFormat:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom error:(NSError **)error
{
    NSString *res = nil;
    @try {
        res = [self formatInOriginalFormat:number regionCallingFrom:regionCallingFrom];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    
    return res;
}


- (NSString *)formatInOriginalFormat:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    if ([NBMetadataHelper hasValue:number.rawInput] && ([self hasUnexpectedItalianLeadingZero:number] || [self hasFormattingPatternForNumber:number] == NO)) {
        // We check if we have the formatting pattern because without that, we might
        // format the number as a group without national prefix.
        return number.rawInput;
    }
    
    if (number.countryCodeSource == nil) {
        return [self format:number numberFormat:NBEPhoneNumberFormatNATIONAL];
    }
    
    NSString *formattedNumber = @"";
    
    switch ([number.countryCodeSource integerValue])
    {
        case NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN:
            formattedNumber = [self format:number numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
            break;
        case NBECountryCodeSourceFROM_NUMBER_WITH_IDD:
            formattedNumber = [self formatOutOfCountryCallingNumber:number regionCallingFrom:regionCallingFrom];
            break;
        case NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN:
            formattedNumber = [[self format:number numberFormat:NBEPhoneNumberFormatINTERNATIONAL] substringFromIndex:1];
            break;
        case NBECountryCodeSourceFROM_DEFAULT_COUNTRY:
            // Fall-through to default case.
        default:
        {
            NSString *regionCode = [self getRegionCodeForCountryCode:number.countryCode];
            // We strip non-digits from the NDD here, and from the raw input later,
            // so that we can compare them easily.
            NSString *nationalPrefix = [self getNddPrefixForRegion:regionCode stripNonDigits:YES];
            NSString *nationalFormat = [self format:number numberFormat:NBEPhoneNumberFormatNATIONAL];
            if (nationalPrefix == nil || nationalPrefix.length == 0)
            {
                // If the region doesn't have a national prefix at all, we can safely
                // return the national format without worrying about a national prefix
                // being added.
                formattedNumber = nationalFormat;
                break;
            }
            // Otherwise, we check if the original number was entered with a national
            // prefix.
            if ([self rawInputContainsNationalPrefix:number.rawInput nationalPrefix:nationalPrefix regionCode:regionCode])
            {
                // If so, we can safely return the national format.
                formattedNumber = nationalFormat;
                break;
            }
            // Metadata cannot be nil here because getNddPrefixForRegion() (above)
            // returns nil if there is no metadata for the region.
            NBPhoneMetaData *metadata = [helper getMetadataForRegion:regionCode];
            NSString *nationalNumber = [self getNationalSignificantNumber:number];
            NBNumberFormat *formatRule = [self chooseFormattingPatternForNumber:metadata.numberFormats nationalNumber:nationalNumber];
            // The format rule could still be nil here if the national number was 0
            // and there was no raw input (this should not be possible for numbers
            // generated by the phonenumber library as they would also not have a
            // country calling code and we would have exited earlier).
            if (formatRule == nil)
            {
                formattedNumber = nationalFormat;
                break;
            }
            // When the format we apply to this number doesn't contain national
            // prefix, we can just return the national format.
            // TODO: Refactor the code below with the code in
            // isNationalPrefixPresentIfRequired.
            NSString *candidateNationalPrefixRule = formatRule.nationalPrefixFormattingRule;
            // We assume that the first-group symbol will never be _before_ the
            // national prefix.
            NSRange firstGroupRange = [candidateNationalPrefixRule rangeOfString:@"$1"];
            if (firstGroupRange.location == NSNotFound)
            {
                formattedNumber = nationalFormat;
                break;
            }
            
            if (firstGroupRange.location <= 0)
            {
                formattedNumber = nationalFormat;
                break;
            }
            candidateNationalPrefixRule = [candidateNationalPrefixRule substringWithRange:NSMakeRange(0, firstGroupRange.location)];
            candidateNationalPrefixRule = [self normalizeDigitsOnly:candidateNationalPrefixRule];
            if (candidateNationalPrefixRule.length == 0)
            {
                // National prefix not used when formatting this number.
                formattedNumber = nationalFormat;
                break;
            }
            // Otherwise, we need to remove the national prefix from our output.
            NBNumberFormat *numFormatCopy = [formatRule copy];
            numFormatCopy.nationalPrefixFormattingRule = nil;
            formattedNumber = [self formatByPattern:number numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[numFormatCopy]];
            break;
        }
    }
    
    NSString *rawInput = number.rawInput;
    // If no digit is inserted/removed/modified as a result of our formatting, we
    // return the formatted phone number; otherwise we return the raw input the
    // user entered.
    if (formattedNumber != nil && rawInput.length > 0)
    {
        NSString *normalizedFormattedNumber = [self normalizeHelper:formattedNumber normalizationReplacements:DIALLABLE_CHAR_MAPPINGS removeNonMatches:YES];
        /** @type {string} */
        NSString *normalizedRawInput = [self normalizeHelper:rawInput normalizationReplacements:DIALLABLE_CHAR_MAPPINGS removeNonMatches:YES];
        
        if ([normalizedFormattedNumber isEqualToString:normalizedRawInput] == NO)
        {
            formattedNumber = rawInput;
        }
    }
    return formattedNumber;
}


/**
 * Check if rawInput, which is assumed to be in the national format, has a
 * national prefix. The national prefix is assumed to be in digits-only form.
 * @param {string} rawInput
 * @param {string} nationalPrefix
 * @param {string} regionCode
 * @return {boolean}
 * @private
 */
- (BOOL)rawInputContainsNationalPrefix:(NSString *)rawInput nationalPrefix:(NSString *)nationalPrefix regionCode:(NSString *)regionCode
{
    BOOL isValid = NO;
    NSString *normalizedNationalNumber = [self normalizeDigitsOnly:rawInput];
    if ([self isStartingStringByRegex:normalizedNationalNumber regex:nationalPrefix])
    {
        // Some Japanese numbers (e.g. 00777123) might be mistaken to contain the
        // national prefix when written without it (e.g. 0777123) if we just do
        // prefix matching. To tackle that, we check the validity of the number if
        // the assumed national prefix is removed (777123 won't be valid in
        // Japan).
        NSString *subString = [normalizedNationalNumber substringFromIndex:nationalPrefix.length];
        NSError *anError = nil;
        isValid = [self isValidNumber:[self parse:subString defaultRegion:regionCode error:&anError]];
        
        if (anError != nil)
            return NO;
    }
    return isValid;
}


/**
 * Returns NO if a number is from a region whose national significant number
 * couldn't contain a leading zero, but has the italian_leading_zero field set
 * to NO.
 * @param {i18n.phonenumbers.PhoneNumber} number
 * @return {boolean}
 * @private
 */
- (BOOL)hasUnexpectedItalianLeadingZero:(NBPhoneNumber*)number
{
    return number.italianLeadingZero && [self isLeadingZeroPossible:number.countryCode] == NO;
}


/**
 * @param {i18n.phonenumbers.PhoneNumber} number
 * @return {boolean}
 * @private
 */
- (BOOL)hasFormattingPatternForNumber:(NBPhoneNumber*)number
{
    NSNumber *countryCallingCode = number.countryCode;
    NSString *phoneNumberRegion = [self getRegionCodeForCountryCode:countryCallingCode];
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCallingCode regionCode:phoneNumberRegion];
    
    if (metadata == nil)
    {
        return NO;
    }
    
    NSString *nationalNumber = [self getNationalSignificantNumber:number];
    NBNumberFormat *formatRule = [self chooseFormattingPatternForNumber:metadata.numberFormats nationalNumber:nationalNumber];
    return formatRule != nil;
}


/**
 * Formats a phone number for out-of-country dialing purposes.
 *
 * Note that in this version, if the number was entered originally using alpha
 * characters and this version of the number is stored in raw_input, this
 * representation of the number will be used rather than the digit
 * representation. Grouping information, as specified by characters such as '-'
 * and ' ', will be retained.
 *
 * <p><b>Caveats:</b></p>
 * <ul>
 * <li>This will not produce good results if the country calling code is both
 * present in the raw input _and_ is the start of the national number. This is
 * not a problem in the regions which typically use alpha numbers.
 * <li>This will also not produce good results if the raw input has any grouping
 * information within the first three digits of the national number, and if the
 * function needs to strip preceding digits/words in the raw input before these
 * digits. Normally people group the first three digits together so this is not
 * a huge problem - and will be fixed if it proves to be so.
 * </ul>
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number that needs to
 *     be formatted.
 * @param {string} regionCallingFrom the region where the call is being placed.
 * @return {string} the formatted phone number.
 */
- (NSString *)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom error:(NSError **)error
{
    NSString *res = nil;
    @try {
        res = [self formatOutOfCountryKeepingAlphaChars:number regionCallingFrom:regionCallingFrom];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}


- (NSString *)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber*)number regionCallingFrom:(NSString *)regionCallingFrom
{
    NSString *rawInput = number.rawInput;
    // If there is no raw input, then we can't keep alpha characters because there
    // aren't any. In this case, we return formatOutOfCountryCallingNumber.
    if (rawInput == nil || rawInput.length == 0)
    {
        return [self formatOutOfCountryCallingNumber:number regionCallingFrom:regionCallingFrom];
    }
    
    NSNumber *countryCode = number.countryCode;
    if ([self hasValidCountryCallingCode:countryCode] == NO)
    {
        return rawInput;
    }
    // Strip any prefix such as country calling code, IDD, that was present. We do
    // this by comparing the number in raw_input with the parsed number. To do
    // this, first we normalize punctuation. We retain number grouping symbols
    // such as ' ' only.
    rawInput = [self normalizeHelper:rawInput normalizationReplacements:ALL_PLUS_NUMBER_GROUPING_SYMBOLS removeNonMatches:NO];
    //NSLog(@"---- formatOutOfCountryKeepingAlphaChars normalizeHelper rawInput [%@]", rawInput);
    // Now we trim everything before the first three digits in the parsed number.
    // We choose three because all valid alpha numbers have 3 digits at the start
    // - if it does not, then we don't trim anything at all. Similarly, if the
    // national number was less than three digits, we don't trim anything at all.
    NSString *nationalNumber = [self getNationalSignificantNumber:number];
    if (nationalNumber.length > 3)
    {
        int firstNationalNumberDigit = [self indexOfStringByString:rawInput target:[nationalNumber substringWithRange:NSMakeRange(0, 3)]];
        if (firstNationalNumberDigit != -1)
        {
            rawInput = [rawInput substringFromIndex:firstNationalNumberDigit];
        }
    }
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadataForRegionCallingFrom = [helper getMetadataForRegion:regionCallingFrom];
    
    if (countryCode.unsignedIntegerValue == NANPA_COUNTRY_CODE_) {
        if ([self isNANPACountry:regionCallingFrom]) {
            return [NSString stringWithFormat:@"%@ %@", countryCode, rawInput];
        }
    } else if (metadataForRegionCallingFrom != nil && [countryCode isEqualToNumber:[self getCountryCodeForValidRegion:regionCallingFrom error:nil]]) {
        NBNumberFormat *formattingPattern = [self chooseFormattingPatternForNumber:metadataForRegionCallingFrom.numberFormats
                                                                    nationalNumber:nationalNumber];
        if (formattingPattern == nil) {
            // If no pattern above is matched, we format the original input.
            return rawInput;
        }
        
        NBNumberFormat *newFormat = [formattingPattern copy];
        // The first group is the first group of digits that the user wrote
        // together.
        newFormat.pattern = @"(\\d+)(.*)";
        // Here we just concatenate them back together after the national prefix
        // has been fixed.
        newFormat.format = @"$1$2";
        // Now we format using this pattern instead of the default pattern, but
        // with the national prefix prefixed if necessary.
        // This will not work in the cases where the pattern (and not the leading
        // digits) decide whether a national prefix needs to be used, since we have
        // overridden the pattern to match anything, but that is not the case in the
        // metadata to date.
        
        return [self formatNsnUsingPattern:rawInput formattingPattern:newFormat numberFormat:NBEPhoneNumberFormatNATIONAL carrierCode:nil];
    }
    
    NSString *internationalPrefixForFormatting = @"";
    // If an unsupported region-calling-from is entered, or a country with
    // multiple international prefixes, the international format of the number is
    // returned, unless there is a preferred international prefix.
    if (metadataForRegionCallingFrom != nil) {
        NSString *internationalPrefix = metadataForRegionCallingFrom.internationalPrefix;
        internationalPrefixForFormatting =
        [self matchesEntirely:UNIQUE_INTERNATIONAL_PREFIX string:internationalPrefix] ? internationalPrefix : metadataForRegionCallingFrom.preferredInternationalPrefix;
    }
    
    NSString *regionCode = [self getRegionCodeForCountryCode:countryCode];
    // Metadata cannot be nil because the country calling code is valid.
    NBPhoneMetaData *metadataForRegion = [self getMetadataForRegionOrCallingCode:countryCode regionCode:regionCode];
    NSString *formattedExtension = [self maybeGetFormattedExtension:number metadata:metadataForRegion numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
    
    if (internationalPrefixForFormatting.length > 0) {
        return [NSString stringWithFormat:@"%@ %@ %@%@", internationalPrefixForFormatting, countryCode, rawInput, formattedExtension];
    } else {
        // Invalid region entered as country-calling-from (so no metadata was found
        // for it) or the region chosen has multiple international dialling
        // prefixes.
        return [self prefixNumberWithCountryCallingCode:countryCode phoneNumberFormat:NBEPhoneNumberFormatINTERNATIONAL formattedNationalNumber:rawInput formattedExtension:formattedExtension];
    }
}


/**
 * Note in some regions, the national number can be written in two completely
 * different ways depending on whether it forms part of the NATIONAL format or
 * INTERNATIONAL format. The numberFormat parameter here is used to specify
 * which format to use for those cases. If a carrierCode is specified, this will
 * be inserted into the formatted string to replace $CC.
 *
 * @param {string} number a string of characters representing a phone number.
 * @param {i18n.phonenumbers.PhoneMetadata} metadata the metadata for the
 *     region that we think this number is from.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @param {string=} opt_carrierCode
 * @return {string} the formatted phone number.
 * @private
 */
- (NSString *)formatNsn:(NSString *)phoneNumber metadata:(NBPhoneMetaData*)metadata phoneNumberFormat:(NBEPhoneNumberFormat)numberFormat carrierCode:(NSString *)opt_carrierCode
{
    NSMutableArray *intlNumberFormats = metadata.intlNumberFormats;
    // When the intlNumberFormats exists, we use that to format national number
    // for the INTERNATIONAL format instead of using the numberDesc.numberFormats.
    NSArray *availableFormats = ([intlNumberFormats count] <= 0 || numberFormat == NBEPhoneNumberFormatNATIONAL) ? metadata.numberFormats : intlNumberFormats;
    NBNumberFormat *formattingPattern = [self chooseFormattingPatternForNumber:availableFormats nationalNumber:phoneNumber];
    
    if (formattingPattern == nil) {
        return phoneNumber;
    }
    
    return [self formatNsnUsingPattern:phoneNumber formattingPattern:formattingPattern numberFormat:numberFormat carrierCode:opt_carrierCode];
}


/**
 * @param {Array.<i18n.phonenumbers.NumberFormat>} availableFormats the
 *     available formats the phone number could be formatted into.
 * @param {string} nationalNumber a string of characters representing a phone
 *     number.
 * @return {i18n.phonenumbers.NumberFormat}
 * @private
 */
- (NBNumberFormat*)chooseFormattingPatternForNumber:(NSArray*)availableFormats nationalNumber:(NSString *)nationalNumber
{
    for (NBNumberFormat *numFormat in availableFormats) {
        unsigned int size = (unsigned int)[numFormat.leadingDigitsPatterns count];
        // We always use the last leading_digits_pattern, as it is the most detailed.
        if (size == 0 || [self stringPositionByRegex:nationalNumber regex:[numFormat.leadingDigitsPatterns lastObject]] == 0) {
            if ([self matchesEntirely:numFormat.pattern string:nationalNumber]) {
                return numFormat;
            }
        }
    }
    
    return nil;
}


/**
 * Note that carrierCode is optional - if nil or an empty string, no carrier
 * code replacement will take place.
 *
 * @param {string} nationalNumber a string of characters representing a phone
 *     number.
 * @param {i18n.phonenumbers.NumberFormat} formattingPattern the formatting rule
 *     the phone number should be formatted into.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @param {string=} opt_carrierCode
 * @return {string} the formatted phone number.
 * @private
 */
- (NSString *)formatNsnUsingPattern:(NSString *)nationalNumber formattingPattern:(NBNumberFormat*)formattingPattern numberFormat:(NBEPhoneNumberFormat)numberFormat carrierCode:(NSString *)opt_carrierCode
{
    NSString *numberFormatRule = formattingPattern.format;
    NSString *domesticCarrierCodeFormattingRule = formattingPattern.domesticCarrierCodeFormattingRule;
    NSString *formattedNationalNumber = @"";
    
    if (numberFormat == NBEPhoneNumberFormatNATIONAL && [NBMetadataHelper hasValue:opt_carrierCode] && domesticCarrierCodeFormattingRule.length > 0) {
        // Replace the $CC in the formatting rule with the desired carrier code.
        NSString *carrierCodeFormattingRule = [self replaceStringByRegex:domesticCarrierCodeFormattingRule regex:CC_PATTERN withTemplate:opt_carrierCode];
        // Now replace the $FG in the formatting rule with the first group and
        // the carrier code combined in the appropriate way.
        numberFormatRule = [self replaceFirstStringByRegex:numberFormatRule regex:FIRST_GROUP_PATTERN
                                              withTemplate:carrierCodeFormattingRule];
        formattedNationalNumber = [self replaceStringByRegex:nationalNumber regex:formattingPattern.pattern withTemplate:numberFormatRule];
    } else {
        // Use the national prefix formatting rule instead.
        NSString *nationalPrefixFormattingRule = formattingPattern.nationalPrefixFormattingRule;
        if (numberFormat == NBEPhoneNumberFormatNATIONAL && [NBMetadataHelper hasValue:nationalPrefixFormattingRule]) {
            NSString *replacePattern = [self replaceFirstStringByRegex:numberFormatRule regex:FIRST_GROUP_PATTERN withTemplate:nationalPrefixFormattingRule];
            formattedNationalNumber = [self replaceStringByRegex:nationalNumber regex:formattingPattern.pattern withTemplate:replacePattern];
        } else {
            formattedNationalNumber = [self replaceStringByRegex:nationalNumber regex:formattingPattern.pattern withTemplate:numberFormatRule];
        }
    }
    
    if (numberFormat == NBEPhoneNumberFormatRFC3966) {
        // Strip any leading punctuation.
        formattedNationalNumber = [self replaceStringByRegex:formattedNationalNumber regex:[NSString stringWithFormat:@"^%@", SEPARATOR_PATTERN] withTemplate:@""];
        
        // Replace the rest with a dash between each number group.
        formattedNationalNumber = [self replaceStringByRegex:formattedNationalNumber regex:SEPARATOR_PATTERN withTemplate:@"-"];
    }
    return formattedNationalNumber;
}


/**
 * Gets a valid number for the specified region.
 *
 * @param {string} regionCode the region for which an example number is needed.
 * @return {i18n.phonenumbers.PhoneNumber} a valid fixed-line number for the
 *     specified region. Returns nil when the metadata does not contain such
 *     information, or the region 001 is passed in. For 001 (representing non-
 *     geographical numbers), call {@link #getExampleNumberForNonGeoEntity}
 *     instead.
 */
- (NBPhoneNumber*)getExampleNumber:(NSString *)regionCode error:(NSError *__autoreleasing *)error
{
    NBPhoneNumber *res = [self getExampleNumberForType:regionCode type:NBEPhoneNumberTypeFIXED_LINE error:error];
    return res;
}


/**
 * Gets a valid number for the specified region and number type.
 *
 * @param {string} regionCode the region for which an example number is needed.
 * @param {i18n.phonenumbers.PhoneNumberType} type the type of number that is
 *     needed.
 * @return {i18n.phonenumbers.PhoneNumber} a valid number for the specified
 *     region and type. Returns nil when the metadata does not contain such
 *     information or if an invalid region or region 001 was entered.
 *     For 001 (representing non-geographical numbers), call
 *     {@link #getExampleNumberForNonGeoEntity} instead.
 */
- (NBPhoneNumber*)getExampleNumberForType:(NSString *)regionCode type:(NBEPhoneNumberType)type error:(NSError *__autoreleasing *)error
{
    NBPhoneNumber *res = nil;
    
    if ([self isValidRegionCode:regionCode] == NO) {
        return nil;
    }
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    NBPhoneNumberDesc *desc = [self getNumberDescByType:[helper getMetadataForRegion:regionCode] type:type];
    
    if ([NBMetadataHelper hasValue:desc.exampleNumber ]) {
        return [self parse:desc.exampleNumber defaultRegion:regionCode error:error];
    }
    
    return res;
}


/**
 * Gets a valid number for the specified country calling code for a
 * non-geographical entity.
 *
 * @param {number} countryCallingCode the country calling code for a
 *     non-geographical entity.
 * @return {i18n.phonenumbers.PhoneNumber} a valid number for the
 *     non-geographical entity. Returns nil when the metadata does not contain
 *     such information, or the country calling code passed in does not belong
 *     to a non-geographical entity.
 */
- (NBPhoneNumber*)getExampleNumberForNonGeoEntity:(NSNumber *)countryCallingCode error:(NSError *__autoreleasing *)error
{
    NBPhoneNumber *res = nil;
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadata = [helper getMetadataForNonGeographicalRegion:countryCallingCode];
    
    if (metadata != nil) {
        NBPhoneNumberDesc *desc = metadata.generalDesc;
        if ([NBMetadataHelper hasValue:desc.exampleNumber]) {
            NSString *callCode = [NSString stringWithFormat:@"+%@%@", countryCallingCode, desc.exampleNumber];
            return [self parse:callCode defaultRegion:NB_UNKNOWN_REGION error:error];
        }
    }
    
    return res;
}


/**
 * Gets the formatted extension of a phone number, if the phone number had an
 * extension specified. If not, it returns an empty string.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the PhoneNumber that might have
 *     an extension.
 * @param {i18n.phonenumbers.PhoneMetadata} metadata the metadata for the
 *     region that we think this number is from.
 * @param {i18n.phonenumbers.PhoneNumberFormat} numberFormat the format the
 *     phone number should be formatted into.
 * @return {string} the formatted extension if any.
 * @private
 */
- (NSString *)maybeGetFormattedExtension:(NBPhoneNumber*)number metadata:(NBPhoneMetaData*)metadata numberFormat:(NBEPhoneNumberFormat)numberFormat
{
    if ([NBMetadataHelper hasValue:number.extension] == NO) {
        return @"";
    } else {
        if (numberFormat == NBEPhoneNumberFormatRFC3966) {
            return [NSString stringWithFormat:@"%@%@", RFC3966_EXTN_PREFIX, number.extension];
        } else {
            if ([NBMetadataHelper hasValue:metadata.preferredExtnPrefix]) {
                return [NSString stringWithFormat:@"%@%@", metadata.preferredExtnPrefix, number.extension];
            } else {
                return [NSString stringWithFormat:@"%@%@", DEFAULT_EXTN_PREFIX, number.extension];
            }
        }
    }
}


/**
 * @param {i18n.phonenumbers.PhoneMetadata} metadata
 * @param {i18n.phonenumbers.PhoneNumberType} type
 * @return {i18n.phonenumbers.PhoneNumberDesc}
 * @private
 */
- (NBPhoneNumberDesc*)getNumberDescByType:(NBPhoneMetaData*)metadata type:(NBEPhoneNumberType)type
{
    switch (type)
    {
        case NBEPhoneNumberTypePREMIUM_RATE:
            return metadata.premiumRate;
        case NBEPhoneNumberTypeTOLL_FREE:
            return metadata.tollFree;
        case NBEPhoneNumberTypeMOBILE:
            if (metadata.mobile == nil) return metadata.generalDesc;
            return metadata.mobile;
        case NBEPhoneNumberTypeFIXED_LINE:
        case NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE:
            if (metadata.fixedLine == nil) return metadata.generalDesc;
            return metadata.fixedLine;
        case NBEPhoneNumberTypeSHARED_COST:
            return metadata.sharedCost;
        case NBEPhoneNumberTypeVOIP:
            return metadata.voip;
        case NBEPhoneNumberTypePERSONAL_NUMBER:
            return metadata.personalNumber;
        case NBEPhoneNumberTypePAGER:
            return metadata.pager;
        case NBEPhoneNumberTypeUAN:
            return metadata.uan;
        case NBEPhoneNumberTypeVOICEMAIL:
            return metadata.voicemail;
        default:
            return metadata.generalDesc;
    }
}

/**
 * Gets the type of a phone number.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number that we want
 *     to know the type.
 * @return {i18n.phonenumbers.PhoneNumberType} the type of the phone number.
 */
- (NBEPhoneNumberType)getNumberType:(NBPhoneNumber*)phoneNumber
{
    NSString *regionCode = [self getRegionCodeForNumber:phoneNumber];
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:phoneNumber.countryCode regionCode:regionCode];
    if (metadata == nil)
    {
        return NBEPhoneNumberTypeUNKNOWN;
    }
    
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:phoneNumber];
    return [self getNumberTypeHelper:nationalSignificantNumber metadata:metadata];
}


/**
 * @param {string} nationalNumber
 * @param {i18n.phonenumbers.PhoneMetadata} metadata
 * @return {i18n.phonenumbers.PhoneNumberType}
 * @private
 */
- (NBEPhoneNumberType)getNumberTypeHelper:(NSString *)nationalNumber metadata:(NBPhoneMetaData*)metadata
{
    NBPhoneNumberDesc *generalNumberDesc = metadata.generalDesc;
    
    //NSLog(@"getNumberTypeHelper - UNKNOWN 1");
    if ([NBMetadataHelper hasValue:generalNumberDesc.nationalNumberPattern] == NO ||
        [self isNumberMatchingDesc:nationalNumber numberDesc:generalNumberDesc] == NO)
    {
        //NSLog(@"getNumberTypeHelper - UNKNOWN 2");
        return NBEPhoneNumberTypeUNKNOWN;
    }
    
    //NSLog(@"getNumberTypeHelper - PREMIUM_RATE 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.premiumRate])
    {
        //NSLog(@"getNumberTypeHelper - PREMIUM_RATE 2");
        return NBEPhoneNumberTypePREMIUM_RATE;
    }
    
    //NSLog(@"getNumberTypeHelper - TOLL_FREE 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.tollFree])
    {
        //NSLog(@"getNumberTypeHelper - TOLL_FREE 2");
        return NBEPhoneNumberTypeTOLL_FREE;
    }
    
    //NSLog(@"getNumberTypeHelper - SHARED_COST 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.sharedCost])
    {
        //NSLog(@"getNumberTypeHelper - SHARED_COST 2");
        return NBEPhoneNumberTypeSHARED_COST;
    }
    
    //NSLog(@"getNumberTypeHelper - VOIP 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.voip])
    {
        //NSLog(@"getNumberTypeHelper - VOIP 2");
        return NBEPhoneNumberTypeVOIP;
    }
    
    //NSLog(@"getNumberTypeHelper - PERSONAL_NUMBER 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.personalNumber])
    {
        //NSLog(@"getNumberTypeHelper - PERSONAL_NUMBER 2");
        return NBEPhoneNumberTypePERSONAL_NUMBER;
    }
    
    //NSLog(@"getNumberTypeHelper - PAGER 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.pager])
    {
        //NSLog(@"getNumberTypeHelper - PAGER 2");
        return NBEPhoneNumberTypePAGER;
    }
    
    //NSLog(@"getNumberTypeHelper - UAN 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.uan])
    {
        //NSLog(@"getNumberTypeHelper - UAN 2");
        return NBEPhoneNumberTypeUAN;
    }
    
    //NSLog(@"getNumberTypeHelper - VOICEMAIL 1");
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.voicemail])
    {
        //NSLog(@"getNumberTypeHelper - VOICEMAIL 2");
        return NBEPhoneNumberTypeVOICEMAIL;
    }
    
    if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.fixedLine])
    {
        if (metadata.sameMobileAndFixedLinePattern)
        {
            //NSLog(@"getNumberTypeHelper - FIXED_LINE_OR_MOBILE");
            return NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE;
        }
        else if ([self isNumberMatchingDesc:nationalNumber numberDesc:metadata.mobile])
        {
            //NSLog(@"getNumberTypeHelper - FIXED_LINE_OR_MOBILE");
            return NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE;
        }
        //NSLog(@"getNumberTypeHelper - FIXED_LINE");
        return NBEPhoneNumberTypeFIXED_LINE;
    }
    
    // Otherwise, test to see if the number is mobile. Only do this if certain
    // that the patterns for mobile and fixed line aren't the same.
    if ([metadata sameMobileAndFixedLinePattern] == NO && [self isNumberMatchingDesc:nationalNumber numberDesc:metadata.mobile]) {
        return NBEPhoneNumberTypeMOBILE;
    }
    
    return NBEPhoneNumberTypeUNKNOWN;
}


/**
 * @param {string} nationalNumber
 * @param {i18n.phonenumbers.PhoneNumberDesc} numberDesc
 * @return {boolean}
 * @private
 */
- (BOOL)isNumberMatchingDesc:(NSString *)nationalNumber numberDesc:(NBPhoneNumberDesc*)numberDesc
{
    if (numberDesc == nil) {
        return NO;
    }
    
    if ([NBMetadataHelper hasValue:numberDesc.possibleNumberPattern] == NO || [numberDesc.possibleNumberPattern isEqual:@"NA"]) {
        return [self matchesEntirely:numberDesc.nationalNumberPattern string:nationalNumber];
    }
    
    if ([NBMetadataHelper hasValue:numberDesc.nationalNumberPattern] == NO || [numberDesc.nationalNumberPattern isEqual:@"NA"]) {
        return [self matchesEntirely:numberDesc.possibleNumberPattern string:nationalNumber];
    }
    
    return [self matchesEntirely:numberDesc.possibleNumberPattern string:nationalNumber] &&
    [self matchesEntirely:numberDesc.nationalNumberPattern string:nationalNumber];
}


/**
 * Tests whether a phone number matches a valid pattern. Note this doesn't
 * verify the number is actually in use, which is impossible to tell by just
 * looking at a number itself.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number that we want
 *     to validate.
 * @return {boolean} a boolean that indicates whether the number is of a valid
 *     pattern.
 */
- (BOOL)isValidNumber:(NBPhoneNumber*)number
{
    NSString *regionCode = [self getRegionCodeForNumber:number];
    return [self isValidNumberForRegion:number regionCode:regionCode];
}


/**
 * Tests whether a phone number is valid for a certain region. Note this doesn't
 * verify the number is actually in use, which is impossible to tell by just
 * looking at a number itself. If the country calling code is not the same as
 * the country calling code for the region, this immediately exits with NO.
 * After this, the specific number pattern rules for the region are examined.
 * This is useful for determining for example whether a particular number is
 * valid for Canada, rather than just a valid NANPA number.
 * Warning: In most cases, you want to use {@link #isValidNumber} instead. For
 * example, this method will mark numbers from British Crown dependencies such
 * as the Isle of Man as invalid for the region "GB" (United Kingdom), since it
 * has its own region code, "IM", which may be undesirable.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number that we want
 *     to validate.
 * @param {?string} regionCode the region that we want to validate the phone
 *     number for.
 * @return {boolean} a boolean that indicates whether the number is of a valid
 *     pattern.
 */
- (BOOL)isValidNumberForRegion:(NBPhoneNumber*)number regionCode:(NSString *)regionCode
{
    NSNumber *countryCode = [number.countryCode copy];
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCode regionCode:regionCode];
    if (metadata == nil ||
        ([NB_REGION_CODE_FOR_NON_GEO_ENTITY isEqualToString:regionCode] == NO &&
         ![countryCode isEqualToNumber:[self getCountryCodeForValidRegion:regionCode error:nil]])) {
            // Either the region code was invalid, or the country calling code for this
            // number does not match that of the region code.
            return NO;
        }
    
    NBPhoneNumberDesc *generalNumDesc = metadata.generalDesc;
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:number];
    
    // For regions where we don't have metadata for PhoneNumberDesc, we treat any
    // number passed in as a valid number if its national significant number is
    // between the minimum and maximum lengths defined by ITU for a national
    // significant number.
    
    if ([NBMetadataHelper hasValue:generalNumDesc.nationalNumberPattern] == NO) {
        unsigned int numberLength = (unsigned int)nationalSignificantNumber.length;
        return numberLength > MIN_LENGTH_FOR_NSN_ && numberLength <= MAX_LENGTH_FOR_NSN_;
    }
    
    return [self getNumberTypeHelper:nationalSignificantNumber metadata:metadata] != NBEPhoneNumberTypeUNKNOWN;
}


/**
 * Returns the region where a phone number is from. This could be used for
 * geocoding at the region level.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number whose origin
 *     we want to know.
 * @return {?string} the region where the phone number is from, or nil
 *     if no region matches this calling code.
 */
- (NSString *)getRegionCodeForNumber:(NBPhoneNumber*)phoneNumber
{
    if (phoneNumber == nil) {
        return nil;
    }
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *regionCodes = [helper regionCodeFromCountryCode:phoneNumber.countryCode];
    if (regionCodes == nil || [regionCodes count] <= 0) {
        return nil;
    }
    
    if ([regionCodes count] == 1) {
        return [regionCodes objectAtIndex:0];
    } else {
        return [self getRegionCodeForNumberFromRegionList:phoneNumber regionCodes:regionCodes];
    }
}


/**
 * @param {i18n.phonenumbers.PhoneNumber} number
 * @param {Array.<string>} regionCodes
 * @return {?string}
 * @private
 
 */
- (NSString *)getRegionCodeForNumberFromRegionList:(NBPhoneNumber*)phoneNumber regionCodes:(NSArray*)regionCodes
{
    NSString *nationalNumber = [self getNationalSignificantNumber:phoneNumber];
    unsigned int regionCodesCount = (unsigned int)[regionCodes count];
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    for (unsigned int i = 0; i<regionCodesCount; i++) {
        NSString *regionCode = [regionCodes objectAtIndex:i];
        NBPhoneMetaData *metadata = [helper getMetadataForRegion:regionCode];
        
        if ([NBMetadataHelper hasValue:metadata.leadingDigits]) {
            if ([self stringPositionByRegex:nationalNumber regex:metadata.leadingDigits] == 0) {
                return regionCode;
            }
        } else if ([self getNumberTypeHelper:nationalNumber metadata:metadata] != NBEPhoneNumberTypeUNKNOWN) {
            return regionCode;
        }
    }
    
    return nil;
}


/**
 * Returns the region code that matches the specific country calling code. In
 * the case of no region code being found, ZZ will be returned. In the case of
 * multiple regions, the one designated in the metadata as the 'main' region for
 * this calling code will be returned.
 *
 * @param {number} countryCallingCode the country calling code.
 * @return {string}
 */
- (NSString *)getRegionCodeForCountryCode:(NSNumber *)countryCallingCode
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *regionCodes = [helper regionCodeFromCountryCode:countryCallingCode];
    return regionCodes == nil ? NB_UNKNOWN_REGION : [regionCodes objectAtIndex:0];
}


/**
 * Returns a list with the region codes that match the specific country calling
 * code. For non-geographical country calling codes, the region code 001 is
 * returned. Also, in the case of no region code being found, an empty list is
 * returned.
 *
 * @param {number} countryCallingCode the country calling code.
 * @return {Array.<string>}
 */
- (NSArray*)getRegionCodesForCountryCode:(NSNumber *)countryCallingCode
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *regionCodes = [helper regionCodeFromCountryCode:countryCallingCode];
    return regionCodes == nil ? nil : regionCodes;
}


/**
 * Returns the country calling code for a specific region. For example, this
 * would be 1 for the United States, and 64 for New Zealand.
 *
 * @param {?string} regionCode the region that we want to get the country
 *     calling code for.
 * @return {number} the country calling code for the region denoted by
 *     regionCode.
 */
- (NSNumber*)getCountryCodeForRegion:(NSString *)regionCode
{
    if ([self isValidRegionCode:regionCode] == NO) {
        return @0;
    }
    
    NSError *error = nil;
    NSNumber *res = [self getCountryCodeForValidRegion:regionCode error:&error];
    if (error != nil) {
        return @0;
    }
    
    return res;
}


/**
 * Returns the country calling code for a specific region. For example, this
 * would be 1 for the United States, and 64 for New Zealand. Assumes the region
 * is already valid.
 *
 * @param {?string} regionCode the region that we want to get the country
 *     calling code for.
 * @return {number} the country calling code for the region denoted by
 *     regionCode.
 * @throws {string} if the region is invalid
 * @private
 */
- (NSNumber*)getCountryCodeForValidRegion:(NSString *)regionCode error:(NSError**)error
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadata = [helper getMetadataForRegion:regionCode];
    
    if (metadata == nil) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid region code:%@", regionCode]
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:@"INVALID_REGION_CODE" code:0 userInfo:userInfo];
        }
        
        return @-1;
    }
    
    return metadata.countryCode;
}


/**
 * Returns the national dialling prefix for a specific region. For example, this
 * would be 1 for the United States, and 0 for New Zealand. Set stripNonDigits
 * to NO to strip symbols like '~' (which indicates a wait for a dialling
 * tone) from the prefix returned. If no national prefix is present, we return
 * nil.
 *
 * <p>Warning: Do not use this method for do-your-own formatting - for some
 * regions, the national dialling prefix is used only for certain types of
 * numbers. Use the library's formatting functions to prefix the national prefix
 * when required.
 *
 * @param {?string} regionCode the region that we want to get the dialling
 *     prefix for.
 * @param {boolean} stripNonDigits NO to strip non-digits from the national
 *     dialling prefix.
 * @return {?string} the dialling prefix for the region denoted by
 *     regionCode.
 */
- (NSString *)getNddPrefixForRegion:(NSString *)regionCode stripNonDigits:(BOOL)stripNonDigits
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadata = [helper getMetadataForRegion:regionCode];
    if (metadata == nil) {
        return nil;
    }
    
    NSString *nationalPrefix = metadata.nationalPrefix;
    // If no national prefix was found, we return nil.
    if (nationalPrefix.length == 0) {
        return nil;
    }
    
    if (stripNonDigits) {
        // Note: if any other non-numeric symbols are ever used in national
        // prefixes, these would have to be removed here as well.
        nationalPrefix = [nationalPrefix stringByReplacingOccurrencesOfString:@"~" withString:@""];
    }
    return nationalPrefix;
}


/**
 * Checks if this is a region under the North American Numbering Plan
 * Administration (NANPA).
 *
 * @param {?string} regionCode the ISO 3166-1 two-letter region code.
 * @return {boolean} NO if regionCode is one of the regions under NANPA.
 */
- (BOOL)isNANPACountry:(NSString *)regionCode
{
    BOOL isExists = NO;
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *res = [helper regionCodeFromCountryCode:[NSNumber numberWithUnsignedInteger:NANPA_COUNTRY_CODE_]];
    
    for (NSString *inRegionCode in res) {
        if ([inRegionCode isEqualToString:regionCode.uppercaseString]) {
            isExists = YES;
        }
    }
    
    return regionCode != nil && isExists;
}


/**
 * Checks whether countryCode represents the country calling code from a region
 * whose national significant number could contain a leading zero. An example of
 * such a region is Italy. Returns NO if no metadata for the country is
 * found.
 *
 * @param {number} countryCallingCode the country calling code.
 * @return {boolean}
 */
- (BOOL)isLeadingZeroPossible:(NSNumber *)countryCallingCode
{
    NBPhoneMetaData *mainMetadataForCallingCode = [self getMetadataForRegionOrCallingCode:countryCallingCode
                                                                               regionCode:[self getRegionCodeForCountryCode:countryCallingCode]];
    
    return mainMetadataForCallingCode != nil && mainMetadataForCallingCode.leadingZeroPossible;
}


/**
 * Checks if the number is a valid vanity (alpha) number such as 800 MICROSOFT.
 * A valid vanity number will start with at least 3 digits and will have three
 * or more alpha characters. This does not do region-specific checks - to work
 * out if this number is actually valid for a region, it should be parsed and
 * methods such as {@link #isPossibleNumberWithReason} and
 * {@link #isValidNumber} should be used.
 *
 * @param {string} number the number that needs to be checked.
 * @return {boolean} NO if the number is a valid vanity number.
 */
- (BOOL)isAlphaNumber:(NSString *)number
{
    if ([self isViablePhoneNumber:number] == NO) {
        // Number is too short, or doesn't match the basic phone number pattern.
        return NO;
    }
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    number = [helper normalizeNonBreakingSpace:number];
    
    /** @type {!goog.string.StringBuffer} */
    NSString *strippedNumber = [number copy];
    [self maybeStripExtension:&strippedNumber];
    
    return [self matchesEntirely:VALID_ALPHA_PHONE_PATTERN_STRING string:strippedNumber];
}


/**
 * Convenience wrapper around {@link #isPossibleNumberWithReason}. Instead of
 * returning the reason for failure, this method returns a boolean value.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the number that needs to be
 *     checked.
 * @return {boolean} NO if the number is possible.
 */
- (BOOL)isPossibleNumber:(NBPhoneNumber*)number error:(NSError**)error
{
    BOOL res = NO;
    @try {
        res = [self isPossibleNumber:number];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}


- (BOOL)isPossibleNumber:(NBPhoneNumber*)number
{
    return [self isPossibleNumberWithReason:number] == NBEValidationResultIS_POSSIBLE;
}


/**
 * Helper method to check a number against a particular pattern and determine
 * whether it matches, or is too short or too long. Currently, if a number
 * pattern suggests that numbers of length 7 and 10 are possible, and a number
 * in between these possible lengths is entered, such as of length 8, this will
 * return TOO_LONG.
 *
 * @param {string} numberPattern
 * @param {string} number
 * @return {ValidationResult}
 * @private
 */
- (NBEValidationResult)testNumberLengthAgainstPattern:(NSString *)numberPattern number:(NSString *)number
{
    if ([self matchesEntirely:numberPattern string:number]) {
        return NBEValidationResultIS_POSSIBLE;
    }
    
    if ([self stringPositionByRegex:number regex:numberPattern] == 0) {
        return NBEValidationResultTOO_LONG;
    } else {
        return NBEValidationResultTOO_SHORT;
    }
}


/**
 * Check whether a phone number is a possible number. It provides a more lenient
 * check than {@link #isValidNumber} in the following sense:
 * <ol>
 * <li>It only checks the length of phone numbers. In particular, it doesn't
 * check starting digits of the number.
 * <li>It doesn't attempt to figure out the type of the number, but uses general
 * rules which applies to all types of phone numbers in a region. Therefore, it
 * is much faster than isValidNumber.
 * <li>For fixed line numbers, many regions have the concept of area code, which
 * together with subscriber number constitute the national significant number.
 * It is sometimes okay to dial the subscriber number only when dialing in the
 * same area. This function will return NO if the subscriber-number-only
 * version is passed in. On the other hand, because isValidNumber validates
 * using information on both starting digits (for fixed line numbers, that would
 * most likely be area codes) and length (obviously includes the length of area
 * codes for fixed line numbers), it will return NO for the
 * subscriber-number-only version.
 * </ol>
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the number that needs to be
 *     checked.
 * @return {ValidationResult} a
 *     ValidationResult object which indicates whether the number is possible.
 */
- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber*)number error:(NSError *__autoreleasing *)error
{
    NBEValidationResult res = NBEValidationResultUNKNOWN;
    @try {
        res = [self isPossibleNumberWithReason:number];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    
    return res;
}


- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber*)number
{
    NSString *nationalNumber = [self getNationalSignificantNumber:number];
    NSNumber *countryCode = number.countryCode;
    // Note: For Russian Fed and NANPA numbers, we just use the rules from the
    // default region (US or Russia) since the getRegionCodeForNumber will not
    // work if the number is possible but not valid. This would need to be
    // revisited if the possible number pattern ever differed between various
    // regions within those plans.
    if ([self hasValidCountryCallingCode:countryCode] == NO) {
        return NBEValidationResultINVALID_COUNTRY_CODE;
    }
    
    NSString *regionCode = [self getRegionCodeForCountryCode:countryCode];
    // Metadata cannot be nil because the country calling code is valid.
    NBPhoneMetaData *metadata = [self getMetadataForRegionOrCallingCode:countryCode regionCode:regionCode];
    NBPhoneNumberDesc *generalNumDesc = metadata.generalDesc;
    
    // Handling case of numbers with no metadata.
    if ([NBMetadataHelper hasValue:generalNumDesc.nationalNumberPattern] == NO) {
        unsigned int numberLength = (unsigned int)nationalNumber.length;
        
        if (numberLength < MIN_LENGTH_FOR_NSN_) {
            return NBEValidationResultTOO_SHORT;
        } else if (numberLength > MAX_LENGTH_FOR_NSN_) {
            return NBEValidationResultTOO_LONG;
        } else {
            return NBEValidationResultIS_POSSIBLE;
        }
    }
    
    NSString *possibleNumberPattern = generalNumDesc.possibleNumberPattern;
    return [self testNumberLengthAgainstPattern:possibleNumberPattern number:nationalNumber];
}


/**
 * Check whether a phone number is a possible number given a number in the form
 * of a string, and the region where the number could be dialed from. It
 * provides a more lenient check than {@link #isValidNumber}. See
 * {@link #isPossibleNumber} for details.
 *
 * <p>This method first parses the number, then invokes
 * {@link #isPossibleNumber} with the resultant PhoneNumber object.
 *
 * @param {string} number the number that needs to be checked, in the form of a
 *     string.
 * @param {string} regionDialingFrom the region that we are expecting the number
 *     to be dialed from.
 *     Note this is different from the region where the number belongs.
 *     For example, the number +1 650 253 0000 is a number that belongs to US.
 *     When written in this form, it can be dialed from any region. When it is
 *     written as 00 1 650 253 0000, it can be dialed from any region which uses
 *     an international dialling prefix of 00. When it is written as
 *     650 253 0000, it can only be dialed from within the US, and when written
 *     as 253 0000, it can only be dialed from within a smaller area in the US
 *     (Mountain View, CA, to be more specific).
 * @return {boolean} NO if the number is possible.
 */
- (BOOL)isPossibleNumberString:(NSString *)number regionDialingFrom:(NSString *)regionDialingFrom error:(NSError**)error
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    number = [helper normalizeNonBreakingSpace:number];
    
    BOOL res = [self isPossibleNumber:[self parse:number defaultRegion:regionDialingFrom error:error]];
    return res;
}

/**
 * Attempts to extract a valid number from a phone number that is too long to be
 * valid, and resets the PhoneNumber object passed in to that valid version. If
 * no valid number could be extracted, the PhoneNumber object passed in will not
 * be modified.
 * @param {i18n.phonenumbers.PhoneNumber} number a PhoneNumber object which
 *     contains a number that is too long to be valid.
 * @return {boolean} NO if a valid phone number can be successfully extracted.
 */

- (BOOL)truncateTooLongNumber:(NBPhoneNumber*)number
{
    if ([self isValidNumber:number]) {
        return YES;
    }
    
    NBPhoneNumber *numberCopy = [number copy];
    NSNumber *nationalNumber = number.nationalNumber;
    do {
        nationalNumber = [NSNumber numberWithLongLong:(long long)floor(nationalNumber.unsignedLongLongValue / 10)];
        numberCopy.nationalNumber = [nationalNumber copy];
        if ([nationalNumber isEqualToNumber:@0] || [self isPossibleNumberWithReason:numberCopy] == NBEValidationResultTOO_SHORT) {
            return NO;
        }
    }
    while ([self isValidNumber:numberCopy] == NO);
    
    number.nationalNumber = nationalNumber;
    return YES;
}


/**
 * Extracts country calling code from fullNumber, returns it and places the
 * remaining number in nationalNumber. It assumes that the leading plus sign or
 * IDD has already been removed. Returns 0 if fullNumber doesn't start with a
 * valid country calling code, and leaves nationalNumber unmodified.
 *
 * @param {!goog.string.StringBuffer} fullNumber
 * @param {!goog.string.StringBuffer} nationalNumber
 * @return {number}
 */
- (NSNumber *)extractCountryCode:(NSString *)fullNumber nationalNumber:(NSString **)nationalNumber
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    fullNumber = [helper normalizeNonBreakingSpace:fullNumber];
    
    if ((fullNumber.length == 0) || ([[fullNumber substringToIndex:1] isEqualToString:@"0"])) {
        // Country codes do not begin with a '0'.
        return @0;
    }
    
    unsigned int numberLength = (unsigned int)fullNumber.length;
    unsigned int maxCountryCode = MAX_LENGTH_COUNTRY_CODE_;
    
    if ([fullNumber hasPrefix:@"+"]) {
        maxCountryCode = MAX_LENGTH_COUNTRY_CODE_ + 1;
    }
    
    for (unsigned int i = 1; i <= maxCountryCode && i <= numberLength; ++i) {
        NSString *subNumber = [fullNumber substringWithRange:NSMakeRange(0, i)];
        NSNumber *potentialCountryCode = [NSNumber numberWithInteger:[subNumber integerValue]];
        
        NSArray *regionCodes = [helper regionCodeFromCountryCode:potentialCountryCode];
        if (regionCodes != nil && regionCodes.count > 0) {
            if (nationalNumber != NULL) {
                if ((*nationalNumber) == nil) {
                    (*nationalNumber) = [NSString stringWithFormat:@"%@", [fullNumber substringFromIndex:i]];
                } else {
                    (*nationalNumber) = [NSString stringWithFormat:@"%@%@", (*nationalNumber), [fullNumber substringFromIndex:i]];
                }
            }
            return potentialCountryCode;
        }
    }
    
    return @0;
}


/**
 * Convenience method to get a list of what regions the library has metadata
 * for.
 * @return {!Array.<string>} region codes supported by the library.
 */

- (NSArray *)getSupportedRegions
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NSArray *allKeys = [[helper CCode2CNMap] allKeys];
    NSPredicate *predicateIsNaN = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [self isNaN:evaluatedObject];
    }];
    
    NSArray *supportedRegions = [allKeys filteredArrayUsingPredicate:predicateIsNaN];
    return supportedRegions;
}

/*
 i18n.phonenumbers.PhoneNumberUtil.prototype.getSupportedRegions = function() {
 return goog.array.filter(
 Object.keys(i18n.phonenumbers.metadata.countryToMetadata),
 function(regionCode) {
 return isNaN(regionCode);
 });
 };
 */

/**
 * Convenience method to get a list of what global network calling codes the
 * library has metadata for.
 * @return {!Array.<number>} global network calling codes supported by the
 *     library.
 */
/*
 i18n.phonenumbers.PhoneNumberUtil.prototype.
 getSupportedGlobalNetworkCallingCodes = function() {
 var callingCodesAsStrings = goog.array.filter(
 Object.keys(i18n.phonenumbers.metadata.countryToMetadata),
 function(regionCode) {
 return !isNaN(regionCode);
 });
 return goog.array.map(callingCodesAsStrings,
 function(callingCode) {
 return parseInt(callingCode, 10);
 });
 };
 */


/**
 * Tries to extract a country calling code from a number. This method will
 * return zero if no country calling code is considered to be present. Country
 * calling codes are extracted in the following ways:
 * <ul>
 * <li>by stripping the international dialing prefix of the region the person is
 * dialing from, if this is present in the number, and looking at the next
 * digits
 * <li>by stripping the '+' sign if present and then looking at the next digits
 * <li>by comparing the start of the number and the country calling code of the
 * default region. If the number is not considered possible for the numbering
 * plan of the default region initially, but starts with the country calling
 * code of this region, validation will be reattempted after stripping this
 * country calling code. If this number is considered a possible number, then
 * the first digits will be considered the country calling code and removed as
 * such.
 * </ul>
 *
 * It will throw a i18n.phonenumbers.Error if the number starts with a '+' but
 * the country calling code supplied after this does not match that of any known
 * region.
 *
 * @param {string} number non-normalized telephone number that we wish to
 *     extract a country calling code from - may begin with '+'.
 * @param {i18n.phonenumbers.PhoneMetadata} defaultRegionMetadata metadata
 *     about the region this number may be from.
 * @param {!goog.string.StringBuffer} nationalNumber a string buffer to store
 *     the national significant number in, in the case that a country calling
 *     code was extracted. The number is appended to any existing contents. If
 *     no country calling code was extracted, this will be left unchanged.
 * @param {boolean} keepRawInput NO if the country_code_source and
 *     preferred_carrier_code fields of phoneNumber should be populated.
 * @param {i18n.phonenumbers.PhoneNumber} phoneNumber the PhoneNumber object
 *     where the country_code and country_code_source need to be populated.
 *     Note the country_code is always populated, whereas country_code_source is
 *     only populated when keepCountryCodeSource is NO.
 * @return {number} the country calling code extracted or 0 if none could be
 *     extracted.
 * @throws {i18n.phonenumbers.Error}
 */
- (NSNumber *)maybeExtractCountryCode:(NSString *)number metadata:(NBPhoneMetaData*)defaultRegionMetadata
                       nationalNumber:(NSString **)nationalNumber keepRawInput:(BOOL)keepRawInput
                          phoneNumber:(NBPhoneNumber**)phoneNumber error:(NSError**)error
{
    if (nationalNumber == NULL || phoneNumber == NULL || number.length <= 0) {
        return @0;
    }
    
    NSString *fullNumber = [number copy];
    // Set the default prefix to be something that will never match.
    NSString *possibleCountryIddPrefix = @"";
    if (defaultRegionMetadata != nil) {
        possibleCountryIddPrefix = defaultRegionMetadata.internationalPrefix;
    }
    
    if (possibleCountryIddPrefix == nil) {
        possibleCountryIddPrefix = @"NonMatch";
    }
    
    /** @type {i18n.phonenumbers.PhoneNumber.CountryCodeSource} */
    NBECountryCodeSource countryCodeSource = [self maybeStripInternationalPrefixAndNormalize:&fullNumber
                                                                           possibleIddPrefix:possibleCountryIddPrefix];
    if (keepRawInput) {
        (*phoneNumber).countryCodeSource = [NSNumber numberWithInteger:countryCodeSource];
    }
    
    if (countryCodeSource != NBECountryCodeSourceFROM_DEFAULT_COUNTRY) {
        if (fullNumber.length <= MIN_LENGTH_FOR_NSN_) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"TOO_SHORT_AFTER_IDD:%@", fullNumber]
                                                                 forKey:NSLocalizedDescriptionKey];
            if (error != NULL) {
                (*error) = [NSError errorWithDomain:@"TOO_SHORT_AFTER_IDD" code:0 userInfo:userInfo];
            }
            return @0;
        }
        
        NSNumber *potentialCountryCode = [self extractCountryCode:fullNumber nationalNumber:nationalNumber];
        
        if (![potentialCountryCode isEqualToNumber:@0]) {
            (*phoneNumber).countryCode = potentialCountryCode;
            return potentialCountryCode;
        }
        
        // If this fails, they must be using a strange country calling code that we
        // don't recognize, or that doesn't exist.
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"INVALID_COUNTRY_CODE:%@", potentialCountryCode]
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL) {
            (*error) = [NSError errorWithDomain:@"INVALID_COUNTRY_CODE" code:0 userInfo:userInfo];
        }
        
        return @0;
    } else if (defaultRegionMetadata != nil) {
        // Check to see if the number starts with the country calling code for the
        // default region. If so, we remove the country calling code, and do some
        // checks on the validity of the number before and after.
        NSNumber *defaultCountryCode = defaultRegionMetadata.countryCode;
        NSString *defaultCountryCodeString = [NSString stringWithFormat:@"%@", defaultCountryCode];
        NSString *normalizedNumber = [fullNumber copy];
        
        if ([normalizedNumber hasPrefix:defaultCountryCodeString]) {
            NSString *potentialNationalNumber = [normalizedNumber substringFromIndex:defaultCountryCodeString.length];
            NBPhoneNumberDesc *generalDesc = defaultRegionMetadata.generalDesc;
            
            NSString *validNumberPattern = generalDesc.nationalNumberPattern;
            // Passing null since we don't need the carrier code.
            [self maybeStripNationalPrefixAndCarrierCode:&potentialNationalNumber metadata:defaultRegionMetadata carrierCode:nil];
            
            NSString *potentialNationalNumberStr = [potentialNationalNumber copy];
            NSString *possibleNumberPattern = generalDesc.possibleNumberPattern;
            // If the number was not valid before but is valid now, or if it was too
            // long before, we consider the number with the country calling code
            // stripped to be a better result and keep that instead.
            if ((![self matchesEntirely:validNumberPattern string:fullNumber] &&
                 [self matchesEntirely:validNumberPattern string:potentialNationalNumberStr]) ||
                [self testNumberLengthAgainstPattern:possibleNumberPattern number:fullNumber] == NBEValidationResultTOO_LONG) {
                (*nationalNumber) = [(*nationalNumber) stringByAppendingString:potentialNationalNumberStr];
                if (keepRawInput) {
                    (*phoneNumber).countryCodeSource = [NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN];
                }
                (*phoneNumber).countryCode = defaultCountryCode;
                return defaultCountryCode;
            }
        }
    }
    // No country calling code present.
    (*phoneNumber).countryCode = @0;
    return @0;
}


/**
 * Strips the IDD from the start of the number if present. Helper function used
 * by maybeStripInternationalPrefixAndNormalize.
 *
 * @param {!RegExp} iddPattern the regular expression for the international
 *     prefix.
 * @param {!goog.string.StringBuffer} number the phone number that we wish to
 *     strip any international dialing prefix from.
 * @return {boolean} NO if an international prefix was present.
 * @private
 */
- (BOOL)parsePrefixAsIdd:(NSString *)iddPattern sourceString:(NSString **)number
{
    if (number == NULL) {
        return NO;
    }
    
    NSString *numberStr = [(*number) copy];
    
    if ([self stringPositionByRegex:numberStr regex:iddPattern] == 0) {
        NSTextCheckingResult *matched = [[self matchesByRegex:numberStr regex:iddPattern] objectAtIndex:0];
        NSString *matchedString = [numberStr substringWithRange:matched.range];
        unsigned int matchEnd = (unsigned int)matchedString.length;
        NSString *remainString = [numberStr substringFromIndex:matchEnd];
        
        NSArray *matchedGroups = [_CAPTURING_DIGIT_PATTERN matchesInString:remainString options:0 range:NSMakeRange(0, remainString.length)];
        
        if (matchedGroups && [matchedGroups count] > 0 && [matchedGroups objectAtIndex:0] != nil) {
            NSString *digitMatched = [remainString substringWithRange:((NSTextCheckingResult*)[matchedGroups objectAtIndex:0]).range];
            if (digitMatched.length > 0) {
                NSString *normalizedGroup = [self normalizeDigitsOnly:digitMatched];
                if ([normalizedGroup isEqualToString:@"0"]) {
                    return NO;
                }
            }
        }
        
        (*number) = [remainString copy];
        return YES;
    }
    
    return NO;
}


/**
 * Strips any international prefix (such as +, 00, 011) present in the number
 * provided, normalizes the resulting number, and indicates if an international
 * prefix was present.
 *
 * @param {!goog.string.StringBuffer} number the non-normalized telephone number
 *     that we wish to strip any international dialing prefix from.
 * @param {string} possibleIddPrefix the international direct dialing prefix
 *     from the region we think this number may be dialed in.
 * @return {CountryCodeSource} the corresponding
 *     CountryCodeSource if an international dialing prefix could be removed
 *     from the number, otherwise CountryCodeSource.FROM_DEFAULT_COUNTRY if
 *     the number did not seem to be in international format.
 */
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString **)numberStr possibleIddPrefix:(NSString *)possibleIddPrefix
{
    if (numberStr == NULL || (*numberStr).length == 0) {
        return NBECountryCodeSourceFROM_DEFAULT_COUNTRY;
    }
    
    // Check to see if the number begins with one or more plus signs.
    if ([self isStartingStringByRegex:(*numberStr) regex:LEADING_PLUS_CHARS_PATTERN]) {
        (*numberStr) = [self replaceStringByRegex:(*numberStr) regex:LEADING_PLUS_CHARS_PATTERN withTemplate:@""];
        // Can now normalize the rest of the number since we've consumed the '+'
        // sign at the start.
        (*numberStr) = [self normalizePhoneNumber:(*numberStr)];
        return NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN;
    }
    
    // Attempt to parse the first digits as an international prefix.
    NSString *iddPattern = [possibleIddPrefix copy];
    [self normalizeSB:numberStr];
    
    return [self parsePrefixAsIdd:iddPattern sourceString:numberStr] ? NBECountryCodeSourceFROM_NUMBER_WITH_IDD : NBECountryCodeSourceFROM_DEFAULT_COUNTRY;
}


/**
 * Strips any national prefix (such as 0, 1) present in the number provided.
 *
 * @param {!goog.string.StringBuffer} number the normalized telephone number
 *     that we wish to strip any national dialing prefix from.
 * @param {i18n.phonenumbers.PhoneMetadata} metadata the metadata for the
 *     region that we think this number is from.
 * @param {goog.string.StringBuffer} carrierCode a place to insert the carrier
 *     code if one is extracted.
 * @return {boolean} NO if a national prefix or carrier code (or both) could
 *     be extracted.
 */
- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString **)number metadata:(NBPhoneMetaData*)metadata carrierCode:(NSString **)carrierCode
{
    if (number == NULL) {
        return NO;
    }
    
    NSString *numberStr = [(*number) copy];
    unsigned int numberLength = (unsigned int)numberStr.length;
    NSString *possibleNationalPrefix = metadata.nationalPrefixForParsing;
    
    if (numberLength == 0 || [NBMetadataHelper hasValue:possibleNationalPrefix] == NO) {
        // Early return for numbers of zero length.
        return NO;
    }
    
    // Attempt to parse the first digits as a national prefix.
    NSString *prefixPattern = [NSString stringWithFormat:@"^(?:%@)", possibleNationalPrefix];
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self regularExpressionWithPattern:prefixPattern options:0 error:&error];
    
    NSArray *prefixMatcher = [currentPattern matchesInString:numberStr options:0 range:NSMakeRange(0, numberLength)];
    if (prefixMatcher && [prefixMatcher count] > 0) {
        NSString *nationalNumberRule = metadata.generalDesc.nationalNumberPattern;
        NSTextCheckingResult *firstMatch = [prefixMatcher objectAtIndex:0];
        NSString *firstMatchString = [numberStr substringWithRange:firstMatch.range];
        
        // prefixMatcher[numOfGroups] == null implies nothing was captured by the
        // capturing groups in possibleNationalPrefix; therefore, no transformation
        // is necessary, and we just remove the national prefix.
        unsigned int numOfGroups = (unsigned int)firstMatch.numberOfRanges - 1;
        NSString *transformRule = metadata.nationalPrefixTransformRule;
        NSString *transformedNumber = @"";
        NSRange firstRange = [firstMatch rangeAtIndex:numOfGroups];
        NSString *firstMatchStringWithGroup = (firstRange.location != NSNotFound && firstRange.location < numberStr.length) ? [numberStr substringWithRange:firstRange] : nil;
        BOOL noTransform = (transformRule == nil || transformRule.length == 0 || [NBMetadataHelper hasValue:firstMatchStringWithGroup] == NO);
        
        if (noTransform) {
            transformedNumber = [numberStr substringFromIndex:firstMatchString.length];
        } else {
            transformedNumber = [self replaceFirstStringByRegex:numberStr regex:prefixPattern withTemplate:transformRule];
        }
        // If the original number was viable, and the resultant number is not,
        // we return.
        if ([NBMetadataHelper hasValue:nationalNumberRule ] && [self matchesEntirely:nationalNumberRule string:numberStr] &&
            [self matchesEntirely:nationalNumberRule string:transformedNumber] == NO) {
            return NO;
        }
        
        if ((noTransform && numOfGroups > 0 && [NBMetadataHelper hasValue:firstMatchStringWithGroup]) || (!noTransform && numOfGroups > 1)) {
            if (carrierCode != NULL && (*carrierCode) != nil) {
                (*carrierCode) = [(*carrierCode) stringByAppendingString:firstMatchStringWithGroup];
            }
        } else if ((noTransform && numOfGroups > 0 && [NBMetadataHelper hasValue:firstMatchString]) || (!noTransform && numOfGroups > 1)) {
            if (carrierCode != NULL && (*carrierCode) != nil) {
                (*carrierCode) = [(*carrierCode) stringByAppendingString:firstMatchString];
            }
        }
        
        (*number) = transformedNumber;
        return YES;
    }
    return NO;
}


/**
 * Strips any extension (as in, the part of the number dialled after the call is
 * connected, usually indicated with extn, ext, x or similar) from the end of
 * the number, and returns it.
 *
 * @param {!goog.string.StringBuffer} number the non-normalized telephone number
 *     that we wish to strip the extension from.
 * @return {string} the phone extension.
 */
- (NSString *)maybeStripExtension:(NSString **)number
{
    if (number == NULL) {
        return @"";
    }
    
    NSString *numberStr = [(*number) copy];
    int mStart = [self stringPositionByRegex:numberStr regex:EXTN_PATTERN];
    
    // If we find a potential extension, and the number preceding this is a viable
    // number, we assume it is an extension.
    if (mStart >= 0 && [self isViablePhoneNumber:[numberStr substringWithRange:NSMakeRange(0, mStart)]]) {
        // The numbers are captured into groups in the regular expression.
        NSTextCheckingResult *firstMatch = [self matcheFirstByRegex:numberStr regex:EXTN_PATTERN];
        unsigned int matchedGroupsLength = (unsigned int)[firstMatch numberOfRanges];
        
        for (unsigned int i=1; i<matchedGroupsLength; i++) {
            NSRange curRange = [firstMatch rangeAtIndex:i];
            
            if (curRange.location != NSNotFound && curRange.location < numberStr.length) {
                NSString *matchString = [(*number) substringWithRange:curRange];
                // We go through the capturing groups until we find one that captured
                // some digits. If none did, then we will return the empty string.
                NSString *tokenedString = [numberStr substringWithRange:NSMakeRange(0, mStart)];
                (*number) = @"";
                (*number) = [(*number) stringByAppendingString:tokenedString];
                
                return matchString;
            }
        }
    }
    
    return @"";
}


/**
 * Checks to see that the region code used is valid, or if it is not valid, that
 * the number to parse starts with a + symbol so that we can attempt to infer
 * the region from the number.
 * @param {string} numberToParse number that we are attempting to parse.
 * @param {?string} defaultRegion region that we are expecting the number to be
 *     from.
 * @return {boolean} NO if it cannot use the region provided and the region
 *     cannot be inferred.
 * @private
 */
- (BOOL)checkRegionForParsing:(NSString *)numberToParse defaultRegion:(NSString *)defaultRegion
{
    // If the number is nil or empty, we can't infer the region.
    return [self isValidRegionCode:defaultRegion] ||
    (numberToParse != nil && numberToParse.length > 0 && [self isStartingStringByRegex:numberToParse regex:LEADING_PLUS_CHARS_PATTERN]);
}


/**
 * Parses a string and returns it in proto buffer format. This method will throw
 * a {@link i18n.phonenumbers.Error} if the number is not considered to be a
 * possible number. Note that validation of whether the number is actually a
 * valid number for a particular region is not performed. This can be done
 * separately with {@link #isValidNumber}.
 *
 * @param {?string} numberToParse number that we are attempting to parse. This
 *     can contain formatting such as +, ( and -, as well as a phone number
 *     extension. It can also be provided in RFC3966 format.
 * @param {?string} defaultRegion region that we are expecting the number to be
 *     from. This is only used if the number being parsed is not written in
 *     international format. The country_code for the number in this case would
 *     be stored as that of the default region supplied. If the number is
 *     guaranteed to start with a '+' followed by the country calling code, then
 *     'ZZ' or nil can be supplied.
 * @return {i18n.phonenumbers.PhoneNumber} a phone number proto buffer filled
 *     with the parsed number.
 * @throws {i18n.phonenumbers.Error} if the string is not considered to be a
 *     viable phone number or if no default region was supplied and the number
 *     is not in international format (does not start with +).
 */
- (NBPhoneNumber*)parse:(NSString *)numberToParse defaultRegion:(NSString *)defaultRegion error:(NSError**)error
{
    NSError *anError = nil;
    NBPhoneNumber *phoneNumber = [self parseHelper:numberToParse defaultRegion:defaultRegion keepRawInput:NO checkRegion:YES error:&anError];
    
    if (anError != nil) {
        if (error != NULL) {
            (*error) = [self errorWithObject:anError.description withDomain:anError.domain];
        }
    }
    return phoneNumber;
}

/**
 * Parses a string using the phone's carrier region (when available, ZZ otherwise).
 * This uses the country the sim card in the phone is registered with.
 * For example if you have an AT&T sim card but are in Europe, this will parse the
 * number using +1 (AT&T is a US Carrier) as the default country code.
 * This also works for CDMA phones which don't have a sim card.
 */
- (NBPhoneNumber*)parseWithPhoneCarrierRegion:(NSString *)numberToParse error:(NSError**)error
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    numberToParse = [helper normalizeNonBreakingSpace:numberToParse];
    
    NSString *defaultRegion = nil;
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
    defaultRegion = [self countryCodeByCarrier];
#else
    defaultRegion = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
#endif
    if ([NB_UNKNOWN_REGION isEqualToString:defaultRegion]) {
        // get region from device as a failover (e.g. iPad)
        NSLocale *currentLocale = [NSLocale currentLocale];
        defaultRegion = [currentLocale objectForKey:NSLocaleCountryCode];
    }
    
    return [self parse:numberToParse defaultRegion:defaultRegion error:error];
}

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

static CTTelephonyNetworkInfo* _telephonyNetworkInfo;

- (CTTelephonyNetworkInfo*)telephonyNetworkInfo{
    
    // cache telephony network info;
    // CTTelephonyNetworkInfo objects are unnecessarily created for every call to parseWithPhoneCarrierRegion:error:
    // when in reality this information not change while an app lives in memory
    // real-world performance test while parsing 93 phone numbers:
    // before change:   126ms
    // after change:    32ms
    // using static instance prevents deallocation crashes due to ios bug
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    
    return _telephonyNetworkInfo;
    
}

- (NSString *)countryCodeByCarrier
{
    
    NSString *isoCode = [[self.telephonyNetworkInfo subscriberCellularProvider] isoCountryCode];
    
    // The 2nd part of the if is working around an iOS 7 bug
    // If the SIM card is missing, iOS 7 returns an empty string instead of nil
    if (!isoCode || [isoCode isEqualToString:@""]) {
        isoCode = NB_UNKNOWN_REGION;
    }
    
    return isoCode;
}

#endif


/**
 * Parses a string and returns it in proto buffer format. This method differs
 * from {@link #parse} in that it always populates the raw_input field of the
 * protocol buffer with numberToParse as well as the country_code_source field.
 *
 * @param {string} numberToParse number that we are attempting to parse. This
 *     can contain formatting such as +, ( and -, as well as a phone number
 *     extension.
 * @param {?string} defaultRegion region that we are expecting the number to be
 *     from. This is only used if the number being parsed is not written in
 *     international format. The country calling code for the number in this
 *     case would be stored as that of the default region supplied.
 * @return {i18n.phonenumbers.PhoneNumber} a phone number proto buffer filled
 *     with the parsed number.
 * @throws {i18n.phonenumbers.Error} if the string is not considered to be a
 *     viable phone number or if no default region was supplied.
 */
- (NBPhoneNumber*)parseAndKeepRawInput:(NSString *)numberToParse defaultRegion:(NSString *)defaultRegion error:(NSError**)error
{
    if ([self isValidRegionCode:defaultRegion] == NO) {
        if (numberToParse.length > 0 && [numberToParse hasPrefix:@"+"] == NO) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid country code:%@", numberToParse]
                                                                 forKey:NSLocalizedDescriptionKey];
            if (error != NULL) {
                (*error) = [NSError errorWithDomain:@"INVALID_COUNTRY_CODE" code:0 userInfo:userInfo];
            }
        }
    }
    return [self parseHelper:numberToParse defaultRegion:defaultRegion keepRawInput:YES checkRegion:YES error:error];
}


/**
 * Parses a string and returns it in proto buffer format. This method is the
 * same as the public {@link #parse} method, with the exception that it allows
 * the default region to be nil, for use by {@link #isNumberMatch}.
 *
 * @param {?string} numberToParse number that we are attempting to parse. This
 *     can contain formatting such as +, ( and -, as well as a phone number
 *     extension.
 * @param {?string} defaultRegion region that we are expecting the number to be
 *     from. This is only used if the number being parsed is not written in
 *     international format. The country calling code for the number in this
 *     case would be stored as that of the default region supplied.
 * @param {boolean} keepRawInput whether to populate the raw_input field of the
 *     phoneNumber with numberToParse.
 * @param {boolean} checkRegion should be set to NO if it is permitted for
 *     the default coregion to be nil or unknown ('ZZ').
 * @return {i18n.phonenumbers.PhoneNumber} a phone number proto buffer filled
 *     with the parsed number.
 * @throws {i18n.phonenumbers.Error}
 * @private
 */
- (NBPhoneNumber*)parseHelper:(NSString *)numberToParse defaultRegion:(NSString *)defaultRegion
                 keepRawInput:(BOOL)keepRawInput checkRegion:(BOOL)checkRegion error:(NSError**)error
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    numberToParse = [helper normalizeNonBreakingSpace:numberToParse];
    
    if (numberToParse == nil) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"NOT_A_NUMBER:%@", numberToParse] withDomain:@"NOT_A_NUMBER"];
        }
        
        return nil;
    } else if (numberToParse.length > MAX_INPUT_STRING_LENGTH_) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"TOO_LONG:%@", numberToParse] withDomain:@"TOO_LONG"];
        }
        
        return nil;
    }
    
    NSString *nationalNumber = @"";
    [self buildNationalNumberForParsing:numberToParse nationalNumber:&nationalNumber];
    
    if ([self isViablePhoneNumber:nationalNumber] == NO) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"NOT_A_NUMBER:%@", nationalNumber] withDomain:@"NOT_A_NUMBER"];
        }
        
        return nil;
    }
    
    // Check the region supplied is valid, or that the extracted number starts
    // with some sort of + sign so the number's region can be determined.
    if (checkRegion && [self checkRegionForParsing:nationalNumber defaultRegion:defaultRegion] == NO) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"INVALID_COUNTRY_CODE:%@", defaultRegion]
                                  withDomain:@"INVALID_COUNTRY_CODE"];
        }
        
        return nil;
    }
    
    NBPhoneNumber *phoneNumber = [[NBPhoneNumber alloc] init];
    if (keepRawInput) {
        phoneNumber.rawInput = [numberToParse copy];
    }
    
    // Attempt to parse extension first, since it doesn't require region-specific
    // data and we want to have the non-normalised number here.
    NSString *extension = [self maybeStripExtension:&nationalNumber];
    if (extension.length > 0) {
        phoneNumber.extension = [extension copy];
    }
    
    NBPhoneMetaData *regionMetadata = [helper getMetadataForRegion:defaultRegion];
    // Check to see if the number is given in international format so we know
    // whether this number is from the default region or not.
    NSString *normalizedNationalNumber = @"";
    NSNumber *countryCode = nil;
    NSString *nationalNumberStr = [nationalNumber copy];
    
    {
        NSError *anError = nil;
        countryCode = [self maybeExtractCountryCode:nationalNumberStr
                                           metadata:regionMetadata
                                     nationalNumber:&normalizedNationalNumber
                                       keepRawInput:keepRawInput
                                        phoneNumber:&phoneNumber error:&anError];
        
        if (anError != nil) {
            if ([anError.domain isEqualToString:@"INVALID_COUNTRY_CODE"] && [self stringPositionByRegex:nationalNumberStr
                                                                                                  regex:LEADING_PLUS_CHARS_PATTERN] >= 0)
            {
                // Strip the plus-char, and try again.
                NSError *aNestedError = nil;
                nationalNumberStr = [self replaceStringByRegex:nationalNumberStr regex:LEADING_PLUS_CHARS_PATTERN withTemplate:@""];
                countryCode = [self maybeExtractCountryCode:nationalNumberStr
                                                   metadata:regionMetadata
                                             nationalNumber:&normalizedNationalNumber
                                               keepRawInput:keepRawInput
                                                phoneNumber:&phoneNumber error:&aNestedError];
                if ([countryCode isEqualToNumber:@0]) {
                    if (error != NULL)
                        (*error) = [self errorWithObject:anError.description withDomain:anError.domain];
                    
                    return nil;
                }
            } else {
                if (error != NULL)
                    (*error) = [self errorWithObject:anError.description withDomain:anError.domain];
                
                return nil;
            }
        }
    }
    
    if (![countryCode isEqualToNumber:@0]) {
        NSString *phoneNumberRegion = [self getRegionCodeForCountryCode:countryCode];
        if (phoneNumberRegion != defaultRegion) {
            // Metadata cannot be nil because the country calling code is valid.
            regionMetadata = [self getMetadataForRegionOrCallingCode:countryCode regionCode:phoneNumberRegion];
        }
    } else {
        // If no extracted country calling code, use the region supplied instead.
        // The national number is just the normalized version of the number we were
        // given to parse.
        [self normalizeSB:&nationalNumber];
        normalizedNationalNumber = [normalizedNationalNumber stringByAppendingString:nationalNumber];
        
        if (defaultRegion != nil) {
            countryCode = regionMetadata.countryCode;
            phoneNumber.countryCode = countryCode;
        } else if (keepRawInput) {
            [phoneNumber clearCountryCodeSource];
        }
    }
    
    if (normalizedNationalNumber.length < MIN_LENGTH_FOR_NSN_){
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"TOO_SHORT_NSN:%@", normalizedNationalNumber] withDomain:@"TOO_SHORT_NSN"];
        }
        
        return nil;
    }
    
    if (regionMetadata != nil) {
        NSString *carrierCode = @"";
        [self maybeStripNationalPrefixAndCarrierCode:&normalizedNationalNumber metadata:regionMetadata carrierCode:&carrierCode];
        
        if (keepRawInput) {
            phoneNumber.preferredDomesticCarrierCode = [carrierCode copy];
        }
    }
    
    NSString *normalizedNationalNumberStr = [normalizedNationalNumber copy];
    
    unsigned int lengthOfNationalNumber = (unsigned int)normalizedNationalNumberStr.length;
    if (lengthOfNationalNumber < MIN_LENGTH_FOR_NSN_) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"TOO_SHORT_NSN:%@", normalizedNationalNumber] withDomain:@"TOO_SHORT_NSN"];
        }
        
        return nil;
    }
    
    if (lengthOfNationalNumber > MAX_LENGTH_FOR_NSN_) {
        if (error != NULL) {
            (*error) = [self errorWithObject:[NSString stringWithFormat:@"TOO_LONG:%@", normalizedNationalNumber] withDomain:@"TOO_LONG"];
        }
        
        return nil;
    }
    
    if ([normalizedNationalNumberStr hasPrefix:@"0"]) {
        phoneNumber.italianLeadingZero = YES;
    }
    
    phoneNumber.nationalNumber =  [NSNumber numberWithLongLong:[normalizedNationalNumberStr longLongValue]];
    return phoneNumber;
}


/**
 * Converts numberToParse to a form that we can parse and write it to
 * nationalNumber if it is written in RFC3966; otherwise extract a possible
 * number out of it and write to nationalNumber.
 *
 * @param {?string} numberToParse number that we are attempting to parse. This
 *     can contain formatting such as +, ( and -, as well as a phone number
 *     extension.
 * @param {!goog.string.StringBuffer} nationalNumber a string buffer for storing
 *     the national significant number.
 * @private
 */
- (void)buildNationalNumberForParsing:(NSString *)numberToParse nationalNumber:(NSString **)nationalNumber
{
    if (nationalNumber == NULL)
        return;
    
    int indexOfPhoneContext = [self indexOfStringByString:numberToParse target:RFC3966_PHONE_CONTEXT];
    if (indexOfPhoneContext > 0)
    {
        unsigned int phoneContextStart = indexOfPhoneContext + (unsigned int)RFC3966_PHONE_CONTEXT.length;
        // If the phone context contains a phone number prefix, we need to capture
        // it, whereas domains will be ignored.
        if ([numberToParse characterAtIndex:phoneContextStart] == '+')
        {
            // Additional parameters might follow the phone context. If so, we will
            // remove them here because the parameters after phone context are not
            // important for parsing the phone number.
            NSRange foundRange = [numberToParse rangeOfString:@";" options:NSLiteralSearch range:NSMakeRange(phoneContextStart, numberToParse.length - phoneContextStart)];
            if (foundRange.location != NSNotFound)
            {
                NSRange subRange = NSMakeRange(phoneContextStart, foundRange.location - phoneContextStart);
                (*nationalNumber) = [(*nationalNumber) stringByAppendingString:[numberToParse substringWithRange:subRange]];
            }
            else
            {
                (*nationalNumber) = [(*nationalNumber) stringByAppendingString:[numberToParse substringFromIndex:phoneContextStart]];
            }
        }
        
        // Now append everything between the "tel:" prefix and the phone-context.
        // This should include the national number, an optional extension or
        // isdn-subaddress component.
        unsigned int rfc3966Start = [self indexOfStringByString:numberToParse target:RFC3966_PREFIX] + (unsigned int)RFC3966_PREFIX.length;
        NSString *subString = [numberToParse substringWithRange:NSMakeRange(rfc3966Start, indexOfPhoneContext - rfc3966Start)];
        (*nationalNumber) = [(*nationalNumber) stringByAppendingString:subString];
    }
    else
    {
        // Extract a possible number from the string passed in (this strips leading
        // characters that could not be the start of a phone number.)
        (*nationalNumber) = [(*nationalNumber) stringByAppendingString:[self extractPossibleNumber:numberToParse]];
    }
    
    // Delete the isdn-subaddress and everything after it if it is present.
    // Note extension won't appear at the same time with isdn-subaddress
    // according to paragraph 5.3 of the RFC3966 spec,
    NSString *nationalNumberStr = [(*nationalNumber) copy];
    int indexOfIsdn = [self indexOfStringByString:nationalNumberStr target:RFC3966_ISDN_SUBADDRESS];
    if (indexOfIsdn > 0)
    {
        (*nationalNumber) = @"";
        (*nationalNumber) = [(*nationalNumber) stringByAppendingString:[nationalNumberStr substringWithRange:NSMakeRange(0, indexOfIsdn)]];
    }
    // If both phone context and isdn-subaddress are absent but other
    // parameters are present, the parameters are left in nationalNumber. This
    // is because we are concerned about deleting content from a potential
    // number string when there is no strong evidence that the number is
    // actually written in RFC3966.
}


/**
 * Takes two phone numbers and compares them for equality.
 *
 * <p>Returns EXACT_MATCH if the country_code, NSN, presence of a leading zero
 * for Italian numbers and any extension present are the same. Returns NSN_MATCH
 * if either or both has no region specified, and the NSNs and extensions are
 * the same. Returns SHORT_NSN_MATCH if either or both has no region specified,
 * or the region specified is the same, and one NSN could be a shorter version
 * of the other number. This includes the case where one has an extension
 * specified, and the other does not. Returns NO_MATCH otherwise. For example,
 * the numbers +1 345 657 1234 and 657 1234 are a SHORT_NSN_MATCH. The numbers
 * +1 345 657 1234 and 345 657 are a NO_MATCH.
 *
 * @param {i18n.phonenumbers.PhoneNumber|string} firstNumberIn first number to
 *     compare. If it is a string it can contain formatting, and can have
 *     country calling code specified with + at the start.
 * @param {i18n.phonenumbers.PhoneNumber|string} secondNumberIn second number to
 *     compare. If it is a string it can contain formatting, and can have
 *     country calling code specified with + at the start.
 * @return {MatchType} NOT_A_NUMBER, NO_MATCH,
 *     SHORT_NSN_MATCH, NSN_MATCH or EXACT_MATCH depending on the level of
 *     equality of the two numbers, described in the method definition.
 */
- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn error:(NSError**)error
{
    NBEMatchType res = 0;
    @try {
        res = [self isNumberMatch:firstNumberIn second:secondNumberIn];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}

- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn
{
    // If the input arguements are strings parse them to a proto buffer format.
    // Else make copies of the phone numbers so that the numbers passed in are not
    // edited.
    /** @type {i18n.phonenumbers.PhoneNumber} */
    NBPhoneNumber *firstNumber = nil, *secondNumber = nil;
    
    if ([firstNumberIn isKindOfClass:[NSString class]]) {
        // First see if the first number has an implicit country calling code, by
        // attempting to parse it.
        NSError *anError;
        firstNumber = [self parse:firstNumberIn defaultRegion:NB_UNKNOWN_REGION error:&anError];
        
        if (anError != nil) {
            if ([anError.domain isEqualToString:@"INVALID_COUNTRY_CODE"] == NO) {
                return NBEMatchTypeNOT_A_NUMBER;
            }
            // The first number has no country calling code. EXACT_MATCH is no longer
            // possible. We parse it as if the region was the same as that for the
            // second number, and if EXACT_MATCH is returned, we replace this with
            // NSN_MATCH.
            if ([secondNumberIn isKindOfClass:[NSString class]] == NO) {
                NSString *secondNumberRegion = [self getRegionCodeForCountryCode:((NBPhoneNumber*)secondNumberIn).countryCode];
                if (secondNumberRegion != NB_UNKNOWN_REGION) {
                    NSError *aNestedError;
                    firstNumber = [self parse:firstNumberIn defaultRegion:secondNumberRegion error:&aNestedError];
                    
                    if (aNestedError != nil) {
                        return NBEMatchTypeNOT_A_NUMBER;
                    }
                    
                    NBEMatchType match = [self isNumberMatch:firstNumber second:secondNumberIn];
                    if (match == NBEMatchTypeEXACT_MATCH) {
                        return NBEMatchTypeNSN_MATCH;
                    }
                    return match;
                }
            }
            // If the second number is a string or doesn't have a valid country
            // calling code, we parse the first number without country calling code.
            NSError *aNestedError;
            firstNumber = [self parseHelper:firstNumberIn defaultRegion:nil keepRawInput:NO checkRegion:NO error:&aNestedError];
            if (aNestedError != nil) {
                return NBEMatchTypeNOT_A_NUMBER;
            }
        }
    } else {
        firstNumber = [firstNumberIn copy];
    }
    
    if ([secondNumberIn isKindOfClass:[NSString class]]) {
        NSError *parseError;
        secondNumber = [self parse:secondNumberIn defaultRegion:NB_UNKNOWN_REGION error:&parseError];
        if (parseError != nil) {
            if ([parseError.domain isEqualToString:@"INVALID_COUNTRY_CODE"] == NO) {
                return NBEMatchTypeNOT_A_NUMBER;
            }
            return [self isNumberMatch:secondNumberIn second:firstNumber];
        } else {
            return [self isNumberMatch:firstNumberIn second:secondNumber];
        }
    }
    else {
        secondNumber = [secondNumberIn copy];
    }
    
    // First clear raw_input, country_code_source and
    // preferred_domestic_carrier_code fields and any empty-string extensions so
    // that we can use the proto-buffer equality method.
    firstNumber.rawInput = @"";
    [firstNumber clearCountryCodeSource];
    firstNumber.preferredDomesticCarrierCode = @"";
    
    secondNumber.rawInput = @"";
    [secondNumber clearCountryCodeSource];
    secondNumber.preferredDomesticCarrierCode = @"";
    
    if (firstNumber.extension != nil && firstNumber.extension.length == 0) {
        firstNumber.extension = nil;
    }
    
    if (secondNumber.extension != nil && secondNumber.extension.length == 0) {
        secondNumber.extension = nil;
    }
    
    // Early exit if both had extensions and these are different.
    if ([NBMetadataHelper hasValue:firstNumber.extension] && [NBMetadataHelper hasValue:secondNumber.extension] &&
        [firstNumber.extension isEqualToString:secondNumber.extension] == NO) {
        return NBEMatchTypeNO_MATCH;
    }
    
    NSNumber *firstNumberCountryCode = firstNumber.countryCode;
    NSNumber *secondNumberCountryCode = secondNumber.countryCode;
    
    // Both had country_code specified.
    if (![firstNumberCountryCode isEqualToNumber:@0] && ![secondNumberCountryCode isEqualToNumber:@0]) {
        if ([firstNumber isEqual:secondNumber]) {
            return NBEMatchTypeEXACT_MATCH;
        } else if ([firstNumberCountryCode isEqualToNumber:secondNumberCountryCode] && [self isNationalNumberSuffixOfTheOther:firstNumber second:secondNumber]) {
            // A SHORT_NSN_MATCH occurs if there is a difference because of the
            // presence or absence of an 'Italian leading zero', the presence or
            // absence of an extension, or one NSN being a shorter variant of the
            // other.
            return NBEMatchTypeSHORT_NSN_MATCH;
        }
        // This is not a match.
        return NBEMatchTypeNO_MATCH;
    }
    // Checks cases where one or both country_code fields were not specified. To
    // make equality checks easier, we first set the country_code fields to be
    // equal.
    firstNumber.countryCode = @0;
    secondNumber.countryCode = @0;
    // If all else was the same, then this is an NSN_MATCH.
    if ([firstNumber isEqual:secondNumber]) {
        return NBEMatchTypeNSN_MATCH;
    }
    
    if ([self isNationalNumberSuffixOfTheOther:firstNumber second:secondNumber]) {
        return NBEMatchTypeSHORT_NSN_MATCH;
    }
    return NBEMatchTypeNO_MATCH;
}


/**
 * Returns NO when one national number is the suffix of the other or both are
 * the same.
 *
 * @param {i18n.phonenumbers.PhoneNumber} firstNumber the first PhoneNumber
 *     object.
 * @param {i18n.phonenumbers.PhoneNumber} secondNumber the second PhoneNumber
 *     object.
 * @return {boolean} NO if one PhoneNumber is the suffix of the other one.
 * @private
 */
- (BOOL)isNationalNumberSuffixOfTheOther:(NBPhoneNumber*)firstNumber second:(NBPhoneNumber*)secondNumber
{
    NSString *firstNumberNationalNumber = [NSString stringWithFormat:@"%@", firstNumber.nationalNumber];
    NSString *secondNumberNationalNumber = [NSString stringWithFormat:@"%@", secondNumber.nationalNumber];
    
    // Note that endsWith returns NO if the numbers are equal.
    return [firstNumberNationalNumber hasSuffix:secondNumberNationalNumber] ||
    [secondNumberNationalNumber hasSuffix:firstNumberNationalNumber];
}


/**
 * Returns NO if the number can be dialled from outside the region, or
 * unknown. If the number can only be dialled from within the region, returns
 * NO. Does not check the number is a valid number.
 * TODO: Make this method public when we have enough metadata to make it
 * worthwhile. Currently visible for testing purposes only.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone-number for which we
 *     want to know whether it is diallable from outside the region.
 * @return {boolean} NO if the number can only be dialled from within the
 *     country.
 */
- (BOOL)canBeInternationallyDialled:(NBPhoneNumber*)number error:(NSError**)error
{
    BOOL res = NO;
    @try {
        res = [self canBeInternationallyDialled:number];
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:exception.reason
                                                             forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            (*error) = [NSError errorWithDomain:exception.name code:0 userInfo:userInfo];
    }
    return res;
}

- (BOOL)canBeInternationallyDialled:(NBPhoneNumber*)number
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    NBPhoneMetaData *metadata = [helper getMetadataForRegion:[self getRegionCodeForNumber:number]];
    if (metadata == nil) {
        // Note numbers belonging to non-geographical entities (e.g. +800 numbers)
        // are always internationally diallable, and will be caught here.
        return YES;
    }
    NSString *nationalSignificantNumber = [self getNationalSignificantNumber:number];
    return [self isNumberMatchingDesc:nationalSignificantNumber numberDesc:metadata.noInternationalDialling] == NO;
}


/**
 * Check whether the entire input sequence can be matched against the regular
 * expression.
 *
 * @param {!RegExp|string} regex the regular expression to match against.
 * @param {string} str the string to test.
 * @return {boolean} NO if str can be matched entirely against regex.
 * @private
 */
- (BOOL)matchesEntirely:(NSString *)regex string:(NSString *)str
{
    if ([regex isEqualToString:@"NA"]) {
        return NO;
    }
    
    NSError *error = nil;
    NSRegularExpression *currentPattern = [self entireRegularExpressionWithPattern:regex options:0 error:&error];
    NSRange stringRange = NSMakeRange(0, str.length);
    NSTextCheckingResult *matchResult = [currentPattern firstMatchInString:str options:NSMatchingAnchored range:stringRange];
    
    if (matchResult != nil) {
        BOOL matchIsEntireString = NSEqualRanges(matchResult.range, stringRange);
        if (matchIsEntireString)
        {
            return YES;
        }
    }
    
    return NO;
}

@end
