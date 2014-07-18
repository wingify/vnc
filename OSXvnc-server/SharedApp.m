/*
 * Source File: SharedApp.m 
 * Project: SharedAppVnc OS X Server
 *
 * Copyright (C) 2005 Grant Wallace, Princeton University. All Rights Reserved.
 *
 *  This is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This software is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this software; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
 *  USA.
 */

//  Created by Grant Wallace on 9/23/05.
//  Copyright 2005 Princeton University. All rights reserved.
//


#include <pthread.h>
#import "SharedApp.h"
#import "SharedAppClient.h"
#import "SharedAppTunnel.h"
#include "CGS-Private.h"

extern int CGSCurrentCursorSeed(void);
extern void refreshCallback(CGRectCount count, const CGRect *rectArray, void *ignore);
extern rfbClientPtr connectReverseClient(char* reverseHost, int reversePort);
//extern CGPoint currentCursorLoc();
extern void setShareApp(SharedApp* sa);
extern void restartListenerThread();

extern ScreenRec hackScreen;

#define preferences [NSUserDefaults standardUserDefaults]

//NSString *ViewerIdentifierTagEnvironmentKey = @"SharedAppViewerTag";

//NSString *DKenableSharedApp = @"EnableAppSharing";
//NSString *DKdisableRemoteEvents = @"DisableRemoteEvents";
//NSString *DKlimitToLocalConnections = @"LimitToLocalConnections";
//NSString *DKswapMouse = @"SwapMouseButtons23";
//NSString *DKpreventDimming = @"PreventDisplayDimming";
//NSString *DKpreventSleep = @"PreventComputerSleeping";
//NSString *DKautorunViewer = @"AutorunViewer";
//NSString *DKpasswordFile = @"PasswordFile";
//NSString *DKrecentClientsArray = @"RecentClients";
//NSString *DKautosaveName = @"SharedAppVncWindow";
//NSString *DKviewerLogFile = @"ViewerLogFile";
//
//
@implementation SharedApp

//+ (void)initialize { 
//	// create the user defaults here if none exists
//    NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
//    
//	// put default prefs in the dictionary
//    [defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:DKenableSharedApp];
//	[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:DKdisableRemoteEvents];
//	[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:DKlimitToLocalConnections];
//	[defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:DKswapMouse];
//	[defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:DKpreventDimming];
//	[defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:DKpreventSleep];
//	[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:DKautorunViewer];
//	//[defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:DKpreventScreenSaver];
//    [defaultPrefs setObject:@"" forKey:DKpasswordFile];
//	[defaultPrefs setObject:@"" forKey:DKviewerLogFile];
//		
//// register the dictionary of defaults
//    [preferences registerDefaults: defaultPrefs];
//	
//}

- (id)init
{
	self = [super init]; //self = [super initWithWindowNibName:@"WindowSelector"];
	arrayLock = [[NSLock alloc] init];
//	pixelLock = [[NSLock alloc] init];
	sharedWindowsArray = [[NSMutableArray alloc] init];
	windowsToBeClosedArray = [[NSMutableArray alloc] init];
	connectedClientsArray = [[NSMutableArray alloc] init];
//	prevClientsArray = [[NSMutableArray alloc] init];
//	tunnelArray = [[NSMutableArray alloc] init];
	setShareApp(self);

	return self;
}

-(void)dealloc
{
//	if (viewerTask) [viewerTask terminate];
//	[viewerTask release];
//	[window saveFrameUsingName:DKautosaveName];
	[sharedWindowsArray removeAllObjects];
	[sharedWindowsArray release];
	[windowsToBeClosedArray removeAllObjects];
	[windowsToBeClosedArray release];
	[connectedClientsArray removeAllObjects];
	[connectedClientsArray release];
//	[prevClientsArray removeAllObjects];
//	[prevClientsArray release];
	[arrayLock release];
//	[pixelLock release];
//	[passwordFile release];
//	[viewerLogFile release];
	[super dealloc];
}


//- (void) applicationWillTerminate: (NSNotification *) notification {
//	NSLog(@"applicationWillTerminate");
//    [self actionStopViewer: self];
//	
//	// kill ssh tunnels
//	SharedAppTunnel* tunnel;
//	NSEnumerator *tunnelEnumerator = [tunnelArray objectEnumerator];
//    while (tunnel = [tunnelEnumerator nextObject]) 
//	{
//		if (tunnel != nil) {
//			NSTask *task = [tunnel task];
//			if (task) [task terminate];
//		}
//	}	
//}
//
//- (void)awakeFromNib
//{
//	[window setFrameAutosaveName:DKautosaveName];
//	[window setFrameUsingName:DKautosaveName];
//	
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(applicationWillTerminate:)
//												 name:NSApplicationWillTerminateNotification
//											   object:NSApp];
//	[self loadUserDefaults:self];
//	
//	// Make this class the root one for AppleEvent calls
//    //[[ NSScriptExecutionContext sharedScriptExecutionContext] setTopLevelObject: self ];
//	
//	pathToAuthentifier = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:
//		@"passwordDialog.app/Contents/MacOS/passwordDialog"] retain];
//		
//	if (pathToAuthentifier) NSLog(@"PATH TO AUTH: %@", pathToAuthentifier);
//	else NSLog(@"PathToAuth NIL");
//}
//
//- (void) loadUserDefaults: sender 
//{
//	[self setEnabled:[preferences boolForKey:DKenableSharedApp]];
//	[self setDisableRemoteEvents:[preferences boolForKey:DKdisableRemoteEvents]];
//	[self setLimitLocal:[preferences boolForKey:DKlimitToLocalConnections]];
//	[self setSwapMouse:[preferences boolForKey:DKswapMouse]];
//	[self setNoDimming:[preferences boolForKey:DKpreventDimming]];
//	[self setNoSleep:[preferences boolForKey:DKpreventSleep]];
//	//[self setNoScreenSaver:[preferences boolForKey:DKpreventScreenSaver]];
//				
//	[prevClientsArray addObjectsFromArray:[preferences stringArrayForKey:DKrecentClientsArray]];
//	if ([prevClientsArray count] > 0)
//	{
//		[comboboxConnectToClient setStringValue:[prevClientsArray objectAtIndex:0]];
//		[comboboxConnectToClient addItemsWithObjectValues:prevClientsArray];	
//	}
//	
//	//passwordfile setup from VNCController.h
//	NSArray *passwordFiles = [NSArray arrayWithObjects:
//        [preferences stringForKey:DKpasswordFile],
//        //[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@".osxvncauth"],
//		@"~/.osxvncauth",
//        @"/tmp/.osxvncauth",
//        nil];
//    NSEnumerator *passwordEnumerators = [passwordFiles objectEnumerator];
//    // Find first writable location for the password file
//    while (passwordFile = [passwordEnumerators nextObject]) 
//	{
//        passwordFile = [passwordFile stringByStandardizingPath];
//        if ([passwordFile length] && [self canWriteToFile:passwordFile])
//		{
//            [passwordFile retain];
//			[preferences setObject:passwordFile forKey:DKpasswordFile];
//			if ([[NSFileManager defaultManager] fileExistsAtPath:passwordFile])
//			{
//				[textfieldPassword setStringValue:@"********"];
//				rfbAuthPasswdFile = strdup([passwordFile cString]);
//			} else {
//				[textfieldPassword setStringValue:@""];
//			}
//			rfbLog("using passwordfile %s", rfbAuthPasswdFile);
//            break;
//        }
//	}
//	
//	NSArray *viewerLogFiles = [NSArray arrayWithObjects:
//        [[NSUserDefaults standardUserDefaults] stringForKey:DKviewerLogFile],
//        @"/var/log/sharedAppVncViewer.log",
//		@"~/Library/Logs/sharedAppVncViewer.log",
//        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"sharedAppVncViewer.log"],
//        @"/tmp/sharedAppVncViewer.log",
//        nil];
//    NSEnumerator *logEnumerators = [viewerLogFiles objectEnumerator];
//
//	
//    // Find first writable location for the log file
//    while (viewerLogFile = [logEnumerators nextObject]) {
//        viewerLogFile = [viewerLogFile stringByStandardizingPath];
//        if ([viewerLogFile length] && [self canWriteToFile:viewerLogFile]) {
//            [viewerLogFile retain];
//			[preferences setObject:viewerLogFile forKey:DKviewerLogFile];
//            break;
//        }
//    }
//	
//	[self setAutorunViewer:[preferences boolForKey:DKautorunViewer]];
//
//}
//
//- (BOOL) canWriteToFile: (NSString *) path 
//{
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
//        return [[NSFileManager defaultManager] isWritableFileAtPath:path];
//    else
//        return [[NSFileManager defaultManager] isWritableFileAtPath:[path stringByDeletingLastPathComponent]];
//}
//
//// Preferences Panel Functions
//- (IBAction) actionShowPreferencePanel:(id)sender
//{
//	NSPoint origin = [window frame].origin;
//	origin.x += 10;
//	origin.y += 10;
//	[preferencePanel setFrameOrigin:origin];
//	[preferencePanel orderFront:self];
//}
//
//
//-(IBAction) changePassword:(id)sender
//{
//	if (![[textfieldPassword stringValue] isEqualToString:@"********"])
//	{
//        [[NSFileManager defaultManager] removeFileAtPath:passwordFile handler:nil];
//		
//        if ([[textfieldPassword stringValue] length]) 
//		{
//            if (vncEncryptAndStorePasswd((char *)[[textfieldPassword stringValue] cString], (char *)[passwordFile cString]) != 0)
//			{
//				[textfieldPassword setStringValue:@""];
//				[preferences setObject:@"" forKey:DKpasswordFile];
//				rfbLog("Password Error! Unable to store password to %s", rfbAuthPasswdFile);
//				NSRunAlertPanel(@"Password Error!", @"Problem - Unable to store password", @"OK", nil, nil);
//            } else {
//				[textfieldPassword setStringValue:@"********"];
//				//rfbLog("stored password to file %s === %s", rfbAuthPasswdFile, [passwordFile cString]);
//			}
//        }
//    }
//}
//
//
//-(IBAction) changeDimming:(id)sender
//{
//	[self setNoDimming:[buttonPreventDimming state]];
//}
//
//-(void) setNoDimming:(BOOL)flag
//{
//	if (rfbNoDimming != flag)
//	{
//		rfbNoDimming = flag;
//		if (rfbNoDimming)
//		{
//			// turn dimming off
//			setDimming(NO);
//		} else {
//			// turn dimming on
//			setDimming(YES);
//		}
//	}
//	[buttonPreventDimming setState:flag];
//	[preferences setBool:flag forKey:DKpreventDimming];
//	
//}
//
//-(IBAction) changeAutorunViewer:(id)sender
//{
//	BOOL flag = [buttonAutorunViewer state];
//	[preferences setBool:flag forKey:DKautorunViewer];
//	//[self setAutorunViewer:[buttonAutorunViewer state]];
//}
//
//-(void) setAutorunViewer:(BOOL)flag
//{
//	if (flag)
//	{
//		[self actionStartViewer:self];
//	} else {
//		[self actionStopViewer:self];
//	}
//	[buttonAutorunViewer setState:flag];
//	[preferences setBool:flag forKey:DKautorunViewer];
//}
//
//-(IBAction) changeSleep:(id)sender
//{
//	[self setNoSleep:[buttonPreventSleeping state]];
//}
//
//-(void) setNoSleep:(BOOL)flag
//{
//	if (rfbNoSleep != flag)
//	{
//		rfbNoSleep = flag;
//		if (rfbNoSleep)
//		{
//			// turn sleep off
//			setSleep(NO);
//			// turn screensaver off also
//			rfbDisableScreenSaver = TRUE;
//			setScreenSaver(NO);
//		} else {
//			// turn sleep on
//			setSleep(YES);
//			// turn screensaver on also
//			rfbDisableScreenSaver = FALSE;
//			setScreenSaver(YES);
//		}
//	}
//	[buttonPreventSleeping setState:flag];
//	[preferences setBool:flag forKey:DKpreventSleep];
//	
//}
//
//
//-(IBAction) changeSwapMouse:(id)sender
//{
//	[self setSwapMouse:[buttonSwapMouseButtons state]];
//}
//
//-(void) setSwapMouse:(BOOL) flag
//{
//	if (rfbSwapButtons != flag)
//	{
//		rfbClientIteratorPtr iterator;
//		rfbClientPtr cl = NULL;
//		
//		rfbSwapButtons = flag;
//		
//		iterator = rfbGetClientIterator();
//		while ((cl = rfbClientIteratorNext(iterator)) != NULL) 
//		{
//			pthread_mutex_lock(&cl->updateMutex);
//			cl->swapMouseButtons23 = rfbSwapButtons; 
//			pthread_mutex_unlock(&cl->updateMutex);
//		}
//		rfbReleaseClientIterator(iterator);
//	}
//	[buttonSwapMouseButtons setState:flag];
//	[preferences setBool:flag forKey:DKswapMouse];
//}
//
//
//-(IBAction) changeDisableRemoteEvents:(id)sender
//{
//    [self setDisableRemoteEvents:[buttonDisableRemoteEvents state]];
//}
//
//-(void) setDisableRemoteEvents:(BOOL) flag
//{
//	if (rfbDisableRemote != flag)
//	{
//		rfbClientIteratorPtr iterator;
//		rfbClientPtr cl = NULL;
//		
//		rfbDisableRemote = flag;
//		
//		iterator = rfbGetClientIterator();
//		while ((cl = rfbClientIteratorNext(iterator)) != NULL) 
//		{
//			pthread_mutex_lock(&cl->updateMutex);
//			cl->disableRemoteEvents = rfbDisableRemote;
//			pthread_mutex_unlock(&cl->updateMutex);
//		}
//		rfbReleaseClientIterator(iterator);
//	}
//	[buttonDisableRemoteEvents setState:flag];
//	[preferences setBool:flag forKey:DKdisableRemoteEvents];
//}
//
//-(IBAction) changeLimitLocal:(id)sender
//{
//	[self setLimitLocal:[buttonLimitToLocalConnections state]];
//}
//
//-(void) setLimitLocal:(BOOL) flag
//{
//	if (rfbLocalhostOnly != flag)
//	{
//		rfbLocalhostOnly = flag;
//		restartListenerThread();
//	}
//	[buttonLimitToLocalConnections setState:flag];
//	[preferences setBool:flag forKey:DKlimitToLocalConnections];
//}
//
//- (IBAction)changeSharing:(id)sender {
//	BOOL state = ([buttonEnable state] == NSOffState) ? TRUE : FALSE;
//	[self setEnabled:state];
//}

-(void) setEnabled:(BOOL)flag
{

	if (flag)
	{
//		[buttonUnshare setEnabled:YES];
//		[buttonUnshareAll setEnabled:YES];
//		[buttonSelectToShare setEnabled:YES];
//		[tableSharedWindows setHidden:NO];
		
		VNCWinInfo *desktopWin = [[VNCWinInfo alloc] init];
		[desktopWin setWindowId:0];
		
		[arrayLock lock];
		[windowsToBeClosedArray addObject:desktopWin];
		[arrayLock unlock];
		
		[self refreshAllWindows];
	}
	else 
	{
//		[buttonUnshare setEnabled:NO];
//		[buttonUnshareAll setEnabled:NO];
//		[buttonSelectToShare setEnabled:NO];
//		[tableSharedWindows setHidden:YES];
		
		CGRectCount rectCount = 1;
		CGRect rectArray[1];
		rectArray[0].origin.x = 0;
		rectArray[0].origin.y = 0;
		rectArray[0].size.width = rfbScreen.width;
		rectArray[0].size.height = rfbScreen.height;
		refreshCallback(rectCount, rectArray, NULL);
		[self resetClientRequestedArea];
	}
	enabled = flag;
//	[buttonEnable setState:!flag];
//	[preferences setBool:flag forKey: DKenableSharedApp];
}

- (BOOL) enabled
{
	return enabled;
}


//// Main Window Functions
//- (IBAction) actionConnectToClient: (id)sender
//{
//	rfbClientPtr cl = nil;
//	NSArray *textArray;
//	NSString *usertext;
//	const char *host;
//	int port;
//	
//	usertext = [comboboxConnectToClient stringValue];
//	textArray = [usertext componentsSeparatedByString:@":"];
//	if ([textArray count] <= 0) return;
//	else if ([textArray count] == 1)
//	{
//		host = [[textArray objectAtIndex:0] cString];
//		port = 5500;
//	}
//	if ([textArray count] == 2)
//	{
//		host = [[textArray objectAtIndex:0] cString];
//		port = [[textArray objectAtIndex:1] intValue];
//	} 
//
//	if (port < 100) port += 5500;
//	cl = connectReverseClient(host, port);
//	
//	if (cl)
//	{
//		SharedAppClient *client = [[SharedAppClient alloc] initWithRfbClient:cl];
//		[arrayLock lock];
//		[connectedClientsArray addObject:client];
//		[arrayLock unlock];
//		[tableConnectedClients reloadData];
//		[client release];
//		
//		// update user defaults
//		[prevClientsArray removeObject:usertext];
//		[prevClientsArray insertObject:usertext atIndex:0];
//		[preferences setObject:prevClientsArray forKey: DKrecentClientsArray];
//		[comboboxConnectToClient removeAllItems];
//		[comboboxConnectToClient addItemsWithObjectValues: prevClientsArray];
//	} else {
//		rfbLog("Connection Failed: NULL cl");
//		NSRunAlertPanel(@"Connection Error!", @"Unable to connect to client %s:%d", @"OK", nil, nil, host, port);
//		
//	}
//	[self refreshAllWindows];
//}

-(void) addClient: (rfbClientPtr)cl
{
	SharedAppClient *client = [[SharedAppClient alloc] initWithRfbClient:cl];
	[arrayLock lock];
	[connectedClientsArray addObject:client];
	[arrayLock unlock];
//	[tableConnectedClients reloadData];
	[client release];
	[self refreshAllWindows];
}


//- (IBAction) actionDisconnectClient: (id)sender
//{
//	int rowIndex = [tableConnectedClients selectedRow];
//	if (rowIndex == -1) return;
//	
//	SharedAppClient *client = [connectedClientsArray objectAtIndex:rowIndex];
//	rfbCloseClient([client clientStruct]);
//	[arrayLock lock];
//	[connectedClientsArray removeObject:client];
//	[arrayLock unlock];
//	[tableConnectedClients reloadData];
//}
//
//- (IBAction) actionStartViewer: (id)sender
//{
//    if (!viewerTask) 
//	{
//		NSString *executable = @"/usr/bin/java";
//        NSString *viewerPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/sharedAppViewer.jar"];
//		NSMutableArray *argv = [[NSMutableArray alloc] init];
//		[argv addObject:@"-jar"];
//		[argv addObject:viewerPath];
//		
//		if (![[NSFileManager defaultManager] fileExistsAtPath:viewerLogFile]) {
//            [[NSFileManager defaultManager] createFileAtPath:viewerLogFile contents:nil attributes:nil];
//        }
//        else { // Clear it
//            serverOutput = [NSFileHandle fileHandleForUpdatingAtPath:viewerLogFile];
//            [serverOutput truncateFileAtOffset:0];
//            [serverOutput closeFile];
//        }
//        serverOutput = [[NSFileHandle fileHandleForUpdatingAtPath:viewerLogFile] retain];
//
//		NSLog(@"Starting viewer: %@ %@ %@", executable, [argv objectAtIndex:0], [argv objectAtIndex:1]);
//		NSLog(@"Viewer Logfile %@", viewerLogFile);
//        
//		viewerTask = [[NSTask alloc] init];
//        [viewerTask setLaunchPath:executable];
//        [viewerTask setArguments:argv];
//        [viewerTask setStandardOutput:serverOutput];
//        [viewerTask setStandardError:serverOutput];
//		
//		/*
//		NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[viewerTask environment]];
//		[environment setObject:@"" forKey:ViewerIdentifierTagEnvironmentKey];
//		[viewerTask setEnvironment:environment];		
//		*/
//		
//        [viewerTask launch];
//        
//        [[NSNotificationCenter defaultCenter] addObserver: self
//                                                 selector: NSSelectorFromString(@"viewerStopped:")
//                                                     name: NSTaskDidTerminateNotification
//                                                   object: viewerTask];
//        
//		[textfieldViewerStatus setStringValue:@"Viewer Running"];
//
//    }
//	
//}
//
//
//- (IBAction) actionStopViewer: (id)sender
//{
//    if (viewerTask != nil) {
//        [viewerTask terminate];
//    } else {
//		[textfieldViewerStatus setStringValue:@"Viewer Stopped"];
//	}
//	
//	
///*	
//	NSEnumerator *processEnumerator = [[AGProcess userProcesses] objectEnumerator];
//    AGProcess *process = nil;
//	NSLog(@"checking processes");
//    
//    while (process = [processEnumerator nextObject]) {
//		NSLog(@"compare to %@", [process command]);
//        if ([@"java" isEqualToString:[process command]]) {
//            NSDictionary *environment = [process environment];
//            
//            if ([environment valueForKey:ViewerIdentifierTagEnvironmentKey]) {
//                NSLog(@"Killing viewer with pid %i.", [process processIdentifier]);
//				
//                if ([process terminate]) {
//                    NSLog(@"Killed viewer.");
//                }
//                else {
//					NSLog(@"Failed to kill viewer.");
//                }
//            }
//        }
//    }
//*/
//}
//
//
//- (void) viewerStopped: (NSNotification *) aNotification {
//    [[NSNotificationCenter defaultCenter] removeObserver: self
//                                                    name: NSTaskDidTerminateNotification
//                                                  object: viewerTask];
//
//	[textfieldViewerStatus setStringValue:@"Viewer Stopped"];
//    
//    [viewerTask release];
//    viewerTask = nil;
//    [serverOutput closeFile];
//    [serverOutput release];
//    serverOutput = nil;
//	
//}
//
//
//// Ssh Tunnel Panel Functions
//- (IBAction) actionShowSshTunnelPanel:(id)sender
//{
//	NSPoint origin = [window frame].origin;
//	origin.x += 10;
//	origin.y += 10;
//	[sshTunnelPanel setFrameOrigin:origin];
//	[sshTunnelPanel orderFront:self];
//}
//
//- (IBAction) actionCloseTunnel: (id)sender
//{
//	int rowIndex = [tableSshTunnels selectedRow];
//	if (rowIndex == -1) return;
//	
//	SharedAppTunnel *tunnel = [tunnelArray objectAtIndex:rowIndex];
//	NSLog(@"Close Tunnel: %@", [tunnel name]);
//    NSTask *task = [tunnel task];
//	if (task) [task terminate];
//}
//
//
//- (IBAction) actionTunnelConnect: (id)sender
//{
//	NSString *host = [textfieldHostString stringValue];
//	NSArray *hostAr = [host componentsSeparatedByString:@":"];
//	NSString *username = [textfieldUsername stringValue];
//	int lport = [textfieldLocalPort intValue];
//	int rport = [textfieldRemotePort intValue];
//	//BOOL bSshGatewayOnly = ([buttonSSHGatewayOnly state] == NSOffState) ? FALSE : TRUE;
//	NSString *finalHost = @"localhost";
//	BOOL bOutgoingTunnel = ([radioButtonTunnelType selectedColumn] == 0) ? TRUE : FALSE;
//	NSString *connDirection = ([radioButtonTunnelType selectedColumn] == 0) ? @"-L" : @"-R";
//	NSPoint origin = [window frame].origin;
//	NSString *tunnelId = @"2";
//	
//	NSString *connectString = @"";
//	NSString *executable = @"/usr/bin/ssh";
//	NSMutableArray *argv = [[NSMutableArray alloc] init];
//
//	// note: unfortuantely the password method doesn't work for multiple ssh hops
//	// one future method might be to execute bash and then read and write from pipes.
//	// or possibly have the password function write out the password n times - one per connection
//	int count = [hostAr count];
//	int i;
//	
//	if (count < 1 || count > 2)
//	{
//		NSString *errStr = @"Incorrect host specification, expecting gateway:host or host";
//		NSRunAlertPanel(@"SSH Tunnel Error!", @"%@", @"OK", nil, nil, errStr);
//		[sshTunnelPanel orderOut:self];
//		return;
//	} else if (count == 2) {
//		finalHost = [hostAr objectAtIndex:1];
//		count--;
//	} 
//		
//	for (i=0; i<count; i++)
//	{
//		int port1, port2;
//		if (bOutgoingTunnel)
//		{ 
//			port1 = lport;
//			port2 = (i<count-1) ? lport : rport;
//		} else {
//			port1 = rport;
//			port2 = (i==0) ? lport : rport;
//		}
//		
//		if (i>0) [argv addObject:executable];
//		if (!bOutgoingTunnel) [argv addObject:@"-g"];
//		[argv addObject:@"-t"];
//		[argv addObject:@"-t"];
//		[argv addObject:connDirection];
//		[argv addObject:[NSString stringWithFormat:@"%d:%@:%d", port1, finalHost, port2]];
//		[argv addObject:[NSString stringWithFormat:@"%@@%@", username, [hostAr objectAtIndex:i]]];
//	}
//	
//	NSEnumerator *enumerator = [argv objectEnumerator];
//	NSString *arg;
//	while (arg = [enumerator nextObject]) 
//	{
//		connectString = [connectString stringByAppendingFormat:@"%@ ", arg];
//	}
//	
//	NSString *remoteHostAbr = [[[hostAr lastObject] componentsSeparatedByString:@"."] objectAtIndex:0];
//	NSString *tunnelName;
//	if (bOutgoingTunnel)
//	{
//		tunnelName = [NSString stringWithFormat:@"%d-->%@:%d", lport, remoteHostAbr, rport];
//	} else {
//		tunnelName = [NSString stringWithFormat:@"%d<--%@:%d", lport, remoteHostAbr, rport];
//	}
//	
//	//NSLog(@"Starting an SSH Tunnel(%d): %d:%@:%d gonly(%d) username(%@)", 
//	//	  bOutgoingTunnel, lport, host, rport, bSshGatewayOnly, username);
//	
//
//	NSLog(@"SSH Tunnel: %@ %@", executable, connectString);
//	//NSRunAlertPanel(@"SSH Tunnel", @"%@", @"OK", nil, nil, connectString);
//	
//    NSMutableDictionary *environment = [ NSMutableDictionary dictionaryWithDictionary: [[ NSProcessInfo processInfo ] environment ]];
//	[ environment removeObjectForKey: @"SSH_AGENT_PID" ];
//	[ environment removeObjectForKey: @"SSH_AUTH_SOCK" ];
//	[ environment setObject: pathToAuthentifier forKey: @"SSH_ASKPASS" ];
//	[ environment setObject:@":0" forKey:@"DISPLAY" ];
//	[ environment setObject: tunnelName forKey: @"TUNNEL_NAME" ];
//	[ environment setObject: tunnelId forKey: @"TUNNEL_ID" ];
//	[ environment setObject: [NSString stringWithFormat:@"%f",origin.x] forKey: @"XOFFSET" ];
//	[ environment setObject: [NSString stringWithFormat:@"%f",origin.y] forKey: @"YOFFSET" ];
//	
//	NSTask *sshTunnelTask = [[NSTask alloc] init];
//	[sshTunnelTask setLaunchPath:executable];
//	[sshTunnelTask setArguments:argv];
//    [sshTunnelTask setEnvironment: environment];
//	[sshTunnelTask setStandardError: [[NSPipe alloc] init]];
//	[sshTunnelTask launch];
//	
//	// Add to table	
//	SharedAppTunnel *tunnel = [[SharedAppTunnel alloc] initWithTask:sshTunnelTask
//															   name:tunnelName 
//																tag:tunnelId
//														  direction:(bOutgoingTunnel)?@"OUT":@"IN"];
//	[arrayLock lock];
//	[tunnelArray addObject:tunnel];
//	[arrayLock unlock];
//	
//	[[NSNotificationCenter defaultCenter] addObserver: self
//											 selector: NSSelectorFromString(@"tunnelStopped:")
//												 name: NSTaskDidTerminateNotification
//											   object: sshTunnelTask];
//	
//	[sshTunnelPanel orderOut:self];
//	
//	[tableSshTunnels reloadData];
//}
//
//
//- (IBAction) actionTunnelCancel: (id)sender
//{
//	[sshTunnelPanel orderOut:self];
//}
//
//
//- (void) tunnelStopped: (NSNotification *) aNotification 
//{
//	NSTask *task = [aNotification object];
//	
//    [[NSNotificationCenter defaultCenter] removeObserver: self
//                                                    name: NSTaskDidTerminateNotification
//                                                  object: task];
//
//	SharedAppTunnel* tunnel;
//	NSEnumerator *enumerator = [[NSArray arrayWithArray:tunnelArray] objectEnumerator];
//	while (tunnel = [enumerator nextObject]) 
//	{
//		if ([tunnel task] == task)
//		{
//			[arrayLock lock];
//			[tunnelArray removeObject:tunnel];
//			[arrayLock unlock];
//			break;
//		}
//	}
//	
//	if (task)
//	{
//		NSFileHandle *ferr = [[task standardError] fileHandleForReading];
//		NSString *errStr = [[NSString alloc] initWithData:[ferr readDataToEndOfFile]
//												 encoding:NSASCIIStringEncoding];
//		
//		NSRunAlertPanel(@"SSH Tunnel Error!", @"%@", @"OK", nil, nil, errStr);
//		NSLog(@"Task Error Msg: %@", errStr);
//		
//		[task release];
//		task = nil;
//	}
//	
//	NSLog(@"Tunnel Removed: Count %d", [tunnelArray count]);
//	
//	[tableSshTunnels reloadData];	
//}
//
//
//- (IBAction)actionSelectWindow:(id)sender {
//	NSScreen			*screen;
//	NSRect				screen_rect;
//
//	screen						= [NSScreen mainScreen];
//	screen_rect					= [screen frame];
//	screen_rect.origin.x		= 0;
//	screen_rect.origin.y		= 0;
//	cover_window				= [[DTFullScreenWindow alloc] initWithContentRect:screen_rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen];
//	[cover_window set_controller:self];
//	[cover_window setAlphaValue:0.0];
//	[cover_window setIgnoresMouseEvents:NO];
//	[cover_window setLevel:CGShieldingWindowLevel()];
//	[cover_window makeKeyAndOrderFront:self];
//	 
//}

- (void)finish_select:(CGPoint)loc {
	int				unknown, res;
	CGSWindow		wid = 0;
	CGSConnection   con = _CGSDefaultConnection(), cid = 0;
	
	if (cover_window) {
		[cover_window orderOut:self];
		[cover_window close];
		cover_window	= 0;
	}
	
//VAO_START REPLACE
//	res	= CGSFindWindowAndOwner(con, 0,1,0, &loc, &unknown, &wid, &cid);
//	if (!res && wid && cid) {
//VAO_BY
    if (TRUE) {
//VAO_END
//VAO_TEMP        wid = 18363;
		// We sucessfully found the window id
		VNCWinInfo *win;		
		NSEnumerator *enumerator;
	
		enumerator = [[NSArray arrayWithArray:sharedWindowsArray] objectEnumerator];
		while (win = [enumerator nextObject]) {
			if ([win windowId] == wid)
			{
				NSLog(@"Duplicate window %d", wid);
				return;
			}
		}

		win = [[VNCWinInfo alloc] initWithWindowId: wid connectionId: cid];
		
		[arrayLock lock];
		[sharedWindowsArray addObject:win];
		[arrayLock unlock];

//		[tableSharedWindows reloadData];
		[self refreshWindow:win];
		//usleep(10000);
		//[win getVisibleRegion];
		[win release];
	}

}


//- (IBAction)actionHideSelected:(id)sender {
//
//	int rowIndex = [tableSharedWindows selectedRow];
//	if (rowIndex == -1) return;
//	
//	VNCWinInfo *win = [sharedWindowsArray objectAtIndex:rowIndex];
//	
//	[arrayLock lock];
//	if (![windowsToBeClosedArray containsObject:win])
//	{
//		[windowsToBeClosedArray addObject:win];
//	}
//	[sharedWindowsArray removeObject:win];
//	[arrayLock unlock];
//	
//	[tableSharedWindows reloadData];
//	
//}
//
//
//- (IBAction)actionHideAll: (id)sender {
//	VNCWinInfo *win;
//	NSEnumerator *enumerator;
//	
//	[arrayLock lock];
//	enumerator = [sharedWindowsArray objectEnumerator];
//	while (win = [enumerator nextObject]) 
//	{
//		if (![windowsToBeClosedArray containsObject:win])
//		{
//			[windowsToBeClosedArray addObject:win];
//		}
//	}
//	[sharedWindowsArray removeAllObjects];
//	[arrayLock unlock];	
//	
//	[tableSharedWindows reloadData];
//
//}


-(void) refreshAllWindows
{
	VNCWinInfo *win;		
	NSEnumerator *enumerator;
	
	enumerator = [[NSArray arrayWithArray:sharedWindowsArray] objectEnumerator];
	while (win = [enumerator nextObject]) {
		[self refreshWindow:win];
	}
}

-(void) refreshWindow:(VNCWinInfo*)win
{
	CGRectCount rectCount = 1;
	CGRect rectArray[1];
	
	[win setDoFullUpdate:TRUE];
	
    rectArray[0].origin.x = [win originX];
    rectArray[0].origin.y = [win originY];
	rectArray[0].size.width = [win width];
	rectArray[0].size.height = [win height];
	
	//rfbLog("Sending refresh for rect %f %f %f %f", 
	//	   rectArray[0].origin.x, rectArray[0].origin.y, rectArray[0].size.width, rectArray[0].size.height);
	
	refreshCallback(rectCount, rectArray, NULL);
	
	return;
}

//// NSTableView callbacks
//- (int)numberOfRowsInTableView : (NSTableView*)table {
//
//	if (table == tableSharedWindows) 
//	{
//		return [sharedWindowsArray count];
//	}
//	else if (table == tableConnectedClients)
//	{
//		return [connectedClientsArray count];
//	}
//	else if (table == tableSshTunnels)
//	{
//		NSLog(@"numberOfRowsInTableView: Count %d", [tunnelArray count]);
//		return [tunnelArray count];
//	}
//	else return 0;
//}
//
//
//- (id)tableView:(NSTableView*)table objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex {
//	
//	int			count;
//	id           theObject = nil, theValue = nil;
//    NSArray     *dataSource = nil;
//	NSString    *identifier = [tableColumn identifier];
//			
//	if (table == tableSharedWindows) dataSource = sharedWindowsArray;
//	else if (table == tableConnectedClients) dataSource = connectedClientsArray;
//	else if (table == tableSshTunnels) dataSource = tunnelArray;
//	
//	count = [dataSource count];
//	//NSLog(@"tableView: Count %d, Row %d", [dataSource count], rowIndex);
//    if (count > rowIndex)
//    {
//        theObject = [dataSource objectAtIndex: rowIndex];
//        theValue = [theObject valueForKey: identifier];
//    } else {
//		theValue = nil;
//	}
//
//    return theValue;
//}
//
//
-(void) resetClientRequestedArea
{
	rfbClientIteratorPtr iterator;
	rfbClientPtr cl = NULL;
	BoxRec box;
	
	box.x1 = 0;
	box.y1 = 0;
	box.x2 = rfbScreen.width;
	box.y2 = rfbScreen.height;
	
	iterator = rfbGetClientIterator();
	while ((cl = rfbClientIteratorNext(iterator)) != NULL) 
	{
		pthread_mutex_lock(&cl->updateMutex);
		REGION_RESET(&hackScreen, &cl->requestedRegion, &box);
		pthread_mutex_unlock(&cl->updateMutex);
	}
	rfbReleaseClientIterator(iterator);
}
//
////*****************************************************************************
//// The following functions may introduce race conditions from multiple client threads
//// Called by Main.c and rfbserver.c possibly by multiple threads (1 per client)


// called by rfbserver when client leaves
// withing clientInput thread - no autorelease pool
-(void) removeClient: (rfbClientPtr)cl
{
	NSEnumerator *enumerator;
	SharedAppClient *client;
	NSAutoreleasePool *tempPool;
		
	tempPool = [[NSAutoreleasePool alloc] init];
		
	enumerator = [[NSArray arrayWithArray:connectedClientsArray] objectEnumerator];
	while (client = [enumerator nextObject]) 
	{
		if ([client clientStruct] == cl)
		{
			[arrayLock lock];
			[connectedClientsArray removeObject:client];
			[arrayLock unlock];
		}
	}
//	[tableConnectedClients reloadData];
	
	[tempPool release];
	return;
	
}

-(VNCWinInfo*) getWindowWithId:(int)wid
{
	VNCWinInfo *win;		
	NSEnumerator *enumerator;
	
	enumerator = [[NSArray arrayWithArray:sharedWindowsArray] objectEnumerator];
	while (win = [enumerator nextObject]) 
	{
//VAO_START ADD_VAO
        //rfbLog("#sharedWindows: %d. this =  %d", [sharedWindowsArray count], [win windowId]);
        if(wid == 0){
            return win;
        }
//VAO_END
		if ([win windowId] == wid)
		{
			return win;
		}
	}
	
	return NULL;
}

-(void) getSharedRegions:(RegionRec*)sharedRegionPtr
{
	VNCWinInfo *win;
	NSEnumerator *enumerator;
	RegionRec winRegion;
	
	REGION_INIT(&hackScreen, &winRegion, NullBox, 0);
	REGION_EMPTY(&hackScreen, sharedRegionPtr);
	
	[arrayLock lock];
	enumerator = [sharedWindowsArray objectEnumerator];
	while (win = [enumerator nextObject]) 
	{
		[win getVisibleRegion:&winRegion];
		REGION_UNION(&hackScreen, sharedRegionPtr, sharedRegionPtr, &winRegion);
	}
	[arrayLock unlock];	
	
	REGION_UNINIT(&hackScreen,&winRegion);
}


-(BOOL) areWindowsToClose
{
//VAO_START VAO
    return false;
//VAO_END
	return ([windowsToBeClosedArray count] > 0);
}

// called within clientOutput thread - no autorelease pool
-(void) checkForClosedWindows
{
//VAO_START VAO
    return;
//VAO_END
    
	VNCWinInfo* win;
	BOOL bRefreshTableView = FALSE;		
	NSEnumerator *enumerator;
	//NSAutoreleasePool *tempPool;
	
	if ([windowsToBeClosedArray count] == 0) return;

	//tempPool = [[NSAutoreleasePool alloc] init];
	
	enumerator = [[NSArray arrayWithArray:windowsToBeClosedArray] objectEnumerator];
	while (win = [enumerator nextObject])
	{
		rfbSharedAppUpdateMsg *updateMsg;
		rfbClientIteratorPtr iterator;
		rfbClientPtr cl = NULL;
		
		//rfbLog("rfbSendWindowClose %x", [win windowId]);
		
		iterator = rfbGetClientIterator();
		while ((cl = rfbClientIteratorNext(iterator)) != NULL) 
		{
			pthread_mutex_lock(&cl->updateMutex);
			
			if (cl->ublen + sz_rfbSharedAppUpdateMsg > UPDATE_BUF_SIZE) 
			{
				rfbSendUpdateBuf(cl);
			}
			updateMsg = (rfbSharedAppUpdateMsg *)(cl->updateBuf + cl->ublen);
			cl->ublen += sz_rfbSharedAppUpdateMsg;
			memset(updateMsg, 0, sz_rfbSharedAppUpdateMsg);
			updateMsg->type = rfbSharedAppUpdate;
			updateMsg->win_id = Swap32IfLE([win windowId]);
			
			rfbSendUpdateBuf(cl);
			
			pthread_mutex_unlock(&cl->updateMutex);
		}
		rfbReleaseClientIterator(iterator);

		[arrayLock lock];
		if ([sharedWindowsArray containsObject:win])
		{
			[sharedWindowsArray removeObject:win];
			bRefreshTableView = TRUE;
		}
		[windowsToBeClosedArray removeObject:win];
		[arrayLock unlock];
	}

	
//	if (bRefreshTableView) 	[tableSharedWindows reloadData];
	
	//[tempPool release];
		
	return;
}


-(BOOL)
rfbSendUpdates: (rfbClientPtr)cl screenRegion:(RegionRec)screenUpdateRegion
{
	int i;
//VAO_START UPDATE
// updated to merge back changes in `rfbSendFramebufferUpdate` since v1.6 since this function is based on `rfbSendFramebufferUpdate`
    int nUpdateRegionRects = 0;
//VAO_END
	NSEnumerator *enumerator;
	VNCWinInfo *win;
	BoxRec box;
	RegionRec winRegion, updateRegion;
//VAO_START STANDARD_VNC
// changes for making the VAOvnc server compatible with standard VNC clients
//	rfbSharedAppUpdateMsg *updateMsg;
//VAO_BY
    rfbFramebufferUpdateMsg *updateMsg;
//VAO_END
	BOOL clearRequestedRegion = FALSE;
	BOOL bResetCursorLocation = FALSE;
	BOOL bResetCursorType = FALSE;
	BOOL bUsePixelImage = TRUE;

    // check if SharedAppEncoding supported for this client 
    if (!cl->supportsSharedAppEncoding) return FALSE;
	
	REGION_INIT(&hackScreen, &updateRegion, NullBox, 0);
	REGION_INIT(&hackScreen, &winRegion, NullBox, 0);
		
	// get the enumerator from an immutable copy since docs say don't modifify array during enumeration.
	enumerator = [[NSArray arrayWithArray:sharedWindowsArray] objectEnumerator];
	while (win = [enumerator nextObject])
	{
		BOOL sendRichCursorEncoding = FALSE;
		BOOL sendCursorPositionEncoding = FALSE;
		BOOL bCursorOnly = FALSE;
			
		if (![win validated])
		{
			[arrayLock lock];
			rfbLog("remove window");
			[windowsToBeClosedArray addObject:win];
			[arrayLock unlock];
			continue;
		}
		
		REGION_EMPTY(&hackScreen, &updateRegion);
		
		[win getVisibleRegion:&winRegion];
		
		if ([win doFullUpdate])
		{
			box.x1 = [win originX];
			box.y1 = [win originY];
			box.x2 = [win originX] + [win width];
			box.y2 = [win originY] + [win height];
			
			REGION_RESET(&hackScreen, &updateRegion, &box);
			[win setDoFullUpdate:FALSE];
		} else {
			REGION_INTERSECT(&hackScreen, &updateRegion, &screenUpdateRegion, &winRegion);
		}

		//rfbLog("winRegion %d %d %d %d", box.x1, box.y1, box.x2, box.y2);
		
		if (cl->preferredEncoding == rfbEncodingCoRRE) {
			nUpdateRegionRects = 0;
			
			for (i = 0; i < REGION_NUM_RECTS(&updateRegion); i++) {
				int x = REGION_RECTS(&updateRegion)[i].x1;
				int y = REGION_RECTS(&updateRegion)[i].y1;
				int w = REGION_RECTS(&updateRegion)[i].x2 - x;
				int h = REGION_RECTS(&updateRegion)[i].y2 - y;
				nUpdateRegionRects += (((w-1) / cl->correMaxWidth + 1)
									   * ((h-1) / cl->correMaxHeight + 1));
			}
		} else if (cl->preferredEncoding == rfbEncodingZlib) {
			nUpdateRegionRects = 0;
			
			for (i = 0; i < REGION_NUM_RECTS(&updateRegion); i++) {
				int x = REGION_RECTS(&updateRegion)[i].x1;
				int y = REGION_RECTS(&updateRegion)[i].y1;
				int w = REGION_RECTS(&updateRegion)[i].x2 - x;
				int h = REGION_RECTS(&updateRegion)[i].y2 - y;
				nUpdateRegionRects += (((h-1) / (ZLIB_MAX_SIZE( w ) / w)) + 1);
			}
		} else if (cl->preferredEncoding == rfbEncodingTight) {
			nUpdateRegionRects = 0;
			
			for (i = 0; i < REGION_NUM_RECTS(&updateRegion); i++) {
				int x = REGION_RECTS(&updateRegion)[i].x1;
				int y = REGION_RECTS(&updateRegion)[i].y1;
				int w = REGION_RECTS(&updateRegion)[i].x2 - x;
				int h = REGION_RECTS(&updateRegion)[i].y2 - y;
				int n = rfbNumCodedRectsTight(cl, x, y, w, h);
				if (n == 0) {
					nUpdateRegionRects = 0xFFFF;
					break;
				}
				nUpdateRegionRects += n;
			}
		} else {
			nUpdateRegionRects = REGION_NUM_RECTS(&updateRegion);
		}
			
		if ( nUpdateRegionRects == 0)
		{
			// no pixels to send, but we may need to send cursor information
			bCursorOnly = TRUE;
			//rfbLog("Cursor Only");
		}

		if (nUpdateRegionRects != 0xFFFF) 
		{	
			if (rfbShouldSendNewCursor(cl)) 
			{
				CGPoint p = currentCursorLoc();
				BoxRec resbox;
				if (POINT_IN_REGION(&hackScreen, &winRegion, p.x, p.y, &resbox))
				{	
					sendRichCursorEncoding = TRUE;
					nUpdateRegionRects++;
				}
				bResetCursorType = TRUE;
			}
			if (rfbShouldSendNewPosition(cl)) 
			{
				CGPoint p = currentCursorLoc();
				BoxRec resbox;
				if (POINT_IN_REGION(&hackScreen, &winRegion, p.x, p.y, &resbox))
				{	
					sendCursorPositionEncoding = TRUE;
					nUpdateRegionRects++;
				}
				bResetCursorLocation = TRUE;
			}
			
			if (cl->needNewScreenSize) {
				nUpdateRegionRects++;
			}
		}
		
		if (nUpdateRegionRects == 0)
        {
            //rfbLog("SHAREDAPP -- no rects to send\n");
            continue;
        }

		if (bUsePixelImage)
		{
			if (!bCursorOnly)
			{
				int prevX = [win originX];
				int prevY = [win originY];
				int prevW = [win width];
				int prevH = [win height];
				
				// Get access to the window pixels
				
				cl->scalingFrameBuffer = [win getPixelAccess];
				cl->scalingPaddedWidthInBytes = [win bytesPerRow]; // * rfbScreen.bitsPerPixel/8;
				
				if (cl->scalingFrameBuffer == NULL || 
					prevX != [win originX] || prevY != [win originY] || 
					prevW != [win width] || prevH != [win height])
				{
					rfbLog("Size or Location changed");
					//[self refreshWindow:win]; // this will cause deadlock on updateMutex
					continue;
				}
				
				// update and translate regions pointers appropriately
				REGION_TRANSLATE(&hackScreen, &updateRegion, -[win originX], -[win originY]);
			}
			box.x1 = 0;
			box.y1 = 0;
		}
		
		// Send stuff
		// Clear client requested region - since we are sending stuff they will send another request
		clearRequestedRegion = TRUE;
		
		if (cl->ublen + sz_rfbSharedAppUpdateMsg > UPDATE_BUF_SIZE) 
        {
			if (!rfbSendUpdateBuf(cl)) {
				REGION_UNINIT(&hackScreen,&winRegion);
				REGION_UNINIT(&hackScreen,&updateRegion);
				return FALSE;
			}
        }
//VAO_START UPDATE
//        updateMsg = (rfbSharedAppUpdateMsg *)(cl->updateBuf + cl->ublen);
//        memset(updateMsg, 0xab, sz_rfbSharedAppUpdateMsg);
//        updateMsg->type = rfbSharedAppUpdate;
//        updateMsg->win_id = Swap32IfLE([win windowId]);
//        updateMsg->parent_id = Swap32IfLE(0);
//		updateMsg->cursorOffsetX = Swap16IfLE([win originX]);
//		updateMsg->cursorOffsetY = Swap16IfLE([win originY]);
//		updateMsg->win_rect.x = Swap16IfLE(box.x1);
//        updateMsg->win_rect.y = Swap16IfLE(box.y1);
//        updateMsg->win_rect.w = Swap16IfLE([win width]);
//        updateMsg->win_rect.h = Swap16IfLE([win height]);
//        updateMsg->nRects = Swap16IfLE(nUpdateRegionRects);
//        cl->ublen += sz_rfbSharedAppUpdateMsg;
//VAO_BY
        updateMsg = (rfbFramebufferUpdateMsg *)(cl->updateBuf + cl->ublen);
        updateMsg->type = rfbFramebufferUpdate;
        updateMsg->nRects = Swap16IfLE(nUpdateRegionRects);
        cl->ublen += sz_rfbFramebufferUpdateMsg;
//VAO_END
		
		if (cl->needNewScreenSize) {
			if (rfbSendScreenUpdateEncoding(cl)) {
				cl->needNewScreenSize = FALSE;
			} else {
				rfbLog("Error Sending Cursor\n");
//VAO_START
// just an explanatory comment: since winRegion and updateRegion have been INITed locally, we need to UNINIT them before we return from the function.
				REGION_UNINIT(&hackScreen,&winRegion);
				REGION_UNINIT(&hackScreen,&updateRegion);
//VAO_END
				return FALSE;
			}            
		}
		
		// Sometimes send the mouse cursor update
		if (sendRichCursorEncoding) {
			if (!rfbSendRichCursorUpdate(cl)) {
				rfbLog("Error Sending Cursor\n");
				REGION_UNINIT(&hackScreen,&winRegion);
				REGION_UNINIT(&hackScreen,&updateRegion);
				return FALSE;
			}
		}
		if (sendCursorPositionEncoding) {
			if (!rfbSendCursorPos(cl)) {
				rfbLog("Error Sending Cursor\n");
				REGION_UNINIT(&hackScreen,&winRegion);
				REGION_UNINIT(&hackScreen,&updateRegion);
				return FALSE;
			}
			
		}

//VAO_START UPDATE
//empty, since we are adding
//VAO_BY
//        cl->screenBuffer = rfbGetFramebuffer();
//VAO_END
		
		for (i = 0; i < REGION_NUM_RECTS(&updateRegion); i++) {
			int x = REGION_RECTS(&updateRegion)[i].x1;
			int y = REGION_RECTS(&updateRegion)[i].y1;
			int w = REGION_RECTS(&updateRegion)[i].x2 - x;
			int h = REGION_RECTS(&updateRegion)[i].y2 - y;
			
			//rfbLog("Send Rect %d", i);
//VAO_START UPDATE
//empty, since we are adding
//VAO_BY
//        rfbGetFramebufferUpdateInRect(x,y,w,h);
//VAO_END
			if (cl->scalingFactor != 1)
				CopyScalingRect( cl, &x, &y, &w, &h, TRUE);
//VAO_START UPDATE
//empty, since we are adding
//VAO_BY
//            else
//                cl->scalingFrameBuffer = cl->screenBuffer;
//VAO_END
			
			cl->rfbRawBytesEquivalent += (sz_rfbFramebufferUpdateRectHeader
										  + w * (cl->format.bitsPerPixel / 8) * h);
			
			switch (cl->preferredEncoding) {
				case rfbEncodingRaw:
					if (!rfbSendRectEncodingRaw(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingRRE:
					if (!rfbSendRectEncodingRRE(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingCoRRE:
					if (!rfbSendRectEncodingCoRRE(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingHextile:
					if (!rfbSendRectEncodingHextile(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingZlib:
					if (!rfbSendRectEncodingZlib(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingTight:
					if (!rfbSendRectEncodingTight(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingZlibHex:
					if (!rfbSendRectEncodingZlibHex(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
				case rfbEncodingZRLE:
					if (!rfbSendRectEncodingZRLE(cl, x, y, w, h)) {
						REGION_UNINIT(&hackScreen,&winRegion);
						REGION_UNINIT(&hackScreen,&updateRegion);
						return FALSE;
					}
					break;
			}
		}
		
        if (nUpdateRegionRects == 0xFFFF && !rfbSendLastRectMarker(cl)) {
			REGION_UNINIT(&hackScreen,&winRegion);
			REGION_UNINIT(&hackScreen,&updateRegion);
			return FALSE;
		} 

		if (!rfbSendUpdateBuf(cl))
			return FALSE;
		
		cl->rfbFramebufferUpdateMessagesSent++;
	
	}
	
	if (clearRequestedRegion)
	{
		REGION_UNINIT(&hackScreen, &cl->requestedRegion);
		REGION_INIT(&hackScreen, &cl->requestedRegion,NullBox,0);
	}
	
	if (bResetCursorLocation) cl->clientCursorLocation = currentCursorLoc();
	
	if (bResetCursorType) cl->currentCursorSeed = CGSCurrentCursorSeed();
	
	REGION_UNINIT(&hackScreen,&winRegion);
    REGION_UNINIT(pScreen,&updateRegion);
	

	
    return TRUE;
	
}



@end
