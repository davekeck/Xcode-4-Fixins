#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static NSString *const kDisableAnimationsClassName = @"XCFixin_DisableAnimations";
static NSString *const kHideDistractionsKey = @"D";
static NSUInteger kHideDistractionsKeyModifiers = (NSCommandKeyMask | NSShiftKeyMask);

@interface XCFixin_HideDistractions : NSObject
@end

@implementation XCFixin_HideDistractions

+ (void)applicationFinishedLaunching: (NSNotification *)notification
{
    NSMenu *mainMenu = nil,
           *viewMenu = nil;
    NSMenuItem *viewMenuItem = nil,
               *hideDistractionsMenuItem = nil;
    
    mainMenu = [NSApp mainMenu];
        XCFixinAssertOrPerform(mainMenu, return);
    
    viewMenuItem = [mainMenu itemWithTitle: @"View"];
        XCFixinAssertOrPerform(viewMenuItem, return);
    
    viewMenu = [viewMenuItem submenu];
        XCFixinAssertOrPerform(viewMenuItem, return);
    
    /* The 'Hide Distractions' menu item key combination can be set below. */
    hideDistractionsMenuItem = [[[NSMenuItem alloc] initWithTitle: @"Hide Distractions" action: @selector(hideDistractions:) keyEquivalent: kHideDistractionsKey] autorelease];
        XCFixinAssertOrPerform(hideDistractionsMenuItem, return);
    [hideDistractionsMenuItem setKeyEquivalentModifierMask: kHideDistractionsKeyModifiers];
    [hideDistractionsMenuItem setTarget: self];
    [viewMenu addItem: hideDistractionsMenuItem];
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
        XCFixinAssertOrPerform(currentMenu, return nil);
    
    pathComponents = [menuItemPath componentsSeparatedByString: @" > "];
    
    for (currentPathComponent in pathComponents)
    {
            XCFixinAssertOrRaise(currentPathComponent);
            XCFixinAssertOrRaise([currentPathComponent length]);
        
        [currentMenu update];
        currentMenuItem = [currentMenu itemWithTitle: currentPathComponent];
            XCFixinConfirmOrPerform(currentMenuItem && [currentMenuItem isEnabled], return nil);
        
        if ([currentMenuItem hasSubmenu])
            currentMenu = [currentMenuItem submenu];
        else
            currentMenu = nil;
    }
    
    return currentMenuItem;
}

+ (void)hideDistractions: (id)sender
{
    NSWindow *activeWindow = nil;
    
    /* Get the front window */
    
    activeWindow = [NSApp keyWindow];
        XCFixinConfirmOrPerform(activeWindow, return);
    
    /* If we get here, everything checks out; that is, we have an active window and we have
       references to the required menus items. */
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow disableFlushWindow];
    
    [self clickMenuItem: [self menuItemWithPath: @"View > Hide Toolbar"]];
    [self clickMenuItem: [self menuItemWithPath: @"View > Hide Tab Bar"]];
    
    /* Zoom our window after hiding the toolbar. */
    
    if (!NSEqualRects([activeWindow frame], [[activeWindow screen] visibleFrame]))
        [activeWindow setFrame: [[activeWindow screen] visibleFrame] display: YES];
    
    /* Perform the rest of our menu items now that the toolbar's taken care of. */
    
    [self clickMenuItem: [self menuItemWithPath: @"View > Debug Area > Hide Debug Area"]];
    [self clickMenuItem: [self menuItemWithPath: @"View > Navigators > Hide Navigator"]];
    [self clickMenuItem: [self menuItemWithPath: @"View > Utilities > Hide Utilities"]];
    [self clickMenuItem: [self menuItemWithPath: @"View > Standard Editor > Show Standard Editor"]];
    [self clickMenuItem: [self menuItemWithPath: @"Edit > Find > Hide Find Bar"]];
    [self clickMenuItem: [self menuItemWithPath: @"Editor > Issues > Hide All Issues"]];
    
    if (NSClassFromString(kDisableAnimationsClassName))
        [activeWindow enableFlushWindow];
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationFinishedLaunching:)
        name: NSApplicationDidFinishLaunchingNotification object: nil];
    
    XCFixinPostflight();
}

@end