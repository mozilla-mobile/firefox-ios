//
//  KIFUIViewActor.m
//  KIF
//
//  Created by Alex Odawa on 1/21/15.
//
//

#import "KIFUIViewTestActor.h"
#import "KIFUIObject.h"
#import "UIWindow-KIFAdditions.h"
#import "NSPredicate+KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "NSString+KIFAdditions.h"

@interface KIFUIViewTestActor ()

@property (nonatomic, strong, readonly) KIFUITestActor *actor;
@property (nonatomic, strong, readwrite) NSPredicate *predicate;

@end


@implementation KIFUIViewTestActor

NSString *const inputFieldTestString = @"Testing";

#pragma mark - Initialization

- (instancetype)usingPredicate:(NSPredicate *)predicate;
{

    [self _appendPredicate:predicate];
    return  self;
}

- (instancetype)usingLabel:(NSString *)accessibilityLabel;
{
    int systemVersion = [UIDevice currentDevice].systemVersion.intValue;
    NSPredicate *predicate;
    if ([accessibilityLabel rangeOfString:@"\n"].location == NSNotFound || systemVersion == 6) {
        predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            id label = [evaluatedObject accessibilityLabel];
            return [accessibilityLabel KIF_isEqualToStringOrAttributedString:label];
        }];
    }
    else {
        // On iOS 6 the accessibility label may contain line breaks, so when trying to find the
        // element, these line breaks are necessary. But on iOS 7 the system replaces them with
        // spaces. So the same test breaks on either iOS 6 or iOS 7. iOS 8 befuddles this again by
        // limiting replacement to spaces in between strings.
        // UNLESS the accessibility label is set programatically in which case the line breaks remain regardless of OS version.
        // To work around this replace the line breaks using the preferred method and try matching both.
        
        __block NSString *alternate = nil;
        if (systemVersion == 7) {
            alternate = [accessibilityLabel stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        } else {
            alternate = [accessibilityLabel stringByReplacingOccurrencesOfString:@"\\b\\n\\b" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, accessibilityLabel.length)];
        }
        
        predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            id label = [evaluatedObject accessibilityLabel];
            return ([accessibilityLabel KIF_isEqualToStringOrAttributedString:label] || [alternate KIF_isEqualToStringOrAttributedString:label]);
        }];
    }
    predicate.kifPredicateDescription = [NSString stringWithFormat:@"Accessibility label equal to \"%@\"", accessibilityLabel];
    return [self usingPredicate:predicate];
}


- (instancetype)usingIdentifier:(NSString *)accessibilityIdentifier;
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        id identifier = [evaluatedObject accessibilityIdentifier];

        return [accessibilityIdentifier KIF_isEqualToStringOrAttributedString:identifier];
    }];
    
    predicate.kifPredicateDescription = [NSString stringWithFormat:@"Accessibility identifier equal to \"%@\"", accessibilityIdentifier];

    return [self usingPredicate:predicate];
}

- (instancetype)usingTraits:(UIAccessibilityTraits)accessibilityTraits;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(accessibilityTraits & %@) == %@", @(accessibilityTraits), @(accessibilityTraits)];
    predicate.kifPredicateDescription = [NSString stringWithFormat:@"Accessibility traits including \"%@\"", [UIAccessibilityElement stringFromAccessibilityTraits:accessibilityTraits]];
    
    return [self usingPredicate:predicate];
}

- (instancetype)usingValue:(NSString *)accessibilityValue;
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *value = [evaluatedObject accessibilityValue];
        if ([value isKindOfClass:[NSAttributedString class]]) {
            value = [(NSAttributedString *)value string];
        }
        return [value isEqualToString:accessibilityValue];
    }];
    predicate.kifPredicateDescription = [NSString stringWithFormat:@"Accessibility Value equal to \"%@\"", accessibilityValue];
    
    return [self usingPredicate: predicate];
}

#pragma mark - System Actions

#if TARGET_IPHONE_SIMULATOR
- (BOOL)acknowledgeSystemAlert;
{
    return [self.actor acknowledgeSystemAlert];
}
#endif

- (void)tapStatusBar;
{
    [self.actor tapStatusBar];
}

- (void)dismissPopover;
{
    [self.actor dismissPopover];
}

#pragma mark - Waiting

- (UIView *)waitForView;
{
    return [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO].view;
}

- (void)waitForAbsenceOfView;
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        // If the app is ignoring interaction events, then wait before doing our analysis
        KIFTestWaitCondition(![[UIApplication sharedApplication] isIgnoringInteractionEvents], error, @"Application is ignoring interaction events.");
        
        // If the element can't be found, then we're done
        KIFUIObject *found = [self _predicateSearchWithRequiresMatch:NO mustBeTappable:NO];
        if (!found) {
            return KIFTestStepResultSuccess;
        }
        
        // If we found an element, but it's not associated with a view, then something's wrong. Wait it out and try again.
        KIFTestWaitCondition(found.view, error, @"Cannot find view containing accessibility element \"%@\"", found.element);
        
        // Hidden views count as absent
        KIFTestWaitCondition([found.view isHidden] || [found.view superview] == nil, error, @"Accessibility element \"%@\" is visible and not hidden.", found);
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)waitToBecomeTappable;

{
    [self _predicateSearchWithRequiresMatch:YES mustBeTappable:YES];
}

- (void)waitToBecomeFirstResponder;
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        UIResponder *firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];

        KIFTestWaitCondition([self.predicate evaluateWithObject:firstResponder], error, @"Expected first responder to match '%@', got '%@'", self.predicate, firstResponder);
        return KIFTestStepResultSuccess;
    }];
}
#pragma mark Typist Waiting

- (void)waitForSoftwareKeyboard;
{
    [self.actor waitForSoftwareKeyboard];
}
- (void)waitForAbsenceOfSoftwareKeyboard;
{
    [self.actor waitForAbsenceOfSoftwareKeyboard];
}
- (void)waitForKeyInputReady;
{
    [self.actor waitForKeyInputReady];
}

#pragma mark - Conditionals

- (BOOL)tryFindingView;
{
    return ([self _predicateSearchWithRequiresMatch:NO mustBeTappable:NO] != nil);
}

- (BOOL)tryFindingTappableView;
{
    return ([self _predicateSearchWithRequiresMatch:NO mustBeTappable:YES] != nil);
}


#pragma mark - Tap Actions

- (void)tap;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:YES];
    [self.actor tapAccessibilityElement:found.element inView:found.view];
}

- (void)longPress;
{
    [self longPressWithDuration:.5];
}

- (void)longPressWithDuration:(NSTimeInterval)duration;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:YES];
    [self.actor longPressAccessibilityElement:found.element inView:found.view duration:duration];
}

#pragma mark - Text Actions;

- (void)clearText;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor clearTextFromElement:found.element inView:found.view];
}

- (void)clearTextFromFirstResponder;
{
    [self.actor clearTextFromFirstResponder];
}

- (void)enterText:(NSString *)text;
{
    [self enterText:text expectedResult:nil];
}

- (void)enterText:(NSString *)text expectedResult:(NSString *)expectedResult;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor enterText:text intoElement:found.element inView:found.view expectedResult:expectedResult];
}

- (void)clearAndEnterText:(NSString *)text;
{
    [self clearAndEnterText:text expectedResult:nil];
}

- (void)clearAndEnterText:(NSString *)text expectedResult:(NSString *)expectedResult;
{
    [self clearText];
    [self enterText:text expectedResult:expectedResult];
}

- (void)enterTextIntoCurrentFirstResponder:(NSString *)text;
{
    [self.actor enterTextIntoCurrentFirstResponder:text];
}

- (void)enterTextIntoCurrentFirstResponder:(NSString *)text fallbackView:(UIView *)fallbackView;
{
    [self.actor enterTextIntoCurrentFirstResponder:text fallbackView:fallbackView];
}

- (void)setText:(NSString *)text;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    if ([found.view respondsToSelector:@selector(setText:)]) {
        [found.view performSelector:@selector(setText:) withObject:text];
    }
}

- (void)expectToContainText:(NSString *)expectedResult;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor expectView:found.view toContainText:expectedResult];
}


#pragma mark - Touch Actions

- (void)tapScreenAtPoint:(CGPoint)screenPoint;
{
    [self.actor tapScreenAtPoint:screenPoint];
}

- (void)swipeInDirection:(KIFSwipeDirection)direction;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor swipeAccessibilityElement:found.element inView:found.view inDirection:direction];
}

#pragma mark - Scroll/Table/CollectionView Actions

- (void)scrollByFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor scrollAccessibilityElement:found.element inView:found.view byFractionOfSizeHorizontal:horizontalFraction vertical:verticalFraction];
}

- (void)tapRowInTableViewAtIndexPath:(NSIndexPath *)indexPath;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UITableView class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor tapRowAtIndexPath:indexPath inTableView:(UITableView *)found.view];
}

- (UITableViewCell *)waitForCellInTableViewAtIndexPath:(NSIndexPath *)indexPath;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UITableView class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    return [self.actor waitForCellAtIndexPath:indexPath inTableView:(UITableView *)found.view];
}

- (void)moveRowInTableViewAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UITableView class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath inTableView:(UITableView *)found.view];
}


- (void)tapCollectionViewItemAtIndexPath:(NSIndexPath *)indexPath;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UICollectionView class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor tapItemAtIndexPath:indexPath inCollectionView:(UICollectionView *)found.view];
}

- (UICollectionViewCell *)waitForCellInCollectionViewAtIndexPath:(NSIndexPath *)indexPath;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UICollectionView class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    return [self.actor waitForCellAtIndexPath:indexPath inCollectionView:(UICollectionView *)found.view];
}


#pragma mark - UIControl Actions

- (void)setSliderValue:(float)value;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UISlider class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor setValue:value forSlider:(UISlider *)found.view];
}

- (void)setSwitchOn:(BOOL)switchIsOn;
{
    KIFUIObject *found = [[self _usingExpectedClass:[UISwitch class]] _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor setSwitch:(UISwitch *)found.view element:found.element On:switchIsOn];
}

#pragma mark - Picker Actions

- (void)selectPickerViewRowWithTitle:(NSString *)title;
{
    [self.actor selectPickerViewRowWithTitle:title];
}

- (void)selectPickerViewRowWithTitle:(NSString *)title inComponent:(NSInteger)component;
{
    [self.actor selectPickerViewRowWithTitle:title inComponent:component];
}

- (void)selectDatePickerValue:(NSArray *)datePickerColumnValues;
{
    [self.actor selectDatePickerValue:datePickerColumnValues];
}

- (void)choosePhotoInAlbum:(NSString *)albumName atRow:(NSInteger)row column:(NSInteger)column;
{
    [self.actor choosePhotoInAlbum:albumName atRow:row column:column];
}

#pragma mark - Pull to Refresh

- (void)pullToRefresh;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor pullToRefreshAccessibilityElement:found.element inView:found.view pullDownDuration:0];
}

- (void)pullToRefreshWithDuration:(KIFPullToRefreshTiming)pullDownDuration;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    [self.actor pullToRefreshAccessibilityElement:found.element inView:found.view pullDownDuration:pullDownDuration];

}

#pragma mark - Getters

- (UIView *)view;
{
    return [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO].view;
}

- (UIAccessibilityElement *)element;
{
    return [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO].element;
}

- (KIFUITestActor *)actor;
{
    return [[KIFUITestActor actorInFile:self.file atLine:self.line delegate:self.delegate] usingTimeout:self.executionBlockTimeout];
}

#pragma mark - NSObject

- (NSString *)description;
{
    KIFUIObject *found = [self _predicateSearchWithRequiresMatch:YES mustBeTappable:NO];
    return [NSString stringWithFormat:@"<%@; view=%@; element=%@; predicate=%@>", [super description], found.view, found.element, self.predicate];
}

#pragma mark - Private Methods

- (instancetype)_usingExpectedClass:(Class)expectedClass;
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:expectedClass];
    }];
    
    predicate.kifPredicateDescription = [NSString stringWithFormat:@"is kind of Class \"%@\"", NSStringFromClass(expectedClass)];
    return [self usingPredicate:predicate];
}

- (void)_appendPredicate:(NSPredicate *)newPredicate;
{
    if (!self.predicate) {
        self.predicate = newPredicate;
    } else {
        NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ self.predicate, newPredicate ]];
        self.predicate = compoundPredicate;
    }
}

- (KIFUIObject *)_predicateSearchWithRequiresMatch:(BOOL)requiresMatch mustBeTappable:(BOOL)tappable;
{
    __block UIView *foundView = nil;
    __block UIAccessibilityElement *foundElement = nil;

    if (requiresMatch) {
        [self.actor waitForAccessibilityElement:&foundElement view:&foundView withElementMatchingPredicate:self.predicate tappable:tappable];
    } else {
        NSError *error;
        [self tryRunningBlock:^KIFTestStepResult(NSError **error) {
            KIFTestWaitCondition([self.actor tryFindingAccessibilityElement:&foundElement view:&foundView withElementMatchingPredicate:self.predicate tappable:tappable error:error], error, @"Waiting on view matching %@", self.predicate.kifPredicateDescription);
            return KIFTestStepResultSuccess;
        } complete:nil timeout:1.0 error:&error];
    }

    if (foundView && foundElement) {
        return [[KIFUIObject alloc] initWithElement:foundElement view:foundView];
    }
    return nil;
}

@end
