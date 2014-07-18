/*
 * Source File: SharedAppClient.h 
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

//  Created by Grant Wallace on 10/20/05.
//  Copyright 2005 Princeton University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "rfb.h"

@interface SharedAppClient : NSObject {
	NSString *name;
	rfbClientPtr cl;
}
-init;
-initWithRfbClient:(rfbClientPtr) clientStruct;
-(void) setName:(NSString*) clientName;
-(void) setClient:(rfbClientPtr) clientStruct;
-(NSString*) name;
-(rfbClientPtr) clientStruct;

@end
