#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP gOriginalOrderFront = nil;

@interface XCFixin_InhibitBezelAlertInteraction : NSObject
@end

@implementation XCFixin_InhibitBezelAlertInteraction

static void overrideOrderFront(id self, SEL _cmd, id arg1)
{

    /* -(void)[DVTBezelAlertPanel orderFront:(id)arg1] */
    
    [self setIgnoresMouseEvents: YES];
    ((void (*)(id, SEL, id))gOriginalOrderFront)(self, _cmd, arg1);

}

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    /* Override -(void)[DVTBezelAlertPanel orderFront:(id)arg1] */
    
    if (!(class = NSClassFromString(@"DVTBezelAlertPanel")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(orderFront:))))
        goto failed;
    
    if (!(gOriginalOrderFront = method_setImplementation(originalMethod, (IMP)&overrideOrderFront)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

@end