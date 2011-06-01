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

#define HDAssertOrRaise(condition) HDAssertOrPerform((condition), [NSException raise: NSGenericException format: @"A XCFixin_HideDistractions exception occurred"])

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

+ (NSMenuItem *)menuItemWithPath: (NSString *)menuItemPath
{

    NSArray *pathComponents = nil;
    NSString *currentPathComponent = nil;
    NSMenu *currentMenu = nil;
    NSMenuItem *currentMenuItem = nil;
    
        NSParameterAssert(menuItemPath);
        NSParameterAssert([menuItemPath length]);
    
    currentMenu = [NSApp mainMenu];
    
        HDAssertOrPerform(currentMenu, return nil);
    
    pathComponents = [menuItemPath componentsSeparatedByString: @" > "];
    
    for (currentPathComponent in pathComponents)
    {
    
            HDAssertOrRaise(currentPathComponent);
            HDAssertOrRaise([currentPathComponent length]);
        
        [currentMenu update];
        currentMenuItem = [currentMenu itemWithTitle: currentPathComponent];
        
            HDConfirmOrPerform(currentMenuItem && [currentMenuItem isEnabled], return nil);
        
        if ([currentMenuItem hasSubmenu])
            currentMenu = [currentMenuItem submenu];
        
        else
            currentMenu = nil;
    
    }
    
    return currentMenuItem;

}

+ (void)hideDistractions: (id)sender
{

    NSMenuItem *hideToolbarMenuItem = nil,
               *hideDebugAreaMenuItem = nil,
               *hideNavigatorMenuItem = nil,
               *hideUtilitiesMenuItem = nil,
               *standardEditorLayoutMenuItem = nil,
               *hideFindBarMenuItem = nil;
    NSWindow *activeWindow = nil;
    
    hideToolbarMenuItem = [self menuItemWithPath: @"View > Hide Toolbar"];
    hideDebugAreaMenuItem = [self menuItemWithPath: @"View > Hide Debug Area"];
    hideNavigatorMenuItem = [self menuItemWithPath: @"View > Navigators > Hide Navigator"];
    hideUtilitiesMenuItem = [self menuItemWithPath: @"View > Utilities > Hide Utilities"];
    standardEditorLayoutMenuItem = [self menuItemWithPath: @"View > Editor > Standard"];
    hideFindBarMenuItem = [self menuItemWithPath: @"Edit > Find > Hide Find Bar"];
    
    /* Get the front window */
    
    activeWindow = [NSApp keyWindow];
    
        HDConfirmOrPerform(activeWindow, return);
    
    /* If we get here, everything checks out; that is, we have an active window and we have
       references to the required menus items. */
    
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
    [self clickMenuItem: hideFindBarMenuItem];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow enableFlushWindow];

}


@end