#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "XCFixin.h"

static IMP gOriginalViewDidInstall = nil;

typedef id (*initWithSupportForRegexImp)(id, SEL, BOOL, BOOL, BOOL);
static initWithSupportForRegexImp gOriginalInitWithSupportForRegex = nil;

static IMP gOriginalShowFindOptionsPopover = nil;

@interface XCFixin_FindFix : NSObject
@end

@implementation XCFixin_FindFix

static void DumpSubviews(NSView *view, NSString *prefix)
{
	NSArray *subviews = [view subviews];
	
	for(NSUInteger i = 0; i < [subviews count]; ++i)
	{
		NSView *subview = [subviews objectAtIndex:i];
		
		NSLog(@"%@%lu. %@ (frame=%@)", prefix, (unsigned long)i, NSStringFromClass([subview class]), NSStringFromRect([subview frame]));
		DumpSubviews(subview, [prefix stringByAppendingString:@"    "]);
	}
}

static void overrideViewDidInstall(id self, SEL _cmd)
{
    /* -(void)[DVTFindBar viewDidInstall] */
	
	BOOL supportsReplace = [[self valueForKey: @"supportsReplace"] boolValue];
	
	NSLog(@"%s: supportsReplace=%s", __FUNCTION__, supportsReplace ? "YES" : "NO");
	
    if (supportsReplace)
    {
        [self setValue: [NSNumber numberWithUnsignedLongLong: 1] forKey: @"finderMode"];
        [self setValue: [NSNumber numberWithDouble: 150.0] forKey: @"preferredViewHeight"];
    }
    
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
	
	NSView *view = [self view];
	
//	NSLog(@"Begin FindBar subviews.");
//	DumpSubviews(view, @"");
//	NSLog(@"End FindBar subviews.");
	
	view = [[view subviews] objectAtIndex:0];
	[view addSubview:[[self optionsCtrl] view]];
}

static void overrideShowFindOptionsPopover(id self, SEL _cmd, id arg1)
{
	// Just do nothing. Actually popping up the popover removes the
	// controls from the find bar, of course...
	//
	// Long term, should really do something a bit neater, such as remove
	// the item from the menu, or at least disable it.
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -(void)[DVTFindBar viewDidInstall] */
    gOriginalViewDidInstall = XCFixinOverrideMethodString(@"DVTFindBar", @selector(viewDidInstall), (IMP)&overrideViewDidInstall);
	XCFixinAssertOrPerform(gOriginalViewDidInstall, goto failed);
	
	gOriginalShowFindOptionsPopover = XCFixinOverrideMethodString(@"DVTFindBar", @selector(_showFindOptionsPopover:), (IMP)&overrideShowFindOptionsPopover);
	XCFixinAssertOrPerform(gOriginalShowFindOptionsPopover, goto failed);
    
    XCFixinPostflight();
}

@end