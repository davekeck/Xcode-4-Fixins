#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP gOriginalMoveToNextPlaceholderFromCharacterIndex = nil;

@interface XCFixin_InhibitTabNextPlaceholder : NSObject
@end

@implementation XCFixin_InhibitTabNextPlaceholder

static BOOL overrideMoveToNextPlaceholderFromCharacterIndex(id self, SEL _cmd, unsigned long long characterIndex, BOOL forward, BOOL onlyIfNearby)
{

    /* -(BOOL)[DVTCompletingTextView _moveToNextPlaceholderFromCharacterIndex:(unsigned long long)arg1 forward:(BOOL)arg2 onlyIfNearby:(BOOL)arg3; */
    
        if (onlyIfNearby)
            return NO;
    
    return ((BOOL (*)(id, SEL, unsigned long long, BOOL, BOOL))gOriginalMoveToNextPlaceholderFromCharacterIndex)(self, _cmd, characterIndex, forward, onlyIfNearby);

}

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    /* Override -(BOOL)[DVTCompletingTextView _moveToNextPlaceholderFromCharacterIndex:(unsigned long long)arg1 forward:(BOOL)arg2 onlyIfNearby:(BOOL)arg3] */
    
    if (!(class = NSClassFromString(@"DVTCompletingTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(_moveToNextPlaceholderFromCharacterIndex: forward: onlyIfNearby:))))
        goto failed;
    
    if (!(gOriginalMoveToNextPlaceholderFromCharacterIndex = method_setImplementation(originalMethod, (IMP)&overrideMoveToNextPlaceholderFromCharacterIndex)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

@end