/* ClickableImageView */

#import <Cocoa/Cocoa.h>

@interface ClickableImageView : NSImageView
{
	id delegate;
}

- (void) setDelegate:(id)d;
- (id) delegate;
@end
