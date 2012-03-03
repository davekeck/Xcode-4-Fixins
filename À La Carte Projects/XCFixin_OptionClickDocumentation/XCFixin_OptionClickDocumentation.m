#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalShowPanel = nil;
static IMP gOriginalLoadWindow = nil;

@interface XCFixin_OptionClickDocumentation : NSObject
@end

@implementation XCFixin_OptionClickDocumentation

static void overrideShowPanel(id self, SEL _cmd)
{
    /* -(void)[IDEQuickHelpOneShotController showPanel] */
    [self performSelector: @selector(showDocumentation:)];
}

static void overrideLoadWindow(id self, SEL _cmd)
{
    /* -(void)[IDEQuickHelpOneShotWindowController loadWindow] */
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -(void)[IDEQuickHelpOneShotController showPanel] */
    gOriginalShowPanel = XCFixinOverrideMethodString(@"IDEQuickHelpOneShotController", @selector(showPanel), (IMP)&overrideShowPanel);
        XCFixinAssertOrPerform(gOriginalShowPanel, goto failed);
    
    /* Override -(void)[IDEQuickHelpOneShotWindowController loadWindow] */
    gOriginalLoadWindow = XCFixinOverrideMethodString(@"IDEQuickHelpOneShotWindowController", @selector(loadWindow), (IMP)&overrideLoadWindow);
        XCFixinAssertOrPerform(gOriginalLoadWindow, goto failed);
    
    XCFixinPostflight();
}

@end