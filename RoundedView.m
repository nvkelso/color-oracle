//
//  RoundedView.m
//  RoundedFloatingPanel
//


#import "RoundedView.h"

// text size 
#define TEXTSIZE 32
#define INFOTEXTSIZE1 16
#define INFOTEXTSIZE2 12

#define V_TITLEOFFSET 5

// horizontal and vertical offset of the lower info text
#define H_INFOTEXTOFFSET1 20
#define V_INFOTEXTOFFSET1 50

#define H_INFOTEXTOFFSET2 50
#define V_INFOTEXTOFFSET2 105

#define BOXCORNERRADIUS 15
#define BOXTRANSPARENCY 0.6

// drop shadow of text
#define SHADOWOFFSET 3
#define SHADOWBLURRADIUS 2
#define SHADOWTRANSPARENCY 0.5

#define MINHEIGHT  65
#define MEDIUMHEIGHT  120

@implementation RoundedView

- (void)awakeFromNib
{
	draggingWindow = NO;
	fullHeight = [self frame].size.height;
	enlargingWindow = NO;
}

- (void) setDelegate:(id)d
{
	delegate = d;
}

- (id) delegate
{
	return delegate;
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (delegate != nil)
		[delegate keyDown:theEvent];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

-(void)drawText:(NSRect)rect
{
	NSMutableDictionary * attrs = [NSMutableDictionary dictionary];
	
	// drop shadow for text
	NSShadow *shadow = [[NSShadow alloc] autorelease];
	[shadow setShadowOffset:NSMakeSize(SHADOWOFFSET, -SHADOWOFFSET)];
	[shadow setShadowBlurRadius:SHADOWBLURRADIUS];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:SHADOWTRANSPARENCY]];
	[attrs setObject: shadow forKey: NSShadowAttributeName];
	
	// main text font
	NSFont *font = [NSFont systemFontOfSize:TEXTSIZE];
	[attrs setObject: font forKey: NSFontAttributeName];
	
	// text color
	[attrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	
	// text alignment
	NSMutableParagraphStyle *pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[pStyle autorelease];
	[pStyle setAlignment:NSCenterTextAlignment];
	[attrs setValue: pStyle forKey: NSParagraphStyleAttributeName];
		
    bool drawInfoText1 = rect.size.height >= MEDIUMHEIGHT;
    bool drawInfoText2 = rect.size.height >= fullHeight - 5;
    
	// draw main text
    rect.size.height -= V_TITLEOFFSET;
	[title drawInRect:rect withAttributes: attrs];
	
	// info text 1
	font = [NSFont systemFontOfSize:INFOTEXTSIZE1];
	[attrs setObject: font forKey: NSFontAttributeName];
	[attrs removeObjectForKey:NSShadowAttributeName];
	
	// draw info text 1
	if (drawInfoText1) {
		rect.size.height -= V_INFOTEXTOFFSET1;
		[info1 drawInRect:rect withAttributes: attrs];
		rect.size.height += V_INFOTEXTOFFSET1; // reset rectangle height
	}
	
	// draw info text 2
	font = [NSFont systemFontOfSize:INFOTEXTSIZE2];
	[attrs setObject: font forKey: NSFontAttributeName];
	if (drawInfoText2) {
		rect.size.height -= V_INFOTEXTOFFSET2;
		[info2 drawInRect:rect withAttributes: attrs];
	}
}	

- (void)drawRect:(NSRect)rect
{
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    
    int minX = NSMinX(rect);
    int midX = NSMidX(rect);
    int maxX = NSMaxX(rect);
    int minY = NSMinY(rect);
    int midY = NSMidY(rect);
    int maxY = NSMaxY(rect);
    float radius = BOXCORNERRADIUS; // 25 is correct value to duplicate Panther's App Switcher
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:[self frame].origin
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:BOXTRANSPARENCY];
    [bgColor setFill];
    [bgPath fill];
	
	[self drawText: rect];
	
    // We need to invalidate window shadow for a window with transparent parts, after drawing
    // The shadow is computed from the opaque (or mostly-opaque) parts and therefore depends on what gets drawn.
    // If shadow is not recomputed, ghost labels will be visible.
    [[self window] invalidateShadow];
}

- (void) setTitle:(NSString*)t
{
	[t retain];
	[title release];
	title = t;
    [self setNeedsDisplay:YES];
}

- (void) setInfo1:(NSString*)i
{
	[i retain];
	[info1 release];
	info1 = i;
    [self setNeedsDisplay:YES];
}

- (void) setInfo2:(NSString*)i
{
	[i retain];
	[info2 release];
	info2 = i;
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[delegate scrollWheel:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[delegate rightMouseDown:theEvent];
}

// resizes the info dialog
// returns a button state for the resize button
- (NSControlStateValue) resizeInfo
{
    NSRect windowFrame = [[self window] frame];
    if (windowFrame.size.height == fullHeight) {
        enlargingWindow = NO;
        windowFrame.size.height = MEDIUMHEIGHT;
    } else if (windowFrame.size.height > MEDIUMHEIGHT) {
        if (enlargingWindow == YES)
            windowFrame.size.height = fullHeight;
        else
            windowFrame.size.height = MEDIUMHEIGHT;
    } else if (windowFrame.size.height > MINHEIGHT) {
        if (enlargingWindow == YES) {
            windowFrame.size.height = fullHeight;
        } else {
            windowFrame.size.height = MINHEIGHT;
        }
    } else if (windowFrame.size.height == MINHEIGHT) {
        enlargingWindow = YES;
        windowFrame.size.height = MEDIUMHEIGHT;
    }
    
    // Before macOS 10.9, windows without a title bar could cover the menu bar.
    // Color Oracle before v1.1.5 had some extra code here to fix this, however,
    // this code did not work properly with some versions of macOS.
    // Color Oracle 1.1.5 now requires macOS 10.9 to avoid this problem.
    // See "NSWindows constrained to not intersect the menu bar" of 10.9 AppKit Release Notes
    
    [[self window] setFrame:windowFrame display:YES animate:YES];
    
    // button state for resize button: the button status should indicate the direction in which the window will grow or shrink
    NSControlStateValue state;
    if (windowFrame.size.height == fullHeight)
        state = NSOnState;
    else if (windowFrame.size.height == MINHEIGHT) {
        state = NSOffState;
    } else {
        // medium size
        state = enlargingWindow ? NSOffState : NSOnState;
    }
    return state;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (draggingWindow == NO) {
		if (delegate != nil)
			[delegate mouseUp:theEvent];
	}
	draggingWindow = NO;
}

- (void)mouseDragged:(NSEvent *)event
{
    // Before macOS 10.9, windows without a title bar could cover the menu bar.
    // Color Oracle before v1.1.5 had some extra code here to fix this, however,
    // this code did not work properly with some versions of macOS.
    // Color Oracle 1.1.5 now requires macOS 10.9 to avoid this problem.
    // See "NSWindows constrained to not intersect the menu bar" of 10.9 AppKit Release Notes
    
    // start new dragging
	if (draggingWindow == NO)
	{
		draggingWindow = YES;
		
        initialWindowFrame = [[self window] frame];
		// mouse location in global coordinates
        dragInitialLocation = [NSEvent mouseLocation];
		initialVOffset = dragInitialLocation.y - initialWindowFrame.origin.y;
		dragInitialLocation.x -= initialWindowFrame.origin.x;
		dragInitialLocation.y -= initialWindowFrame.origin.y;
		return;
	}
    
    // continue dragging
    if (draggingWindow == YES) {
		NSPoint currentLocation;
		NSPoint newOrigin;
        
		// mouse location in global coordinates
        currentLocation = [NSEvent mouseLocation];
		newOrigin.x = currentLocation.x - dragInitialLocation.x;
		newOrigin.y = currentLocation.y - dragInitialLocation.y;
		[[self window] setFrameOrigin:newOrigin];
	}
}

@end
