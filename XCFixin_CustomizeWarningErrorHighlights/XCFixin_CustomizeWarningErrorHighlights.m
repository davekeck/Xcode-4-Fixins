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
static DVTTextAnnotationTheme * debuggerTheme;
static DVTTextAnnotationTheme * grayTheme;


@implementation XCFixin_CustomizeWarningErrorHighlights

static void overridenewMessageAttributesForFont(id self, SEL _cmd, DVTTextAnnotationTheme* arg1, id arg2){
	
	const char* className = class_getName([self class]);	
	DVTTextAnnotationTheme * newTheme  = arg1;
	
	if ( strcmp(className, "IDEBuildIssueStaticAnalyzerResultAnnotation") == 0 ||
		 strcmp(className, "IDEBuildIssueStaticAnalyzerEventStepAnnotation") == 0 ){	// apply our own theme for Warning Messages	
		newTheme = analyzerTheme;
	}else
	
	if (  strcmp(className, "IDEDiagnosticWarningAnnotation") == 0 ||
		strcmp(className, "IDEBuildIssueWarningAnnotation") == 0 ){	// apply our own theme for Warning Messages	
		newTheme = warningTheme;
	}else

	if (  strcmp(className, "IDEDiagnosticErrorAnnotation") == 0 ||
		strcmp(className, "IDEBuildIssueErrorAnnotation") == 0  ){		// apply our own theme for Error Messages	
		newTheme = errorTheme;
	}else

	if (  strcmp(className, "DBGInstructionPointerAnnotation") == 0 ){	// apply our own theme for debugging annotations	
		newTheme = debuggerTheme;
	}else

	if (  strcmp(className, "IDEBuildIssueNoticeAnnotation") == 0 ){	// apply our own theme for Build Issue Notice annotations	
		newTheme = grayTheme;
	}else
	
	if (  strcmp(className, "IBAnnotation") == 0 || strcmp(className, "DBGBreakpointAnnotation") == 0 ){	
		// nothing to be done here... those anotations are only for the sidebar, so no overlay applied
		//on top of the source code for those ones
	}else{
		/// what the heck is it then?
		NSLog(@">>> %s\n", className);
	}

    ((void (*)(id, SEL, DVTTextAnnotationTheme*, id))gOriginalnewMessageAttributesForFont)(self, _cmd , newTheme, arg2);
}



+ (void)pluginDidLoad: (NSBundle *)plugin{
	
    XCFixinPreflight();
	float lineAlpha = 0.20;	//whole line
	float topAlpha = 0.4;	//the right-hand label
	float bottomAlpha = 0.4;

	//define gradient for warning text highlight
	NSColor * warningColor = [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha: lineAlpha];
	NSGradient * gWarning = [[NSGradient alloc] initWithStartingColor: [warningColor colorWithAlphaComponent: topAlpha]
														  endingColor: [warningColor colorWithAlphaComponent: bottomAlpha]];
	//define warning text highlight theme
	warningTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: warningColor 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor clearColor] 
									 messageBubbleGradient: gWarning
												caretColor: [NSColor yellowColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gWarning release];
	
	
	//define gradient for error text highlight
	NSColor * errorColor = [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha: lineAlpha];
	NSGradient * gError = [[NSGradient alloc] initWithStartingColor: [errorColor colorWithAlphaComponent: topAlpha]
														endingColor: [errorColor colorWithAlphaComponent: bottomAlpha]];
	//define error text highlight theme
	errorTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: errorColor 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor clearColor] 
									 messageBubbleGradient: gError
												caretColor: [NSColor redColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	];
	[gError release];
	

	//define gradient for static Analyzer text highlight
	NSColor * analyzerColor = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:1 alpha: lineAlpha];
	NSGradient * gAnalyzer = [[NSGradient alloc] initWithStartingColor: [analyzerColor colorWithAlphaComponent: topAlpha]
														   endingColor: [analyzerColor colorWithAlphaComponent: bottomAlpha]];
	//define static Analyzer text highlight theme
	analyzerTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: analyzerColor 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor clearColor] 
									 messageBubbleGradient: gAnalyzer
												caretColor: [NSColor blueColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gAnalyzer release];

	
	//define gradient for debugger text highlight
	NSColor * debuggerColor = [NSColor colorWithDeviceRed:0.0 green:1 blue:0.5 alpha: lineAlpha];
	NSGradient * gDebugger = [[NSGradient alloc] initWithStartingColor: [debuggerColor colorWithAlphaComponent: topAlpha]
														   endingColor: [debuggerColor colorWithAlphaComponent: bottomAlpha]];
	//define static debugger text highlight theme
	debuggerTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: debuggerColor 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor clearColor] 
									 messageBubbleGradient: gDebugger
												caretColor: [NSColor greenColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gDebugger release];
	

	//define gradient for Notice text highlight
	NSColor * noticeColor = [NSColor colorWithDeviceRed:0.25 green:0.25 blue:0.25 alpha: lineAlpha];
	NSGradient * gNotice = [[NSGradient alloc] initWithStartingColor: [noticeColor colorWithAlphaComponent: topAlpha]
														 endingColor: [noticeColor colorWithAlphaComponent: bottomAlpha]];
	//define Notice text highlight theme
	grayTheme = 
	[[DVTTextAnnotationTheme alloc] initWithHighlightColor: noticeColor 
											borderTopColor: [NSColor clearColor]
										 borderBottomColor: [NSColor clearColor]
										   overlayGradient: nil
								  messageBubbleBorderColor: [NSColor clearColor] 
									 messageBubbleGradient: gNotice
												caretColor: [NSColor grayColor]  
							   highlightedRangeBorderColor: [NSColor clearColor] 
	 ];
	[gNotice release];

	gOriginalnewMessageAttributesForFont = XCFixinOverrideMethodString(@"DVTTextAnnotation", @selector(setTheme:forState:), (IMP)&overridenewMessageAttributesForFont);
		XCFixinAssertOrPerform(gOriginalnewMessageAttributesForFont, goto failed);
    XCFixinPostflight();
}

@end