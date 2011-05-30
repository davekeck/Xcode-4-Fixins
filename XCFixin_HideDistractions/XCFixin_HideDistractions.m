#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#define HDAssertMessageFormat @"Nailtail assertion failed (file: %s, function: %s, line: %u): %s\n"

#define HDAssertOrPerform(condition, action)                                                                                                                              \
({                                                                                                                                                                        \
                                                                                                                                                                          \
    bool __evaluated_condition = false;                                                                                                                                   \
                                                                                                                                                                          \
    __evaluated_condition = (condition);                                                                                                                                  \
                                                                                                                                                                          \
    if (!__evaluated_condition)                                                                                                                                           \
    {                                                                                                                                                                     \
                                                                                                                                                                          \
        NSLog(HDAssertMessageFormat, __FILE__, __PRETTY_FUNCTION__, __LINE__, (#condition));                                                                              \
        action;                                                                                                                                                           \
                                                                                                                                                                          \
    }                                                                                                                                                                     \
                                                                                                                                                                          \
})

#define HDConfirmOrPerform(condition, action)         \
({                                                    \
                                                      \
    if (!(condition))                                 \
    {                                                 \
                                                      \
        action;                                       \
                                                      \
    }                                                 \
                                                      \
})

static NSString *const kDisableAnimationsClassName = @"XCFixin_DisableAnimations";

@interface XCFixin_HideDistractions : NSObject
@end

@implementation XCFixin_HideDistractions

+ (void)pluginDidLoad: (NSBundle *)plugin
{

    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationFinishedLaunching:)
        name: NSApplicationDidFinishLaunchingNotification object: nil];
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    failed:
    {
    
        NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
    
    }

}

+ (void)applicationFinishedLaunching: (NSNotification *)notification
{

    NSMenu *mainMenu = nil,
           *viewMenu = nil;
    NSMenuItem *viewMenuItem = nil,
               *hideDistractionsMenuItem = nil;
    
    mainMenu = [NSApp mainMenu];
    
        HDAssertOrPerform(mainMenu, return);
    
    viewMenuItem = [mainMenu itemWithTitle: @"View"];
    
        HDAssertOrPerform(viewMenuItem, return);
    
    viewMenu = [viewMenuItem submenu];
    
        HDAssertOrPerform(viewMenuItem, return);
    
    hideDistractionsMenuItem = [viewMenu addItemWithTitle: @"Hide Distractions" action: @selector(hideDistractions:) keyEquivalent: @"d"];
    
        HDAssertOrPerform(hideDistractionsMenuItem, return);
    
    [hideDistractionsMenuItem setKeyEquivalentModifierMask: (NSCommandKeyMask | NSShiftKeyMask)];
    [hideDistractionsMenuItem setTarget: self];

}

+ (void)hideDistractions: (id)sender
{

    NSMenu *mainMenu = nil,
           *viewMenu = nil,
           *navigatorsMenu = nil;
    NSMenuItem *viewMenuItem = nil,
               *navigatorsMenuItem = nil,
               *hideToolbarMenuItem = nil,
               *hideDebugAreaMenuItem = nil,
               *hideNavigatorMenuItem = nil;
    NSWindow *activeWindow = nil;
    
    mainMenu = [NSApp mainMenu];
    
        HDAssertOrPerform(mainMenu, return);
    
    viewMenuItem = [mainMenu itemWithTitle: @"View"];
    
        HDAssertOrPerform(viewMenuItem, return);
    
    viewMenu = [viewMenuItem submenu];
    
        HDAssertOrPerform(viewMenu, return);
    
    [viewMenu update];
    
    navigatorsMenuItem = [viewMenu itemWithTitle: @"Navigators"];
    
        HDAssertOrPerform(navigatorsMenuItem, return);
    
    navigatorsMenu = [navigatorsMenuItem submenu];
    
        HDAssertOrPerform(navigatorsMenu, return);
    
    [navigatorsMenu update];
    
    activeWindow = [NSApp keyWindow];
    
        HDConfirmOrPerform(activeWindow, return);
    
    /* If we get here, everything checks out; that is, we have an active window and we have references to the required menus. */
    
    hideToolbarMenuItem = [viewMenu itemWithTitle: @"Hide Toolbar"];
    hideDebugAreaMenuItem = [viewMenu itemWithTitle: @"Hide Debug Area"];
    hideNavigatorMenuItem = [navigatorsMenu itemWithTitle: @"Hide Navigator"];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow disableFlushWindow];
    
    if (hideToolbarMenuItem && [hideToolbarMenuItem isEnabled])
        [NSApp sendAction: [hideToolbarMenuItem action] to: [hideToolbarMenuItem target] from: hideToolbarMenuItem];
    
    /* Zoom our window after hiding the toolbar. */
    
    if (!NSEqualRects([activeWindow frame], [[activeWindow screen] visibleFrame]))
        [activeWindow setFrame: [[activeWindow screen] visibleFrame] display: YES];
    
    if (hideDebugAreaMenuItem && [hideDebugAreaMenuItem isEnabled])
        [NSApp sendAction: [hideDebugAreaMenuItem action] to: [hideDebugAreaMenuItem target] from: hideDebugAreaMenuItem];
    
    if (hideNavigatorMenuItem && [hideNavigatorMenuItem isEnabled])
        [NSApp sendAction: [hideNavigatorMenuItem action] to: [hideNavigatorMenuItem target] from: hideNavigatorMenuItem];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow enableFlushWindow];

}

@end