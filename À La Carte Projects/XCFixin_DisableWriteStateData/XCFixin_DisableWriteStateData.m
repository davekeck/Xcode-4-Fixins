#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP gOriginalWriteStateData = nil;

@interface XCFixin_DisableWriteStateData : NSObject
@end

@implementation XCFixin_DisableWriteStateData

static BOOL overrideWriteStateData(id self, SEL _cmd)
{

    return YES;

}

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    /* Override -(BOOL)[IDEWorkspaceDocument writeStateData]; */
    
    if (!(class = NSClassFromString(@"IDEWorkspaceDocument")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(writeStateData))))
        goto failed;
    
    if (!(gOriginalWriteStateData = method_setImplementation(originalMethod, (IMP)&overrideWriteStateData)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

@end