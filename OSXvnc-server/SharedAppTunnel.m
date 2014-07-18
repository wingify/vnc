//
//  SharedAppTunnel.m
//  OSXvnc
//
//  Created by Grant Wallace on 2/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SharedAppTunnel.h"


@implementation SharedAppTunnel

-init
{
	return [self initWithTask: nil name:nil tag:nil direction:nil];
}

-initWithTask:(NSTask*) _task
		 name:(NSString*) _name
		  tag:(NSString*) _tag
	direction:(NSString*) _dir
{
	[super init];
	
	task = _task;	
	name = _name;
	tag = _tag;
	direction = _dir;
	
	if (task) [task retain];	
	if (name) [name retain];
	if (tag) [tag retain];
	if (direction) [direction retain];

	
	return self;
	
}


-(void)dealloc
{
	if (task) [task release];
	if (name) [name release];
	if (tag) [tag release];
	if (direction) [direction release];
	task = nil;
	name = nil;
	tag = nil;
	direction = nil;
}

-(NSString*) name
{
	return name;
}

-(NSString*) tag
{
	return tag;
}

-(NSString*) direction
{
	return direction;
}

-(NSTask*) task
{
	return task;
}

@end
