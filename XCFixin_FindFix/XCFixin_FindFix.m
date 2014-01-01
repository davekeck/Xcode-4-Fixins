#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "XCFixin.h"

static IMP gOriginalViewDidInstall = nil;
static IMP gOriginalSetFinderMode = nil;
static IMP gOriginalRecentsMenu = nil;
static BOOL gIsXcode5 = NO;

@interface XCFixin_FindFix : NSObject
@end

@implementation XCFixin_FindFix

#define MSGSEND(SELF, SEL, ...) (objc_msgSend((SELF), @selector(SEL), ##__VA_ARGS__))

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

static void ForEachOption(id optionsCtrl, void (*fn)(id option, id context), id context)
{
	(*fn)(MSGSEND(optionsCtrl, matchingStyleView), context);
	(*fn)(MSGSEND(optionsCtrl, hitsMustContainView), context);
	(*fn)(MSGSEND(optionsCtrl, matchCaseView), context);
	(*fn)(MSGSEND(optionsCtrl, wrapView), context);
}

static void RemoveOptionFromSuperview(id option, id context)
{
	[option retain];
	[option removeFromSuperview];
}

// RemoveOptionsFromSuperview and AddOptionToFindBar must be called as a
// pair, because they contain matching release and retain calls.

static void RemoveOptionsFromSuperview(id optionsCtrl)
{
	ForEachOption(optionsCtrl, &RemoveOptionFromSuperview, nil);
}

static void AddOptionToFindBar(id option, id findBarView)
{
	NSView *stackView = [[findBarView subviews] objectAtIndex:0];
	[stackView addSubview:option];
	[option release];
}

static void AddOptionsToFindBar(id optionsCtrl, id findBarView)
{
	ForEachOption(optionsCtrl, &AddOptionToFindBar, findBarView);
}

static void overrideViewDidInstall(id self, SEL _cmd)
{
    /* -(void)[DVTFindBar viewDidInstall] */
	
	//NSLog(@"%s: check supportsReplace.", __FUNCTION__);
	BOOL supportsReplace = [[self valueForKey: @"supportsReplace"] boolValue];
	
	// NSLog(@"%s: supportsReplace=%s", __FUNCTION__, supportsReplace ? "YES" : "NO");
	
    if (supportsReplace)
    {
		//NSLog(@"%s: set finderMode.", __FUNCTION__);
        [self setValue: [NSNumber numberWithUnsignedLongLong: 1] forKey: @"finderMode"];
		
		//NSLog(@"%s: set preferredViewHeight.", __FUNCTION__);
		double preferredViewHeight = gIsXcode5 ? 150. : 45.;
        [self setValue: [NSNumber numberWithDouble: preferredViewHeight] forKey: @"preferredViewHeight"];
    }
    
	//NSLog(@"%s: calling original.", __FUNCTION__);
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
	
	if (gIsXcode5)
	{
		//	NSLog(@"Begin FindBar subviews.");
		//	DumpSubviews(view, @"");
		//	NSLog(@"End FindBar subviews.");
		
		id optionsCtrl = MSGSEND(self, optionsCtrl);
		
		RemoveOptionsFromSuperview(optionsCtrl);
		AddOptionsToFindBar(optionsCtrl, [self view]);
	}
	else
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0), dispatch_get_main_queue(),
					   ^{
						   MSGSEND(self, setShowsOptions:, (BOOL)YES);
					   });
	}
}

static void overrideSetFinderMode(id self, SEL _cmd, unsigned long long newFinderMode)
{
	// Don't allow setting of find mode if replace is supported.
	if (newFinderMode == 0 && (BOOL)MSGSEND(self, supportsReplace))
		newFinderMode = 1;
	
	unsigned long long oldFinderMode = (unsigned long long)MSGSEND(self, finderMode);
	if (newFinderMode != oldFinderMode)
	{
		if (gIsXcode5)
			RemoveOptionsFromSuperview(MSGSEND(self, optionsCtrl));
		
		((void (*)(id, SEL, unsigned long long))gOriginalSetFinderMode)(self, _cmd, newFinderMode);
		
		if (gIsXcode5)
			AddOptionsToFindBar(MSGSEND(self, optionsCtrl), [self view]);
	}
}

static id overrideRecentsMenu(id self, SEL _cmd)
{
	NSMenu *recentsMenu = ((id (*)(id, SEL))gOriginalRecentsMenu)(self, _cmd);
	
//	NSLog(@"%s: class = %@", __FUNCTION__, NSStringFromClass([recentsMenu class]));
	
	// Well, there'll only be one copy of the find options item. But, no
	// reason to make things flakier than they need to be.
	{
		NSInteger i = 0;
		
		while (i < [recentsMenu numberOfItems])
		{
			NSMenuItem *item = [recentsMenu itemAtIndex:i];
		
			if ([item target] == self && [item action] == @selector(_showFindOptionsPopover:))
				[recentsMenu removeItemAtIndex:i];
			else
			{
				if ([[item title] isEqualToString:@"Insert Pattern"])
				{
					
				}
				
				++i;
			}
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
