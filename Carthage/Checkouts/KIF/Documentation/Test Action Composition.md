Test Action Compostion
======================

KIF-next's sequential operations allow for powerful composition of methods.  Early on this was used for implementing `-[KIFUITestActor clearTextFromViewWithAccessibilityLabel:]`, where KIF would wait for the view with that label, then instantly access it so it could get the string length and generate a string of backspaces.

As of KIF-next 2.0.0pre4, this API has been formalized and simplified so that you can explore new meaningful behavior with a minimal amount of code.

Below are two such examples demonstrated in the test suite:

    @interface KIFUITestActor (Composition)

    - (void)tapViewIfNotSelected:(NSString *)label;
    - (void)tapViewWithAccessibilityHint:(NSString *)hint;

    @end
    
-tapViewIfNotSelected:
----------------------

In the first case, imagine we don't have complete control over out test environment.  It isn't too hard to imagine tend to be quite stateful and you can't always test in a vaccum.  You have a checkbox, it may be checked, it may be unchecked, and you want to always get it to the checked state in your app.  Let's see how we can implement this with composition.

First, we see how `tapViewWithAccessibilityLabel:` is implemented:

    - (void)tapViewWithAccessibilityLabel:(NSString *)label
    {
        [self tapViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone];
    }

Second, we expand out `tapViewWithAccessibilityLabel:value:traits:` to get:

    - (void)tapViewWithAccessibilityLabel:(NSString *)label
    {
        UIView *view = nil;
        UIAccessibilityElement *element = nil;
    
        [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil
              traits:UIAccessibilityTraitNone tappable:YES];
        [self tapAccessibilityElement:element inView:view];
    }

At this point, modifying it to only tap if not selected is trivial.  We can check the known accessibility element's traits and only tap if selected is missing:

    - (void)tapViewIfNotSelected:(NSString *)label
    {
        UIView *view;
        UIAccessibilityElement *element;
        
	    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil
	          traits:UIAccessibilityTraitNone tappable:YES];
	    
	    if ((element.accessibilityTraits & UIAccessibilityTraitSelected) == UIAccessibilityTraitNone) {
	        [self tapAccessibilityElement:element inView:view];
	    }
	}

Add this method to a category and you're good to go.

- tapViewWithAccessibilityHint:
-------------------------------

Say you want to tap a view based on something other than its label, value, and traits.  You could care about its `accessibilityHint`, `accessibilityLabel`, whether or not its on the top half of the screen, etc.  Let's continue to decompose `tapViewWithAccessibilityLabel:value:traits:` to get a method that can handle these special cases.

The first thing we need to do is expand out `waitForAccessibilityElement:view:withLabel:value:traits:tappable:`.

    - (void)tapViewWithAccessibilityLabel:(NSString *)label
    {
        __block UIView *view;
        __block UIAccessibilityElement *element;
    
        [self runBlock:^KIFTestStepResult(NSError **error) {
            return [UIAccessibilityElement accessibilityElement:&element view:&view withLabel:label
                value:nil traits:UIAccessibilityTraitNone tappable:YES error:error]
                ? KIFTestStepResultSuccess : KIFTestStepResultWait;
        }];
        
        [self tapAccessibilityElement:element inView:view];
    }

That gets us a little further but we're still dealing with a monolithic method, let's expand `accessibilityElement:view:withLabel:value:traits:tappable:error:`.

    - (void)tapViewWithAccessibilityLabel:(NSString *)label
    {
        __block UIView *view;
        __block UIAccessibilityElement *element;
    
        [self runBlock:^KIFTestStepResult(NSError **error) {
            element = [UIAccessibilityElement accessibilityElementWithLabel:label value:nil traits:UIAccessibilityTraitNone error:error];
            if (!element) {
                return KIFTestStepResultWait;
            }
    
            view = [UIAccessibilityElement viewContainingAccessibilityElement:element tappable:YES error:error];
            if (!view) {
                return KIFTestStepResultWait;
            }
            
            return KIFTestStepResultSuccess;
        }];
        
        [self tapAccessibilityElement:element inView:view];
    }

Now we're getting somewhere. Everything you want to eliminate is in one function call to `accessibilityElementWithLabel:view:traits:error:`.  Looking at the source, it just calls a similarly named method in `UIApplication` and then adds some fancy error message construction.  We can swap this out with our own error logic and a call to the much more flexible `-[UIApplication accessibilityElementWithMatchingBlock:]`.
	
	- (void)tapViewWithAccessibilityHint:(NSString *)hint
	{
	    __block UIView *view;
	    __block UIAccessibilityElement *element;
	    
	    [self runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
	        
	        element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^BOOL(UIAccessibilityElement *element) {
	            return [element.accessibilityHint isEqualToString:hint];
	        }];
	        
	        KIFTestWaitCondition(element, error, @"Could not find element with hint: %@", hint);
	        
	        view = [UIAccessibilityElement viewContainingAccessibilityElement:element tappable:YES error:error];
	        return view ? KIFTestStepResultSuccess : KIFTestStepResultWait;
	    }];
	    
	    [self tapAccessibilityElement:element inView:view];
	}
	
It was quite a few steps to get here but in both cases it involved some degree of fairly trivial expansions until we found something we could swap out.  You should be able to apply these approaches to perform your own app specific tasks.