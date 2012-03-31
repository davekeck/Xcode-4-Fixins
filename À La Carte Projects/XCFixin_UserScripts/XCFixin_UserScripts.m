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

static BOOL IsRightClass(id obj,const char *what,const char *wantedClassName)
{
	Class wantedClass=objc_getClass(wantedClassName);
	
	for(Class c=[obj class];c;c=class_getSuperclass(c))
	{
		if(c==wantedClass)
			return YES;
	}
	
	if(what)
		NSLog(@"FATAL: %s is %s; must be %s.\n",what,class_getName([obj class]),class_getName(wantedClass));
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static NSMenuItem *TestAdd(NSMenu *menu,NSString *title,id target,SEL sel)
{
	NSMenuItem *item=[menu addItemWithTitle:title action:NULL keyEquivalent:@""];
	
	[item setTarget:target];
	[item setAction:sel];
	[item setEnabled:YES];
	
	NSLog(@"%s: added %@ to menu %@.\n",__FUNCTION__,[item title],[menu title]);
	
	return item;
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
	
	if(!IsRightClass(mainWindow,"main window","IDEWorkspaceWindow"))
		return nil;
	
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
	
	id primaryEditorDocument=objc_msgSend(editorArea,@selector(primaryEditorDocument));
	//NSLog(@"%s: ped=%p (%s)\n",__FUNCTION__,ped,class_getName([ped class]));
	if(!primaryEditorDocument)
	{
		NSLog(@"Can't find IDE text view - no primary editor document.\n");
		return nil;
	}
	
	if(!IsRightClass(primaryEditorDocument,"primary editor document","IDESourceCodeDocument"))
		return nil;
	
	NSMutableSet *documentEditors=(NSMutableSet *)objc_msgSend(primaryEditorDocument,@selector(_documentEditors));
	if(!documentEditors)
	{
		NSLog(@"Can't find IDE text view - no documentEditors.\n");
		return nil;
	}
	
	id textView=nil;
	for(id documentEditor in documentEditors)
	{
		if(IsRightClass(documentEditor,NULL,"IDEViewController"))
		{
			if(!textView)
				textView=objc_msgSend(documentEditor,@selector(textView));
			else
			{
				NSLog(@"Can't find IDE text view - multiple IDEViewControllers for the document.\n");
				return nil;
			}
		}
	}
	
	if(!textView)
	{
		NSLog(@"Can't find IDE text view - no IDEViewController for the document.\n");
		return nil;
	}
	
	return textView;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface XCFixin_ScriptsHandler:NSObject

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation XCFixin_ScriptsHandler

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static BOOL FindNextSeparator(NSMenu *menu,NSUInteger startIndex,NSUInteger *separatorIndex)
{
	for(NSUInteger i=startIndex;i<[menu numberOfItems];++i)
	{
		if([[menu itemAtIndex:i] isSeparatorItem])
		{
			*separatorIndex=i;
			return YES;
		}
	}
	
	return NO;
}

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
	
	NSUInteger firstSep;
	if(!FindNextSeparator(scriptsMenu,0,&firstSep))
	{
		NSLog(@"%s: Scripts menu separator not found.\n",__FUNCTION__);
		return;
	}
	
	NSUInteger secondSep;
	if(FindNextSeparator(scriptsMenu,firstSep+1,&secondSep))
	{
		while(secondSep!=firstSep)
			[scriptsMenu removeItemAtIndex:secondSep--];
	}
	
	NSString *appSupportFolderName=SystemFolderName(kApplicationSupportFolderType,kUserDomain);
	NSLog(@"appSupportFolderName=%@\n",appSupportFolderName);
	
	NSString *scriptsFolderName=[NSString pathWithComponents:[NSArray arrayWithObjects:appSupportFolderName,@"Developer",@"Shared",@"Xcode",@"Scripts",nil]];
	NSLog(@"scriptsFolderName=%@\n",scriptsFolderName);
	
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
			[scriptsMenu insertItem:[NSMenuItem separatorItem]
							atIndex:firstSep+1];
			
			for(NSUInteger i=0;i<[scripts count];++i)
			{
				NSString *name=[scripts objectAtIndex:i];
				NSString *path=[NSString pathWithComponents:[NSArray arrayWithObjects:scriptsFolderName,name,nil]];
				
				NSMenuItem *scriptMenuItem=[[[NSMenuItem alloc] initWithTitle:name
																	   action:nil
																keyEquivalent:@""] autorelease];
				[scriptMenuItem setTarget:self];
				[scriptMenuItem setAction:@selector(runScriptAction:)];
				[scriptMenuItem setRepresentedObject:path];
				
				[scriptsMenu insertItem:scriptMenuItem
								atIndex:firstSep+1+i];
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(void)runScript:(NSString *)path
{
	NSLog(@"%s: path=%@\n",__FUNCTION__,path);
	
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
	
	NSTask *task=[[[NSTask alloc] init] autorelease];
	
	[task setLaunchPath:path];
	NSLog(@"%s: [task launchPath] = %@\n",__FUNCTION__,[task launchPath]);
	
	NSPipe *stdinPipe=[NSPipe pipe];
	NSPipe *stdoutPipe=[NSPipe pipe];
	NSPipe *stderrPipe=[NSPipe pipe];
	
	[task setStandardOutput:stdoutPipe];
	[task setStandardInput:stdinPipe];
	[task setStandardError:stderrPipe];
	
	NSLog(@"%s: launching task...\n",__FUNCTION__);
	[task launch];
	NSLog(@"%s: task launched.\n",__FUNCTION__);
	
	NSLog(@"%s: writing %u bytes to task's stdin...\n",__FUNCTION__,[selectionData length]);
	[[stdinPipe fileHandleForWriting] writeData:selectionData];
	[[stdinPipe fileHandleForWriting] closeFile];
	NSLog(@"%s: wrote to task's stdin.\n",__FUNCTION__);

	NSLog(@"%s: reading from task's stdout...\n",__FUNCTION__);
	NSData *outputData=[[stdoutPipe fileHandleForReading] readDataToEndOfFile];
	NSLog(@"%s: read %u bytes from task's stdout.\n",__FUNCTION__,[outputData length]);
	
	NSLog(@"%s: waiting for task exit...\n",__FUNCTION__);
	[task waitUntilExit];
	NSLog(@"%s: task exit.\n",__FUNCTION__);
	
	if([task terminationStatus]!=0)
	{
		NSLog(@"Script failed - exit code %d.\n",[task terminationStatus]);
		return;
	}
	
	NSString *outputStr=[[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
	[textView insertText:outputStr replacementRange:selectionRange];

	NSLog(@"%s: script run, all done.\n",__FUNCTION__);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(IBAction)runScriptAction:(id)arg
{
	[self runScript:[arg representedObject]];
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
	
	NSMenuItem *test1Item=TestAdd(scriptsMenu,@"Test1",self,@selector(test1:));
	[test1Item setKeyEquivalent:@"6"];
	[test1Item setKeyEquivalentModifierMask:NSShiftKeyMask|NSAlternateKeyMask];
	
	TestAdd(scriptsMenu,@"Test2",self,@selector(test2:));
	
	[scriptsMenu addItem:[NSMenuItem separatorItem]];
	
	TestAdd(scriptsMenu,@"Refresh",self,@selector(refreshScriptsMenuAction:));
	
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static void DumpClassHierarchy(Class subclass)
{
	int depth=0;
	
	for(Class c=subclass;c;c=class_getSuperclass(c),++depth)
		NSLog(@"%d: %s\n",depth,class_getName(c));
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static void DumpMethodList(Class c)
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	
	unsigned num_ms;
	Method *ms=class_copyMethodList(c,&num_ms);
	NSLog(@"%s: %u methods:\n",class_getName(c),num_ms);
	for(unsigned i=0;i<num_ms;++i)
	{
		Method *m=&ms[i];
		
		const char *name=sel_getName(method_getName(*m));
		NSLog(@"    %u. %s\n",i,name);
		
		//		for(unsigned j=0;j<method_getNumberOfArguments(*m);++j)
		//		{
		//			char tmp[1000];
		//			method_getArgumentType(*m,j,tmp,sizeof tmp);
		//			NSLog(@"        %u. %s\n",j,tmp);
		//		}
	}
	
	[pool drain];
	pool=nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(IBAction)test1:(id)arg
{
	NSLog(@"%s\n",__FUNCTION__);
	
	return;
	
	NSApplication *app=[NSApplication sharedApplication];
	NSWindow *window=[app mainWindow];
	NSLog(@"%s: window=%p\n",__FUNCTION__,window);
	if(!window)
		return;
	
	Class IDEWorkspaceWindow,IDEWorkspaceWindowController;
	if(!GetClasses("IDEWorkspaceWindow",&IDEWorkspaceWindow,
				   "IDEWorkspaceWindowController",&IDEWorkspaceWindowController,
				   NULL))
	{
		return;
	}
	
	//	DumpClassHierarchy([ped class]);
	//	DumpMethodList([ped class]);
	
//	NSLog(@"Document Editors:\n");
//	NSMutableSet *documentEditors=(NSMutableSet *)objc_msgSend(ped,@selector(_documentEditors));
//	for(id documentEditor in documentEditors)
//	{
//		NSLog(@"    documentEditor: %@\n",GetObjectDescription(documentEditor));
//		DumpClassHierarchy([documentEditor class]);
//		
//		if(IsRightClass(documentEditor,NULL,"IDEViewController"))
//		{
//			//			id contextMenuSelection=CIM(documentEditor,contextMenuSelection,);
//			//			NSLog(@"    contextMenuSelection: %@\n",GetObjectDescription(contextMenuSelection));
//			//			
//			//			id outputSelection=CIM(documentEditor,outputSelection,);
//			//			NSLog(@"    outputSelection: %@\n",GetObjectDescription(outputSelection));
//			//			
//			//			id currentSelectedItems=CIM(documentEditor,currentSelectedItems,);
//			//			NSLog(@"    currentSelectedItems %@\n",GetObjectDescription(currentSelectedItems));
//			
//			id textView=objc_msgSend(documentEditor,@selector(textView));
//			NSLog(@"    textView %@\n",GetObjectDescription(textView));
//			
//			NSArray *textViewSelectedRanges=objc_msgSend(textView,@selector(selectedRanges));
//			if([textViewSelectedRanges count]>0)
//			{
//				NSValue *first=[textViewSelectedRanges objectAtIndex:0];
//				if(strcmp([first objCType],@encode(NSRange))==0)
//				{
//					NSRange range;
//					[first getValue:&range];
//					
//					//					objc_msgSend(textView,@selector(breakUndoCoalescing));
//					//					objc_msgSend(textView,@selector(insertText:replacementRange:),(id)@"FRED1234DERF",range);
//					
//					NSTextStorage *textViewTextStorage=objc_msgSend(textView,@selector(textStorage));
//					NSString *textViewString=[textViewTextStorage string];
//					if(textViewString)
//					{
//						NSString *region=[textViewString substringWithRange:range];
//						NSLog(@"%s: region=%@\n",__FUNCTION__,region);
//					}
//				}
//			}
//		}
//	}
	
	
	//	SEL workspaceWindowControllerForWindowSEL=@selector(workspaceWindowControllerForWindow:);
	//	{
	//		Method m=class_getClassMethod(IDEWorkspaceWindowController,workspaceWindowControllerForWindowSEL);
	//		IMP i=method_getImplementation(m);
	//		id wc=(*i)(IDEWorkspaceWindowController,workspaceWindowControllerForWindowSEL,(id)window);
	//	}
	
	// - (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(IBAction)test2:(id)arg
{
	NSLog(@"%s\n",__FUNCTION__);
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
