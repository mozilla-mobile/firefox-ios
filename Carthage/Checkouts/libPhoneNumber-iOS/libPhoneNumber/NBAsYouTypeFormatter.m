//
//  NBAsYouTypeFormatter.m
//  libPhoneNumber
//
//  Created by ishtar on 13. 2. 25..
//

#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumberDefines.h"

#import "NBMetadataHelper.h"

#import "NBPhoneNumberUtil.h"
#import "NBPhoneMetaData.h"
#import "NBNumberFormat.h"


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


@interface NBAsYouTypeFormatter ()

@property (nonatomic, strong, readwrite) NSString *DIGIT_PLACEHOLDER_;
@property (nonatomic, assign, readwrite) NSString *SEPARATOR_BEFORE_NATIONAL_NUMBER_;
@property (nonatomic, strong, readwrite) NSString *currentOutput_, *currentFormattingPattern_;
@property (nonatomic, strong, readwrite) NSString *defaultCountry_;
@property (nonatomic, strong, readwrite) NSString *nationalPrefixExtracted_;
@property (nonatomic, strong, readwrite) NSMutableString *formattingTemplate_, *accruedInput_, *prefixBeforeNationalNumber_, *accruedInputWithoutFormatting_, *nationalNumber_;
@property (nonatomic, strong, readwrite) NSRegularExpression *DIGIT_PATTERN_, *NATIONAL_PREFIX_SEPARATORS_PATTERN_, *CHARACTER_CLASS_PATTERN_, *STANDALONE_DIGIT_PATTERN_;
@property (nonatomic, strong, readwrite) NSRegularExpression *ELIGIBLE_FORMAT_PATTERN_;
@property (nonatomic, assign, readwrite) BOOL ableToFormat_, inputHasFormatting_, isCompleteNumber_, isExpectingCountryCallingCode_, shouldAddSpaceAfterNationalPrefix_;
@property (nonatomic, strong, readwrite) NBPhoneNumberUtil *phoneUtil_;
@property (nonatomic, assign, readwrite) NSUInteger lastMatchPosition_, originalPosition_, positionToRemember_;
@property (nonatomic, assign, readwrite) NSUInteger MIN_LEADING_DIGITS_LENGTH_;
@property (nonatomic, strong, readwrite) NSMutableArray *possibleFormats_;
@property (nonatomic, strong, readwrite) NBPhoneMetaData *currentMetaData_, *defaultMetaData_, *EMPTY_METADATA_;

@end


@implementation NBAsYouTypeFormatter

- (id)init
{
    self = [super init];
    
    if (self) {
        _isSuccessfulFormatting = NO;
        /**
         * The digits that have not been entered yet will be represented by a \u2008,
         * the punctuation space.
         * @const
         * @type {string}
         * @private
         */
        self.DIGIT_PLACEHOLDER_ = @"\u2008";
        
        /**
         * Character used when appropriate to separate a prefix, such as a long NDD or a
         * country calling code, from the national number.
         * @const
         * @type {string}
         * @private
         */
        self.SEPARATOR_BEFORE_NATIONAL_NUMBER_ = @" ";
        
        /**
         * This is the minimum length of national number accrued that is required to
         * trigger the formatter. The first element of the leadingDigitsPattern of
         * each numberFormat contains a regular expression that matches up to this
         * number of digits.
         * @const
         * @type {number}
         * @private
         */
        self.MIN_LEADING_DIGITS_LENGTH_ = 3;
        
        /**
         * @type {string}
         * @private
         */
        self.currentOutput_ = @"";
        
        /**
         * @type {!goog.string.StringBuffer}
         * @private
         */
        self.formattingTemplate_ = [NSMutableString stringWithString:@""];
        
        NSError *anError = nil;
        
        /**
         * @type {RegExp}
         * @private
         */
        self.DIGIT_PATTERN_ = [NSRegularExpression regularExpressionWithPattern:self.DIGIT_PLACEHOLDER_ options:0 error:&anError];
        
        /**
         * A set of characters that, if found in a national prefix formatting rules, are
         * an indicator to us that we should separate the national prefix from the
         * number when formatting.
         * @const
         * @type {RegExp}
         * @private
         */
        self.NATIONAL_PREFIX_SEPARATORS_PATTERN_ = [NSRegularExpression regularExpressionWithPattern:@"[- ]" options:0 error:&anError];
        
        /**
         * A pattern that is used to match character classes in regular expressions.
         * An example of a character class is [1-4].
         * @const
         * @type {RegExp}
         * @private
         */
        self.CHARACTER_CLASS_PATTERN_ = [NSRegularExpression regularExpressionWithPattern:@"\\[([^\\[\\]])*\\]" options:0 error:&anError];
        
        /**
         * Any digit in a regular expression that actually denotes a digit. For
         * example, in the regular expression 80[0-2]\d{6,10}, the first 2 digits
         * (8 and 0) are standalone digits, but the rest are not.
         * Two look-aheads are needed because the number following \\d could be a
         * two-digit number, since the phone number can be as long as 15 digits.
         * @const
         * @type {RegExp}
         * @private
         */
        self.STANDALONE_DIGIT_PATTERN_ = [NSRegularExpression regularExpressionWithPattern:@"\\d(?=[^,}][^,}])" options:0 error:&anError];
        
        /**
         * A pattern that is used to determine if a numberFormat under availableFormats
         * is eligible to be used by the AYTF. It is eligible when the format element
         * under numberFormat contains groups of the dollar sign followed by a single
         * digit, separated by valid phone number punctuation. This prevents invalid
         * punctuation (such as the star sign in Israeli star numbers) getting into the
         * output of the AYTF.
         * @const
         * @type {RegExp}
         * @private
         */
        NSString *eligible_format = @"^[-x‐-―−ー－-／ ­​⁠　()（）［］.\\[\\]/~⁓∼～]*(\\$\\d[-x‐-―−ー－-／ ­​⁠　()（）［］.\\[\\]/~⁓∼～]*)+$";
        self.ELIGIBLE_FORMAT_PATTERN_ = [NSRegularExpression regularExpressionWithPattern:eligible_format options:0 error:&anError];
        
        /**
         * The pattern from numberFormat that is currently used to create
         * formattingTemplate.
         * @type {string}
         * @private
         */
        self.currentFormattingPattern_ = @"";
        
        /**
         * @type {!goog.string.StringBuffer}
         * @private
         */
        self.accruedInput_ = [NSMutableString stringWithString:@""];
        
        /**
         * @type {!goog.string.StringBuffer}
         * @private
         */
        self.accruedInputWithoutFormatting_ = [NSMutableString stringWithString:@""];
        
        /**
         * This indicates whether AsYouTypeFormatter is currently doing the
         * formatting.
         * @type {BOOL}
         * @private
         */
        self.ableToFormat_ = YES;
        
        /**
         * Set to YES when users enter their own formatting. AsYouTypeFormatter will
         * do no formatting at all when this is set to YES.
         * @type {BOOL}
         * @private
         */
        self.inputHasFormatting_ = NO;
        
        /**
         * This is set to YES when we know the user is entering a full national
         * significant number, since we have either detected a national prefix or an
         * international dialing prefix. When this is YES, we will no longer use
         * local number formatting patterns.
         * @type {BOOL}
         * @private
         */
        self.isCompleteNumber_ = NO;
        
        /**
         * @type {BOOL}
         * @private
         */
        self.isExpectingCountryCallingCode_ = NO;
        
        /**
         * @type {number}
         * @private
         */
        self.lastMatchPosition_ = 0;
        
        /**
         * The position of a digit upon which inputDigitAndRememberPosition is most
         * recently invoked, as found in the original sequence of characters the user
         * entered.
         * @type {number}
         * @private
         */
        self.originalPosition_ = 0;
        
        /**
         * The position of a digit upon which inputDigitAndRememberPosition is most
         * recently invoked, as found in accruedInputWithoutFormatting.
         * entered.
         * @type {number}
         * @private
         */
        self.positionToRemember_ = 0;
        
        /**
         * This contains anything that has been entered so far preceding the national
         * significant number, and it is formatted (e.g. with space inserted). For
         * example, this can contain IDD, country code, and/or NDD, etc.
         * @type {!goog.string.StringBuffer}
         * @private
         */
        self.prefixBeforeNationalNumber_ = [NSMutableString stringWithString:@""];
        
        /**
         * @type {BOOL}
         * @private
         */
        self.shouldAddSpaceAfterNationalPrefix_ = NO;
        
        /**
         * This contains the national prefix that has been extracted. It contains only
         * digits without formatting.
         * @type {string}
         * @private
         */
        self.nationalPrefixExtracted_ = @"";
        
        /**
         * @type {!goog.string.StringBuffer}
         * @private
         */
        self.nationalNumber_ = [NSMutableString stringWithString:@""];
        
        /**
         * @type {Array.<i18n.phonenumbers.NumberFormat>}
         * @private
         */
        self.possibleFormats_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

/**
 * Constructs an AsYouTypeFormatter for the specific region.
 *
 * @param {string} regionCode the ISO 3166-1 two-letter region code that denotes
 *     the region where the phone number is being entered.
 * @constructor
 */

- (id)initWithRegionCode:(NSString*)regionCode
{
	return [self initWithRegionCode:regionCode bundle:[NSBundle mainBundle]];
}

- (id)initWithRegionCodeForTest:(NSString*)regionCode
{
	return [self initWithRegionCodeForTest:regionCode bundle:[NSBundle mainBundle]];
}

- (id)initWithRegionCode:(NSString*)regionCode bundle:(NSBundle *)bundle
{
    self = [self init];
	if (self) {
        /**
		* @private
		* @type {i18n.phonenumbers.PhoneNumberUtil}
		*/
        self.phoneUtil_ = [[NBPhoneNumberUtil alloc] init];
        self.defaultCountry_ = regionCode;
        self.currentMetaData_ = [self getMetadataForRegion_:self.defaultCountry_];
        /**
         * @type {i18n.phonenumbers.PhoneMetadata}
         * @private
         */
        self.defaultMetaData_ = self.currentMetaData_;
        
        /**
         * @const
         * @type {i18n.phonenumbers.PhoneMetadata}
         * @private
         */
        self.EMPTY_METADATA_ = [[NBPhoneMetaData alloc] init];
        [self.EMPTY_METADATA_ setInternationalPrefix:@"NA"];
    }
    
    return self;

}

- (id)initWithRegionCodeForTest:(NSString*)regionCode bundle:(NSBundle *)bundle
{
	self = [self init];
    
    if (self) {
        self.phoneUtil_ = [[NBPhoneNumberUtil alloc] init];
        
        self.defaultCountry_ = regionCode;
        self.currentMetaData_ = [self getMetadataForRegion_:self.defaultCountry_];
        self.defaultMetaData_ = self.currentMetaData_;
        self.EMPTY_METADATA_ = [[NBPhoneMetaData alloc] init];
        [self.EMPTY_METADATA_ setInternationalPrefix:@"NA"];
    }
    
    return self;
}

/**
 * The metadata needed by this class is the same for all regions sharing the
 * same country calling code. Therefore, we return the metadata for "main"
 * region for this country calling code.
 * @param {string} regionCode an ISO 3166-1 two-letter region code.
 * @return {i18n.phonenumbers.PhoneMetadata} main metadata for this region.
 * @private
 */
- (NBPhoneMetaData*)getMetadataForRegion_:(NSString*)regionCode
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    /** @type {number} */
    NSNumber *countryCallingCode = [self.phoneUtil_ getCountryCodeForRegion:regionCode];
    /** @type {string} */
    NSString *mainCountry = [self.phoneUtil_ getRegionCodeForCountryCode:countryCallingCode];
    /** @type {i18n.phonenumbers.PhoneMetadata} */
    NBPhoneMetaData *metadata = [helper getMetadataForRegion:mainCountry];
    if (metadata != nil) {
        return metadata;
    }
    // Set to a default instance of the metadata. This allows us to function with
    // an incorrect region code, even if formatting only works for numbers
    // specified with '+'.
    return self.EMPTY_METADATA_;
};


/**
 * @return {BOOL} YES if a new template is created as opposed to reusing the
 *     existing template.
 * @private
 */
- (BOOL)maybeCreateNewTemplate_
{
    // When there are multiple available formats, the formatter uses the first
    // format where a formatting template could be created.
    /** @type {number} */
    unsigned int possibleFormatsLength = (unsigned int)[self.possibleFormats_ count];
    for (unsigned int i = 0; i < possibleFormatsLength; ++i)
    {
        /** @type {i18n.phonenumbers.NumberFormat} */
        NBNumberFormat *numberFormat = [self.possibleFormats_ safeObjectAtIndex:i];
        /** @type {string} */
        NSString *pattern = numberFormat.pattern;
        
        if (!pattern.length || [self.currentFormattingPattern_ isEqualToString:pattern]) {
            return NO;
        }
        
        if ([self createFormattingTemplate_:numberFormat ])
        {
            self.currentFormattingPattern_ = pattern;
            NSRange nationalPrefixRange = NSMakeRange(0, [numberFormat.nationalPrefixFormattingRule length]);
            if (nationalPrefixRange.length > 0) {
                NSTextCheckingResult *matchResult =
                [self.NATIONAL_PREFIX_SEPARATORS_PATTERN_ firstMatchInString:numberFormat.nationalPrefixFormattingRule
                                                                     options:0
                                                                       range:nationalPrefixRange];
                self.shouldAddSpaceAfterNationalPrefix_ = (matchResult != nil);
            } else {
                self.shouldAddSpaceAfterNationalPrefix_ = NO;
            }
            // With a new formatting template, the matched position using the old
            // template needs to be reset.
            self.lastMatchPosition_ = 0;
            return YES;
        }
    }
    self.ableToFormat_ = NO;
    return NO;
};


/**
 * @param {string} leadingThreeDigits first three digits of entered number.
 * @private
 */
- (void)getAvailableFormats_:(NSString*)leadingDigits
{
    /** @type {Array.<i18n.phonenumbers.NumberFormat>} */
    BOOL isIntlNumberFormats = (self.isCompleteNumber_ && self.currentMetaData_.intlNumberFormats.count > 0);
    NSMutableArray *formatList = isIntlNumberFormats ? self.currentMetaData_.intlNumberFormats : self.currentMetaData_.numberFormats;
    
    /** @type {number} */
    unsigned int formatListLength = (unsigned int)formatList.count;
    
    for (unsigned int i = 0; i < formatListLength; ++i)
    {
        /** @type {i18n.phonenumbers.NumberFormat} */
        NBNumberFormat *format = [formatList safeObjectAtIndex:i];
        /** @type {BOOL} */
        BOOL nationalPrefixIsUsedByCountry = (self.currentMetaData_.nationalPrefix && self.currentMetaData_.nationalPrefix.length > 0);
        
        if (!nationalPrefixIsUsedByCountry || self.isCompleteNumber_ || format.nationalPrefixOptionalWhenFormatting ||
            [self.phoneUtil_ formattingRuleHasFirstGroupOnly:format.nationalPrefixFormattingRule])
        {
            if ([self isFormatEligible_:format.format]) {
                [self.possibleFormats_ addObject:format];
            }
        }
    }
    
    [self narrowDownPossibleFormats_:leadingDigits];
};


/**
 * @param {string} format
 * @return {BOOL}
 * @private
 */
- (BOOL)isFormatEligible_:(NSString*)format
{
    if ( !format.length ) {
        return NO;        
    }
    NSTextCheckingResult *matchResult =
        [self.ELIGIBLE_FORMAT_PATTERN_ firstMatchInString:format options:0 range:NSMakeRange(0, [format length])];
    return (matchResult != nil);
};


/**
 * @param {string} leadingDigits
 * @private
 */
- (void)narrowDownPossibleFormats_:(NSString *)leadingDigits
{
    /** @type {Array.<i18n.phonenumbers.NumberFormat>} */
    NSMutableArray *possibleFormats = [[NSMutableArray alloc] init];
    /** @type {number} */
    NSUInteger indexOfLeadingDigitsPattern = (unsigned int)leadingDigits.length - self.MIN_LEADING_DIGITS_LENGTH_;
    /** @type {number} */
    NSUInteger possibleFormatsLength = (unsigned int)self.possibleFormats_.count;
    
    for (NSUInteger i = 0; i < possibleFormatsLength; ++i)
    {
        /** @type {i18n.phonenumbers.NumberFormat} */
        NBNumberFormat *format = [self.possibleFormats_ safeObjectAtIndex:i];
        
        if (format.leadingDigitsPatterns.count == 0) {
            // Keep everything that isn't restricted by leading digits.
            [possibleFormats addObject:format];
            continue;
        }
        
        /** @type {number} */
        NSInteger lastLeadingDigitsPattern = MIN(indexOfLeadingDigitsPattern, format.leadingDigitsPatterns.count - 1);
        
        /** @type {string} */
        NSString *leadingDigitsPattern = [format.leadingDigitsPatterns safeObjectAtIndex:lastLeadingDigitsPattern];

        if ([self.phoneUtil_ stringPositionByRegex:leadingDigits regex:leadingDigitsPattern] == 0) {
            [possibleFormats addObject:format];
        }
    }
    self.possibleFormats_ = possibleFormats;
};


/**
 * @param {i18n.phonenumbers.NumberFormat} format
 * @return {BOOL}
 * @private
 */
- (BOOL)createFormattingTemplate_:(NBNumberFormat*)format
{
    /** @type {string} */
    NSString *numberPattern = format.pattern;
    
    // The formatter doesn't format numbers when numberPattern contains '|', e.g.
    // (20|3)\d{4}. In those cases we quickly return.
    NSRange stringRange = [numberPattern rangeOfString:@"|"];
    if (stringRange.location != NSNotFound) {
        return NO;
    }
    
    // Replace anything in the form of [..] with \d
    numberPattern = [self.CHARACTER_CLASS_PATTERN_ stringByReplacingMatchesInString:numberPattern
                                                                            options:0 range:NSMakeRange(0, [numberPattern length])
                                                                       withTemplate:@"\\\\d"];
    
    // Replace any standalone digit (not the one in d{}) with \d
    numberPattern = [self.STANDALONE_DIGIT_PATTERN_ stringByReplacingMatchesInString:numberPattern
                                                                             options:0 range:NSMakeRange(0, [numberPattern length])
                                                                        withTemplate:@"\\\\d"];
    self.formattingTemplate_ = [NSMutableString stringWithString:@""];
    
    /** @type {string} */
    NSString *tempTemplate = [self getFormattingTemplate_:numberPattern numberFormat:format.format];
    if (tempTemplate.length > 0) {
        [self.formattingTemplate_ appendString:tempTemplate];
        return YES;
    }
    return NO;
};


/**
 * Gets a formatting template which can be used to efficiently format a
 * partial number where digits are added one by one.
 *
 * @param {string} numberPattern
 * @param {string} numberFormat
 * @return {string}
 * @private
 */
- (NSString*)getFormattingTemplate_:(NSString*)numberPattern numberFormat:(NSString*)numberFormat
{
    // Creates a phone number consisting only of the digit 9 that matches the
    // numberPattern by applying the pattern to the longestPhoneNumber string.
    /** @type {string} */
    NSString *longestPhoneNumber = @"999999999999999";
    
    /** @type {Array.<string>} */
    NSArray *m = [self.phoneUtil_ matchedStringByRegex:longestPhoneNumber regex:numberPattern];
    
    // this match will always succeed
    /** @type {string} */
    NSString *aPhoneNumber = [m safeObjectAtIndex:0];
    // No formatting template can be created if the number of digits entered so
    // far is longer than the maximum the current formatting rule can accommodate.
    if (aPhoneNumber.length < self.nationalNumber_.length) {
        return @"";
    }
    // Formats the number according to numberFormat
    /** @type {string} */
    NSString *template = [self.phoneUtil_ replaceStringByRegex:aPhoneNumber regex:numberPattern withTemplate:numberFormat];
    
    // Replaces each digit with character DIGIT_PLACEHOLDER
    template = [self.phoneUtil_ replaceStringByRegex:template regex:@"9" withTemplate:self.DIGIT_PLACEHOLDER_];
    return template;
};


/**
 * Clears the internal state of the formatter, so it can be reused.
 */
- (void)clear
{
    self.currentOutput_ = @"";
    self.accruedInput_ = [NSMutableString stringWithString:@""];
    self.accruedInputWithoutFormatting_ = [NSMutableString stringWithString:@""];
    self.formattingTemplate_ = [NSMutableString stringWithString:@""];
    self.lastMatchPosition_ = 0;
    self.currentFormattingPattern_ = @"";
    self.prefixBeforeNationalNumber_ = [NSMutableString stringWithString:@""];
    self.nationalPrefixExtracted_ = @"";
    self.nationalNumber_ = [NSMutableString stringWithString:@""];
    self.ableToFormat_ = YES;
    self.inputHasFormatting_ = NO;
    self.positionToRemember_ = 0;
    self.originalPosition_ = 0;
    self.isCompleteNumber_ = NO;
    self.isExpectingCountryCallingCode_ = NO;
    [self.possibleFormats_ removeAllObjects];
    self.shouldAddSpaceAfterNationalPrefix_ = NO;
    
    if (self.currentMetaData_ != self.defaultMetaData_) {
        self.currentMetaData_ = [self getMetadataForRegion_:self.defaultCountry_];
    }
}

- (NSString*)removeLastDigitAndRememberPosition
{
    NSString *accruedInputWithoutFormatting = [self.accruedInput_ copy];
    [self clear];
    
    NSString *result = @"";
    
    if (accruedInputWithoutFormatting.length <= 0) {
        return result;
    }
    
    for (unsigned int i=0; i<accruedInputWithoutFormatting.length - 1; i++) {
        NSString *ch = [accruedInputWithoutFormatting substringWithRange:NSMakeRange(i, 1)];
        result = [self inputDigitAndRememberPosition:ch];
    }
    
    return result;
}

- (NSString*)removeLastDigit
{
    NSString *accruedInputWithoutFormatting = [self.accruedInput_ copy];
    [self clear];
    
    NSString *result = @"";
    
    if (accruedInputWithoutFormatting.length <= 0) {
        return result;
    }
    
    for (unsigned int i=0; i<accruedInputWithoutFormatting.length - 1; i++) {
        NSString *ch = [accruedInputWithoutFormatting substringWithRange:NSMakeRange(i, 1)];
        result = [self inputDigit:ch];
    }
    
    return result;
}

- (NSString *)inputStringAndRememberPosition:(NSString *)string
{
    [self clear];
    
    NSString *result = @"";
    
    for (unsigned int i=0; i<string.length; i++) {
        NSString *ch = [string substringWithRange:NSMakeRange(i, 1)];
        result = [self inputDigitAndRememberPosition:ch];
    }
    
    return result;
}

- (NSString *)inputString:(NSString *)string
{
    [self clear];
    
    NSString *result = @"";
    
    for (unsigned int i=0; i<string.length; i++) {
        NSString *ch = [string substringWithRange:NSMakeRange(i, 1)];
        result = [self inputDigit:ch];
    }
    
    return result;
}

/**
 * Formats a phone number on-the-fly as each digit is entered.
 *
 * @param {string} nextChar the most recently entered digit of a phone number.
 *     Formatting characters are allowed, but as soon as they are encountered
 *     this method formats the number as entered and not 'as you type' anymore.
 *     Full width digits and Arabic-indic digits are allowed, and will be shown
 *     as they are.
 * @return {string} the partially formatted phone number.
 */
- (NSString*)inputDigit:(NSString*)nextChar
{
    if (!nextChar || nextChar.length <= 0) {
        return self.currentOutput_;
    }
    self.currentOutput_ = [self inputDigitWithOptionToRememberPosition_:nextChar rememberPosition:NO];
    return self.currentOutput_;
}


/**
 * Same as {@link #inputDigit}, but remembers the position where
 * {@code nextChar} is inserted, so that it can be retrieved later by using
 * {@link #getRememberedPosition}. The remembered position will be automatically
 * adjusted if additional formatting characters are later inserted/removed in
 * front of {@code nextChar}.
 *
 * @param {string} nextChar
 * @return {string}
 */
- (NSString*)inputDigitAndRememberPosition:(NSString*)nextChar
{
    if (!nextChar || nextChar.length <= 0) {
        return self.currentOutput_;
    }
    self.currentOutput_ = [self inputDigitWithOptionToRememberPosition_:nextChar rememberPosition:YES];
    return self.currentOutput_;
};


/**
 * @param {string} nextChar
 * @param {BOOL} rememberPosition
 * @return {string}
 * @private
 */

- (NSString*)inputDigitWithOptionToRememberPosition_:(NSString*)nextChar rememberPosition:(BOOL)rememberPosition
{
    if (!nextChar || nextChar.length <= 0) {
        _isSuccessfulFormatting = NO;
        return self.currentOutput_;
    }
    
    [self.accruedInput_ appendString:nextChar];
    
    if (rememberPosition) {
        self.originalPosition_ = self.accruedInput_.length;
    }
    
    // We do formatting on-the-fly only when each character entered is either a
    // digit, or a plus sign (accepted at the start of the number only).
    if (![self isDigitOrLeadingPlusSign_:nextChar])
    {
        self.ableToFormat_ = NO;
        self.inputHasFormatting_ = YES;
    } else {
        nextChar = [self normalizeAndAccrueDigitsAndPlusSign_:nextChar rememberPosition:rememberPosition];
    }
    
    if (!self.ableToFormat_) {
        // When we are unable to format because of reasons other than that
        // formatting chars have been entered, it can be due to really long IDDs or
        // NDDs. If that is the case, we might be able to do formatting again after
        // extracting them.
        
        if (self.inputHasFormatting_) {
            _isSuccessfulFormatting = YES;
            return [NSString stringWithString:self.accruedInput_];
        }
        else if ([self attemptToExtractIdd_]) {
            if ([self attemptToExtractCountryCallingCode_]) {
                _isSuccessfulFormatting = YES;
                return [self attemptToChoosePatternWithPrefixExtracted_];
            }
        }
        else if ([self ableToExtractLongerNdd_]) {
            // Add an additional space to separate long NDD and national significant
            // number for readability. We don't set shouldAddSpaceAfterNationalPrefix_
            // to YES, since we don't want this to change later when we choose
            // formatting templates.
            [self.prefixBeforeNationalNumber_ appendString:[NSString stringWithFormat: @"%@", self.SEPARATOR_BEFORE_NATIONAL_NUMBER_]];
            _isSuccessfulFormatting = YES;
            return [self attemptToChoosePatternWithPrefixExtracted_];
        }
        
        _isSuccessfulFormatting = NO;
        return self.accruedInput_;
    }
    
    // We start to attempt to format only when at least MIN_LEADING_DIGITS_LENGTH
    // digits (the plus sign is counted as a digit as well for this purpose) have
    // been entered.
    switch (self.accruedInputWithoutFormatting_.length)
    {
        case 0:
        case 1:
        case 2:
            _isSuccessfulFormatting = YES;
            return self.accruedInput_;
        case 3:
            if ([self attemptToExtractIdd_]) {
                self.isExpectingCountryCallingCode_ = YES;
            } else {
                // No IDD or plus sign is found, might be entering in national format.
                self.nationalPrefixExtracted_ = [self removeNationalPrefixFromNationalNumber_];
                _isSuccessfulFormatting = YES;
                return [self attemptToChooseFormattingPattern_];
            }
        default:
            if (self.isExpectingCountryCallingCode_) {
                if ([self attemptToExtractCountryCallingCode_]) {
                    self.isExpectingCountryCallingCode_ = NO;
                }
                _isSuccessfulFormatting = YES;
                return [NSString stringWithFormat:@"%@%@", self.prefixBeforeNationalNumber_, self.nationalNumber_];
            }
            
            if (self.possibleFormats_.count > 0) {
                // The formatting patterns are already chosen.
                /** @type {string} */
                NSString *tempNationalNumber = [self inputDigitHelper_:nextChar];
                // See if the accrued digits can be formatted properly already. If not,
                // use the results from inputDigitHelper, which does formatting based on
                // the formatting pattern chosen.
                /** @type {string} */
                NSString *formattedNumber = [self attemptToFormatAccruedDigits_];
                if (formattedNumber.length > 0) {
                    _isSuccessfulFormatting = YES;
                    return formattedNumber;
                }
                
                [self narrowDownPossibleFormats_:self.nationalNumber_];
                
                if ([self maybeCreateNewTemplate_]) {
                    _isSuccessfulFormatting = YES;
                    return [self inputAccruedNationalNumber_];
                }
                
                if (self.ableToFormat_) {
                    _isSuccessfulFormatting = YES;
                    return [self appendNationalNumber_:tempNationalNumber];
                } else {
                    _isSuccessfulFormatting = NO;
                    return self.accruedInput_;
                }
            }
            else {
                _isSuccessfulFormatting = NO;
                return [self attemptToChooseFormattingPattern_];
            }
    }
    
    _isSuccessfulFormatting = NO;
};


/**
 * @return {string}
 * @private
 */
- (NSString*)attemptToChoosePatternWithPrefixExtracted_
{
    self.ableToFormat_ = YES;
    self.isExpectingCountryCallingCode_ = NO;
    [self.possibleFormats_ removeAllObjects];
    return [self attemptToChooseFormattingPattern_];
};


/**
 * Some national prefixes are a substring of others. If extracting the shorter
 * NDD doesn't result in a number we can format, we try to see if we can extract
 * a longer version here.
 * @return {BOOL}
 * @private
 */
- (BOOL)ableToExtractLongerNdd_
{
    if (self.nationalPrefixExtracted_.length > 0)
    {
        // Put the extracted NDD back to the national number before attempting to
        // extract a new NDD.
        /** @type {string} */
        NSString *nationalNumberStr = [NSString stringWithString:self.nationalNumber_];
        self.nationalNumber_ = [NSMutableString stringWithString:@""];
        [self.nationalNumber_ appendString:self.nationalPrefixExtracted_];
        [self.nationalNumber_ appendString:nationalNumberStr];
        // Remove the previously extracted NDD from prefixBeforeNationalNumber. We
        // cannot simply set it to empty string because people sometimes incorrectly
        // enter national prefix after the country code, e.g. +44 (0)20-1234-5678.
        /** @type {string} */
        NSString *prefixBeforeNationalNumberStr = [NSString stringWithString:self.prefixBeforeNationalNumber_];
        NSRange lastRange = [prefixBeforeNationalNumberStr rangeOfString:self.nationalPrefixExtracted_ options:NSBackwardsSearch];
        /** @type {number} */
        unsigned int indexOfPreviousNdd = (unsigned int)lastRange.location;
        self.prefixBeforeNationalNumber_ = [NSMutableString stringWithString:@""];
        [self.prefixBeforeNationalNumber_ appendString:[prefixBeforeNationalNumberStr substringWithRange:NSMakeRange(0, indexOfPreviousNdd)]];
    }
    
    return self.nationalPrefixExtracted_ != [self removeNationalPrefixFromNationalNumber_];
};


/**
 * @param {string} nextChar
 * @return {BOOL}
 * @private
 */
- (BOOL)isDigitOrLeadingPlusSign_:(NSString*)nextChar
{
    NSString *digitPattern = [NSString stringWithFormat:@"([%@])", NB_VALID_DIGITS_STRING];
    NSString *plusPattern = [NSString stringWithFormat:@"[%@]+", NB_PLUS_CHARS];
    
    BOOL isDigitPattern = [[self.phoneUtil_ matchesByRegex:nextChar regex:digitPattern] count] > 0;
    BOOL isPlusPattern = [[self.phoneUtil_ matchesByRegex:nextChar regex:plusPattern] count] > 0;
    
    return isDigitPattern || (self.accruedInput_.length == 1 && isPlusPattern);
};


/**
 * Check to see if there is an exact pattern match for these digits. If so, we
 * should use this instead of any other formatting template whose
 * leadingDigitsPattern also matches the input.
 * @return {string}
 * @private
 */
- (NSString*)attemptToFormatAccruedDigits_
{
    /** @type {string} */
    NSString *nationalNumber = [NSString stringWithString:self.nationalNumber_];
    
    /** @type {number} */
    unsigned int possibleFormatsLength = (unsigned int)self.possibleFormats_.count;
    for (unsigned int i = 0; i < possibleFormatsLength; ++i)
    {
        /** @type {i18n.phonenumbers.NumberFormat} */
        NBNumberFormat *numberFormat = self.possibleFormats_[i];
        /** @type {string} */
        NSString * pattern = numberFormat.pattern;
        /** @type {RegExp} */
        NSString *patternRegExp = [NSString stringWithFormat:@"^(?:%@)$", pattern];
        BOOL isPatternRegExp = [[self.phoneUtil_ matchesByRegex:nationalNumber regex:patternRegExp] count] > 0;
        if (isPatternRegExp) {
            if (numberFormat.nationalPrefixFormattingRule.length > 0) {
                NSArray *matches = [self.NATIONAL_PREFIX_SEPARATORS_PATTERN_ matchesInString:numberFormat.nationalPrefixFormattingRule
                                                                                     options:0
                                                                                       range:NSMakeRange(0, numberFormat.nationalPrefixFormattingRule.length)];
                self.shouldAddSpaceAfterNationalPrefix_ = [matches count] > 0;
            } else {
                self.shouldAddSpaceAfterNationalPrefix_ = NO;
            }
            
            /** @type {string} */
            NSString *formattedNumber = [self.phoneUtil_ replaceStringByRegex:nationalNumber
                                                                        regex:pattern
                                                                 withTemplate:numberFormat.format];
            return [self appendNationalNumber_:formattedNumber];
        }
    }
    return @"";
};


/**
 * Combines the national number with any prefix (IDD/+ and country code or
 * national prefix) that was collected. A space will be inserted between them if
 * the current formatting template indicates this to be suitable.
 * @param {string} nationalNumber The number to be appended.
 * @return {string} The combined number.
 * @private
 */
- (NSString*)appendNationalNumber_:(NSString*)nationalNumber
{
    /** @type {number} */
    unsigned int prefixBeforeNationalNumberLength = (unsigned int)self.prefixBeforeNationalNumber_.length;
    unichar blank_char = [self.SEPARATOR_BEFORE_NATIONAL_NUMBER_ characterAtIndex:0];
    if (self.shouldAddSpaceAfterNationalPrefix_ && prefixBeforeNationalNumberLength > 0 &&
        [self.prefixBeforeNationalNumber_ characterAtIndex:prefixBeforeNationalNumberLength - 1] != blank_char)
    {
        // We want to add a space after the national prefix if the national prefix
        // formatting rule indicates that this would normally be done, with the
        // exception of the case where we already appended a space because the NDD
        // was surprisingly long.
        
        return [NSString stringWithFormat:@"%@%@%@", self.prefixBeforeNationalNumber_, self.SEPARATOR_BEFORE_NATIONAL_NUMBER_, nationalNumber];
    } else {
        return [NSString stringWithFormat:@"%@%@", self.prefixBeforeNationalNumber_, nationalNumber];
    }
};


/**
 * Returns the current position in the partially formatted phone number of the
 * character which was previously passed in as the parameter of
 * {@link #inputDigitAndRememberPosition}.
 *
 * @return {number}
 */
- (NSInteger)getRememberedPosition
{
    if (!self.ableToFormat_) {
        return self.originalPosition_;
    }
    /** @type {number} */
    NSInteger accruedInputIndex = 0;
    /** @type {number} */
    NSInteger currentOutputIndex = 0;
    /** @type {string} */
    NSString *accruedInputWithoutFormatting = self.accruedInputWithoutFormatting_;
    /** @type {string} */
    NSString *currentOutput = self.currentOutput_;
    
    while (accruedInputIndex < self.positionToRemember_ && currentOutputIndex < currentOutput.length)
    {
        if ([accruedInputWithoutFormatting characterAtIndex:accruedInputIndex] == [currentOutput characterAtIndex:currentOutputIndex])
        {
            accruedInputIndex++;
        }
        currentOutputIndex++;
    }
    return currentOutputIndex;
};


/**
 * Attempts to set the formatting template and returns a string which contains
 * the formatted version of the digits entered so far.
 *
 * @return {string}
 * @private
 */
- (NSString*)attemptToChooseFormattingPattern_
{
    /** @type {string} */
    NSString *nationalNumber = [self.nationalNumber_ copy];
    // We start to attempt to format only when as least MIN_LEADING_DIGITS_LENGTH
    // digits of national number (excluding national prefix) have been entered.
    if (nationalNumber.length >= self.MIN_LEADING_DIGITS_LENGTH_) {
        [self getAvailableFormats_:nationalNumber];
        // See if the accrued digits can be formatted properly already.
        NSString *formattedNumber = [self attemptToFormatAccruedDigits_];
        if (formattedNumber.length > 0) {
            return formattedNumber;
        }
        return [self maybeCreateNewTemplate_] ? [self inputAccruedNationalNumber_] : self.accruedInput_;
    } else {
        return [self appendNationalNumber_:nationalNumber];
    }
}


/**
 * Invokes inputDigitHelper on each digit of the national number accrued, and
 * returns a formatted string in the end.
 *
 * @return {string}
 * @private
 */
- (NSString*)inputAccruedNationalNumber_
{
    /** @type {string} */
    NSString *nationalNumber = [self.nationalNumber_ copy];
    /** @type {number} */
    unsigned int lengthOfNationalNumber = (unsigned int)nationalNumber.length;
    if (lengthOfNationalNumber > 0) {
        /** @type {string} */
        NSString *tempNationalNumber = @"";
        for (unsigned int i = 0; i < lengthOfNationalNumber; i++)
        {
            tempNationalNumber = [self inputDigitHelper_:[NSString stringWithFormat: @"%C", [nationalNumber characterAtIndex:i]]];
        }
        return self.ableToFormat_ ? [self appendNationalNumber_:tempNationalNumber] : self.accruedInput_;
    } else {
        return self.prefixBeforeNationalNumber_;
    }
};


/**
 * @return {BOOL} YES if the current country is a NANPA country and the
 *     national number begins with the national prefix.
 * @private
 */
- (BOOL)isNanpaNumberWithNationalPrefix_
{
    // For NANPA numbers beginning with 1[2-9], treat the 1 as the national
    // prefix. The reason is that national significant numbers in NANPA always
    // start with [2-9] after the national prefix. Numbers beginning with 1[01]
    // can only be short/emergency numbers, which don't need the national prefix.
    if (![self.currentMetaData_.countryCode isEqual:@1]) {
        return NO;
    }
    
    /** @type {string} */
    NSString *nationalNumber = [self.nationalNumber_ copy];
    return ([nationalNumber characterAtIndex:0] == '1') && ([nationalNumber characterAtIndex:1] != '0') &&
        ([nationalNumber characterAtIndex:1] != '1');
};


/**
 * Returns the national prefix extracted, or an empty string if it is not
 * present.
 * @return {string}
 * @private
 */
- (NSString*)removeNationalPrefixFromNationalNumber_
{
    /** @type {string} */
    NSString *nationalNumber = [self.nationalNumber_ copy];
    /** @type {number} */
    unsigned int startOfNationalNumber = 0;
    
    if ([self isNanpaNumberWithNationalPrefix_]) {
        startOfNationalNumber = 1;
        [self.prefixBeforeNationalNumber_ appendString:@"1"];
        [self.prefixBeforeNationalNumber_ appendFormat:@"%@", self.SEPARATOR_BEFORE_NATIONAL_NUMBER_];
        self.isCompleteNumber_ = YES;
    }
    else if (self.currentMetaData_.nationalPrefixForParsing != nil && self.currentMetaData_.nationalPrefixForParsing.length > 0)
    {
        /** @type {RegExp} */
        NSString *nationalPrefixForParsing = [NSString stringWithFormat:@"^(?:%@)", self.currentMetaData_.nationalPrefixForParsing];
        /** @type {Array.<string>} */
        NSArray *m = [self.phoneUtil_ matchedStringByRegex:nationalNumber regex:nationalPrefixForParsing];
        NSString *firstString = [m safeObjectAtIndex:0];
        if (m != nil && firstString != nil && firstString.length > 0) {
            // When the national prefix is detected, we use international formatting
            // rules instead of national ones, because national formatting rules could
            // contain local formatting rules for numbers entered without area code.
            self.isCompleteNumber_ = YES;
            startOfNationalNumber = (unsigned int)firstString.length;
            [self.prefixBeforeNationalNumber_ appendString:[nationalNumber substringWithRange:NSMakeRange(0, startOfNationalNumber)]];
        }
    }
    
    self.nationalNumber_ = [NSMutableString stringWithString:@""];
    [self.nationalNumber_ appendString:[nationalNumber substringFromIndex:startOfNationalNumber]];
    return [nationalNumber substringWithRange:NSMakeRange(0, startOfNationalNumber)];
};


/**
 * Extracts IDD and plus sign to prefixBeforeNationalNumber when they are
 * available, and places the remaining input into nationalNumber.
 *
 * @return {BOOL} YES when accruedInputWithoutFormatting begins with the
 *     plus sign or valid IDD for defaultCountry.
 * @private
 */
- (BOOL)attemptToExtractIdd_
{
    /** @type {string} */
    NSString *accruedInputWithoutFormatting = [self.accruedInputWithoutFormatting_ copy];
    /** @type {RegExp} */
    NSString *internationalPrefix = [NSString stringWithFormat:@"^(?:\\+|%@)", self.currentMetaData_.internationalPrefix];
    /** @type {Array.<string>} */
    NSArray *m = [self.phoneUtil_ matchedStringByRegex:accruedInputWithoutFormatting regex:internationalPrefix];
    
    NSString *firstString = [m safeObjectAtIndex:0];
    
    if (m != nil && firstString != nil && firstString.length > 0) {
        self.isCompleteNumber_ = YES;
        /** @type {number} */
        unsigned int startOfCountryCallingCode = (unsigned int)firstString.length;
        self.nationalNumber_ = [NSMutableString stringWithString:@""];
        [self.nationalNumber_ appendString:[accruedInputWithoutFormatting substringFromIndex:startOfCountryCallingCode]];
        self.prefixBeforeNationalNumber_ = [NSMutableString stringWithString:@""];
        [self.prefixBeforeNationalNumber_ appendString:[accruedInputWithoutFormatting substringWithRange:NSMakeRange(0, startOfCountryCallingCode)]];
        
        if ([accruedInputWithoutFormatting characterAtIndex:0] != '+')
        {
            [self.prefixBeforeNationalNumber_ appendString:[NSString stringWithFormat: @"%@", self.SEPARATOR_BEFORE_NATIONAL_NUMBER_]];
        }
        return YES;
    }
    return NO;
};


/**
 * Extracts the country calling code from the beginning of nationalNumber to
 * prefixBeforeNationalNumber when they are available, and places the remaining
 * input into nationalNumber.
 *
 * @return {BOOL} YES when a valid country calling code can be found.
 * @private
 */
- (BOOL)attemptToExtractCountryCallingCode_
{
    if (self.nationalNumber_.length == 0) {
        return NO;
    }
    
    /** @type {!goog.string.StringBuffer} */
    NSString *numberWithoutCountryCallingCode = @"";
    
    /** @type {number} */
    NSNumber *countryCode = [self.phoneUtil_ extractCountryCode:self.nationalNumber_ nationalNumber:&numberWithoutCountryCallingCode];
    
    if ([countryCode isEqualToNumber:@0]) {
        return NO;
    }
    
    self.nationalNumber_ = [NSMutableString stringWithString:@""];
    [self.nationalNumber_ appendString:numberWithoutCountryCallingCode];
    
    /** @type {string} */
    NSString *newRegionCode = [self.phoneUtil_ getRegionCodeForCountryCode:countryCode];
    
    if ([NB_REGION_CODE_FOR_NON_GEO_ENTITY isEqualToString:newRegionCode]) {
        NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
        self.currentMetaData_ = [helper getMetadataForNonGeographicalRegion:countryCode];
    } else if (newRegionCode != self.defaultCountry_) {
        self.currentMetaData_ = [self getMetadataForRegion_:newRegionCode];
    }
    
    /** @type {string} */
    NSString *countryCodeString = [NSString stringWithFormat:@"%@", countryCode];
    [self.prefixBeforeNationalNumber_ appendString:countryCodeString];
    [self.prefixBeforeNationalNumber_ appendString:[NSString stringWithFormat: @"%@", self.SEPARATOR_BEFORE_NATIONAL_NUMBER_]];
    return YES;
};


/**
 * Accrues digits and the plus sign to accruedInputWithoutFormatting for later
 * use. If nextChar contains a digit in non-ASCII format (e.g. the full-width
 * version of digits), it is first normalized to the ASCII version. The return
 * value is nextChar itself, or its normalized version, if nextChar is a digit
 * in non-ASCII format. This method assumes its input is either a digit or the
 * plus sign.
 *
 * @param {string} nextChar
 * @param {BOOL} rememberPosition
 * @return {string}
 * @private
 */
- (NSString*)normalizeAndAccrueDigitsAndPlusSign_:(NSString *)nextChar rememberPosition:(BOOL)rememberPosition
{
    /** @type {string} */
    NSString *normalizedChar;
    
    if ([nextChar isEqualToString:@"+"]) {
        normalizedChar = nextChar;
        [self.accruedInputWithoutFormatting_ appendString:nextChar];
    } else {
        normalizedChar = [[self.phoneUtil_ DIGIT_MAPPINGS] objectForKey:nextChar];
        if (!normalizedChar) return @"";
        
        [self.accruedInputWithoutFormatting_ appendString:normalizedChar];
        [self.nationalNumber_ appendString:normalizedChar];
    }
    
    if (rememberPosition) {
        self.positionToRemember_ = self.accruedInputWithoutFormatting_.length;
    }
    
    return normalizedChar;
};


/**
 * @param {string} nextChar
 * @return {string}
 * @private
 */
- (NSString*)inputDigitHelper_:(NSString *)nextChar
{
    /** @type {string} */
    NSString *formattingTemplate = [self.formattingTemplate_ copy];
    NSString *subedString = @"";
    
    if (formattingTemplate.length > self.lastMatchPosition_) {
        subedString = [formattingTemplate substringFromIndex:self.lastMatchPosition_];
    }
    
    if ([self.phoneUtil_ stringPositionByRegex:subedString regex:self.DIGIT_PLACEHOLDER_] >= 0) {
        /** @type {number} */
        int digitPatternStart = [self.phoneUtil_ stringPositionByRegex:formattingTemplate regex:self.DIGIT_PLACEHOLDER_];
        
        /** @type {string} */
        NSRange tempRange = [formattingTemplate rangeOfString:self.DIGIT_PLACEHOLDER_];
        NSString *tempTemplate = [formattingTemplate stringByReplacingOccurrencesOfString:self.DIGIT_PLACEHOLDER_
                                                                               withString:nextChar
                                                                                  options:NSLiteralSearch
                                                                                    range:tempRange];
        self.formattingTemplate_ = [NSMutableString stringWithString:@""];
        [self.formattingTemplate_ appendString:tempTemplate];
        self.lastMatchPosition_ = digitPatternStart;
        return [tempTemplate substringWithRange:NSMakeRange(0, self.lastMatchPosition_ + 1)];
    } else {
        if (self.possibleFormats_.count == 1)
        {
            // More digits are entered than we could handle, and there are no other
            // valid patterns to try.
            self.ableToFormat_ = NO;
        }  // else, we just reset the formatting pattern.
        self.currentFormattingPattern_ = @"";
        return self.accruedInput_;
    }
};


/**
 * Returns the formatted number.
 *
 * @return {string}
 */
- (NSString *)description
{
    return self.currentOutput_;
}

@end
