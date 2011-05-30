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

+ (void)clickMenuItem: (NSMenuItem *)menuItem
{

    if (menuItem && [menuItem isEnabled])
        [NSApp sendAction: [menuItem action] to: [menuItem target] from: menuItem];

}

+ (void)hideDistractions: (id)sender
{

    NSMenu *mainMenu = nil,
           *viewMenu = nil,
           *navigatorsMenu = nil,
           *utilitiesMenu = nil,
           *editorMenu = nil;
    NSMenuItem *viewMenuItem = nil,
               *navigatorsMenuItem = nil,
               *utilitiesMenuItem = nil,
               *editorMenuItem = nil,
               *hideToolbarMenuItem = nil,
               *hideDebugAreaMenuItem = nil,
               *hideNavigatorMenuItem = nil,
               *hideUtilitiesMenuItem = nil,
               *standardEditorLayoutMenuItem = nil;
    NSWindow *activeWindow = nil;
    
    mainMenu = [NSApp mainMenu];
    
        HDAssertOrPerform(mainMenu, return);
    
    /* Get View menu */
    
    viewMenuItem = [mainMenu itemWithTitle: @"View"];
    
        HDAssertOrPerform(viewMenuItem, return);
    
    viewMenu = [viewMenuItem submenu];
    
        HDAssertOrPerform(viewMenu, return);
    
    [viewMenu update];
    
    /* Get View > Navigators menu */
    
    navigatorsMenuItem = [viewMenu itemWithTitle: @"Navigators"];
    
        HDAssertOrPerform(navigatorsMenuItem, return);
    
    navigatorsMenu = [navigatorsMenuItem submenu];
    
        HDAssertOrPerform(navigatorsMenu, return);
    
    [navigatorsMenu update];
    
    /* Get View > Utilities menu */
    
    utilitiesMenuItem = [viewMenu itemWithTitle: @"Utilities"];
    
        HDAssertOrPerform(utilitiesMenuItem, return);
    
    utilitiesMenu = [utilitiesMenuItem submenu];
    
        HDAssertOrPerform(utilitiesMenu, return);
    
    [utilitiesMenu update];
    
    /* Get View > Editor menu */
    
    editorMenuItem = [viewMenu itemWithTitle: @"Editor"];
    
        HDAssertOrPerform(editorMenuItem, return);
    
    editorMenu = [editorMenuItem submenu];
    
        HDAssertOrPerform(editorMenu, return);
    
    [editorMenu update];
    
    /* Get the front window */
    
    activeWindow = [NSApp keyWindow];
    
        HDConfirmOrPerform(activeWindow, return);
    
    /* If we get here, everything checks out; that is, we have an active window and we have references to the required menus. */
    
    hideToolbarMenuItem = [viewMenu itemWithTitle: @"Hide Toolbar"];
    hideDebugAreaMenuItem = [viewMenu itemWithTitle: @"Hide Debug Area"];
    hideNavigatorMenuItem = [navigatorsMenu itemWithTitle: @"Hide Navigator"];
    hideUtilitiesMenuItem = [utilitiesMenu itemWithTitle: @"Hide Utilities"];
    standardEditorLayoutMenuItem = [editorMenu itemWithTitle: @"Standard"];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow disableFlushWindow];
    
    /* First we need to hide our active window's toolbar */
    
    [self clickMenuItem: hideToolbarMenuItem];
    
    /* Zoom our window after hiding the toolbar. */
    
    if (!NSEqualRects([activeWindow frame], [[activeWindow screen] visibleFrame]))
        [activeWindow setFrame: [[activeWindow screen] visibleFrame] display: YES];
    
    /* Perform the rest of our menu items now that the toolbar's taken care of. */
    
    [self clickMenuItem: hideDebugAreaMenuItem];
    [self clickMenuItem: hideNavigatorMenuItem];
    [self clickMenuItem: hideUtilitiesMenuItem];
    [self clickMenuItem: standardEditorLayoutMenuItem];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow enableFlushWindow];

}


@end