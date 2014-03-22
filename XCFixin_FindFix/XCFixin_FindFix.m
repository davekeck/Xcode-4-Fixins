#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "XCFixin.h"

static IMP gOriginalViewDidInstall = nil;
static IMP gOriginalSetFinderMode = nil;
static IMP gOriginalRecentsMenu = nil;
static BOOL gIsXcode5 = NO;
static NSString *gAutoPopulateUserDefaultsKey = @"XCFixinFindFixAutoPopulate";

@interface XCFixin_FindFix : NSObject
@end

@implementation XCFixin_FindFix

#define MSGSEND(RESULT_TYPE, SELF, SELECTOR, ...) (((RESULT_TYPE (*)(id, SEL, ...))&objc_msgSend)((SELF), @selector(SELECTOR), ##__VA_ARGS__))

static void SetAutoPopulate(BOOL autoPopulate)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	[userDefaults setBool:autoPopulate forKey:gAutoPopulateUserDefaultsKey];
}

static BOOL GetAutoPopulate(void)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	BOOL autoPopulate = [userDefaults boolForKey:gAutoPopulateUserDefaultsKey];
	return autoPopulate;
}

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

static NSArray *RemoveOptionsFromSuperview(NSViewController *findBar)
{
	NSView *optionsCtrl = MSGSEND(NSView *, findBar, optionsCtrl);
	
	NSView *matchingStyleView = MSGSEND(NSView *, optionsCtrl, matchingStyleView);
	NSView *hitsMustContainView = MSGSEND(NSView *, optionsCtrl, hitsMustContainView);
	NSView *matchCaseView = MSGSEND(NSView *, optionsCtrl, matchCaseView);
	NSView *wrapView = MSGSEND(NSView *, optionsCtrl, wrapView);
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:4];
	
	[array addObject:matchingStyleView];
	[array addObject:hitsMustContainView];
	[array addObject:matchCaseView];
	[array addObject:wrapView];
	
	for (NSView *view in array)
		[view removeFromSuperview];
	
	return array;
}

static void AddOptionsToFindBar(NSViewController *findBar, NSArray *options)
{
	NSView *findBarView = [findBar view];
	NSArray *findBarSubviews = [findBarView subviews];
	NSView *findBarStackView = [findBarSubviews objectAtIndex:0];
	
	for (NSView *view in options)
		[findBarStackView addSubview:view];
}

static void overrideViewDidInstall(id self, SEL _cmd)
{
	NSTextView *textView = XCFixinFindIDETextView(NO);
	NSLog(@"%s: textView = %p", __FUNCTION__, textView);

    /* -(void)[DVTFindBar viewDidInstall] */
	
	//NSLog(@"%s: check supportsReplace.", __FUNCTION__);
	BOOL supportsReplace = [[self valueForKey: @"supportsReplace"] boolValue];
	
	// NSLog(@"%s: supportsReplace=%s", __FUNCTION__, supportsReplace ? "YES" : "NO");
	
    if (supportsReplace)
    {
		//NSLog(@"%s: set finderMode.", __FUNCTION__);
        [self setValue: [NSNumber numberWithUnsignedLongLong: 1] forKey: @"finderMode"];
		
		//NSLog(@"%s: set preferredViewHeight.", __FUNCTION__);
		double preferredViewHeight = gIsXcode5 ? 135. : 45.;
        [self setValue: [NSNumber numberWithDouble: preferredViewHeight] forKey: @"preferredViewHeight"];
    }
    
	//NSLog(@"%s: calling original.", __FUNCTION__);
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
	
	if (gIsXcode5)
	{
		//	NSLog(@"Begin FindBar subviews.");
		//	DumpSubviews(view, @"");
		//	NSLog(@"End FindBar subviews.");
		
		NSArray *views = RemoveOptionsFromSuperview(self);
		
		AddOptionsToFindBar(self, views);
	}
	else
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0), dispatch_get_main_queue(),
					   ^{
						   MSGSEND(void, self, setShowsOptions:, (BOOL)YES);
					   });
	}

	if (GetAutoPopulate())
	{
		if (textView)
		{
			NSLog(@"%s: got text view.", __FUNCTION__);
			
			NSArray *selectedRanges = [textView selectedRanges];
			
			// Start out with first bit of selection...
			NSRange populateRange = [[selectedRanges objectAtIndex:0] rangeValue];
			if (populateRange.length == 0)
			{
				// No selection, so use the word about the cursor.
				//
				// (NSRange is small, so it's an honarary primitive for the
				// purposes of manual message sending.)
				populateRange = MSGSEND(NSRange, textView, wordRangeAtLocation:, (unsigned long long)populateRange.location);
			}
			
			if (populateRange.length > 0)
			{
				NSTextStorage *textStorage = [textView textStorage];
				NSString *textStorageString = [textStorage string];
				
				NSString *populateString = [textStorageString substringWithRange:populateRange];
				
				NSLog(@"Populate string: ``%@''.", populateString);
				
				MSGSEND(void, self, setFindString:, populateString);
			}
		}
	}
}

static void overrideSetFinderMode(id self, SEL _cmd, unsigned long long newFinderMode)
{
	// Don't allow setting of find mode if replace is supported.
	if (newFinderMode == 0 && MSGSEND(BOOL, self, supportsReplace))
		newFinderMode = 1;
	
	unsigned long long oldFinderMode = MSGSEND(unsigned long long, self, finderMode);
	if (newFinderMode != oldFinderMode)
	{
		NSArray *views = nil;
		
		if (gIsXcode5)
			views = RemoveOptionsFromSuperview(self);
		
		((void (*)(id, SEL, unsigned long long))gOriginalSetFinderMode)(self, _cmd, newFinderMode);
		
		if (gIsXcode5)
			AddOptionsToFindBar(self, views);
	}
}

static id overrideRecentsMenu(id self, SEL _cmd)
{
	NSMenu *recentsMenu = ((id (*)(id, SEL))gOriginalRecentsMenu)(self, _cmd);
	
//	NSLog(@"%s: class = %@", __FUNCTION__, NSStringFromClass([recentsMenu class]));
	
	// Well, there'll only be one copy of each item to remove. But, no
	// reason to make things flakier than they need to be.
	{
		NSInteger i = 0;
		
		while (i < [recentsMenu numberOfItems])
		{
			NSMenuItem *item = [recentsMenu itemAtIndex:i];
		
			if ([item target] == self && [item action] == @selector(_showFindOptionsPopover:))
				[recentsMenu removeItemAtIndex:i];
			else if ([item target] == [XCFixin_FindFix class] && [item action] == @selector(populateFindString:))
				[recentsMenu removeItemAtIndex:i];
			else
				++i;
		}
		
		// Insert the populate option
		{
			NSMenuItem *populateFindString = [[NSMenuItem alloc] initWithTitle:@"Populate From Editor"
																		 action:@selector(populateFindString:)
																  keyEquivalent:@"e"];
			
			[populateFindString setTarget:[XCFixin_FindFix class]];
			
			// This is supposed to be reminiscent of Command+E.
			[populateFindString setKeyEquivalentModifierMask:NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask];
			
			[recentsMenu insertItem:populateFindString atIndex:0];
		}
	}
	
	return recentsMenu;
}

+(void)autoPopulateClicked:(id)arg
{
	//	NSLog(@"%s: arg = (%@ *)%p", __FUNCTION__, NSStringFromClass([arg class]), arg);
	NSMenuItem *item = (NSMenuItem *)arg;
	
	BOOL autoPopulate = [item state] == NSOnState;
	autoPopulate = !autoPopulate;
	
	SetAutoPopulate(autoPopulate);
	[item setState:autoPopulate ? NSOnState : NSOffState];
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -(void)[DVTFindBar viewDidInstall] */
    gOriginalViewDidInstall = XCFixinOverrideMethodString(@"DVTFindBar", @selector(viewDidInstall), (IMP)&overrideViewDidInstall);
	XCFixinAssertOrPerform(gOriginalViewDidInstall, goto failed);
	
	gOriginalSetFinderMode = XCFixinOverrideMethodString(@"DVTFindBar", @selector(setFinderMode:), (IMP)&overrideSetFinderMode);
	XCFixinAssertOrPerform(gOriginalSetFinderMode, goto failed);
	
	if (class_respondsToSelector(objc_getClass("DVTFindBar"), @selector(_showFindOptionsPopover:)))
	{
		gIsXcode5 = YES;

		gOriginalRecentsMenu = XCFixinOverrideMethodString(@"DVTFindBar", @selector(_recentsMenu), (IMP)&overrideRecentsMenu);
		XCFixinAssertOrPerform(gOriginalRecentsMenu, goto failed);
	}
	
	// Add auto populate menu option.
	{
		NSMenu *findMenu = nil;
		
		if (gIsXcode5)
		{
			NSMenu *mainMenu = [NSApp mainMenu];
			int findMenuIndex = [mainMenu indexOfItemWithTitle:@"Find"];
			if (findMenuIndex >= 0)
				findMenu = [[mainMenu itemAtIndex:findMenuIndex] submenu];
		}
		else
		{
			NSMenu *mainMenu = [NSApp mainMenu];
			int editMenuIndex = [mainMenu indexOfItemWithTitle:@"Edit"];
			if (editMenuIndex >= 0)
			{
				NSMenu *editMenu = [[mainMenu itemAtIndex:editMenuIndex] submenu];
				int findMenuIndex = [editMenu indexOfItemWithTitle:@"Find"];
				if (findMenuIndex >= 0)
					findMenu = [[editMenu itemAtIndex:findMenuIndex] submenu];
			}
		}
		
		if (findMenu)
		{
			NSMenuItem *autoPopulateItem = [NSMenuItem new];
		
			[autoPopulateItem setTitle:@"Auto Populate Find Bar"];
			[autoPopulateItem setTarget:[XCFixin_FindFix class]];
			[autoPopulateItem setAction:@selector(autoPopulateClicked:)];
			[autoPopulateItem setEnabled:YES];
			[autoPopulateItem setState:GetAutoPopulate() ? NSOnState : NSOffState];
			
			[findMenu addItem:autoPopulateItem];
		}
	}
	
	//NSLog(@"gIsXcode5 = %d.", (int)gIsXcode5);
    
    XCFixinPostflight();
}

@end
