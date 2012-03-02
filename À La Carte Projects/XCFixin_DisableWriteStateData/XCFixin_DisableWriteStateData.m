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
    
    Class class = nil;
    Method originalMethod = nil;
    
    /* Override -(BOOL)[IDEWorkspaceDocument writeStateData] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"IDEWorkspaceDocument"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(writeStateData)), goto failed);
    XCFixinAssertOrPerform(gOriginalWriteStateData = method_setImplementation(originalMethod, (IMP)&overrideWriteStateData), goto failed);
    
    XCFixinPostflight();
}

@end