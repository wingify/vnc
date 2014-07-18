/*
 * Source File: SharedApp.h 
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

#ifndef _SHAREDAPP_H_
#define _SHAREDAPP_H_

#import <Cocoa/Cocoa.h>
#import "VNCWinInfo.h"
#import	"DTFullScreenWindow.h"
#include "rfb.h"

extern Bool rfbDisableScreenSaver;


@interface SharedApp : NSObject {
//	IBOutlet NSWindow *window;
//	IBOutlet NSPanel  *preferencePanel;
//	IBOutlet NSPanel  *sshTunnelPanel;
//    // Main window
//	IBOutlet NSButton *buttonUnshare;
//	IBOutlet NSButton *buttonUnshareAll;
//	IBOutlet NSButton *buttonSelectToShare;
//	IBOutlet NSTableView *tableSharedWindows;
//	IBOutlet NSTableView *tableConnectedClients;
//	IBOutlet NSComboBox *comboboxConnectToClient;
//	// preferences panel
//	IBOutlet NSButton *buttonEnable;
//	IBOutlet NSButton *buttonPreventDimming;
//    IBOutlet NSButton *buttonPreventSleeping;
//	IBOutlet NSButton *buttonAutorunViewer;
//    IBOutlet NSButton *buttonSwapMouseButtons;
//    IBOutlet NSButton *buttonDisableRemoteEvents;
//    IBOutlet NSButton *buttonLimitToLocalConnections;
//	IBOutlet NSTextField *textfieldPassword;
//	IBOutlet NSTextField *textfieldViewerStatus;
//    // ssh tunnel panel
//	IBOutlet NSMatrix *radioButtonTunnelType;
//	IBOutlet NSTextField *textfieldLocalPort;
//	IBOutlet NSTextField *textfieldRemotePort;
//	IBOutlet NSTextField *textfieldHostString;
//	IBOutlet NSTextField *textfieldUsername;
//	IBOutlet NSButton *buttonSSHGatewayOnly;
//	IBOutlet NSTableView *tableSshTunnels;
//    // data
//	NSString *passwordFile;
//	NSString *viewerLogFile;
	NSLock *arrayLock;
//	NSLock *pixelLock;
	NSMutableArray *sharedWindowsArray;
	NSMutableArray *windowsToBeClosedArray;
	NSMutableArray *connectedClientsArray;
//	NSMutableArray *prevClientsArray;
//	NSMutableArray *tunnelArray;
//	NSTask *viewerTask;
//    NSFileHandle *serverOutput;
//    NSString *pathToAuthentifier;
	DTFullScreenWindow	*cover_window;
	BOOL enabled;
}

//// actions
//// Main window
//- (IBAction) actionShowPreferencePanel:(id)sender;
//- (IBAction) actionShowSshTunnelPanel:(id)sender;
//- (IBAction) actionSelectWindow: (id)sender;
//- (IBAction) actionHideSelected: (id)sender;
//- (IBAction) actionHideAll: (id)sender;
//- (IBAction) actionConnectToClient: (id)sender;
//- (IBAction) actionDisconnectClient: (id)sender;
//- (IBAction) actionStartViewer: (id)sender;
//- (IBAction) actionStopViewer: (id)sender;
//- (IBAction) actionCloseTunnel: (id)sender;
//// preferences panel
//-(IBAction) changeSharing:(id)sender;
//-(IBAction) changePassword:(id)sender;
//-(IBAction) changeDimming:(id)sender;
//-(IBAction) changeSleep:(id)sender;
//-(IBAction) changeAutorunViewer:(id)sender;
//-(IBAction) changeSwapMouse:(id)sender;
//-(IBAction) changeDisableRemoteEvents:(id)sender;
//-(IBAction) changeLimitLocal:(id)sender;
//// SSH tunnel panel
//- (IBAction) actionTunnelConnect: (id)sender;
//- (IBAction) actionTunnelCancel: (id)sender;
//
//// preferences panel - helper functions
//-(void) setNoSleep:(BOOL)flag;
//-(void) setNoDimming:(BOOL)flag;
//-(void) setAutorunViewer:(BOOL)flag;
//-(void) setLimitLocal:(BOOL) flag;
//-(void) setDisableRemoteEvents:(BOOL) flag;
//-(void) setSwapMouse:(BOOL) flag;
-(void) setEnabled: (BOOL)flag;
//
//	// table data source
//- (int) numberOfRowsInTableView : (NSTableView*)table;
//- (id) tableView:(NSTableView*)table objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex;

// data access

- (BOOL) enabled;

//// other
//- (void) applicationWillTerminate: (NSNotification *) notification;
//- (void) viewerStopped: (NSNotification *) aNotification;
//- (void) tunnelStopped: (NSNotification *) aNotification;
//- (void) loadUserDefaults: (id)sender;
//- (BOOL) canWriteToFile: (NSString *) path;
- (void) finish_select:(CGPoint)loc;
- (void) addClient: (rfbClientPtr)cl;
- (void) removeClient: (rfbClientPtr)cl;
//
//- (void) refreshAllWindows;
//- (void) refreshWindow:(VNCWinInfo*)win;
- (VNCWinInfo*) getWindowWithId:(int)wid;
- (void) getSharedRegions:(RegionRec*)sharedRegionPtr;
- (BOOL) areWindowsToClose;
//- (void) resetClientRequestedArea;
- (void) checkForClosedWindows;
- (BOOL) rfbSendUpdates:(rfbClientPtr)cl screenRegion:(RegionRec)screenUpdateRegion;
@end

#endif