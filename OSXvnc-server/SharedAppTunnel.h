//
//  SharedAppTunnel.h
//  OSXvnc
//
//  Created by Grant Wallace on 2/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SharedAppTunnel : NSObject {
	NSTask *task;
	NSString *name;
	NSString *tag;
	NSString *direction;
}
-initWithTask:(NSTask*) _task
		 name:(NSString*) _name
		  tag:(NSString*) _tag
	direction:(NSString*) _dir;

-(NSString*) name;
-(NSString*) tag;
-(NSString*) direction;
-(NSTask*) task;

@end
