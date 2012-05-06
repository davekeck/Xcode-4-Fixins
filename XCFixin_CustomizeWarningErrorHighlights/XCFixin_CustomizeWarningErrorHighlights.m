#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "XCFixin.h"


static IMP gOriginalnewMessageAttributesForFont = nil;


@interface DVTTextAnnotationTheme : NSObject{}
- (id)initWithHighlightColor:(id)arg1 borderTopColor:(id)arg2 borderBottomColor:(id)arg3 overlayGradient:(id)arg4 messageBubbleBorderColor:(id)arg5 messageBubbleGradient:(id)arg6 caretColor:(id)arg7 highlightedRangeBorderColor:(id)arg8;
@end


@interface XCFixin_CustomizeWarningErrorHighlights : NSObject{
}

@end

static DVTTextAnnotationTheme * warningTheme;
static DVTTextAnnotationTheme * errorTheme;
static DVTTextAnnotationTheme * analyzerTheme;


@implementation XCFixin_CustomizeWarningErrorHighlights

static void overridenewMessageAttributesForFont(id self, SEL _cmd, DVTTextAnnotationTheme* arg1, id arg2){

	const char* className = class_getName([self class]);	
	DVTTextAnnotationTheme * newTheme  = arg1;
	
	if (  strcmp(className, "IDEBuildIssueStaticAnalyzerResultAnnotation") == 0 ){	// apply our own theme for Warning Messages	
		newTheme = analyzerTheme;
	}
	
	if (  strcmp(className, "IDEDiagnosticWarningAnnotation") == 0 ){	// apply our own theme for Warning Messages	
		newTheme = warningTheme;
	}

	if (  strcmp(className, "IDEDiagnosticErrorAnnotation") == 0 ){		// apply our own theme for Error Messages	
		newTheme = errorTheme;
	}

    ((void (*)(id, SEL, DVTTextAnnotationTheme*, id))gOriginalnewMessageAttributesForFont)(self, _cmd , newTheme, arg2);
}



+ (void)pluginDidLoad: (NSBundle *)plugin{
	
    XCFixinPreflight();

	//define gradient for warning text highlight
	NSGradient * gWarning = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:0.5]
												   endingColor: [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:0.5]];
	
	//define warning text highlight theme
	warningTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:0.2] 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:0.3] 
									 messageBubbleGradient: gWarning
												caretColor: [NSColor yellowColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gWarning release];
	
	//define gradient for error text highlight
	NSGradient * gError = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.5]
												   endingColor: [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.5]];
	
	//define error text highlight theme
	errorTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.2] 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.3] 
									 messageBubbleGradient: gError
												caretColor: [NSColor redColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	];
	[gError release];

	//define gradient for static Analyzer text highlight
	NSGradient * gAnalyzer = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:0.8 green:0.8 blue:1 alpha:0.5]
														endingColor: [NSColor colorWithDeviceRed:0.8 green:0.8 blue:1 alpha:0.5]];
	
	//define static Analyzer text highlight theme
	analyzerTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: [NSColor colorWithDeviceRed:0.8 green:0.8 blue:1 alpha:0.2] 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor colorWithDeviceRed:0.8 green:0.8 blue:1 alpha:0.3] 
									 messageBubbleGradient: gAnalyzer
												caretColor: [NSColor blueColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gAnalyzer release];

	gOriginalnewMessageAttributesForFont = XCFixinOverrideMethodString(@"DVTTextAnnotation", @selector(setTheme:forState:), (IMP)&overridenewMessageAttributesForFont);
		XCFixinAssertOrPerform(gOriginalnewMessageAttributesForFont, goto failed);
    XCFixinPostflight();
}

@end