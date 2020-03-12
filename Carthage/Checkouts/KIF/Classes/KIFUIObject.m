//
//  KIFUIObject.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import "KIFUIObject.h"


@implementation KIFUIObject

- (instancetype)initWithElement:(UIAccessibilityElement *)element view:(UIView *)view;
{
    self = [super init];
    if (self) {
        _element = element;
        _view = view;
    }
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@;\n| element=%@;\n| |  view=%@>", [super description], self.element, self.view];
}
@end
