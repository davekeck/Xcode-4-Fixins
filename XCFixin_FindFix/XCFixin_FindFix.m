#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "XCFixin.h"

static IMP gOriginalViewDidInstall = nil;

typedef id (*initWithSupportForRegexImp)(id, SEL, BOOL, BOOL, BOOL);
static initWithSupportForRegexImp gOriginalInitWithSupportForRegex = nil;

static IMP gOriginalShowFindOptionsPopover = nil;

static IMP gOriginalSetFinderMode = nil;
static IMP gOriginalChangeFinderMode = nil;

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

static void ForEachOption(id optionsCtrl, void (*fn)(id option, id context), id context)
{
	(*fn)([optionsCtrl matchingStyleView], context);
	(*fn)([optionsCtrl hitsMustContainView], context);
	(*fn)([optionsCtrl matchCaseView], context);
	(*fn)([optionsCtrl wrapView], context);
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
	
	BOOL supportsReplace = [[self valueForKey: @"supportsReplace"] boolValue];
	
	NSLog(@"%s: supportsReplace=%s", __FUNCTION__, supportsReplace ? "YES" : "NO");
	
    if (supportsReplace)
    {
        [self setValue: [NSNumber numberWithUnsignedLongLong: 1] forKey: @"finderMode"];
        [self setValue: [NSNumber numberWithDouble: 150.0] forKey: @"preferredViewHeight"];
    }
    
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
	
//	NSLog(@"Begin FindBar subviews.");
//	DumpSubviews(view, @"");
//	NSLog(@"End FindBar subviews.");
	
	id optionsCtrl = [self optionsCtrl];
	
	RemoveOptionsFromSuperview(optionsCtrl);
	AddOptionsToFindBar(optionsCtrl, [self view]);
}

static void overrideShowFindOptionsPopover(id self, SEL _cmd, id arg1)
{
	// Just do nothing. Actually popping up the popover removes the
	// controls from the find bar, of course...
	//
	// Long term, should really do something a bit neater, such as remove
	// the item from the menu, or at least disable it.
}

static void overrideSetFinderMode(id self, SEL _cmd, unsigned long long arg1)
{
	unsigned long long oldFinderMode = (unsigned long long)[self finderMode];
	if (arg1 != oldFinderMode)
	{
		id optionsCtrl = [self optionsCtrl];
		
		RemoveOptionsFromSuperview(optionsCtrl);
		
		((void (*)(id, SEL, unsigned long long))gOriginalSetFinderMode)(self, _cmd, arg1);
		
		AddOptionsToFindBar(optionsCtrl, [self view]);
	}
}

static void overrideChangeFinderMode(id self, SEL _cmd, id arg1)
{
	// This never seems to get called...
	
	//NSLog(@"%s: self=%p _cmd=%p arg1=%p", __FUNCTION__, self, _cmd, arg1);
	
	((void (*)(id, SEL, id))gOriginalChangeFinderMode)(self, _cmd, arg1);
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    /* Override -(void)[DVTFindBar viewDidInstall] */
    gOriginalViewDidInstall = XCFixinOverrideMethodString(@"DVTFindBar", @selector(viewDidInstall), (IMP)&overrideViewDidInstall);
	XCFixinAssertOrPerform(gOriginalViewDidInstall, goto failed);
	
	gOriginalShowFindOptionsPopover = XCFixinOverrideMethodString(@"DVTFindBar", @selector(_showFindOptionsPopover:), (IMP)&overrideShowFindOptionsPopover);
	XCFixinAssertOrPerform(gOriginalShowFindOptionsPopover, goto failed);
	
	gOriginalSetFinderMode = XCFixinOverrideMethodString(@"DVTFindBar", @selector(setFinderMode:), (IMP)&overrideSetFinderMode);
	XCFixinAssertOrPerform(gOriginalShowFindOptionsPopover, goto failed);

	gOriginalChangeFinderMode = XCFixinOverrideMethodString(@"DVTFindBar", @selector(changeFinderMode:), (IMP)&overrideChangeFinderMode);
	XCFixinAssertOrPerform(gOriginalChangeFinderMode, goto failed);
    
    XCFixinPostflight();
}

@end