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
    XCFixinPreflight()
    
    Class class = nil;
    Method originalMethod = nil;
    
    /* Override -(void)[IDEQuickHelpOneShotController showPanel] */
    if (!(class = NSClassFromString(@"IDEQuickHelpOneShotController")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(showPanel))))
        goto failed;
    
    if (!(gOriginalShowPanel = method_setImplementation(originalMethod, (IMP)&overrideShowPanel)))
        goto failed;
    
    /* Override -(void)[IDEQuickHelpOneShotWindowController loadWindow] */
    if (!(class = NSClassFromString(@"IDEQuickHelpOneShotWindowController")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(loadWindow))))
        goto failed;
    
    if (!(gOriginalLoadWindow = method_setImplementation(originalMethod, (IMP)&overrideLoadWindow)))
        goto failed;
    
    XCFixinPostflight();
}

@end