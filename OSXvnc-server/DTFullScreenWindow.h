//
//  DTFullScreenWindow.h
//  Desktop Transporter
//
//  Created by Daniel St¿dle on Wed Mar 31 2004.
//  Copyright (c) 2004  Daniel Stødle, daniels@stud.cs.uit.no. All rights reserved.
//


#ifndef DTFULLSCREENWINDOW_H
#define DTFULLSCREENWINDOW_H

//  Includes
#import <Cocoa/Cocoa.h>


@interface DTFullScreenWindow : NSWindow {
	id		controller;
}
- (void)set_controller:(id)ctrl;

@end

#endif
