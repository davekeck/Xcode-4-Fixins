#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>
#import <objc/runtime.h>

#include <sys/stat.h>

#import "XCFixin.h"

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

// if true, extra verbose logging via NSLog.
#define VERBOSE_LOGGING 0

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

// if true, an extra test menu item for whatever I'm testing at the
// moment.
#define TEST_UI 0

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSString *GetObjectDescription(id obj)
{
	if(!obj)
		return @"nil";
	else
		return [NSString stringWithFormat:@"(%s *)%p: %@",class_getName([obj class]),obj,obj];
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

#if VERBOSE_LOGGING

static void Log(NSString *fmt,...)  NS_FORMAT_FUNCTION(1,2);

static void Log(NSString *fmt,...)
{
	va_list v;
	va_start(v,fmt);
	NSLogv(fmt,v);
	va_end(v);
}

#else//VERBOSE_LOGGING

#define Log(...) ((void)0)

#endif//VERBOSE_LOGGING

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSTextView *FindIDETextView(BOOL log)
{
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
	if(!mainWindow)
	{
		if(log)
			Log(@"Can't find IDE text view - no main window.\n");
		
		return nil;
	}
	
	Class DVTCompletingTextView=objc_getClass("DVTCompletingTextView");
	if(!DVTCompletingTextView)
	{
		if(log)
			Log(@"Can't find IDE text view - DVTCompletingTextView class unavailable.\n");
		
		return nil;
	}
	
	id textView=nil;
	
	for(NSResponder *responder=[mainWindow firstResponder];responder;responder=[responder nextResponder])
	{
		if([responder isKindOfClass:DVTCompletingTextView])
		{
			textView=responder;
			break;
		}
	}
	
	if(!textView)
	{
		if(log)
			Log(@"Can't find IDE text view - no DVTCompletingTextView in the responder chain.\n");
		
		return nil;
	}
	
	return textView;
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

enum ScriptReselectMode
{
	SRM_NONE,
	SRM_MARKER,
	SRM_ALL,
};
typedef enum ScriptReselectMode ScriptReselectMode;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

enum ScriptStdinMode
{
	SSM_NONE,
	SSM_SELECTION,
	SSM_LINETEXT_OR_SELECTION,
	SSM_LINE_OR_SELECTION,
};
typedef enum ScriptStdinMode ScriptStdinMode;

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

@interface XCFixin_Script:NSObject
{
	NSString *fileName_;
	ScriptStdinMode stdinMode_;
	ScriptReselectMode reselectMode_;
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation XCFixin_Script

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(id)initWithFileName:(NSString *)fileName
{
	if((self=[super init]))
	{
		fileName_=[fileName retain];
		stdinMode_=SSM_SELECTION;
		reselectMode_=SRM_MARKER;
	}
	
	return self;
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

-(void)setReselectMode:(ScriptReselectMode)reselectMode
{
	reselectMode_=reselectMode;
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

-(void)setStdinMode:(ScriptStdinMode)stdinMode
{
	stdinMode_=stdinMode;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSRange NSMakeRangeFromStartAndEnd(NSUInteger start,NSUInteger end)
{
	NSRange r;
	
	r.location=start;
	r.length=end-start;
	
	return r;
}

-(void)run
{
	Log(@"%s: path=%@\n",__FUNCTION__,fileName_);
	
	NSTextView *textView=FindIDETextView(YES);
	if(!textView)
	{
		Log(@"Not running scripts - can't find IDE text view.\n");
		return;
	}
	
	NSTextStorage *textStorage=[textView textStorage];
	if(!textStorage)
	{
		Log(@"Not running scripts - IDE text view has no text storage.\n");
		return;
	}
	
	NSArray *inputRanges=[textView selectedRanges];
	Log(@"%s: %zu selected ranges:\n",__FUNCTION__,(size_t)[inputRanges count]);
	for(NSUInteger i=0;i<[inputRanges count];++i)
		Log(@"    %zu. %@\n",(size_t)i,NSStringFromRange([[inputRanges objectAtIndex:i] rangeValue]));
	
	Log(@"%s: select range: %@\n",__FUNCTION__,NSStringFromRange([textView selectedRange]));
			  
	NSString *inputStr=nil;
	NSData *inputData=nil;
	NSRange inputRange=[textView selectedRange];
	{
		NSString *textStorageString=[textStorage string];
		
		switch(stdinMode_)
		{
			case SSM_LINETEXT_OR_SELECTION:
			case SSM_LINE_OR_SELECTION:
				if(inputRange.length==0)
				{
					NSUInteger startIndex,contentsEndIndex,endIndex;
					[textStorageString getLineStart:&startIndex
												end:&endIndex
										contentsEnd:&contentsEndIndex
										   forRange:inputRange];
					
					inputRange.location=startIndex;
					
					if(stdinMode_==SSM_LINE_OR_SELECTION)
						inputRange.length=endIndex-startIndex;
					else
						inputRange.length=contentsEndIndex-startIndex;
				}
				
				// fall through
			case SSM_SELECTION:
				inputStr=[textStorageString substringWithRange:inputRange];
				inputData=[inputStr dataUsingEncoding:NSUTF8StringEncoding];
				
				// fall through
			default:
				break;
		}
	}
	
	NSTask *task=[[[NSTask alloc] init] autorelease];
	
	[task setLaunchPath:fileName_];
	Log(@"%s: [task launchPath] = %@\n",__FUNCTION__,[task launchPath]);
	
	NSPipe *stdinPipe=[NSPipe pipe];
	NSPipe *stdoutPipe=[NSPipe pipe];
	NSPipe *stderrPipe=[NSPipe pipe];
	
	[task setStandardOutput:stdoutPipe];
	[task setStandardInput:stdinPipe];
	[task setStandardError:stderrPipe];
	
	NSData *stdoutData=nil;
	
	@try
	{
		Log(@"%s: launching task...\n",__FUNCTION__);
		[task launch];
		Log(@"%s: task launched.\n",__FUNCTION__);
		
		if(inputData)
		{
			@try
			{
				Log(@"%s: writing %zu bytes to task's stdin...\n",__FUNCTION__,(size_t)[inputData length]);
				[[stdinPipe fileHandleForWriting] writeData:inputData];
				Log(@"%s: wrote to task's stdin.\n",__FUNCTION__);
			}
			@catch(NSException *e)
			{
				// Maybe the task finished really quickly and it doesn't care what's in its stdin.
				Log(@"%s: ignoring error (%@) writing to task's stdin.\n",__FUNCTION__,e);
			}
		}
		
		[[stdinPipe fileHandleForWriting] closeFile];
		
		@try
		{
			Log(@"%s: reading from task's stdout...\n",__FUNCTION__);
			stdoutData=[[stdoutPipe fileHandleForReading] readDataToEndOfFile];
			Log(@"%s: read %zu bytes from task's stdout.\n",__FUNCTION__,(size_t)[stdoutData length]);
		}
		@catch(NSException *e)
		{
			Log(@"%s: error (%@) reading from task's stdout.\n",__FUNCTION__,e);
		}

		Log(@"%s: waiting for task exit...\n",__FUNCTION__);
		[task waitUntilExit];
		Log(@"%s: task exit.\n",__FUNCTION__);
		
		int exitCode=[task terminationStatus];
		
		if(exitCode!=0)
		{
			NSData *stderrData=nil;
			
			@try
			{
				Log(@"%s: reading from task's stderr...\n",__FUNCTION__);
				stderrData=[[stderrPipe fileHandleForReading] readDataToEndOfFile];
				Log(@"%s: read %zu bytes from task's stderr.\n",__FUNCTION__,(size_t)[stderrData length]);
			}
			@catch(NSException *e)
			{
				Log(@"%s: ignoring error (%@) reading from task's stderr.\n",__FUNCTION__,e);
				stderrData=nil;
			}
			
			NSString *alertBody=@"";
			if(stderrData)
			{
				alertBody=[[[NSString alloc] initWithData:stderrData
												 encoding:NSUTF8StringEncoding] autorelease];
			}
			
			NSUInteger maxLen=1000;
			if([alertBody length]>maxLen)
				alertBody=[[alertBody substringToIndex:maxLen] stringByAppendingString:[NSString stringWithFormat:@"\n\n(%u chars snipped)",(unsigned)([alertBody length]-maxLen)]];
			
			if([alertBody length]==0)
				alertBody=@"No error output was provided.";
			
			[[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Script failed - exit code %d",exitCode]
							 defaultButton:@"OK"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"%@",alertBody] runModal];
			return;
		}
	}
	@catch(NSException *e)
	{
		if([[e name] isEqualToString:@"NSInvalidArgumentException"])
		{
			[[NSAlert alertWithMessageText:@"Script launch failed"
							 defaultButton:@"OK"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"Failed to launch \"%@\".\n\nReason: %@.",[task launchPath],[e reason]] runModal];
			
			return;
		}
		else
			@throw e;
	}
	@finally
	{
	}
	
	if(stdoutData)
	{
		NSString *selectionMarker=@"%%\x25{PBXSelection}%%%";
		
		NSString *stdoutStr=[[[NSString alloc] initWithData:stdoutData
												   encoding:NSUTF8StringEncoding] autorelease];
		
		NSRange a;//before 1st marker
		NSRange b;//between 1st marker and 2nd marker (selection goes here)
		NSRange c;//after 2nd marker
		
		switch(reselectMode_)
		{
			case SRM_ALL:
			{
				a=NSMakeRange(0,0);
				b=NSMakeRange(0,[stdoutStr length]);
				c=NSMakeRange([stdoutStr length],0);
			}
				break;
				
			case SRM_MARKER:
			{
				NSRange r1=[stdoutStr rangeOfString:selectionMarker
											options:NSLiteralSearch
											  range:NSMakeRangeFromStartAndEnd(0,
																			   [stdoutStr length])];
				
				if(r1.location==NSNotFound)
				{
					// no selection anywhere
					a=NSMakeRangeFromStartAndEnd(0,
												 [stdoutStr length]);
					c=b=NSMakeRange([stdoutStr length],
									0);
				}
				else
				{
					a=NSMakeRangeFromStartAndEnd(0,
												 r1.location);
					
					NSRange r2=[stdoutStr rangeOfString:selectionMarker
												options:NSLiteralSearch
												  range:NSMakeRangeFromStartAndEnd(r1.location+[selectionMarker length],
																				   [stdoutStr length])];
					
					if(r2.location==NSNotFound)
					{
						b=NSMakeRange(r1.location+[selectionMarker length],
									  0);
						c=NSMakeRangeFromStartAndEnd(r1.location+[selectionMarker length],
													 [stdoutStr length]);
					}
					else
					{
						b=NSMakeRangeFromStartAndEnd(r1.location+[selectionMarker length],
													 r2.location);
						c=NSMakeRangeFromStartAndEnd(r2.location+[selectionMarker length],
													 [stdoutStr length]);
					}
				}
			}
				break;
				
			default:
			case SRM_NONE:
			{
				a=NSMakeRange(0,[stdoutStr length]);
				b=NSMakeRange([stdoutStr length],0);
				c=NSMakeRange([stdoutStr length],0);
			}
				break;
		}
		
		
		stdoutStr=[[[stdoutStr substringWithRange:a] stringByAppendingString:[stdoutStr substringWithRange:b]] stringByAppendingString:[stdoutStr substringWithRange:c]];
		
		[textView breakUndoCoalescing];
		
		// don't insert text if the two strings are actually the same.
		//
		// this is a fix for scripts that just pop a %%%{PBXSeleciton}%%%
		// into their input to put the cursor somewhere.
		if(![stdoutStr isEqualToString:inputStr])
		{
			[textView insertText:stdoutStr
				replacementRange:inputRange];
		}
		
		[textView setSelectedRange:NSMakeRange(inputRange.location+a.length,
											   b.length)];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(void)dealloc
{
	Log(@"%s: (%s *)%p: %@\n",__FUNCTION__,class_getName([self class]),self,fileName_);
	
	[fileName_ release];
	fileName_=nil;
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface XCFixin_ScriptsHandler:NSObject
{
#if TEST_UI
	NSMenuItem *testUIMenuItem_;
#endif//TEST_UI
	NSMenuItem *refreshMenuItem_;
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation XCFixin_ScriptsHandler

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSString *SystemFolderName(int folderType,int domain)
{
	OSErr err;
	
	FSRef folder;
	err=FSFindFolder(domain,folderType,kCreateFolder,&folder);
	if(err!=noErr)
		return nil;
	
	CFURLRef url=CFURLCreateFromFSRef(kCFAllocatorDefault,&folder);
	NSString *result=[(NSURL *)url path];
	CFRelease(url);
	
	return result;
}

-(void)refreshScriptsMenu
{
	NSMenu *mainMenu=[NSApp mainMenu];
	if(!mainMenu)
	{
		Log(@"%s: main menu not found.\n",__FUNCTION__);
		return;
	}
	
	int scriptsMenuIndex=[mainMenu indexOfItemWithTitle:@"Scripts"];
	if(scriptsMenuIndex<0)
	{
		Log(@"%s: Scripts menu not found.\n",__FUNCTION__);
		return;
	}
	
	NSMenu *scriptsMenu=[[mainMenu itemAtIndex:scriptsMenuIndex] submenu];
	
	//
	[scriptsMenu removeAllItems];
	
	NSString *appSupportFolderName=SystemFolderName(kApplicationSupportFolderType,kUserDomain);
	Log(@"appSupportFolderName=%@\n",appSupportFolderName);
	
	NSString *scriptsFolderName=[NSString pathWithComponents:[NSArray arrayWithObjects:appSupportFolderName,@"Developer/Shared/Xcode/Scripts",nil]];
	Log(@"scriptsFolderName=%@\n",scriptsFolderName);
	
	NSString *scriptsPListName=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,@"Scripts.xml",nil]];
	Log(@"scriptsPListName=%@\n",scriptsPListName);
	NSDictionary *scriptsProperties=[NSDictionary dictionaryWithContentsOfFile:scriptsPListName];
	if(!scriptsProperties)
		Log(@"%s: No scripts plist loaded.\n",__FUNCTION__);
	else
		Log(@"%s: Scripts plist: %@\n",__FUNCTION__,scriptsProperties);

	NSArray *scriptsFolderContents=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:scriptsFolderName
																					   error:nil];
	if([scriptsFolderContents count]>0)
	{
		NSMutableArray *scripts=[NSMutableArray arrayWithCapacity:0];
		
		NSFileManager *defaultManager=[NSFileManager defaultManager];
		
		for(NSUInteger i=0;i<[scriptsFolderContents count];++i)
		{
			NSString *name=[scriptsFolderContents objectAtIndex:i];
			NSString *path=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,name,nil]];
			
			struct stat st;
			if(stat([path UTF8String],&st)!=0)
			{
				Log(@"%@: not a script (stat failed)\n",path);
				continue;
			}
			
			if(!(st.st_mode&(S_IFLNK|S_IFREG)))
			{
				Log(@"%@: not a script (not symlink or regular file)\n",path);
				continue;
			}
			
			if(![defaultManager isExecutableFileAtPath:path])
			{
				Log(@"%@: not a script (not executable)\n",path);
				continue;
			}
			
			[scripts addObject:name];
		}
		
		if([scripts count]>0)
		{
			for(NSUInteger scriptIdx=0;scriptIdx<[scripts count];++scriptIdx)
			{
				NSString *name=[scripts objectAtIndex:scriptIdx];
				NSString *path=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,name,nil]];
				
				Log(@"Creating XCFixin_Script for %@.\n",path);
				XCFixin_Script *script=[[[XCFixin_Script alloc] initWithFileName:path] autorelease];
				
				NSMenuItem *scriptMenuItem=[[[NSMenuItem alloc] initWithTitle:name
																	   action:nil
																keyEquivalent:@""] autorelease];
				[scriptMenuItem setTarget:self];
				[scriptMenuItem setAction:@selector(runScriptAction:)];
				[scriptMenuItem setRepresentedObject:script];
				
				NSDictionary *scriptProperties=[scriptsProperties objectForKey:name];
				if(![scriptProperties isKindOfClass:[NSDictionary class]])
					scriptProperties=nil;
				
				Log(@"    Script properties: %@\n",scriptProperties);

				NSString *keyEquivalent=[scriptProperties objectForKey:@"keyEquivalent"];
				if(keyEquivalent&&[keyEquivalent length]>0)
				{
					// Yeah, OK, so I just completely could NOT work out how you're supposed to
					// do this officially. So you have to use emacs notation.
					//
					// C- = control
					// M- = Alt/Option ("Meta")
					// S- = Shift
					// s- = Command ("super")
					
					unsigned modifiers=0;
					
					for(NSUInteger i=0;i+1<[keyEquivalent length];i+=2)
					{
						char c=[keyEquivalent characterAtIndex:i];
						
						switch(c)
						{
							case 'C':
								modifiers|=NSControlKeyMask;
								break;
								
							case 'M':
								modifiers|=NSAlternateKeyMask;
								break;
								
							case 'S':
								modifiers|=NSShiftKeyMask;
								break;
								
							case 's':
								modifiers|=NSCommandKeyMask;
								break;
								
							default:
								// some kind of error here, or something??
								//
								// not like it's hard to spot or complicated to fix...
								break;
						}
					}
					
					[scriptMenuItem setKeyEquivalent:[keyEquivalent substringFromIndex:[keyEquivalent length]-1]];
					[scriptMenuItem setKeyEquivalentModifierMask:modifiers];
				}
				
				NSString *stdinMode=[scriptProperties objectForKey:@"stdinMode"];
				if(stdinMode)
				{
					if([stdinMode caseInsensitiveCompare:@"none"]==NSOrderedSame)
						[script setStdinMode:SSM_NONE];
					else if([stdinMode caseInsensitiveCompare:@"selection"]==NSOrderedSame)
						[script setStdinMode:SSM_SELECTION];
					else if([stdinMode caseInsensitiveCompare:@"lineorselection"]==NSOrderedSame)
						[script setStdinMode:SSM_LINE_OR_SELECTION];
					else if([stdinMode caseInsensitiveCompare:@"linetextorselection"]==NSOrderedSame)
						[script setStdinMode:SSM_LINETEXT_OR_SELECTION];
				}
				
				NSString *reselectMode=[scriptProperties objectForKey:@"reselectMode"];
				if(reselectMode)
				{
					if([reselectMode caseInsensitiveCompare:@"none"]==NSOrderedSame)
						[script setReselectMode:SRM_NONE];
					else if([reselectMode caseInsensitiveCompare:@"marker"]==NSOrderedSame)
						[script setReselectMode:SRM_MARKER];
					else if([reselectMode caseInsensitiveCompare:@"all"]==NSOrderedSame)
						[script setReselectMode:SRM_ALL];
				}
				
				[scriptsMenu addItem:scriptMenuItem];
			}
		}
		
		if([scriptsMenu numberOfItems]>0)
			[scriptsMenu addItem:[NSMenuItem separatorItem]];
	}

#if TEST_UI
	testUIMenuItem_=[scriptsMenu addItemWithTitle:@"Test Item"
										   action:@selector(testUIAction:)
									keyEquivalent:@""];
	[testUIMenuItem_ setTarget:self];
#endif//TEST_UI
	
	refreshMenuItem_=[scriptsMenu addItemWithTitle:@"Refresh"
											 action:@selector(refreshScriptsMenuAction:)
									 keyEquivalent:@""];
	[refreshMenuItem_ setTarget:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(IBAction)runScriptAction:(id)arg
{
	[[arg representedObject] run];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#if TEST_UI
-(IBAction)testUIAction:(id)arg
{
	NSAlert *alert=[NSAlert alertWithMessageText:@"UI Test Text"
								   defaultButton:@"OK"
								 alternateButton:nil
									 otherButton:nil
					   informativeTextWithFormat:@"UI Test Body (%p)",self];
	int x=[alert runModal];
	Log(@"%s: result: %d\n",__FUNCTION__,x);
}
#endif//TEST_UI

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

-(IBAction)refreshScriptsMenuAction:(id)arg
{
	[self refreshScriptsMenu];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(BOOL)install
{
	NSMenu *mainMenu=[NSApp mainMenu];
	if(!mainMenu)
	{
		Log(@"%s: main menu not found!\n",__FUNCTION__);
		return NO;
	}
	
	NSInteger menuIndex=[mainMenu indexOfItemWithTitle:@"Window"];
	if(menuIndex<0)
		menuIndex=[mainMenu numberOfItems];
	
	NSMenuItem *scriptsMenuItem=[mainMenu insertItemWithTitle:@"Scripts"
													   action:NULL
												keyEquivalent:@""
													  atIndex:menuIndex];
	[scriptsMenuItem setEnabled:YES];
	
	NSMenu *scriptsMenu=[[[NSMenu alloc] initWithTitle:@"Scripts"] autorelease];
	[scriptsMenu setAutoenablesItems:YES];
	
	[scriptsMenuItem setSubmenu:scriptsMenu];
	
	[self refreshScriptsMenu];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem==refreshMenuItem_)
	{
		// `Refresh' is always enabled.
		return YES;
	}
	
	if(FindIDETextView(NO))
	{
		// Script items are enabled if the focus is on a text editor.
		return YES;
	}
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static BOOL GetClasses(const char *name0,...)
{
	va_list v;
	va_start(v,name0);
	
	for(const char *name=name0;name;name=va_arg(v,const char *))
	{
		Class *c=va_arg(v,Class *);
		
		*c=objc_getClass(name);
		if(!*c)
		{
			Log(@"FATAL: class %s not found.\n",name);
			return NO;
		}
	}
	
	return YES;
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface XCFixin_UserScripts : NSObject
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation XCFixin_UserScripts

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
	XCFixin_ScriptsHandler *handler=[[XCFixin_ScriptsHandler alloc] init];
	if(!handler)
		Log(@"%s: handler init failed.\n",__FUNCTION__);
	else
	{
		BOOL goodInstall=[handler install];
		(void)goodInstall;
		Log(@"%s: handler installed: %s\n",__FUNCTION__,goodInstall?"YES":"NO");
	}
    
    XCFixinPostflight();
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@end
