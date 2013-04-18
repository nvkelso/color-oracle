#import "ClickableImageView.h"

@implementation ClickableImageView

- (void) setDelegate:(id)d
{
	delegate = d;
}

- (id) delegate
{
	return delegate;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[delegate scrollWheel:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[delegate rightMouseDown:theEvent];
}

-(void)mouseDown:(NSEvent*) evt
{
	[delegate mouseDown:evt];
}

- (void)keyDown:(NSEvent *)theEvent
{
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

// this should accelerate drawing
// http://developer.apple.com/documentation/Performance/Conceptual/Drawing/index.html#//apple_ref/doc/uid/10000151i
- (BOOL)isOpaque
{
	return YES;
}

// this should accelerate drawing
// http://developer.apple.com/documentation/Performance/Conceptual/Drawing/index.html#//apple_ref/doc/uid/10000151i
- (BOOL)wantsDefaultClipping
{
	// no need to clip drawing
	return NO;
}

// added in Color Oracle 1.1.4 for support for retina displays.
- (void)setImage:(NSImage *)image
{
	[self setImageScaling: NSScaleProportionally];
	[super setImage: image];
}

@end