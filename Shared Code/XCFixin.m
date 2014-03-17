#import "XCFixin.h"
#import <objc/runtime.h>
#import <Cocoa/Cocoa.h>

BOOL XCFixinShouldLoad(void)
{
    BOOL result = NO;
    
    @autoreleasepool {
        
        /* Prevent our plugins from loading in non-IDE processes, like xcodebuild. */
        NSString *processName = [[NSProcessInfo processInfo] processName];
        XCFixinConfirmOrPerform([processName caseInsensitiveCompare: @"xcode"] == NSOrderedSame, return result);
        
        /* Prevent our plugins from loading in Xcode versions < 4. */
        NSArray *versionComponents = [[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"] componentsSeparatedByString: @"."];
        XCFixinConfirmOrPerform(versionComponents && [versionComponents count], return result);
        NSInteger xcodeMajorVersion = [[versionComponents objectAtIndex: 0] integerValue];
        XCFixinConfirmOrPerform(xcodeMajorVersion >= 4, return result);
        
        result = YES;
        
    }
    
    return result;
}

const NSUInteger XCFixinMaxLoadAttempts = 3;
IMP XCFixinOverrideMethod(Class class, SEL selector, IMP newImplementation)
{
    Method *classMethods = nil;
    IMP result = nil;
    
        XCFixinAssertOrPerform(class, goto cleanup);
        XCFixinAssertOrPerform(selector, goto cleanup);
        XCFixinAssertOrPerform(newImplementation, goto cleanup);
    
    Method originalMethod = class_getInstanceMethod(class, selector);
        XCFixinAssertOrPerform(originalMethod, goto cleanup);
    
    IMP originalImplementation = method_getImplementation(originalMethod);
    unsigned int classMethodsCount = 0;
    classMethods = class_copyMethodList(class, &classMethodsCount);
        XCFixinAssertOrPerform(classMethods, goto cleanup);
    
    /* Check to see if the method is defined at the level of 'class', rather than at a super class' level. */
    BOOL methodDefined = NO;
    for (unsigned int i = 0; i < classMethodsCount; i++)
    {
        if (classMethods[i] == originalMethod)
        {
            methodDefined = YES;
            break;
        }
    }
    
    /* If the method's defined at the level of 'class', then we'll just set its implementation. */
    if (methodDefined)
    {
        IMP setImplementationResult = method_setImplementation(originalMethod, newImplementation);
            XCFixinAssertOrPerform(setImplementationResult, goto cleanup);
    }
    
    /* If the method isn't defined at the level of 'class' (and therefore it's defined at a superclass' level), then
       we need to add a method to the level of 'class'. */
    else
    {
        /* Use the return/argument types for the existing method. */
        const char *types = method_getTypeEncoding(originalMethod);
            XCFixinAssertOrPerform(types, goto cleanup);
        
        BOOL addMethodResult = class_addMethod(class, selector, newImplementation, types);
            XCFixinAssertOrPerform(addMethodResult, goto cleanup);
    }
    
    result = originalImplementation;
    
    cleanup:
    {
        if (classMethods)
            free(classMethods),
            classMethods = nil;
    }
    
    return result;
}

NSTextView *XCFixinFindIDETextView(BOOL log)
{
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
	if(!mainWindow)
	{
		if(log)
			NSLog(@"Can't find IDE text view - no main window.\n");
		
		return nil;
	}
	
	Class DVTCompletingTextView=objc_getClass("DVTCompletingTextView");
	if(!DVTCompletingTextView)
	{
		if(log)
			NSLog(@"Can't find IDE text view - DVTCompletingTextView class unavailable.\n");
		
		return nil;
	}
	
	id textView=nil;
	
	for(NSResponder *responder=[mainWindow firstResponder];responder;responder=[responder nextResponder])
	{
		if([responder isKindOfClass:DVTCompletingTextView])
		{
			textView=responder;
			break;
		}
	}
	
	if(!textView)
	{
		if(log)
			NSLog(@"Can't find IDE text view - no DVTCompletingTextView in the responder chain.\n");
		
		return nil;
	}
	
	return textView;
}

