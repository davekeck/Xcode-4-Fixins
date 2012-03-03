#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalWriteStateData = nil;

@interface XCFixin_DisableWriteStateData : NSObject
@end

@implementation XCFixin_DisableWriteStateData

static BOOL overrideWriteStateData(id self, SEL _cmd)
{
    /* -(BOOL)[IDEWorkspaceDocument writeStateData] */
    return YES;
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -(BOOL)[IDEWorkspaceDocument writeStateData] */
    gOriginalWriteStateData = XCFixinOverrideMethodString(@"IDEWorkspaceDocument", @selector(writeStateData), (IMP)&overrideWriteStateData);
        XCFixinAssertOrPerform(gOriginalWriteStateData, goto failed);
    
    XCFixinPostflight();
}

@end