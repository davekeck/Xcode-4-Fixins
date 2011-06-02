#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP gOriginalInitWithContentRect = nil;

@interface XCFixin_InhibitBezelAlertInteraction : NSObject
@end

@implementation XCFixin_InhibitBezelAlertInteraction

static id overrideInitWithContentRect(id self, SEL _cmd, NSRect arg1, NSUInteger arg2, NSBackingStoreType arg3, BOOL arg4)
{

    /* -(id)[DVTBezelAlertPanel initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle
        backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation] */
    
    if (!(self = ((id (*)(id, SEL, NSRect, NSUInteger, NSBackingStoreType, BOOL))gOriginalInitWithContentRect)(self, _cmd, arg1, arg2, arg3, arg4)))
        return nil;
    
    [self setIgnoresMouseEvents: YES];
    
    return self;

}

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    /* Override -(id)[DVTBezelAlertPanel initWithContentRect:(NSRect)arg1 styleMask:(NSUInteger)arg2
        backing:(NSBackingStoreType)arg3 defer:(BOOL)arg4] */
    
    if (!(class = NSClassFromString(@"DVTBezelAlertPanel")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(initWithContentRect: styleMask: backing: defer:))))
        goto failed;
    
    if (!(gOriginalInitWithContentRect = method_setImplementation(originalMethod, (IMP)&overrideInitWithContentRect)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

@end