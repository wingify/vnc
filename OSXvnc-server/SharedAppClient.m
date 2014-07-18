/*
 * Source File: SharedAppClient.m 
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
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#import "SharedAppClient.h"


@implementation SharedAppClient

-init
{
	return [self initWithRfbClient: nil];
}

-initWithRfbClient:(rfbClientPtr) clientStruct
{
	struct hostent *host;
	struct sockaddr_in addr;
	int addrlen = sizeof(struct sockaddr_in);
	
	[super init];
	cl = clientStruct;
	
	getpeername(cl->sock, (struct sockaddr *)&addr, &addrlen);
	host = gethostbyaddr((char*) &addr.sin_addr, addrlen, AF_INET);
	if (host) 
	{
		name = [[NSString alloc] initWithCString:host->h_name];
	} else {
		name = [[NSString alloc] initWithCString:cl->host];
	}
	
	return self;

}


-(void)dealloc
{
	if (name) [name release];
	[super dealloc];
}

-(void) setName:(NSString*) clientName
{
	[clientName retain];
	[name release];
	name = clientName;
}

-(void) setClient:(rfbClientPtr) clientStruct
{
	cl = clientStruct;
}

-(NSString*) name {	return name; }

-(rfbClientPtr) clientStruct { return cl; }



@end
