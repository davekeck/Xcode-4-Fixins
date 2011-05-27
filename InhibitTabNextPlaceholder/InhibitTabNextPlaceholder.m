#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP gOriginalImplementation = nil;

@interface InhibitTabNextPlaceholder : NSObject
@end

@implementation InhibitTabNextPlaceholder

static BOOL inhibitMoveToNextPlaceholderFromCharacterIndex(id self, SEL _cmd, unsigned long long characterIndex, BOOL forward, BOOL onlyIfNearby)
{

        if (onlyIfNearby)
            return NO;
    
    return ((BOOL (*)(id, SEL, unsigned long long, BOOL, BOOL))gOriginalImplementation)(self, _cmd, characterIndex, forward, onlyIfNearby);

}

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    if (!(class = NSClassFromString(@"DVTCompletingTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(_moveToNextPlaceholderFromCharacterIndex: forward: onlyIfNearby:))))
        goto failed;
    
    if (!(gOriginalImplementation = method_setImplementation(originalMethod, (IMP)&inhibitMoveToNextPlaceholderFromCharacterIndex)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

@end