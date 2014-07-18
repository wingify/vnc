/*  CGS-Private.h
	
	Other private CG defs.
*/

#ifndef CGS_WE_PRIVATE_H
#define CGS_WE_PRIVATE_H

//  Includes
#include	<Carbon/Carbon.h>
#include	"CGSPrivate.h"

//  Functions
extern OSStatus CGSGetWindowCount(const CGSConnection cid, CGSConnection targetCID, int* outCount); 
extern OSStatus CGSGetWindowList(const CGSConnection cid, CGSConnection targetCID, int count, int* list, int* outCount);

extern OSStatus CGContextCopyWindowContentsToRect(const CGContextRef cref, const CGRect size, const CGSConnection, const CGSWindow wid);
//extern OSStatus CGContextCopyDisplayContentsToRect(int, CGRect r, ...);

/*  CGSGetSharedWindow:
	cid:		Connection of the calling app (_CGSDefaultConnection())
	wid:		Window id of window that we want shared access to
	unknown:	Passing in 1 here seems to do the trick
	unknown2:   0 works
*/
extern OSStatus CGSGetSharedWindow(const CGSConnection cid, const CGSWindow wid, int unknown, int unknown2);

/*  CGWindowContextCreate:
	Creates a context based on contents of the window referenced by wid. If wid is not owned by the calling
	process, the window needs to be shared (using CGSSharedWindow) first.
	cid:	Connection of the calling app (_CGSDefaultConnection())
	wid:	ID of window forming the basis of the new context
	area:   Area of the window we're interested in capturing
*/
extern CGContextRef CGWindowContextCreate(const CGSConnection cid, const CGSWindow wid, const CGRect area);

/*  CGContextGetPixelAccess:
	Gets pixel access to the given context.
*/
extern uint32_t*	CGContextGetPixelAccess(const CGContextRef cref); //, const CGSWindow wid);

/*  CGPixelAccessLock, Unlock:
	Locks and unlocks pixel access.

	pixel:  Value returned from CGContextGetPixelAccess.
*/
extern OSStatus		CGPixelAccessLock(uint32_t *pixel);
extern OSStatus		CGPixelAccessUnlock(uint32_t *pixel);

/*  CGPixelAccessCreateImageFromRect:
	Creates an image using the passed-in pixel data (obtained using CGContextGetPixelAccess),
	having the specified size.
	pixel:  The pixels
	size:   Size of resulting image (?)
*/
extern CGImageRef   CGPixelAccessCreateImageFromRect(uint32_t* pixel, const CGRect size);

extern OSStatus		CGSSetDebugOptions(uint32_t opts);

/*  CGSFindWindowAndOwner:
	cid:		Connection id of calling application
	unknown1:   Should be 0
	unknown2:   Should be 1
	unknown3:   Should be 0
	loc:		Location on screen to probe
	unknown4:   No clue
	window_id:  ID of window found at loc
	connection_id:  ID of connection owning window at loc
*/
extern OSStatus		CGSFindWindowAndOwner(const CGSConnection cid, int unknown1, int unknown2, int unknown3, CGPoint *loc, uint32_t *unknown4, CGSWindow *window_id, CGSConnection *connection_id);

#endif
