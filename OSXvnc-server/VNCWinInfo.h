/*
 * Source File: VNCWinInfo.h 
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

#ifndef _VNCWININFO_H_
#define _VNCWININFO_H_

#import <Cocoa/Cocoa.h>
#include "CGSPrivate.h"
#include "rfb.h"


@interface VNCWinInfo : NSObject {
	CGSWindow		windowId;
	CGSConnection	connectionId;
	CGRect			location;
	NSString		*processName;		//  name of process owning window
	pid_t			processId;
	CGSConnection	defaultCon;
	CGContextRef window_context;
	CGContextRef bitmap_context;
	char* data;
	int bytesPerRow;
	BOOL doFullUpdate;
	NSDate *lastPixelAccessTime;
	//BOOL validate;
}

-init;
-initWithWindowId: (CGSWindow) wid 
	 connectionId: (CGSConnection) cid;

-(CGSWindow) windowId;
-(CGRect) location;
-(NSString*) processName;
-(int) originX;
-(int) originY;
-(int) width;
-(int) height;
-(int) bytesPerRow;
-(BOOL) validated;
-(char*) getPixelAccess;
-(NSString*) lookupProcessName;
-(BOOL)	doFullUpdate;
-(void) setDoFullUpdate:(BOOL)flag;
-(BOOL) isTopWindow;
-(void) getVisibleRegion:(RegionRec*)visibleRegionPtr;

-(void) setWindowId: (CGSWindow)winid;


/*
-(void) setWindowId: (CGSWindow) wid;
-(void) setConnectionId: (CGSConnection) cid;
-(void) setLocation: (CGRect) loc;
-(void) setName: (CGSWindow) name;
*/
@end

#endif