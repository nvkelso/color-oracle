//
//  TransparentWindow.m
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
//


#import "TransparentWindow.h"
#import "WindowLevel.h"

@implementation TransparentWindow

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(NSWindowStyleMask)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
    
    // Using NSBorderlessWindowMask results in a window without a title bar.
    if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask 
								  backing:NSBackingStoreBuffered 
									defer:NO]) {
        [self setLevel: WINDOWLEVEL];
        
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:1.0];
        //Set backgroundColor to clearColor
        self.backgroundColor = NSColor.clearColor;
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
        
        [self setHasShadow:YES];
        return self;
    }
    
    return nil;
}

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (BOOL)acceptsFirstResponder:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (NSRect)constrainFrameRect:(NSRect)frameRect
                    toScreen:(NSScreen *)screen
{
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    if (frameRect.origin.x < 0) {
        frameRect.origin.x = 0;
    }
    if (frameRect.origin.x + frameRect.size.width > screenFrame.size.width) {
        frameRect.origin.x = screenFrame.origin.x + screenFrame.size.width - frameRect.size.width;
    }
    if (frameRect.origin.y < 0) {
        frameRect.origin.y = 0;
    }

    return [super constrainFrameRect: frameRect toScreen: screen];
}

@end
