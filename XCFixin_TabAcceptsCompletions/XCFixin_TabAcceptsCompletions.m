#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalInsertUsefulPrefix = nil;

@interface XCFixin_TabAcceptsCompletions : NSObject
@end

@implementation XCFixin_TabAcceptsCompletions

static void overrideInsertUsefulPrefix(id self, SEL _cmd)
{
	[[[self performSelector:@selector(textView)] performSelector:@selector(completionController)] performSelector:@selector(acceptCurrentCompletion)];
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -[DVTTextCompletionSession insertUsefulPrefix] */
    gOriginalInsertUsefulPrefix = XCFixinOverrideMethodString(@"DVTTextCompletionSession", @selector(insertUsefulPrefix), (IMP)&overrideInsertUsefulPrefix);
        XCFixinAssertOrPerform(gOriginalInsertUsefulPrefix, goto failed);
    
    XCFixinPostflight();
}

@end