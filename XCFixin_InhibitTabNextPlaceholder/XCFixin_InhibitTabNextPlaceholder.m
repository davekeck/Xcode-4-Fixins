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
    
    /* Override -(BOOL)[DVTCompletingTextView _moveToNextPlaceholderFromCharacterIndex:(unsigned long long)arg1 forward:(BOOL)arg2 onlyIfNearby:(BOOL)arg3] */
    gOriginalMoveToNextPlaceholderFromCharacterIndex = XCFixinOverrideMethodString(@"DVTCompletingTextView",
        @selector(_moveToNextPlaceholderFromCharacterIndex: forward: onlyIfNearby:), (IMP)&overrideMoveToNextPlaceholderFromCharacterIndex);
        XCFixinAssertOrPerform(gOriginalMoveToNextPlaceholderFromCharacterIndex, goto failed);
    
    XCFixinPostflight();
}

@end