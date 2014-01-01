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

@interface XCFixin_AddedView : NSView
@end

@implementation XCFixin_AddedView
@end

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

static NSView *GetFindBarStackView(NSView *findBarView)
{
	NSArray *subviews = [findBarView subviews];
	NSView *stackView = [subviews objectAtIndex:0];
	
	return stackView;
}

static void ForEachOption(id optionsCtrl, void (*fn)(id option, id context), id context)
{
	(*fn)(MSGSEND(NSView *, optionsCtrl, matchingStyleView), context);
	(*fn)(MSGSEND(NSView *, optionsCtrl, hitsMustContainView), context);
	(*fn)(MSGSEND(NSView *, optionsCtrl, matchCaseView), context);
	(*fn)(MSGSEND(NSView *, optionsCtrl, wrapView), context);
}

static void RemoveOptionFromSuperview(id option, id context)
{
	[option retain];
	[option removeFromSuperview];
}

// RemoveOptionsFromSuperview and AddOptionToFindBar must be called as a
// pair, because they contain matching release and retain calls.

static void RemoveOptionsFromSuperview(id optionsCtrl, NSView *findBarView)
{
	// Remove the popover options.
	ForEachOption(optionsCtrl, &RemoveOptionFromSuperview, nil);

	// Remove any added options.
	NSArray *subviews = [NSArray arrayWithArray:[GetFindBarStackView(findBarView) subviews]];
	for(NSView *view in subviews)
	{
		if ([view isKindOfClass:[XCFixin_AddedView class]])
			[view removeFromSuperview];
	}
}

static void AddOptionToView(id option, id view)
{
	[view addSubview:option];
	[option release];
}

+(void)autoPopulateButtonClicked:(id)arg
{
	NSButton *button = (NSButton *)arg;
	BOOL autoPopulate = [button state] == NSOnState;
	SetAutoPopulate(autoPopulate);
}

static void AddOptionsToFindBar(id optionsCtrl, NSView *findBarView)
{
	NSView *findBarStackView = GetFindBarStackView(findBarView);
	
	ForEachOption(optionsCtrl, &AddOptionToView, findBarStackView);
	
	// Add the auto populate option.
	{
		// these are (roughly) the expected values, at least on my PC...
		NSRect viewRect = NSMakeRect(0.f, 84.f, 256.f, 20.f);
		NSRect buttonRect = NSMakeRect(106.f, 1.f, 250.f, 18.f);
		NSFont *buttonFont = nil;
		
		NSView *wrapView = MSGSEND(NSView *, optionsCtrl, wrapView);
		if (wrapView && [[wrapView subviews] count] > 0)
		{
			NSButton *wrapButton = [[wrapView subviews] objectAtIndex:0];
			
			viewRect = [wrapView frame];
			viewRect.origin.y += viewRect.size.height;
			
			buttonRect = [wrapButton frame];
			buttonRect.size.width = viewRect.size.width - buttonRect.origin.x;
			
			buttonFont = [wrapButton font];
		}
		
		NSView *autoPopulateView = [[[XCFixin_AddedView alloc] initWithFrame:viewRect] autorelease];
		
		NSButton *autoPopulateButton = [[[NSButton alloc] initWithFrame:buttonRect] autorelease];
		
		[autoPopulateButton setTitle:@"Auto Populate"];
		[autoPopulateButton setButtonType:NSSwitchButton];
		[autoPopulateButton setState:GetAutoPopulate() ? NSOnState : NSOffState];
		
		[autoPopulateButton setAction:@selector(autoPopulateButtonClicked:)];
		[autoPopulateButton setTarget:[XCFixin_FindFix class]];
		 
		if (buttonFont)
		{
			// I was hoping this would make the check box part the same
			// size as the existing controls - but it doesn't.
			[autoPopulateButton setFont:buttonFont];
		}
		
		[autoPopulateView addSubview:autoPopulateButton];
		[findBarStackView addSubview:autoPopulateView];
		
		NSLog(@"Begin FindBar subviews.");
		DumpSubviews(findBarView, @"");
		NSLog(@"End FindBar subviews.");
	}
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
		double preferredViewHeight = gIsXcode5 ? 155. : 45.;
        [self setValue: [NSNumber numberWithDouble: preferredViewHeight] forKey: @"preferredViewHeight"];
    }
    
	//NSLog(@"%s: calling original.", __FUNCTION__);
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
	
	if (gIsXcode5)
	{
		//	NSLog(@"Begin FindBar subviews.");
		//	DumpSubviews(view, @"");
		//	NSLog(@"End FindBar subviews.");
		
		id optionsCtrl = MSGSEND(id, self, optionsCtrl);
		
		RemoveOptionsFromSuperview(optionsCtrl, [self view]);
		AddOptionsToFindBar(optionsCtrl, [self view]);
		
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
	else
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0), dispatch_get_main_queue(),
					   ^{
						   MSGSEND(void, self, setShowsOptions:, (BOOL)YES);
					   });
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
		if (gIsXcode5)
			RemoveOptionsFromSuperview(MSGSEND(id, self, optionsCtrl), [self view]);
		
		((void (*)(id, SEL, unsigned long long))gOriginalSetFinderMode)(self, _cmd, newFinderMode);
		
		if (gIsXcode5)
			AddOptionsToFindBar(MSGSEND(id, self, optionsCtrl), [self view]);
	}
}

+(void)populateFindString:(id)arg
{
	NSLog(@"Populate.");
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
			NSMenuItem *populateFindString = [[[NSMenuItem alloc] initWithTitle:@"Populate From Editor"
																		 action:@selector(populateFindString:)
																  keyEquivalent:@"e"] autorelease];
			
			[populateFindString setTarget:[XCFixin_FindFix class]];
			
			// This is supposed to be reminiscent of Command+E.
			[populateFindString setKeyEquivalentModifierMask:NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask];
			
			[recentsMenu insertItem:populateFindString atIndex:0];
		}
	}
	
	return recentsMenu;
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
	
	//NSLog(@"gIsXcode5 = %d.", (int)gIsXcode5);
    
    XCFixinPostflight();
}

@end
