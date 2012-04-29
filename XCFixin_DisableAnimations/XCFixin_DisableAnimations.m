#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalInitWithDuration = nil;
static IMP gOriginalSetDuration = nil;

@interface XCFixin_DisableAnimations : NSObject
@end

@implementation XCFixin_DisableAnimations

static void overrideInitWithDuration(id self, SEL _cmd, NSTimeInterval arg1, NSAnimationCurve arg2)
{
    /* -[NSAnimation initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve] */
    ((void (*)(id, SEL, NSTimeInterval, NSAnimationCurve))gOriginalInitWithDuration)(self, _cmd, 0.0, arg2);
}

static void overrideSetDuration(id self, SEL _cmd, NSTimeInterval arg1)
{
    /* -[NSAnimation setDuration:(NSTimeInterval)duration] */
    ((void (*)(id, SEL, NSTimeInterval))gOriginalSetDuration)(self, _cmd, 0.0);
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -[NSAnimation initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve] */
    gOriginalInitWithDuration = XCFixinOverrideMethodString(@"NSAnimation", @selector(initWithDuration: animationCurve:), (IMP)&overrideInitWithDuration);
        XCFixinAssertOrPerform(gOriginalInitWithDuration, goto failed);
    
    /* Override -[NSAnimation setDuration:(NSTimeInterval)duration] */
    gOriginalSetDuration = XCFixinOverrideMethodString(@"NSAnimation", @selector(setDuration:), (IMP)&overrideSetDuration);
        XCFixinAssertOrPerform(gOriginalSetDuration, goto failed);
    
    XCFixinPostflight();
}

@end