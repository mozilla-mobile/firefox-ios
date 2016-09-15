//
//  NBPhoneNumberFormat.m
//  libPhoneNumber
//
//

#import "NBNumberFormat.h"


@implementation NBNumberFormat


- (id)initWithPattern:(NSString *)pattern withFormat:(NSString *)format withLeadingDigitsPatterns:(NSMutableArray *)leadingDigitsPatterns withNationalPrefixFormattingRule:(NSString *)nationalPrefixFormattingRule whenFormatting:(BOOL)nationalPrefixOptionalWhenFormatting withDomesticCarrierCodeFormattingRule:(NSString *)domesticCarrierCodeFormattingRule
{
    self = [self init];
    
    _pattern = pattern;
    _format = format;
    _leadingDigitsPatterns = leadingDigitsPatterns;
    _nationalPrefixFormattingRule = nationalPrefixFormattingRule;
    _nationalPrefixOptionalWhenFormatting = nationalPrefixOptionalWhenFormatting;
    _domesticCarrierCodeFormattingRule = domesticCarrierCodeFormattingRule;
        
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        self.nationalPrefixOptionalWhenFormatting = NO;
        self.leadingDigitsPatterns = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"[pattern:%@, format:%@, leadingDigitsPattern:%@, nationalPrefixFormattingRule:%@, nationalPrefixOptionalWhenFormatting:%@, domesticCarrierCodeFormattingRule:%@]",
            self.pattern, self.format, self.leadingDigitsPatterns, self.nationalPrefixFormattingRule, self.nationalPrefixOptionalWhenFormatting?@"Y":@"N", self.domesticCarrierCodeFormattingRule];
}


- (id)copyWithZone:(NSZone *)zone
{
	NBNumberFormat *phoneFormatCopy = [[NBNumberFormat allocWithZone:zone] init];
    
    /*
     1 @property (nonatomic, strong, readwrite) NSString *pattern;
     2 @property (nonatomic, strong, readwrite) NSString *format;
     3 @property (nonatomic, strong, readwrite) NSString *leadingDigitsPattern;
     4 @property (nonatomic, strong, readwrite) NSString *nationalPrefixFormattingRule;
     6 @property (nonatomic, assign, readwrite) BOOL nationalPrefixOptionalWhenFormatting;
     5 @property (nonatomic, strong, readwrite) NSString *domesticCarrierCodeFormattingRule;
    */
    
    phoneFormatCopy.pattern = [self.pattern copy];
    phoneFormatCopy.format = [self.format copy];
    phoneFormatCopy.leadingDigitsPatterns = [self.leadingDigitsPatterns copy];
    phoneFormatCopy.nationalPrefixFormattingRule = [self.nationalPrefixFormattingRule copy];
    phoneFormatCopy.nationalPrefixOptionalWhenFormatting = self.nationalPrefixOptionalWhenFormatting;
    phoneFormatCopy.domesticCarrierCodeFormattingRule = [self.domesticCarrierCodeFormattingRule copy];
    
	return phoneFormatCopy;
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        self.pattern = [coder decodeObjectForKey:@"pattern"];
        self.format = [coder decodeObjectForKey:@"format"];
        self.leadingDigitsPatterns = [coder decodeObjectForKey:@"leadingDigitsPatterns"];
        self.nationalPrefixFormattingRule = [coder decodeObjectForKey:@"nationalPrefixFormattingRule"];
        self.nationalPrefixOptionalWhenFormatting = [[coder decodeObjectForKey:@"nationalPrefixOptionalWhenFormatting"] boolValue];
        self.domesticCarrierCodeFormattingRule = [coder decodeObjectForKey:@"domesticCarrierCodeFormattingRule"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.pattern forKey:@"pattern"];
    [coder encodeObject:self.format forKey:@"format"];
    [coder encodeObject:self.leadingDigitsPatterns forKey:@"leadingDigitsPatterns"];
    [coder encodeObject:self.nationalPrefixFormattingRule forKey:@"nationalPrefixFormattingRule"];
    [coder encodeObject:[NSNumber numberWithBool:self.nationalPrefixOptionalWhenFormatting] forKey:@"nationalPrefixOptionalWhenFormatting"];
    [coder encodeObject:self.domesticCarrierCodeFormattingRule forKey:@"domesticCarrierCodeFormattingRule"];
}


@end
