//
//  RoundedView.h
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
//


#import <Cocoa/Cocoa.h>

@interface RoundedView : NSView
{
	id delegate;
	NSString *title;
	NSString *info1;
	NSString *info2;
	BOOL draggingWindow;
    NSPoint dragInitialLocation;
	NSRect initialWindowFrame;
	int fullHeight;
	int initialVOffset;
	BOOL enlargingWindow;
}

- (void) setDelegate:(id)d;
- (id) delegate;
- (NSControlStateValue) resizeInfo;
- (void) setTitle:(NSString*)t;
- (void) setInfo1:(NSString*)i;
- (void) setInfo2:(NSString*)i;
- (BOOL) isValidHeight:(NSInteger) height;

@end
