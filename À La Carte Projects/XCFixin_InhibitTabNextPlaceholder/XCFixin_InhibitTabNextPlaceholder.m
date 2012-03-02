#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalMoveToNextPlaceholderFromCharacterIndex = nil;

@interface XCFixin_InhibitTabNextPlaceholder : NSObject
@end

@implementation XCFixin_InhibitTabNextPlaceholder

static BOOL overrideMoveToNextPlaceholderFromCharacterIndex(id self, SEL _cmd, unsigned long long characterIndex, BOOL forward, BOOL onlyIfNearby)
{
    /* -(BOOL)[DVTCompletingTextView _moveToNextPlaceholderFromCharacterIndex:(unsigned long long)arg1 forward:(BOOL)arg2 onlyIfNearby:(BOOL)arg3; */
    XCFixinConfirmOrPerform(!onlyIfNearby, return NO);
    return ((BOOL (*)(id, SEL, unsigned long long, BOOL, BOOL))gOriginalMoveToNextPlaceholderFromCharacterIndex)(self, _cmd, characterIndex, forward, onlyIfNearby);
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    Class class = nil;
    Method originalMethod = nil;
    
    /* Override -(BOOL)[DVTCompletingTextView _moveToNextPlaceholderFromCharacterIndex:(unsigned long long)arg1 forward:(BOOL)arg2 onlyIfNearby:(BOOL)arg3] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"DVTCompletingTextView"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(_moveToNextPlaceholderFromCharacterIndex: forward: onlyIfNearby:)), goto failed);
    XCFixinAssertOrPerform(gOriginalMoveToNextPlaceholderFromCharacterIndex = method_setImplementation(originalMethod, (IMP)&overrideMoveToNextPlaceholderFromCharacterIndex), goto failed);
    
    XCFixinPostflight();
}

@end