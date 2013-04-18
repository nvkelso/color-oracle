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
                styleMask:(unsigned int)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
    
    if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask 
								  backing:NSBackingStoreBuffered 
									defer:NO]) {
        [self setLevel: WINDOWLEVEL];
        [self setBackgroundColor: [NSColor clearColor]];
        [self setAlphaValue:1.0];
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

@end
