/*
 * Source File: VNCWinInfo.m 
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

#import "VNCWinInfo.h"
#include "CGS-Private.h"


@implementation VNCWinInfo

-init
{
	return [self initWithWindowId: -1 connectionId: -1];
}

-(void)dealloc
{
	if (data) free(data);
	if (bitmap_context) CGContextRelease(bitmap_context);
	if (processName) [processName release];
	[super dealloc];
}


-initWithWindowId: (CGSWindow) wid 
	 connectionId: (CGSConnection) cid
{
	[super init];
	
	defaultCon = _CGSDefaultConnection();
	windowId = wid;
	connectionId = cid;
	
	data = 0;
	window_context = 0;
	bitmap_context = 0;
	processName = 0;
	doFullUpdate = TRUE;
	//validate = TRUE;
	lastPixelAccessTime = [NSDate date]; //dateWithTimeIntervalSinceReferenceDate:0];

	CGSConnectionGetPID(cid, &processId, defaultCon);
	processName = [self lookupProcessName]; // @"Unknown";

	// setup up for shared access
	CGSGetSharedWindow(defaultCon, windowId, 1, 0);
	
	return self;
}


-(CGSWindow) windowId {	return windowId; }
-(CGRect) location { return location; }
-(int) originX { return location.origin.x; }
-(int) originY { return location.origin.y; }
-(int) width { return location.size.width; }
-(int) height { return location.size.height; }
-(int) bytesPerRow { return bytesPerRow; }
-(NSString*) processName { return processName; }

-(void) setWindowId: (CGSWindow)winid
{
	windowId = winid;
	
}


-(NSString*) lookupProcessName{
	ProcessSerialNumber psn;
	ProcessInfoRec		p_info;
	const int			maxLen = 127;
	char				name[maxLen+1];
	
	if (GetProcessForPID(processId, &psn) != noErr) {
		printf("Warning: Failed to get process serial num for pid %d\n", processId);
		return 0;
	}
	memset(&p_info, 0, sizeof(ProcessInfoRec));
	memset(name, 0, maxLen+1);
	p_info.processInfoLength	= sizeof(ProcessInfoRec);
	p_info.processName			= name;
	if (GetProcessInformation(&psn, &p_info) != noErr) {
		printf("Warning: Failed to get process info pid %d/psn %d\n", processId, *(int*)&psn);
		return 0;
	}
	return [[NSString alloc] initWithCString:name];
}

//VAO_START
- (BOOL)relookForWindow{
    //rfbLog("RELOOK called. current id = %d", windowId);
    CFArrayRef arr = CGWindowListCreate(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    
    CFArrayRef info = CGWindowListCreateDescriptionFromArray(arr);
    int infoCount = CFArrayGetCount(info);
    for(int i = 0; i < infoCount; i++){
        CFDictionaryRef infoDic = (CFDictionaryRef) CFArrayGetValueAtIndex(info, i);
        int w_owner_pid = [(NSNumber *) CFDictionaryGetValue(infoDic, kCGWindowOwnerPID) integerValue];
        NSString *w_owner_name = (NSString *) CFDictionaryGetValue(infoDic, kCGWindowOwnerName);
        if([w_owner_name isEqualToString:@"iOS Simulator"]){
            NSString *w_name = (NSString *) CFDictionaryGetValue(infoDic, kCGWindowName);
            if(w_name && w_name.length > 0){
                int w_id = [(NSNumber *) CFDictionaryGetValue(infoDic, kCGWindowNumber) integerValue];
                
                windowId = w_id;
                processId = w_owner_pid;
                doFullUpdate = TRUE;
                //rfbLog("RELOOK found new window. id = %d", windowId);
                return TRUE;
            }
        }
    }
    return FALSE;
}
//VAO_END

-(BOOL) validated
{
	OSStatus status;
	CGRect vloc;
	
	status = CGSGetScreenRectForWindow(defaultCon, windowId, &vloc);
	if (status != noErr)  
	{
		printf("Validation Error\n");

//VAO_START REPLACE
//		return FALSE;
//VAO_BY
        BOOL isOK = [self relookForWindow];
        if(isOK){
            status = CGSGetScreenRectForWindow(defaultCon, windowId, &vloc);
            if (status != noErr)
                return FALSE;
        }
		else return FALSE;
//VAO_END

	}
	
//VAO_START ADD
// hack to remove title bar from window
    vloc.origin.y += 22;
    vloc.size.height -= 22;
//VAO_END

	if (vloc.size.width != location.size.width || vloc.size.height != location.size.height ||
		vloc.origin.x != location.origin.x || vloc.origin.y != location.origin.y)
	{
		CGColorSpaceRef color_space;
		int depth=32;
		int bitsPerComponent = 8;
//VAO_START REPLACE
//        NSLog(@"Get New bitmap_context");
//VAO_BY
		NSLog(@"Get New bitmap_context. old=%@, new=%@", NSStringFromRect(*(NSRect*)&location), NSStringFromRect(*(NSRect*)&vloc));
//VAO_END

		if (data) { free(data); data = 0; }
		if (bitmap_context) { CGContextRelease(bitmap_context); bitmap_context = 0; }
		
		bytesPerRow =  vloc.size.width * (depth / 8);
	
		data = malloc(bytesPerRow * vloc.size.height);
		color_space	= CGColorSpaceCreateDeviceRGB();
//VAO_START REPLACE
//        bitmap_context = CGBitmapContextCreate(data, vloc.size.width, vloc.size.height, bitsPerComponent, bytesPerRow, color_space, kCGImageAlphaNoneSkipFirst);
//VAO_BY
// The implicit bitmapByteOrder is kCGBitmapByteOrderDefault (because it's value is 0). However, it is causing XRGB of `kCGImageAlphaNoneSkipFirst` to be interpreted as BGRX. Explicitly adding `kCGBitmapByteOrder32Host` fixes the issue.
		bitmap_context = CGBitmapContextCreate(data, vloc.size.width, vloc.size.height, bitsPerComponent, bytesPerRow, color_space, kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder32Host);
//VAO_END
		CGColorSpaceRelease(color_space);
	}
	location = vloc;
	//rfbLog("win %d location (%.0f %.0f) size (%.0f %.0f)", windowId, location.origin.x, location.origin.y, location.size.width, location.size.height);
	return TRUE;
}


-(BOOL)	doFullUpdate
{
	return doFullUpdate;
}

-(void) setDoFullUpdate:(BOOL)flag
{
	doFullUpdate = flag;
}


-(BOOL) isTopWindow
{
	int workspace, window, retCount;
	OSStatus status;
	
	status =  CGSGetWorkspace(defaultCon, &workspace);
	if (status != noErr) { rfbLog("GetWindowWorkspace Error"); return FALSE; }
	
	status = CGSGetWorkspaceWindowList(defaultCon, workspace, 1, &window, &retCount);
	if (status != noErr) { rfbLog("GetWorkspaceWindowList Error"); return FALSE; }
	
	if (window == windowId) return TRUE;
	else return FALSE;
}

-(void) getVisibleRegion:(RegionRec*)visibleRegionPtr
{
	// loop through all windows - union the screen locations of windows that are above this window
	// subtract union from this window's screen space.
	#define MAX_WINDOW_COUNT 512
	int workspace, windowCount, i;
	int windowList[MAX_WINDOW_COUNT];
	RegionRec unionRegion, winRegion;
	BoxRec box;
	CGRect rect;
	OSStatus status;
	
	REGION_EMPTY(&hackScreen, visibleRegionPtr);
	
	status =  CGSGetWorkspace(defaultCon, &workspace);
	if (status != noErr) { rfbLog("GetWindowWorkspace Error"); return; }
	
//VAO_START REPLACE
//	status = CGSGetWorkspaceWindowCount(defaultCon, workspace, &windowCount);
//	if (status != noErr) { rfbLog("GetWorkspaceCount Error"); return; }
//	
//	windowCount = (MAX_WINDOW_COUNT > windowCount) ? windowCount : MAX_WINDOW_COUNT;
//	
//	status = CGSGetWorkspaceWindowList(defaultCon, workspace, windowCount, windowList, &windowCount);
//	if (status != noErr) { rfbLog("GetWorkspaceWindowList workspace %d windowCount %d Error, %d", workspace, windowCount, status); return; }
//VAO_BY

// not working
//    windowCount = 0;
//    NSCountWindows(&windowCount);
//    rfbLog("window count NSCountWindows: %d", windowCount);
//    NSArray *lst = [NSWindow windowNumbersWithOptions:NSWindowNumberListAllApplications|NSWindowNumberListAllSpaces];
//    rfbLog("window count windowNumbersWithOptions: %s, %d", [[lst description] UTF8String], [lst count]);

// `kCGWindowListOptionAll` gives hidden windows as well as windows on other workspaces.
// `kCGWindowListOptionOnScreenOnly` gives only visible windows on currently visible workspace
//    CFArrayRef arr = CGWindowListCreate(kCGWindowListOptionAll | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    CFArrayRef arr = CGWindowListCreate(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    windowCount = CFArrayGetCount(arr);
    BOOL windowFound = FALSE;
    for(int i = 0; i < windowCount; i++){
        CGWindowID winId = (CGWindowID) CFArrayGetValueAtIndex(arr, i);
        windowList[i] = winId;
        if(winId == windowId)
            windowFound = TRUE;
    }
    
    if(!windowFound){
        [self relookForWindow];
    }
//    rfbLog("window count CGWindowListCreate: %d", CFArrayGetCount(arr));
    
//    CFArrayRef info = CGWindowListCreateDescriptionFromArray(arr);
//    int infoCount = CFArrayGetCount(info);
//    for(int i = 0; i < infoCount; i++){
//        CFDictionaryRef infoDic = (CFDictionaryRef) CFArrayGetValueAtIndex(info, i);
//        int w_id = [(NSNumber *) CFDictionaryGetValue(infoDic, kCGWindowNumber) integerValue];
//        char *w_name = [(NSString *) CFDictionaryGetValue(infoDic, kCGWindowName) cString];
//        char *w_owner_name = [(NSString *) CFDictionaryGetValue(infoDic, kCGWindowOwnerName) cString];
//        CFBooleanRef w_onscr_x = (CFBooleanRef) CFDictionaryGetValue(infoDic, kCGWindowIsOnscreen);
//        char *w_onscr = w_onscr_x != NULL ? (CFBooleanGetValue(w_onscr_x) ? "yes" : "no") : "n/a";
//        int w_owner_pid = [(NSNumber *) CFDictionaryGetValue(infoDic, kCGWindowOwnerPID) integerValue];
//        int w_layer = [(NSNumber *) CFDictionaryGetValue(infoDic, kCGWindowLayer) integerValue];
//        CGRect w_rect_x;
//        bool w_rect_ok = CGRectMakeWithDictionaryRepresentation((CFDictionaryRef) CFDictionaryGetValue(infoDic, kCGWindowBounds), &w_rect_x);
//        char *w_rect = w_rect_ok ? [[NSString stringWithFormat:@"(%d,%d,%d,%d)", (int) w_rect_x.origin.x, (int) w_rect_x.origin.y, (int) w_rect_x.size.width, (int) w_rect_x.size.height] cString] : "error";
//        
//        if(windowId == w_id){
//        rfbLog("window(%d): id = %d, name = %s, owner = %s, onScreen = %s, owner_pid = %d, layer = %d, rect = %s", windowId, w_id, w_name, w_owner_name, w_onscr, w_owner_pid, w_layer, w_rect);
//        }
//        
//        int propCount = CFDictionaryGetCount(infoDic);
//        void *keys[1024], *values[1024];
//        CFDictionaryGetKeysAndValues(infoDic, keys, values);
//        for(int j = 0; j < propCount; j++){
//            if(i == infoCount - 1)
//                rfbLog("win %d: %s = %d", w_id, [(NSString *)(keys[j]) cString], 0);
//        }
//    }
//VAO_END

	REGION_INIT(&hackScreen, &unionRegion, NullBox, 0);
	REGION_INIT(&hackScreen, &winRegion, NullBox, 0);	
	
	for (i=0; i<windowCount; i++)
	{

		// window level is like the first bit (dock, menu, modal, normal etc.)
		//status = CGSGetWindowLevel(defaultCon, windowList[i], &windowLevel);
   
		status = CGSGetScreenRectForWindow(defaultCon, windowList[i], &rect);
		if (status != noErr) { rfbLog("GetScreenRectForWindow Error"); return; }
		//rfbLog("WINDOW %d Level %d x %.0f y %.0f w %.0f h %.0f", windowList[i], windowLevel,
		//	   rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
		
		box.x1 = rect.origin.x;
		box.y1 = rect.origin.y;
		box.x2 = box.x1 + rect.size.width;
		box.y2 = box.y1 + rect.size.height;
		
//VAO_START ADD
// hack to remove title bar from window
        box.y1 += 22;
        // no need to update y2 (y2 is different from height)
//VAO_END

		REGION_RESET(&hackScreen, &winRegion, &box);
		if (windowList[i] != windowId)
		{
//VAO_START HACK
// comment out this block to ensure hidden regions of window are also updated.
// if this is done, any overlapping portion of other windows will be visible remotely.
			// union all higher level windows
//			REGION_UNION(&hackScreen, &unionRegion, &unionRegion, &winRegion);
//VAO_END
		} else {
			// subtract higher level windows region from window region
			REGION_SUBTRACT(&hackScreen, visibleRegionPtr, &winRegion, &unionRegion);	
			break;
		}
	}
	REGION_UNINIT(&hackScreen, &unionRegion);
	REGION_UNINIT(&hackScreen, &winRegion);
	return;
}

//VAO_START
//Modeled after `rfbGetFramebufferUpdateInRect` as that function does the corresponding work in normal VNC
-(char*) getPixelAccess
{
    if (![self validated]) return NULL;
    
    int x = location.origin.x;
    int y = location.origin.y;
    int w = location.size.width;
    int h = location.size.height;
    
    CGDirectDisplayID mainDisplayID = CGMainDisplayID();
    CGRect rect = CGRectMake (x,y,w,h);
    CGImageRef imageRef = CGDisplayCreateImageForRect(mainDisplayID, location);
    CGDataProviderRef dataProvider = CGImageGetDataProvider (imageRef);
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    int imgBytesPerRow = CGImageGetBytesPerRow(imageRef);
    int imgBitsPerPixel = CGImageGetBitsPerPixel(imageRef);
		
    if (imgBitsPerPixel != 32)
        rfbLog("getPixelAccess: BitsPerPixel MISMATCH: frameBuffer %d, rect image %d", 32, imgBitsPerPixel);

// This happens!!!
//    if (imgBytesPerRow != bytesPerRow)
//        rfbLog("bytesPerRow MISMATCH: frameBuffer %d, rect image %d. w = %d, 4w = %d, %d, %d %d", bytesPerRow, imgBytesPerRow, w, 4*w, CGImageGetWidth(imageRef), CFDataGetLength(dataRef), h);

// Manual copying of bytes as done in original code of `rfbGetFramebufferUpdateInRect` doesn't work here.
// Instead, the method used in original `getPixelAccess` works. So, we use that.
    CGRect scr = location;
	scr.origin.x = scr.origin.y = 0;
    CGContextDrawImage(bitmap_context, scr, imageRef);
    CGImageRelease(imageRef);
    [(id)dataRef release];
    return data;
    
//    x = y = 0;
//    char *dest = (char *)[frameBufferData mutableBytes] + frameBufferBytesPerRow * y + x * (frameBufferBitsPerPixel/8);
//    char *dest = data;
//    const char *source = [(NSData *)dataRef bytes];
//    return source;
//		
//    while (h--) {
//        memcpy(dest, source, w*(imgBitsPerPixel/8));
//        dest += bytesPerRow;//frameBufferBytesPerRow;
//        source += imgBytesPerRow;
//    }
//    return dest;
//    if (imageRef != NULL)
//        CGImageRelease(imageRef);
//    return dest;
//    [(id)dataRef release];
//    return dest;
}
//VAO_END

//VAO_START REPLACE
//-(char*) getPixelAccess
//VAO_BY
// new definition written above
-(char*) getPixelAccess1
//VAO_END
{
	CGImageRef image = 0;
	uint32_t *pixel;
	OSStatus status;
	CGRect scr;
	CGRect vloc;
	char *retval = NULL;
	NSTimeInterval secondsElapsed;
	double mintime = 0.05;
	
	if (![self validated]) return NULL;
	
	//[accessLock lock]
		//secondsElapsed = [[NSDate date] timeIntervalSinceDate:lastPixelAccessTime];
		//if (secondsElapsed > mintime) lastPixelAccessTime = [NSDate date];
	//[accessLock unlock]
	//if (secondsElapsed < mintime) return data;
	
	
	scr = location;
	scr.origin.x = scr.origin.y = 0;
	
	window_context = CGWindowContextCreate(defaultCon, windowId, scr);
	if (window_context)
	{
		pixel = CGContextGetPixelAccess(window_context);
		if (pixel) 
		{
			status = CGPixelAccessLock(pixel);
			if (status != 0) 
			{
				// double check that size of position haven't changed
				status = CGSGetScreenRectForWindow(defaultCon, windowId, &vloc);
				if (status == noErr) 
				{
					if (vloc.size.width == location.size.width && vloc.size.height == location.size.height &&
						vloc.origin.x == location.origin.x && vloc.origin.y == location.origin.y)
					{
						image = CGPixelAccessCreateImageFromRect(pixel, scr);
						if (image) 
						{
							CGContextDrawImage(bitmap_context, scr, image);
							CGImageRelease(image);
							retval = data;
						} else {
							NSLog(@"getPixelAccess: createImage failed");
						}
					} else {
						NSLog(@"getPixelAccess: size/location changed");
					}
				} else {
					NSLog(@"getPixelAccess: screenRect failed");
				}
				status = CGPixelAccessUnlock(pixel);
			} else {
				NSLog(@"getPixelAccess: pixel lock failed");
			}
		} else {
			NSLog(@"getPixelAccess: pixel access failed");
		}
		CGContextRelease(window_context);
		window_context = 0;
	} else {
		NSLog(@"getPixelAccess: windowContext failed");
	}
	
	return retval;
}



@end
