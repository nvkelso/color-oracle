#import "KeyableWindow.h"
#import "WindowLevel.h"

@implementation KeyableWindow

- (id)initWithContentRect:(NSRect)contentRect 
				styleMask:(NSWindowStyleMask)aStyle 
				  backing:(NSBackingStoreType)bufferingType 
					defer:(BOOL)flag {	
	
	
    // pass NSBorderlessWindowMask so that the window doesn't have a title bar
    self = [super initWithContentRect:contentRect 
							styleMask:NSBorderlessWindowMask 
							  backing:bufferingType 
								defer:flag];
	if(self) {
		// This next line pulls the window up to the front on top of other 
		// system windows.
		
		// NSFloatingWindowLevel and NSModalPanelWindowLevel do not cover the 
		// dock, which is not what we want.
		// We have to use window level kCGDockWindowLevel (=20) to cover the dock.
		// The dock should be covered, otherwise the user can resize the dock
		// while the simulation window is visible. A gost-dock and the resized
		// dock would be visible in this case.
		// NSMainMenuWindowLevel (=24) is reserved for the application’s main menu,
		// but would cover the dock and not the menu. This is what we want.
		// NSStatusWindowLevel (=25) also covers the menu, which is not what we want.
		// So use kCGDockWindowLevel + 1: this covers the dock but not the menu.
		[self setLevel:	WINDOWLEVEL];
		[self setHasShadow: NO];
		[self setOpaque:YES];
	}
    return self;
}

// a borderless window can't usually accept key events without this.
- (BOOL)canBecomeKeyWindow
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
