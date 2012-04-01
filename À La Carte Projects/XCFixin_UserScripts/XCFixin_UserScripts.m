#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/objc-runtime.h>

#include <sys/stat.h>

#import "XCFixin.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSString *GetObjectDescription(id obj)
{
	if(!obj)
		return @"nil";
	else
		return [NSString stringWithFormat:@"(%s *)%p: %@",class_getName([obj class]),obj,obj];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSTextView *FindIDETextView(void)
{
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
	if(!mainWindow)
	{
		NSLog(@"Can't find IDE text view - no main window.\n");
		return nil;
	}
	
	if(![mainWindow isKindOfClass:objc_getClass("IDEWorkspaceWindow")])
	{
		NSLog(@"Can't find IDE text view - main window is class %@.\n",[mainWindow class]);
		return nil;
	}
	
	id windowController=objc_msgSend(objc_getClass("IDEWorkspaceWindowController"),
									 @selector(workspaceWindowControllerForWindow:),
									 (id)mainWindow);
	//NSLog(@"%s: wc=%p (%s)\n",__FUNCTION__,wc,class_getName([wc class]));
	if(!windowController)
	{
		NSLog(@"Can't find IDE text view - no window controller.\n");
		return nil;
	}
	
	id tabController=objc_msgSend(windowController,@selector(activeWorkspaceTabController));
	//NSLog(@"%s: tc=%p (%s)\n",__FUNCTION__,tc,class_getName([tc class]));
	if(!tabController)
	{
		NSLog(@"Can't find IDE text view - no tab controller.\n");
		return nil;
	}
	
	id editorArea=objc_msgSend(tabController,@selector(editorArea));
	//NSLog(@"%s: ea=%p (%s)\n",__FUNCTION__,editorArea,class_getName([ea class]));
	if(!editorArea)
	{
		NSLog(@"Can't find IDE text view - no editor area.\n");
		return nil;
	}
	
	id primaryEditorContext=objc_msgSend(editorArea,@selector(primaryEditorContext));
	if(!primaryEditorContext)
	{
		NSLog(@"Can't find IDE text view - no primary editor context.\n");
		return nil;
	}
	
	if(![primaryEditorContext isKindOfClass:objc_getClass("IDEEditorContext")])
	{
		NSLog(@"Can't find IDE text view - primary editor context is class %@.\n",[mainWindow class]);
		return nil;
	}
	
	id editor=objc_msgSend(primaryEditorContext,@selector(editor));
	if(!editor)
	{
		NSLog(@"Can't find IDE text view - no primary editor context editor.\n");
		return nil;
	}
	
	if([editor isKindOfClass:objc_getClass("IDESourceCodeEditor")])
	{
		id textView=objc_msgSend(editor,@selector(textView));
		if(!textView)
		{
			NSLog(@"Can't find IDE text view - primary editor context's IDESourceCodeEditor editor has nil text view.\n");
			return nil;
		}
		
		return textView;
	}
	else if([editor isKindOfClass:objc_getClass("IDEComparisonEditor")])
	{
		id keyEditor=objc_msgSend(editor,@selector(keyEditor));
		if(!keyEditor)
		{
			NSLog(@"Can't find IDE text view - primary editor context's IDEComparisonEditor has nil keyEditor.\n");
			return nil;
		}

		if(![keyEditor isKindOfClass:objc_getClass("IDESourceCodeEditor")])
		{
			NSLog(@"Can't find IDE text view - primary editor context's IDEComparisonEditor keyEditor is class %@.\n",[keyEditor class]);
			return nil;
		}
		
		id textView=objc_msgSend(keyEditor,@selector(textView));
		if(!textView)
		{
			NSLog(@"Can't find IDE text view - primary editor context's IDEComparisonEditor IDESourceCodeEditor keyEditor has nil text view.\n");
			return nil;
		}

		return textView;
	}
	else
	{
		NSLog(@"Can't find IDE text view - primary editor context's editor is unsupported class %@.\n",[editor class]);
		return nil;
	}
	
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface XCFixin_Script:NSObject
{
	NSString *fileName_;
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
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(NSString *)fileName
{
	return fileName_;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(void)run
{
	NSLog(@"%s: path=%@\n",__FUNCTION__,fileName_);
	
	NSTextView *textView=FindIDETextView();
	if(!textView)
	{
		NSLog(@"Not running scripts - can't find IDE text view.\n");
		return;
	}
	
	NSTextStorage *textStorage=[textView textStorage];
	if(!textStorage)
	{
		NSLog(@"Not running scripts - IDE text view has no text storage.\n");
		return;
	}
	
	NSRange selectionRange=[textView selectedRange];
	NSString *selectionStr=[[textStorage string] substringWithRange:selectionRange];
	NSData *selectionData=[selectionStr dataUsingEncoding:NSUTF8StringEncoding];
	
	NSData *outputData=nil;
	
	NSTask *task=[[[NSTask alloc] init] autorelease];
	
	[task setLaunchPath:fileName_];
	NSLog(@"%s: [task launchPath] = %@\n",__FUNCTION__,[task launchPath]);
	
	NSPipe *stdinPipe=[NSPipe pipe];
	NSPipe *stdoutPipe=[NSPipe pipe];
	NSPipe *stderrPipe=[NSPipe pipe];
	
	[task setStandardOutput:stdoutPipe];
	[task setStandardInput:stdinPipe];
	[task setStandardError:stderrPipe];
	
	int exitCode=0;
	
	@try
	{
		NSLog(@"%s: launching task...\n",__FUNCTION__);
		[task launch];
		NSLog(@"%s: task launched.\n",__FUNCTION__);
		
		NSLog(@"%s: writing %u bytes to task's stdin...\n",__FUNCTION__,[selectionData length]);
		[[stdinPipe fileHandleForWriting] writeData:selectionData];
		[[stdinPipe fileHandleForWriting] closeFile];
		NSLog(@"%s: wrote to task's stdin.\n",__FUNCTION__);
		
		NSLog(@"%s: reading from task's stdout...\n",__FUNCTION__);
		outputData=[[stdoutPipe fileHandleForReading] readDataToEndOfFile];
		NSLog(@"%s: read %u bytes from task's stdout.\n",__FUNCTION__,[outputData length]);
		
		NSLog(@"%s: waiting for task exit...\n",__FUNCTION__);
		[task waitUntilExit];
		NSLog(@"%s: task exit.\n",__FUNCTION__);
		
		exitCode=[task terminationStatus];
		if(exitCode!=0)
			NSLog(@"Script failed - exit code %d.\n",exitCode);
	}
	@catch(NSException *e)
	{
		if([[e name] isEqualToString:@"NSInvalidArgumentException"])
		{
			exitCode=-1;
		
			NSLog(@"Script launch failed.\n");
		}
		else
			@throw e;
	}
	@finally
	{
	}
	
	if(exitCode!=0)
		outputData=nil;
	
	if(outputData)
	{
		NSString *outputStr=[[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
		[textView breakUndoCoalescing];
		[textView insertText:outputStr replacementRange:selectionRange];
	}
	
//	NSLog(@"%s: script run, all done.\n",__FUNCTION__);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(void)dealloc
{
	NSLog(@"%s: (%s *)%p: %@\n",__FUNCTION__,class_getName([self class]),self,fileName_);
	
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

// Yeah, OK, so I just completely could NOT work out how you're supposed to
// do this officially. So you have to use emacs notation.
//
// C- = control
// M- = Alt/Option ("Meta")
// S- = Shift
// s- = Command ("super")
//
static void SetKeyEquivalentFromString(NSMenuItem *item,NSString *str)
{
	if(!str||[str length]==0)
		return;
	
	unsigned modifiers=0;
	
	for(NSUInteger i=0;i+1<[str length];i+=2)
	{
		char c=[str characterAtIndex:i];
		
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
	
	[item setKeyEquivalent:[str substringFromIndex:[str length]-1]];
	[item setKeyEquivalentModifierMask:modifiers];
}

-(void)refreshScriptsMenu
{
	NSMenu *mainMenu=[NSApp mainMenu];
	if(!mainMenu)
	{
		NSLog(@"%s: main menu not found.\n",__FUNCTION__);
		return;
	}
	
	int scriptsMenuIndex=[mainMenu indexOfItemWithTitle:@"Scripts"];
	if(scriptsMenuIndex<0)
	{
		NSLog(@"%s: Scripts menu not found.\n",__FUNCTION__);
		return;
	}
	
	NSMenu *scriptsMenu=[[mainMenu itemAtIndex:scriptsMenuIndex] submenu];
	
	//
	[scriptsMenu removeAllItems];
	
	NSString *appSupportFolderName=SystemFolderName(kApplicationSupportFolderType,kUserDomain);
	NSLog(@"appSupportFolderName=%@\n",appSupportFolderName);
	
	NSString *scriptsFolderName=[NSString pathWithComponents:[NSArray arrayWithObjects:appSupportFolderName,@"Developer/Shared/Xcode/Scripts",nil]];
	NSLog(@"scriptsFolderName=%@\n",scriptsFolderName);
	
	NSString *scriptsPListName=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,@"Scripts.xml",nil]];
	NSLog(@"scriptsPListName=%@\n",scriptsPListName);
	NSDictionary *scriptsProperties=[NSDictionary dictionaryWithContentsOfFile:scriptsPListName];
	if(!scriptsProperties)
		NSLog(@"%s: No scripts plist loaded.\n",__FUNCTION__);
	else
		NSLog(@"%s: Scripts plist: %@\n",__FUNCTION__,scriptsProperties);

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
				NSLog(@"%@: not a script (stat failed)\n",path);
				continue;
			}
			
			if(!(st.st_mode&(S_IFLNK|S_IFREG)))
			{
				NSLog(@"%@: not a script (not symlink or regular file)\n",path);
				continue;
			}
			
			if(![defaultManager isExecutableFileAtPath:path])
			{
				NSLog(@"%@: not a script (not executable)\n",path);
				continue;
			}
			
			[scripts addObject:name];
		}
		
		if([scripts count]>0)
		{
			for(NSUInteger i=0;i<[scripts count];++i)
			{
				NSString *name=[scripts objectAtIndex:i];
				NSString *path=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,name,nil]];
				
				NSLog(@"Creating XCFixin_Script for %@.\n",path);
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
				
				NSLog(@"    Script properties: %@\n",scriptProperties);
				
				SetKeyEquivalentFromString(scriptMenuItem,[scriptProperties objectForKey:@"keyEquivalent"]);
				
				[scriptsMenu addItem:scriptMenuItem];
			}
		}
		
		if([scriptsMenu numberOfItems]>0)
			[scriptsMenu addItem:[NSMenuItem separatorItem]];
		
		[[scriptsMenu addItemWithTitle:@"Refresh"
								action:@selector(refreshScriptsMenuAction:)
						 keyEquivalent:@""] setTarget:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(IBAction)runScriptAction:(id)arg
{
	[[arg representedObject] run];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

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
		NSLog(@"%s: main menu not found!\n",__FUNCTION__);
		return NO;
	}
	
	NSInteger helpIndex=[mainMenu indexOfItemWithTitle:@"Help"];
	if(helpIndex<0)
		helpIndex=[mainMenu numberOfItems];
	
	NSMenuItem *scriptsMenuItem=[mainMenu insertItemWithTitle:@"Scripts"
													   action:NULL
												keyEquivalent:@""
													  atIndex:helpIndex];
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
	NSLog(@"%s: title=\"%@\"\n",__FUNCTION__,[menuItem title]);
	return YES;
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
			NSLog(@"FATAL: class %s not found.\n",name);
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
		NSLog(@"%s: handler init failed.\n",__FUNCTION__);
	else
	{
		BOOL goodInstall=[handler install];
		NSLog(@"%s: handler installed: %s\n",__FUNCTION__,goodInstall?"YES":"NO");
	}
    
    XCFixinPostflight();
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@end
