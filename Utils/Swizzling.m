/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#include <objc/runtime.h>

BOOL SwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel)
{
    Method dstMethod = class_getInstanceMethod(class, dstSel);
    Method srcMethod = class_getInstanceMethod(class, srcSel);
    IMP srcIMP = method_getImplementation(srcMethod);
    if (class_addMethod(class, dstSel, srcIMP, method_getTypeEncoding(srcMethod))) {
        class_replaceMethod(class, dstSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod));
    } else {
        method_exchangeImplementations(dstMethod, srcMethod);
    }
    return (method_getImplementation(srcMethod) == method_getImplementation(class_getInstanceMethod(class, dstSel)));
}

BOOL SwizzleClassMethods(Class class, SEL dstSel, SEL srcSel)
{
    Class metaClass = object_getClass(class);
    return SwizzleInstanceMethods(metaClass, dstSel, srcSel);
}
