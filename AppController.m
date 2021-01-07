//
//  AppController.m
//
//  Created by Bernhard Jenny on 01.09.05.
//  Copyright 2005 Bernhard Jenny. All rights reserved.
//  More info on screen capturing: http://www.cocoadev.com/index.pl?ScreenShotCode
//  and http://www.idevapps.com/forum/archive/index.php/t-2895.html
//  Window fading and tranparent rounded window from: http://mattgemmell.com/source/
//  Hot key handling: OverlayWindow.m in FunkyOverlayWindow sample code
//  at http://developer.apple.com/samplecode/FunkyOverlayWindow/FunkyOverlayWindow.html
//  For hot keys see also http://www.dbachrach.com/blog/2005/11/program-global-hotkeys-in-cocoa-easily.html
//
//  Simulation of color blindness:
//  Protanopia simulation after Digital Video Colourmaps for Checking the
//  Legibility of Displays by Dichromat. F, Viénot, Hans Brettel, John D. Mollon
//  Color Research and Application, Vol 24, No 4, ...
/*
 
 // this is a slow, but readable version of the protan simulation
 double gamma = 2.2;
 
 double r = *(srcBitmapData + c * 4);
 double g = *(srcBitmapData + c * 4 + 1);
 double b = *(srcBitmapData + c * 4 + 2);
 
 double rlin = pow(r / 255., gamma);
 double glin = pow(g / 255., gamma);
 double blin = pow(b / 255., gamma);
 
 double r_lin = 0.992052 * rlin + 0.003974;
 double g_lin = 0.992052 * glin + 0.003974;
 double b_lin = 0.992052 * blin + 0.003974;
 
 double r_protan = 0.1124 * r_lin + 0.8876 * g_lin + 0 * b_lin;
 double g_protan = 0.1124 * r_lin + 0.8876 * g_lin + 0 * b_lin;
 double b_protan = 0.0040 * r_lin - 0.0040 * g_lin + 1 * b_lin;
 
 r = 255. * pow(r_protan, 1. / gamma);
 g = 255. * pow(g_protan, 1. / gamma);
 b = 255. * pow(b_protan, 1. / gamma);
 
 *(dstBitmapData + c * 4) = (unsigned char)r;
 *(dstBitmapData + c * 4 + 1) = (unsigned char)g;
 *(dstBitmapData + c * 4 + 2) = (unsigned char)b;
 *(dstBitmapData + c * 4 + 3) = 255;
 
 */

#include "WindowLevel.h"
#import "AppController.h"
#import "ClickableImageView.h"
#import "KeyableWindow.h"
#include "InfoText.h"
#import "LaunchAtLoginController.h"
#import "PFMoveApplication.h"

/* Web site for this project */
#define HOMEPAGE @"http://colororacle.org/"

/* wait this long for the menu to hide */
#define MILLISEC_TO_HIDE_MENU 50

/* interval for animating the menu icon while displaying the welcome dialog.
In seconds */
#define WELCOME_ANIMATION_INTERVAL 0.1

enum simulation {normalView, protan, deutan, tritan, grayscale};

// fading speed
#define FADETIMEINTERVAL 0.05
#define FADETRANSPARENCYSTEP 0.3

// Gamma for converting from screen rgb to linear rgb and back again.
// The publication describing the algorithm uses a gamma value of 2.2, which
// is the standard value on windows system and for sRGB. Macs mostly use a
// gamma value of 1.8. Differences between the two gamma settings are
// hardly visible though.
#define GAMMA 1.8

#define keyNone (-1)

#define DEFAULTDEUTANHOTKEY kVK_F5
#define DEFAULTPROTANHOTKEY keyNone
#define DEFAULTTRITANHOTKEY keyNone
#define DEFAULTGRAYSCALEHOTKEY kVK_F6

// handle hotkeys
const UInt32 kHotKeyIdentifier='blnd';
UInt32 gProtanHotKey;
UInt32 gDeutanHotKey;
UInt32 gTritanHotKey;
UInt32 gGrayscHotKey;

EventHotKeyRef gProtanHotKeyRef;
EventHotKeyRef gDeutanHotKeyRef;
EventHotKeyRef gTritanHotKeyRef;
EventHotKeyRef gGrayscaleHotKeyRef;
//EventHotKeyRef gRightArrowHotKeyRef;
//EventHotKeyRef gLeftArrowHotKeyRef;

EventHotKeyID gWindowsCloseHotKeyID;
const UInt32 kWindowsCloseHotKey = 0xd;	// 'w'
EventHotKeyRef gWindowsCloseHotKeyRef;


// This routine is called when a hotkey is pressed.
pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
	// We can assume our hotkey was pressed
	AppController *app = (__bridge AppController *)userData;
	int simulationID = [app simulationID];
	
	EventHotKeyID hkCom;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hkCom),NULL,&hkCom);
	NSWindow *keyWindow = nil;
	
	switch (hkCom.id) {
		case 1:
			if (simulationID == deutan)
				[app selItemNormal:nil];
			else
				[app selItemDeutan:nil];
			break;
		case 2:
			if (simulationID == protan)
				[app selItemNormal:nil];
			else
				[app selItemProtan:nil];
			break;
		case 3:
			if (simulationID == tritan)
				[app selItemNormal:nil];
			else
				[app selItemTritan:nil];
			break;
        case 4:
            if (simulationID == grayscale)
                [app selItemNormal:nil];
            else
                [app selItemGrayscale:nil];
            break;
        case 5: // close a window
			keyWindow = [NSApp keyWindow];
			if (keyWindow != nil) {
				[keyWindow orderOut:nil];
				
				// hide this app if no window is visible anymore
				NSWindow *aboutBox = [app aboutBox];
				NSWindow *preferencesPanel = [app preferencesPanel];
				if ([aboutBox isVisible] == NO && [preferencesPanel isVisible] == NO)
					[NSApp hide:nil];
				// bring the remaining window to the foreground
				else if (keyWindow == aboutBox)
					[preferencesPanel makeKeyAndOrderFront:nil];
				else
					[aboutBox makeKeyAndOrderFront:nil];
			}
			break;
	}
	return noErr;
}

@implementation AppController

-(int)menu2fkey:(NSInteger)menuItemID
{
	switch (menuItemID) {
		case 0:
			return keyNone;
		case 2:
			return kVK_F1;
		case 3:
			return kVK_F2;
		case 4:
			return kVK_F3;
		case 5:
			return kVK_F4;
		case 6:
			return kVK_F5;
		case 7:
			return kVK_F6;
		case 8:
			return kVK_F7;
		case 9:
			return kVK_F8;
		case 10:
			return kVK_F9;
		case 11:
			return kVK_F10;
		case 12:
			return kVK_F11;
		case 13:
			return kVK_F12;
		case 14:
			return kVK_F13;
		case 15:
			return kVK_F14;
		case 16:
			return kVK_F15;
		case 17:
			return kVK_F16;
        case 18:
            return kVK_F17;
        case 19:
            return kVK_F18;
        case 20:
            return kVK_F19;
        case 21:
            return kVK_F20;
	}
	return keyNone;
}

-(int)fkey2menu:(int)fkey
{
	switch (fkey) {
		case keyNone:
			return 0;
		case kVK_F1:
			return 2;
		case kVK_F2:
			return 3;
		case kVK_F3:
			return 4;
		case kVK_F4:
			return 5;
		case kVK_F5:
			return 6;
		case kVK_F6:
			return 7;
		case kVK_F7:
			return 8;
		case kVK_F8:
			return 9;
		case kVK_F9:
			return 10;
		case kVK_F10:
			return 11;
		case kVK_F11:
			return 12;
		case kVK_F12:
			return 13;
		case kVK_F13:
			return 14;
		case kVK_F14:
			return 15;
		case kVK_F15:
			return 16;
		case kVK_F16:
			return 17;
        case kVK_F17:
            return 18;
        case kVK_F18:
            return 19;
        case kVK_F19:
            return 20;
        case kVK_F20:
            return 21;
	}
	return -1;
}

-(NSString*)fkey2String:(int)fkey
{
	switch (fkey) {
		case kVK_F1:
			return @"F1";
		case kVK_F2:
			return @"F2";
		case kVK_F3:
			return @"F3";
		case kVK_F4:
			return @"F4";
		case kVK_F5:
			return @"F5";
		case kVK_F6:
			return @"F6";
		case kVK_F7:
			return @"F7";
		case kVK_F8:
			return @"F8";
		case kVK_F9:
			return @"F9";
		case kVK_F10:
			return @"F10";
		case kVK_F11:
			return @"F11";
		case kVK_F12:
			return @"F12";
		case kVK_F13:
			return @"F13";
		case kVK_F14:
			return @"F14";
		case kVK_F15:
			return @"F15";
		case kVK_F16:
			return @"F16";
        case kVK_F17:
            return @"F17";
        case kVK_F18:
            return @"F18";
        case kVK_F19:
            return @"F19";
        case kVK_F20:
            return @"F20";
	}
	return @"-";
}

-(long)fkey2Unicode:(int)fkey
{
	switch (fkey) {
		case kVK_F1:
			return NSF1FunctionKey;
		case kVK_F2:
			return NSF2FunctionKey;
		case kVK_F3:
			return NSF3FunctionKey;
		case kVK_F4:
			return NSF4FunctionKey;
		case kVK_F5:
			return NSF5FunctionKey;
		case kVK_F6:
			return NSF6FunctionKey;
		case kVK_F7:
			return NSF7FunctionKey;
		case kVK_F8:
			return NSF8FunctionKey;
		case kVK_F9:
			return NSF9FunctionKey;
		case kVK_F10:
			return NSF10FunctionKey;
		case kVK_F11:
			return NSF11FunctionKey;
		case kVK_F12:
			return NSF12FunctionKey;
		case kVK_F13:
			return NSF13FunctionKey;
		case kVK_F14:
			return NSF14FunctionKey;
		case kVK_F15:
			return NSF15FunctionKey;
		case kVK_F16:
			return NSF16FunctionKey;
        case kVK_F17:
            return NSF17FunctionKey;
        case kVK_F18:
            return NSF18FunctionKey;
        case kVK_F19:
            return NSF19FunctionKey;
        case kVK_F20:
            return NSF20FunctionKey;
	}
	return keyNone;
}


// from OverlayWindow.m in FunkyOverlayWindow sample code
-(void)installHotKeys
{
	EventTypeSpec eventType;
    
    EventHandlerUPP appHotKeyFunction = NewEventHandlerUPP(hotKeyHandler);
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    InstallApplicationEventHandler(appHotKeyFunction, 1, &eventType, (__bridge void *)self, NULL);
    
	// install first deutan, then protan, then tritan, then grayscale.
	// if two hot-keys use the same key, the first installed will be executed.

	if (gDeutanHotKey != keyNone) {
        EventHotKeyID deutanHotKeyID;
        deutanHotKeyID.signature = kHotKeyIdentifier;
		deutanHotKeyID.id = 1;
		RegisterEventHotKey(gDeutanHotKey, 0, deutanHotKeyID, GetApplicationEventTarget(), 0, &gDeutanHotKeyRef);
	}
	
	if (gProtanHotKey != keyNone) {
        EventHotKeyID protanHotKeyID;
        protanHotKeyID.signature = kHotKeyIdentifier;
		protanHotKeyID.id = 2;
    	RegisterEventHotKey(gProtanHotKey, 0, protanHotKeyID, GetApplicationEventTarget(), 0, &gProtanHotKeyRef);
	}
	
	if (gTritanHotKey != keyNone) {
        EventHotKeyID tritanHotKeyID;
        tritanHotKeyID.signature = kHotKeyIdentifier;
		tritanHotKeyID.id = 3;
		RegisterEventHotKey(gTritanHotKey, 0, tritanHotKeyID, GetApplicationEventTarget(), 0, &gTritanHotKeyRef);
	}
    
    if (gGrayscHotKey != keyNone) {
        EventHotKeyID grayscaleHotKeyID;
        grayscaleHotKeyID.signature = kHotKeyIdentifier;
        grayscaleHotKeyID.id = 4;
        RegisterEventHotKey(gGrayscHotKey, 0, grayscaleHotKeyID, GetApplicationEventTarget(), 0, &gGrayscaleHotKeyRef);
    }
}

-(void)removeHotKeys
{
	UnregisterEventHotKey (gProtanHotKeyRef);
	UnregisterEventHotKey (gDeutanHotKeyRef);
	UnregisterEventHotKey (gTritanHotKeyRef);
    UnregisterEventHotKey (gGrayscaleHotKeyRef);
}

// close about and preferences windows with command-w
-(void)installCloseWindowsHotKey
{
	// add hot key handler for closing windows (preferences panel and about box)
    gWindowsCloseHotKeyID.signature=kHotKeyIdentifier;
    gWindowsCloseHotKeyID.id = 5;
    RegisterEventHotKey(kWindowsCloseHotKey, cmdKey, gWindowsCloseHotKeyID, GetApplicationEventTarget(), 0, &gWindowsCloseHotKeyRef);
}

-(void)removeCloseWindowHotKey
{
	UnregisterEventHotKey (gWindowsCloseHotKeyRef);
}

-(void) updatePreferencesDefaultsButton
{
	if (gProtanHotKey == DEFAULTPROTANHOTKEY
		&& gDeutanHotKey == DEFAULTDEUTANHOTKEY
		&& gTritanHotKey == DEFAULTTRITANHOTKEY
        && gGrayscHotKey == DEFAULTGRAYSCALEHOTKEY)
		[prefsDefaultsButton setEnabled:NO];
	else
		[prefsDefaultsButton setEnabled:YES];
}

-(void)initLUTs
{
	const double gamma_inv = 1. / GAMMA;
	
	int i;
	rgb2lin_red_LUT = malloc(sizeof(unsigned short) * 256);
	for (i = 0; i < 256; i++) {
		// compute linear rgb between 0 and 1
		const double lin = (0.992052 * pow(i / 255., GAMMA) + 0.003974);
		
		// scale linear rgb
		rgb2lin_red_LUT[i] = (unsigned short)(lin * 32767.);
	}
	
	lin2rgb_LUT = malloc(sizeof(unsigned char) * 256);
	for (i = 0; i < 256; i++) {
		lin2rgb_LUT[i] = (unsigned char)(255. * pow(i / 255., gamma_inv));
	}
}

-(void)initWindows
{
	// Get the screen rect of our main display
    NSRect screenRect = [[NSScreen mainScreen] frame];
	
	// create a new window
	mainWindow = [[KeyableWindow alloc] initWithContentRect:screenRect
												  styleMask:NSBorderlessWindowMask
													backing:NSBackingStoreBuffered
													  defer:NO
													 screen:[NSScreen mainScreen]];
	
	imageView = [[ClickableImageView alloc] initWithFrame:screenRect];
	[imageView setDelegate:self];
	[imageView setImageFrameStyle: NSImageFrameNone];
	[imageView setImageScaling: NSScaleNone];
	[mainWindow setContentView:imageView];
	[mainWindow setInitialFirstResponder:imageView];
	[infoView setDelegate:self];
	[mainWindow addChildWindow:infoWindow ordered:NSWindowAbove];
}

-(void)initMenu
{
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	
	// build the NSStatusBar for selecting the type of color blindness
	statusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
	[statusItem setMenu:m_menu];
	[statusItem setToolTip:TOOLTIPTEXT];
}

- (id)init
{
	if (!(self = [super init]))  return nil;
	if (self) {
		
		[self initLUTs];
		simulationID = normalView;
		screenshot = nil;
		quartzScreenCapture = nil;
		shouldQuit = NO;
		screenShotBuffer = nil;
		simulationBuffer = nil;
		
		gDeutanHotKey = DEFAULTDEUTANHOTKEY;
		gProtanHotKey = DEFAULTPROTANHOTKEY;
		gTritanHotKey = DEFAULTTRITANHOTKEY;
        gGrayscHotKey = DEFAULTGRAYSCALEHOTKEY;
    }
	return self;
}

- (void)awakeFromNib
{
	[aboutBox center];
	[preferencesPanel center];
	[self initWindows];
	[self initMenu];
    
    // button to resize info window needs transparent background outside the button area
    [infoResizeButton setWantsLayer:YES];
    infoResizeButton.layer.backgroundColor = [NSColor clearColor].CGColor;
}

- (void)dealloc
{
	if (rgb2lin_red_LUT)
		free (rgb2lin_red_LUT);
	if (lin2rgb_LUT)
		free (lin2rgb_LUT);
	
	if (screenShotBuffer)
		free (screenShotBuffer);
	if (simulationBuffer)
		free (simulationBuffer);
}

-(void)computeTritan
{
	/* Code for tritan simulation from GIMP 2.2
	*  This could be optimised for speed.
	*  Performs tritan color image simulation based on
	*  Brettel, Vienot and Mollon JOSA 14/10 1997
	*  L,M,S for lambda=475,485,575,660
	*
	* Load the LMS anchor-point values for lambda = 475 & 485 nm (for
	* protans & deutans) and the LMS values for lambda = 575 & 660 nm
	* (for tritans)
	*/
	
	// RGBA (OpenGL capture) or ARGB (Quartz capture)?
	int alphaFirst = [screenshot bitmapFormat] & NSAlphaFirstBitmapFormat;

	double anchor_e0 = 0.05059983 + 0.08585369 + 0.00952420;
	double anchor_e1 = 0.01893033 + 0.08925308 + 0.01370054;
	double anchor_e2 = 0.00292202 + 0.00975732 + 0.07145979;
	double inflection = anchor_e1 / anchor_e0;
	
	/* Set 1: regions where lambda_a=575, set 2: lambda_a=475 */
	double a1 = -anchor_e2 * 0.007009;
	double b1 = anchor_e2 * 0.0914;
	double c1 = anchor_e0 * 0.007009 - anchor_e1 * 0.0914;
	double a2 = anchor_e1 * 0.3636  - anchor_e2 * 0.2237;
	double b2 = anchor_e2 * 0.1284  - anchor_e0 * 0.3636;
	double c2 = anchor_e0 * 0.2237  - anchor_e1 * 0.1284;
	
	int r, c;
	
	NSInteger rows = [screenshot pixelsHigh];
	NSInteger cols = [screenshot pixelsWide];
	NSInteger bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	
	// recycle the buffer if it has been allocated before and if it's
	// the right size.
	if (cols != simulationBufferWidth || rows != simulationBufferHeight
		|| simulationBuffer == nil) {
		if (simulationBuffer != nil)
			free (simulationBuffer);
		simulationBuffer = malloc(cols * rows * 4);
		simulationBufferWidth = cols;
		simulationBufferHeight = rows;
	}
	
	u_int32_t *dstBitmapData = (u_int32_t*)simulationBuffer;
	
	u_int32_t prevSrc = 0;
	u_int32_t color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			if (*((u_int32_t*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color;
			} else {
				prevSrc = *((u_int32_t*)srcPtr);
				
				// get linear rgb values in the range 0..2^15-1
				double red = rgb2lin_red_LUT[srcPtr[0 + alphaFirst]] / 32767.;
				double green = rgb2lin_red_LUT[srcPtr[1 + alphaFirst]] / 32767.;
				double blue = rgb2lin_red_LUT[srcPtr[2 + alphaFirst]] / 32767.;
				
				/* Convert to LMS (dot product with transform matrix) */
				double redOld   = red;
				double greenOld = green;
				red   = redOld * 0.05059983 + greenOld * 0.08585369 + blue * 0.00952420;
				green = redOld * 0.01893033 + greenOld * 0.08925308 + blue * 0.01370054;
				//blue  = redOld * 0.00292202 + greenOld * 0.00975732 + blue * 0.07145979; // Static analysis: Value stored to 'blue' is never read
				
				double tmp = green / red;
				
				/* See which side of the inflection line we fall... */
				if (tmp < inflection)
					blue = -(a1 * red + b1 * green) / c1;
				else
					blue = -(a2 * red + b2 * green) / c2;
				
				/* Convert back to RGB (cross product with transform matrix) */
				redOld   = red;
				greenOld = green;
				int32_t ired   = (int)(255. * (redOld * 30.830854 -
											greenOld * 29.832659 + blue * 1.610474));
				int32_t igreen = (int)(255. * (-redOld * 6.481468 +
											greenOld * 17.715578 - blue * 2.532642));
				int32_t iblue  = (int)(255. * (-redOld * 0.375690 -
											greenOld * 1.199062 + blue * 14.273846));
				
				// convert reduced linear rgb to gamma corrected rgb
				if (ired < 0)
					ired = 0;
				else if (ired > 255)
					ired = 255;
				else
					ired = lin2rgb_LUT[(int)(ired)];
				
				if (igreen < 0)
					igreen = 0;
				else if (igreen > 255)
					igreen = 255;
				else
					igreen = lin2rgb_LUT[(int)(igreen)];
				
				if (iblue < 0)
					iblue = 0;
				else if (iblue > 255)
					iblue = 255;
				else
					iblue = lin2rgb_LUT[(int)(iblue)];
				
#ifdef __BIG_ENDIAN__
				color = ired << 24 | igreen << 16 | iblue << 8 | 0x000000ff;
#endif
#ifdef __LITTLE_ENDIAN__
				color = ired | igreen << 8 | iblue << 16 | 0xff000000;
#endif
				*(dstBitmapData++) = color;
			}
			
			srcPtr+=4;
		}
		srcBitmapData+=bytesPerRow;
	}
}

-(void)compute:(long) k1 k2:(long)k2 k3:(long)k3
{
	int r, c;
	
	// RGBA (OpenGL capture) or ARGB (Quartz capture)?
	int alphaFirst = [screenshot bitmapFormat] & NSAlphaFirstBitmapFormat;
	
	NSInteger rows = [screenshot pixelsHigh];
	NSInteger cols = [screenshot pixelsWide];
	NSInteger bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	
	// recycle the buffer if it has been allocated before and if it's
	// the right size.
	if (cols != simulationBufferWidth || rows != simulationBufferHeight
		|| simulationBuffer == nil) {
		if (simulationBuffer != nil)
			free (simulationBuffer);
		simulationBuffer = malloc(cols * rows * 4);
		simulationBufferWidth = cols;
		simulationBufferHeight = rows;
	}
	
	u_int32_t *dstBitmapData = (u_int32_t*)simulationBuffer;
	
	u_int32_t prevSrc = 0;
	u_int32_t color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			// this version has been optimized for speed.
			// see at the begining of this file for a more readable version.
			if (*((u_int32_t*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color; // re-use cached previous value
			} else {
				prevSrc = *((u_int32_t*)srcPtr);
				
				// get linear rgb values in the range 0..2^15-1
				const long r_lin = rgb2lin_red_LUT[srcPtr[0 + alphaFirst]];
				const long g_lin = rgb2lin_red_LUT[srcPtr[1 + alphaFirst]];
				const long b_lin = rgb2lin_red_LUT[srcPtr[2 + alphaFirst]];
				
				// simulated red and green are identical
				// scale the matrix values to 0..2^15 for integer computations of the simulated protan values.
				// divide after the computation by 2^15 to rescale.
				// also divide by 2^15 and multiply by 2^8 to scale the linear rgb to 0..255
				// total division is by 2^15 * 2^15 / 2^8 = 2^22
				// shift the bits by 22 places instead of dividing
				long r_blind = (k1 * r_lin + k2 * g_lin)  >> 22;
				long b_blind = (k3 * r_lin - k3 * g_lin + 32768 * b_lin) >> 22;
				
				if (r_blind < 0)
					r_blind = 0;
				else if (r_blind > 255)
					r_blind = 255;
				
				if (b_blind < 0)
					b_blind = 0;
				else if (b_blind > 255)
					b_blind = 255;
				
				// convert reduced linear rgb to gamma corrected rgb
				const u_int32_t red = lin2rgb_LUT[r_blind];
				const u_int32_t blue = lin2rgb_LUT[b_blind];
				
#ifdef __BIG_ENDIAN__
				color = red << 24 | red << 16 | blue << 8 | 0x000000ff;
#endif
#ifdef __LITTLE_ENDIAN__
				color = red | red << 8 | blue << 16 | 0xff000000;
#endif
				*(dstBitmapData++) = color;
			}
			
			srcPtr+=4;
		}
		srcBitmapData+=bytesPerRow;
	}
}

-(void)computeGrayscale
{
	/* Code for grayscale computation, modified from computeTritan.
	 Based on https://en.wikipedia.org/wiki/Grayscale#Colorimetric_.28luminance-preserving.29_conversion_to_grayscale
	 Tim van Werkhoven 20140318
	 */
	
	// RGBA (OpenGL capture) or ARGB (Quartz capture)?
	int alphaFirst = [screenshot bitmapFormat] & NSAlphaFirstBitmapFormat;
	
//	double anchor_e0 = 0.05059983 + 0.08585369 + 0.00952420;
//	double anchor_e1 = 0.01893033 + 0.08925308 + 0.01370054;
//	double anchor_e2 = 0.00292202 + 0.00975732 + 0.07145979;
//	double inflection = anchor_e1 / anchor_e0;
//
//	/* Set 1: regions where lambda_a=575, set 2: lambda_a=475 */
//	double a1 = -anchor_e2 * 0.007009;
//	double b1 = anchor_e2 * 0.0914;
//	double c1 = anchor_e0 * 0.007009 - anchor_e1 * 0.0914;
//	double a2 = anchor_e1 * 0.3636  - anchor_e2 * 0.2237;
//	double b2 = anchor_e2 * 0.1284  - anchor_e0 * 0.3636;
//	double c2 = anchor_e0 * 0.2237  - anchor_e1 * 0.1284;
	
	NSInteger r, c;
	
	NSInteger rows = [screenshot pixelsHigh];
	NSInteger cols = [screenshot pixelsWide];
	NSInteger bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	
	// recycle the buffer if it has been allocated before and if it's
	// the right size.
	if (cols != simulationBufferWidth || rows != simulationBufferHeight
			|| simulationBuffer == nil) {
		if (simulationBuffer != nil)
			free (simulationBuffer);
		simulationBuffer = malloc(cols * rows * 4);
		simulationBufferWidth = cols;
		simulationBufferHeight = rows;
	}
	
	u_int32_t *dstBitmapData = (u_int32_t*)simulationBuffer;
	
	u_int32_t prevSrc = 0;
	u_int32_t color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			if (*((u_int32_t*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color;
			} else {
				prevSrc = *((u_int32_t*)srcPtr);
				
				// get linear rgb values in the range 0..2^15-1
				double red = rgb2lin_red_LUT[srcPtr[0 + alphaFirst]] / 32767.;
				double green = rgb2lin_red_LUT[srcPtr[1 + alphaFirst]] / 32767.;
				double blue = rgb2lin_red_LUT[srcPtr[2 + alphaFirst]] / 32767.;

				/* Convert to grayscale (dot product with transform matrix) */

				// Step 1. sRGB color space gamma expansion (not required here?)
//				if (red <= 0.04045)
//					red = red/12.92;
//				else
//					red = pow((red+0.055)/1.055, 2.4);
//
//				if (green <= 0.04045)
//					green = green/12.92;
//				else
//					green = pow((green+0.055)/1.055, 2.4);
//
//				if (blue <= 0.04045)
//					blue = blue/12.92;
//				else
//					blue = pow((blue+0.055)/1.055, 2.4);

				// Step 2. luminance calculation
				double luminance = 0.2126*red + 0.7152*green + 0.0722*blue;
				
				// Step 3. gamma compression (not required here?)
//				if (luminance > 0.0031308)
//					luminance = 12.92*luminance;
//				else
//					luminance = 1.055*pow(luminance, 1.0/2.4) - 0.055;

				// Convert to RGB [0, 255]
				int32_t ired   = (int)(255. * luminance);
				int32_t igreen = (int)(255. * luminance);
				int32_t iblue  = (int)(255. * luminance);
				
				// convert reduced linear rgb to gamma corrected rgb
				if (ired < 0)
					ired = 0;
				else if (ired > 255)
					ired = 255;
				else
					ired = lin2rgb_LUT[(int)(ired)];
				
				if (igreen < 0)
					igreen = 0;
				else if (igreen > 255)
					igreen = 255;
				else
					igreen = lin2rgb_LUT[(int)(igreen)];
				
				if (iblue < 0)
					iblue = 0;
				else if (iblue > 255)
					iblue = 255;
				else
					iblue = lin2rgb_LUT[(int)(iblue)];
				
#ifdef __BIG_ENDIAN__
				color = ired << 24 | igreen << 16 | iblue << 8 | 0x000000ff;
#endif
#ifdef __LITTLE_ENDIAN__
				color = ired | igreen << 8 | iblue << 16 | 0xff000000;
#endif
				*(dstBitmapData++) = color;
			}
			
			srcPtr+=4;
		}
		srcBitmapData+=bytesPerRow;
	}
}


-(void)simulate
{
	if (screenshot == nil)
		return;
    switch (simulationID) {
		case protan:
			[self compute: 3683 k2: 29084 k3: 131];
			break;
		case deutan:
			[self compute: 9591 k2: 23173 k3: -730];
			break;
		case tritan:
			[self computeTritan];
			break;
		case grayscale:
			[self computeGrayscale];
			break;
	}
	
	NSInteger rows = [screenshot pixelsHigh];
	NSInteger cols = [screenshot pixelsWide];
	
	simulation =
		[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: (unsigned char**)&simulationBuffer
												pixelsWide: cols
												pixelsHigh: rows
											 bitsPerSample: 8
										   samplesPerPixel: 4
												  hasAlpha: YES
												  isPlanar: NO
											colorSpaceName: NSDeviceRGBColorSpace
											   bytesPerRow: cols * 4
											  bitsPerPixel: 32];
}

-(void)fillWindow
{
	if (simulation == nil)
		return;
	// create an NSImage and display it in the NSImageView
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:simulation];
	//[image setFlipped:NO];
	[imageView setImage: image];
}

-(void)fillInfo
{
	switch (simulationID) {
		case deutan:
			[infoView setTitle:DEUTANTEXT];
			[infoView setInfo1:DEUTANINFOTEXT];
			break;
		case protan:
			[infoView setTitle:PROTANTEXT];
			[infoView setInfo1:PROTANINFOTEXT];
			break;
		case tritan:
			[infoView setTitle:TRITANTEXT];
			[infoView setInfo1:TRITANINFOTEXT];
			break;
		case grayscale:
			[infoView setTitle:GRAYSCTEXT];
			[infoView setInfo1:GRAYSCINFOTEXT];
			break;
	}
	
    // build info text consisting of information about (1) how to exit simulation
    // (2) drag info panel, and (3) hotkey mapping.
    NSMutableString *infoString = [NSMutableString string];
    [infoString appendString:INFO_MESSAGE_PART1];
    
    // add info about hotkey mapping
    BOOL hasHotKey = gDeutanHotKey != keyNone || gProtanHotKey != keyNone || gTritanHotKey != keyNone || gGrayscHotKey != keyNone;
    if (hasHotKey) {
        [infoString appendString: @","];
    }
    if (gDeutanHotKey != keyNone) {
        NSString *deutanKeyStr = [self fkey2String:gDeutanHotKey];
        [infoString appendString:[NSString stringWithFormat: INFOMESSAGEPRESS_DEUTAN, deutanKeyStr]];
        if (gProtanHotKey != keyNone || gTritanHotKey != keyNone || gGrayscHotKey != keyNone) {
            [infoString appendString: @","];
        }
    }
    if (gProtanHotKey != keyNone) {
        NSString *protanKeyStr = [self fkey2String:gProtanHotKey];
        [infoString appendString:[NSString stringWithFormat: INFOMESSAGEPRESS_PROTAN, protanKeyStr]];
        if (gTritanHotKey != keyNone || gGrayscHotKey != keyNone) {
            [infoString appendString: @","];
        }
    }
    if (gTritanHotKey != keyNone) {
        NSString *tritanKeyStr = [self fkey2String:gTritanHotKey];
        [infoString appendString:[NSString stringWithFormat: INFOMESSAGEPRESS_TRITAN, tritanKeyStr]];
        if (gGrayscHotKey != keyNone) {
            [infoString appendString: @","];
        }
    }
    if (gGrayscHotKey != keyNone) {
        NSString *grayscKeyStr = [self fkey2String:gGrayscHotKey];
        [infoString appendString:[NSString stringWithFormat: INFOMESSAGEPRESS_GRAYSC, grayscKeyStr]];
    }
    if (hasHotKey) {
        [infoString appendString: @" vision"];
    }
    [infoString appendString: @".\n"];
    [infoString appendString: INFO_MESSAGE_PART2];
    
    [infoView setInfo2:infoString];
}

-(int)simulationID
{
	return simulationID;
}

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	// enable menu items for simulating color impaired vision when capturing the screen is possible or the permission dialog is not currently visible
	BOOL enableSimulationMenuItems = [self canCaptureScreen] || !permissionDialog.isVisible;
	
	if ([menuItem action] == @selector(selItemNormal:)) {
		[menuItem setState: simulationID == normalView ? NSOnState : NSOffState];
		return YES;
	}
	
	if ([menuItem action] == @selector(selItemProtan:)) {
		if (gProtanHotKey != keyNone)
		{
			unichar ch[1];
			ch[0] = [self fkey2Unicode: gProtanHotKey];
			[menuItem setKeyEquivalentModifierMask:NSFunctionKeyMask];
			[menuItem setKeyEquivalent:[NSString stringWithCharacters:ch length:1]];
		} else {
			[menuItem setKeyEquivalent:@""];
		}
		
		[menuItem setState: simulationID == protan ? NSOnState : NSOffState];
		return enableSimulationMenuItems;
	}
	
	if ([menuItem action] == @selector(selItemDeutan:)) {
		if (gDeutanHotKey != keyNone)
		{
			unichar ch[1];
			ch[0] = [self fkey2Unicode: gDeutanHotKey];
			[menuItem setKeyEquivalentModifierMask:NSFunctionKeyMask];
			[menuItem setKeyEquivalent:[NSString stringWithCharacters:ch length:1]];
		} else {
			[menuItem setKeyEquivalent:@""];
		}
		
		[menuItem setState: simulationID == deutan ? NSOnState : NSOffState];
		return enableSimulationMenuItems;
	}
	
	if ([menuItem action] == @selector(selItemTritan:)) {
		if (gTritanHotKey != keyNone)
		{
			unichar ch[1];
			ch[0] = [self fkey2Unicode: gTritanHotKey];
			[menuItem setKeyEquivalentModifierMask:NSFunctionKeyMask];
			[menuItem setKeyEquivalent:[NSString stringWithCharacters:ch length:1]];
		} else {
			[menuItem setKeyEquivalent:@""];
		}
		
		[menuItem setState: simulationID == tritan ? NSOnState : NSOffState];
		return enableSimulationMenuItems;
	}
    
    if ([menuItem action] == @selector(selItemGrayscale:)) {
        if (gGrayscHotKey != keyNone)
        {
            unichar ch[1];
            ch[0] = [self fkey2Unicode: gGrayscHotKey];
            [menuItem setKeyEquivalentModifierMask:NSFunctionKeyMask];
            [menuItem setKeyEquivalent:[NSString stringWithCharacters:ch length:1]];
        } else {
            [menuItem setKeyEquivalent:@""];
        }
        
        [menuItem setState: simulationID == grayscale ? NSOnState : NSOffState];
        return enableSimulationMenuItems;
    }
	
	if ([menuItem action] == @selector(selItemSave:)) {
		return simulationID != normalView;
	}
	
	return YES;
}

-(void)fadeInWindows
{
	if ([mainWindow isVisible] == YES || timer != nil)
		return;
	
	[mainWindow setAlphaValue:0];
	[infoWindow setAlphaValue:0];
	
	// force the infoView to be redrawn.
	// Otherwise the infoWindow would be square, white, and not transparent
	[infoView setNeedsDisplay:YES];
	
	[mainWindow makeKeyAndOrderFront:self];
	[infoWindow makeKeyAndOrderFront:self];
		
	// Set up the timer to periodically call the fadeIn: method.
	timer = [NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL
											 target:self
										   selector:@selector(fadeIn:)
										   userInfo:nil repeats:YES];
}

-(void)finishFadeIn
{
	// make this app the active one. This ensures that we get all key events.
	// Not elegant, but it works.
	[NSApp activateIgnoringOtherApps: YES];
}

// based on http://mattgemmell.com/source/
- (void)fadeIn:(NSTimer *)theTimer
{
    if ([mainWindow alphaValue] < 1.0) {
        [mainWindow setAlphaValue:[mainWindow alphaValue] + FADETRANSPARENCYSTEP];
		[infoWindow setAlphaValue:[infoWindow alphaValue] + FADETRANSPARENCYSTEP];
		// shadow was lost somehow (probably when setting alphaValue to 0)
		// re-enable the shadows
		[infoWindow setHasShadow:YES];
    } else {
        // destroy the timer
        [timer invalidate];
        timer = nil;
		
		[self finishFadeIn];
	}
}

-(void) fadeOutWindow
{
	if ([mainWindow isVisible] == NO || timer != nil)
		return;
	
	// Set up the timer to periodically call the fadeOut: method.
	timer = [NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL
											 target:self
										   selector:@selector(fadeOut:)
										   userInfo:nil repeats:YES];
}

-(void)finishFadeOut
{
	[mainWindow orderOut:self];
	
	if (shouldQuit == YES) {
		[[NSApplication sharedApplication] terminate:self];
		return;
	}
	
	// deactivate this application, so that previous application owns the key window again.
	// [NSApp deactivate]; is not enough,
	// see http://lists.apple.com/archives/Cocoa-dev/2005/Jul/msg01399.html
	// don't deactivate this app when the preferences or the about panel is visible.
	// This is the case when the user selected "Prefs" or "About" in the menu while
	// the mainWindow with the simulation was visible
	if ([aboutBox isVisible] == NO && [preferencesPanel isVisible] == NO)
		[NSApp hide:nil];
}

// based on http://mattgemmell.com/source/
- (void)fadeOut:(NSTimer *)theTimer
{
    if ([mainWindow alphaValue] > 0.0) {
        // If window is still partially opaque, reduce its opacity.
        [mainWindow setAlphaValue:[mainWindow alphaValue] - FADETRANSPARENCYSTEP];
		[infoWindow setAlphaValue:[infoWindow alphaValue] - FADETRANSPARENCYSTEP];
    } else {
        // Otherwise, if window is completely transparent, destroy the timer and close the window.
        [timer invalidate];
        timer = nil;
		[self finishFadeOut];
	}
}

-(void)finishFadeOutAndSave
{
	[mainWindow orderOut:self];
	
	// setup the save panel
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:NSLocalizedString(@"Save Image", @"Screenshot")];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"tif", @"tiff", nil]];

	if (simulationID == protan)
		[savePanel setMessage:NSLocalizedString(@"Save the screen with simulated protan color vision to a TIFF file.", @"Screenshot")];
	else if (simulationID == deutan)
		[savePanel setMessage:NSLocalizedString(@"Save the screen with simulated deutan color vision to a TIFF file.", @"Screenshot")];
	else if (simulationID == tritan)
		[savePanel setMessage:NSLocalizedString(@"Save the screen with simulated tritan color vision to a TIFF file.", @"Screenshot")];
    else if (simulationID == grayscale)
        [savePanel setMessage:NSLocalizedString(@"Save the screen in grayscale to a TIFF file.", @"Screenshot")];
	
	// setNameFieldStringValue available with OS X 10.6 or newer
	if ([savePanel respondsToSelector:@selector(setNameFieldStringValue:)]) {
		if (simulationID == protan)
			[savePanel setNameFieldStringValue: NSLocalizedString(@"Protanopia.tif", @"Screenshot")];
		else if (simulationID == deutan)
			[savePanel setNameFieldStringValue: NSLocalizedString(@"Deuteranopia.tif", @"Screenshot")];
		else if (simulationID == tritan)
			[savePanel setNameFieldStringValue: NSLocalizedString(@"Tritanopia.tif", @"Screenshot")];
        else if (simulationID == grayscale)
            [savePanel setNameFieldStringValue: NSLocalizedString(@"Grayscale.tif", @"Screenshot")];
	}
	
	simulationID = normal;
	
	[savePanel setLevel:WINDOWLEVEL];
	[savePanel orderFront:self];
	NSInteger result = [savePanel runModal];
	
	// hides this app when no dialog is visible
	[self finishFadeOut];
	
    if (result == NSOKButton) {
        // get path to new file
        NSURL *url = [savePanel URL];
        // write to tiff file
        NSData *tiff = [simulation TIFFRepresentation];
        [tiff writeToURL:url atomically:YES];
    }
}

// based on http://mattgemmell.com/source/
- (void)fadeOutAndSave:(NSTimer *)theTimer
{
    if ([mainWindow alphaValue] > 0.0) {
        // If window is still partially opaque, reduce its opacity.
        [mainWindow setAlphaValue:[mainWindow alphaValue] - FADETRANSPARENCYSTEP];
		[infoWindow setAlphaValue:[infoWindow alphaValue] - FADETRANSPARENCYSTEP];
    } else {
        // Otherwise, if window is completely transparent, destroy the timer and close the window.
        [timer invalidate];
        timer = nil;
		[self finishFadeOutAndSave];
	}
}

/*
Fade out the panels of this app (preferences panel and about box) and take a screenshot
when the panels are not visible anymore.
Hiding the panels before taking the screenshots is required to work around the problem related
to deactivating this app. When the color blind simulation should stop, the main window is hidden.
The previously active app should be made active again, so it has the key focus again. This is
only possible by hiding this app using [NSApp hide]. The panel would disappear at this moment.
*/
-(void) fadeOutPanelsAndTakeScreenshot
{
	if (timer != nil)
		return;
	if ([aboutBox isVisible] == NO && [preferencesPanel isVisible] == NO)
		return;
	
	// Set up the timer to periodically call the fadeOutPanelsAndTakeScreenshot: method.
	timer = [NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL
											 target:self
										   selector:@selector(fadeOutPanelsAndTakeScreenshot:)
										   userInfo:nil repeats:YES];
}

-(void)finishfadeOutPanelsAndTakeScreenshot
{
	[preferencesPanel orderOut:self];
	[aboutBox orderOut:self];
	[self takeScreenShot];
	[self updateSimulation];
}

// based on http://mattgemmell.com/source/
- (void)fadeOutPanelsAndTakeScreenshot:(NSTimer *)theTimer
{
    if ([preferencesPanel alphaValue] > 0 || [aboutBox alphaValue] > 0) {
        // If window is still partially opaque, reduce its opacity.
        [preferencesPanel setAlphaValue:[preferencesPanel alphaValue] - FADETRANSPARENCYSTEP];
		[aboutBox setAlphaValue:[aboutBox alphaValue] - FADETRANSPARENCYSTEP];
    } else {
        // Otherwise, if window is completely transparent, destroy the timer and close the window.
        [timer invalidate];
        timer = nil;
		[self finishfadeOutPanelsAndTakeScreenshot];
	}
}

-(void)updateSimulation
{
	if (screenshot == nil)
		return; // we likely do not have the permission to capture the screen
	
	// simulate color blindness
	[self simulate];
	
	// Fill the window with the simulated image
	[self fillWindow];
	
	// fill windows with new information
	[self fillInfo];
	
	// show the windows
	[self fadeInWindows];
}

-(IBAction)selItemNormal:(id)sender
{
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
	simulationID = normalView;
	[self fadeOutWindow];
}

-(void) sleep:(float) millisec
{
	struct timespec rqtp = { 0 };
    rqtp.tv_nsec = millisec * 1000 * 1000; // Convert from mS to nS
    nanosleep(&rqtp, NULL);
}

// wait until the menu is completely hidden this avoids ghost images of the menu
// in the color corrected image.
-(void) hideMenu
{
	// have a little break. This should give Quartz enough time to completely hide the menu.
	[self sleep: MILLISEC_TO_HIDE_MENU];
}

-(void)selItem: (int) simID withIcon:(NSString*) iconName{
    // close welcome dialog, should it still be open
    [self closeWelcomeDialog:self];
    simulationID = simID;
    [self hideMenu];
    [mainWindow setLevel: WINDOWLEVEL];
    [self takeScreenShot]; // on macOS 10.15 and later, this will trigger a system dialog asking the user to grant access to screen recording, if this is the first time Color Oracle is run.
	if ([self canCaptureScreen]) {
		[statusItem setImage:[NSImage imageNamed:iconName]];
		[self updateSimulation];
	} else {
		[self selItemNormal:self];
		if ([permissionDialog isVisible] == NO) {
			[permissionDialog center];
			// move the permission dialog down to make sure it does not overlap the system dialog informing the user that "Color Oracle would like to record this computer's screen".
			NSRect frame = [permissionDialog frame];
			[permissionDialog setFrameOrigin:NSMakePoint(frame.origin.x, frame.origin.y - 220)];
			[permissionDialog makeKeyAndOrderFront:self];
		}
		
		// show permission dialog in front of all other apps
		[NSApp activateIgnoringOtherApps:YES];
	}
}

-(IBAction)selItemProtan:(id)sender
{
    [self selItem: protan withIcon: @"menuIconProtan"];
}

-(IBAction)selItemDeutan:(id)sender
{
    [self selItem: deutan withIcon: @"menuIconDeutan"];
}

-(IBAction)selItemTritan:(id)sender
{
	[self selItem: tritan withIcon: @"menuIconTritan"];
}

-(IBAction)selItemGrayscale:(id)sender
{
	[self selItem: grayscale withIcon: @"menuIconGrayscale"];
}

-(IBAction)selItemSave:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
	
	if (simulationID == normalView
		|| simulation == nil
		|| [mainWindow isVisible] == NO
		|| timer != nil) {
		simulationID = normalView;
		return;
	}
	// Set up the timer to periodically call the fadeOut: method.
	timer = [NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL
											 target:self
										   selector:@selector(fadeOutAndSave:)
										   userInfo:nil repeats:YES];
}

-(IBAction)selItemPreferences:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	
	// if simulation window is visible, first hide the simulation window
	if ([mainWindow isVisible])
		[self selItemNormal:self];
	
    // show window in front of all other apps
	[NSApp activateIgnoringOtherApps: YES];
	
	// bring the other dialogs to the foreground if it they are visible
	if ([aboutBox isVisible])
		[aboutBox orderFront:self];
	if ([permissionDialog isVisible])
		[permissionDialog orderFront:self];
	
	// only configure GUI of preferences panel if the panel is not visible yet.
	if ([preferencesPanel isVisible] == NO) {
		// configure menus for selecting function keys
		[protanHotKeyMenu selectItemAtIndex:[self fkey2menu:gProtanHotKey]];
		[deutanHotKeyMenu selectItemAtIndex:[self fkey2menu:gDeutanHotKey]];
		[tritanHotKeyMenu selectItemAtIndex:[self fkey2menu:gTritanHotKey]];
		[grayscaleHotKeyMenu selectItemAtIndex:[self fkey2menu:gGrayscHotKey]];
        
		// enable / disable button for resetting preferences to default values.
		[self updatePreferencesDefaultsButton];
        
        // initialize "launch at login" checkbox
        [self updateLoginButton: nil];
    }
    
    // bring the preferences panel to the foreground
	[preferencesPanel makeKeyAndOrderFront:self];
	
	// changing the alpha before has no effect.
	[preferencesPanel setAlphaValue: 1];
}

-(IBAction)selItemAbout:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	
	// if simulation window is visible, first hide the simulation window
	if ([mainWindow isVisible])
		[self selItemNormal:self];
		
    // show window in front of all other apps
	[NSApp activateIgnoringOtherApps: YES];
	
	// bring the other dialogs to the foreground if they are visible
	if ([preferencesPanel isVisible])
		[preferencesPanel orderFront:self];
	if ([permissionDialog isVisible])
		[permissionDialog orderFront:self];
	
	[aboutBox makeKeyAndOrderFront:self];
	[aboutBox setAlphaValue: 1];
}

-(IBAction)selItemQuit:(id)sender
{
	if ([mainWindow isVisible]) {
		shouldQuit = YES;
		[self fadeOutWindow];
	} else {
		[[NSApplication sharedApplication] terminate:self];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[self selItemNormal:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self selItemNormal:self];
}

-(void)mouseDown:(NSEvent*) evt
{
	[self selItemNormal:self];
}

-(void)mouseUp:(NSEvent*) evt
{
	[self selItemNormal:self];
}

- (void)keyDown:(NSEvent *)theEvent
{
    // switch simulation when left or right arrow key is pressed
    NSString *const character = [theEvent charactersIgnoringModifiers];
    unichar const code = [character characterAtIndex:0];
    switch (code) {
        // right arrow
        case NSRightArrowFunctionKey:
            switch (simulationID) {
                case deutan:
                    [self selItemProtan:nil];
                    break;
                case protan:
                    [self selItemTritan:nil];
                    break;
                case tritan:
                    [self selItemGrayscale:nil];
                    break;
                case grayscale:
                    [self selItemDeutan:nil];
                    break;
                default:
                    break;
            }
            break;
            
        // left arrow
        case NSLeftArrowFunctionKey:
            switch (simulationID) {
                case deutan:
                    [self selItemGrayscale:nil];
                    break;
                case protan:
                    [self selItemDeutan:nil];
                    break;
                case tritan:
                    [self selItemProtan:nil];
                    break;
                case grayscale:
                    [self selItemTritan:nil];
                    break;
                default:
                    break;
            }
            break;
        
        // hide simulation if any other key is pressed
        default:
            [self selItemNormal:self];
    }
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
	[self selItemNormal:self];
	[self removeCloseWindowHotKey];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	[self installCloseWindowsHotKey];
}

// animates the menu icon while the welcome dialog is visible
- (void)animateMenuIcon:(NSTimer *)theTimer
{
	long imageID = [[[statusItem image] name] intValue];
	imageID++;
	if (imageID > 24)
		imageID = 1;
	NSString *newName = [NSString stringWithFormat:@"%ld", imageID];
	[statusItem setImage:[NSImage imageNamed:newName]];
}

// closes the welcome dialog and stops the animated welcome menu item
-(IBAction)closeWelcomeDialog:(id)sender
{
	// don't close the dialog twice
	if (welcomeDialog == nil)
		return;
	
	// close the dialog. Don't close if sender is nil. This is an ugly hack. See
	// windowWillClose
	if (sender != nil)
		[welcomeDialog close];
	
	welcomeDialog = nil;
	
	// stop the animation
	if (timer != nil) {
		[timer invalidate];
		timer = nil;
	}
	
	// make sure the icon is the default menu icon
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
}

-(IBAction)closePermissionDialog:(id)sender
{
	[permissionDialog orderOut:self];
}

// button to launch Color Oracle at login
- (IBAction)login:(id)sender {
    BOOL launchAtLogin = ([sender state] == NSOnState);
    
    NSString* pathToCopiedBundle = nil;
    if (launchAtLogin) {
        pathToCopiedBundle = PFMoveToApplicationsFolderIfNecessary();
    }
    
    if (pathToCopiedBundle != nil && [pathToCopiedBundle isEqualToString:@"error"]) {
        [loginButton setState:NSControlStateValueOff];
        return;
    }
    
    // URL of this app bundle. If app was moved, use the path to the copied bundle. Otherwise get bundle path.
    NSURL* appURL = pathToCopiedBundle != nil ? [NSURL fileURLWithPath:pathToCopiedBundle]
        : [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

    // add or remove Color Oracle to/from login items
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [launchController setLaunchAtLogin:launchAtLogin forURL: appURL];
    
    // exit if Color Oracle moved itself to the Applications folder
    if (pathToCopiedBundle != nil) {
        [NSApp terminate:nil];
    }
}

// button to resize info window was pressed
- (IBAction)resizeInfo:(id)sender {
    NSControlStateValue buttonState = [infoView resizeInfo];
    // non-standard use of disclosure button: need to adjust state to indicate direction of resizing
    [infoResizeButton setState:buttonState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // retrieve defaults, object is created if it does not exist
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // retrieve the hot keys from the preference file
	gProtanHotKey = (UInt32)[defaults integerForKey:@"protanHotKey"];
	if (gProtanHotKey == 0)
		gProtanHotKey = DEFAULTPROTANHOTKEY;
	gDeutanHotKey = (UInt32)[defaults integerForKey:@"deutanHotKey"];
	if (gDeutanHotKey == 0)
		gDeutanHotKey = DEFAULTDEUTANHOTKEY;
	gTritanHotKey = (UInt32)[defaults integerForKey:@"tritanHotKey"];
	if (gTritanHotKey == 0)
		gTritanHotKey = DEFAULTTRITANHOTKEY;
    gGrayscHotKey = (UInt32)[defaults integerForKey:@"grayscaleHotKey"];
    if (gGrayscHotKey == 0) {
        // If this is the first time version 1.3 with grayscale simulation
        // is started, make sure the hot key for grayscale is not identical
        // to any other previously set hot key.
        if (gProtanHotKey == DEFAULTGRAYSCALEHOTKEY
            || gDeutanHotKey == DEFAULTGRAYSCALEHOTKEY
            || gTritanHotKey == DEFAULTGRAYSCALEHOTKEY) {
                gGrayscHotKey = keyNone;
        } else {
            gGrayscHotKey = DEFAULTGRAYSCALEHOTKEY;
        }
    }
	[self installHotKeys];
	
	// get position of infoWindow from preferences file
	NSInteger boxH = [defaults integerForKey:@"boxH"];
	NSInteger boxV = [defaults integerForKey:@"boxV"];
    if (boxH == 0 || boxV == 0)
		[infoWindow center];
	else
		[infoWindow setFrameOrigin:NSMakePoint(boxH, boxV)];
	
	// set height of infoWindow from preferences file
	NSInteger height = [defaults integerForKey:@"boxHeight"];
    if ([infoView isValidHeight: height]) {
		NSRect frame = [infoWindow frame];
		frame.size.height = height;
		[infoWindow setFrame:frame display:YES];
	}
	
	// make sure the infoWindow is visible on the screen
	NSRect screenRect = [[infoWindow screen] frame];
	if (NSContainsRect(screenRect, [infoWindow frame]) == NO)
		[infoWindow center];
	
	// show welcome dialog if this is the first time Color Oracle is launched
	BOOL launchedBefore = [defaults boolForKey:@"launchedBefore"];
	if (launchedBefore == NO) {
        [welcomeDialog center];
		[welcomeDialog makeKeyAndOrderFront:self];
        
        // show window in front of all other apps
        [NSApp activateIgnoringOtherApps:YES];
		
		timer = [NSTimer scheduledTimerWithTimeInterval:WELCOME_ANIMATION_INTERVAL
												 target:self
											   selector:@selector(animateMenuIcon:)
											   userInfo:nil repeats:YES];
		[defaults setBool:YES forKey:@"launchedBefore"];
	}
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateLoginButton:)
												 name:NSWindowDidBecomeKeyNotification
											   object:preferencesPanel];
}

- (BOOL)canCaptureScreen
{
	// from:
	// https://stackoverflow.com/questions/56597221/detecting-screen-recording-settings-on-macos-catalina/58786245#58786245
	// https://stackoverflow.com/a/58985069
	// by @chockenberry.
	BOOL hasScreenCapturePermissions = YES;
	if (@available(macOS 10.15, *)) {
		hasScreenCapturePermissions = NO;
		NSRunningApplication *runningApplication = NSRunningApplication.currentApplication;
		NSNumber *ourProcessIdentifier = [NSNumber numberWithInteger:runningApplication.processIdentifier];
		
		CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
		NSUInteger numberOfWindows = CFArrayGetCount(windowList);
		for (int index = 0; index < numberOfWindows; index++) {
			// get information for each window
			NSDictionary *windowInfo = (NSDictionary *)CFArrayGetValueAtIndex(windowList, index);
			NSString *windowName = windowInfo[(id)kCGWindowName];
			NSNumber *processIdentifier = windowInfo[(id)kCGWindowOwnerPID];
			
			// don't check windows owned by this process
			if (! [processIdentifier isEqual:ourProcessIdentifier]) {
				// get process information for each window
				pid_t pid = processIdentifier.intValue;
				NSRunningApplication *windowRunningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
				if (! windowRunningApplication) {
					// ignore processes we don't have access to, such as WindowServer, which manages the windows named "Menubar" and "Backstop Menubar"
				}
				else {
					NSString *windowExecutableName = windowRunningApplication.executableURL.lastPathComponent;
					if (windowName) {
						if ([windowExecutableName isEqual:@"Dock"]) {
							// ignore the Dock, which provides the desktop picture
						}
						else {
							hasScreenCapturePermissions = YES;
							break;
						}
					}
				}
			}
		}
		CFRelease(windowList);
	}
	return hasScreenCapturePermissions;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// retreived defaults, object is created if it does not exist
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    // write app version
    // this was added to version 1.3.0 (April 2018)
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    [defaults setObject: appVersion forKey:@"version"];
    
    // store the hot keys in the preference file
    [defaults setInteger:gProtanHotKey forKey:@"protanHotKey"];
	[defaults setInteger:gDeutanHotKey forKey:@"deutanHotKey"];
	[defaults setInteger:gTritanHotKey forKey:@"tritanHotKey"];
    [defaults setInteger:gGrayscHotKey forKey:@"grayscaleHotKey"];
	
	// store position of infoWindow in preference file
	NSRect frame = [infoWindow frame];
	[defaults setInteger:frame.origin.x forKey:@"boxH"];
	[defaults setInteger:frame.origin.y forKey:@"boxV"];
	
	// store height of infoWindow in preference file
	[defaults setInteger:frame.size.height forKey:@"boxHeight"];
}

// event handler for function key menu in preferences panel
-(void)protanKey:(id)sender
{
	NSPopUpButton *menu = (NSPopUpButton*)sender;
	int key = [self menu2fkey:[menu indexOfSelectedItem]];
	if (gProtanHotKey != key) {
		[self removeHotKeys];
		gProtanHotKey = key;
		[self installHotKeys];
		[self fillInfo];
		[self updatePreferencesDefaultsButton];
	}
}

// event handler for function key menu in preferences panel
-(void)deutanKey:(id)sender
{
	NSPopUpButton *menu = (NSPopUpButton*)sender;
	int key = [self menu2fkey:[menu indexOfSelectedItem]];
	if (gDeutanHotKey != key) {
		[self removeHotKeys];
		gDeutanHotKey = key;
		[self installHotKeys];
		[self fillInfo];
		[self updatePreferencesDefaultsButton];
	}
}

// event handler for function key menu in preferences panel
-(void)tritanKey:(id)sender
{
	NSPopUpButton *menu = (NSPopUpButton*)sender;
	int key = [self menu2fkey:[menu indexOfSelectedItem]];
	if (gTritanHotKey != key) {
		[self removeHotKeys];
		gTritanHotKey = key;
		[self installHotKeys];
		[self fillInfo];
		[self updatePreferencesDefaultsButton];
	}
}

// event handler for function key menu in preferences panel
-(void)grayscaleKey:(id)sender
{
    NSPopUpButton *menu = (NSPopUpButton*)sender;
    int key = [self menu2fkey:[menu indexOfSelectedItem]];
    if (gGrayscHotKey != key) {
        [self removeHotKeys];
        gGrayscHotKey = key;
        [self installHotKeys];
        [self fillInfo];
        [self updatePreferencesDefaultsButton];
    }
}

/* Takes a screenshot using Quartz (available since 10.6). */
-(void)takeScreenShot
{
	// don't take screenshot when the main window is visible
	if ([mainWindow isVisible] == YES)
		return;
	
	if ([preferencesPanel isVisible] == YES || [aboutBox isVisible] == YES) {
		[self fadeOutPanelsAndTakeScreenshot];
		return;
	}
	
    // release previous screen capture, first the NSBitmapImageRep then the CGImage
    if (quartzScreenCapture != NULL)
        CGImageRelease(quartzScreenCapture);
    
    // an alternative screen could be specified here
    quartzScreenCapture = CGDisplayCreateImage(kCGDirectMainDisplay);
    // The caller of CGDisplayCreateImage is responsible for releasing the image
    // by calling CGImageRelease.
	if (quartzScreenCapture == NULL) {
		screenshot = nil;
		return;
	}
    
	// if the user has not granted rights to capture the screen, do not compute and show simulated color impaired visions
	if ([self canCaptureScreen] == NO) {
		CGImageRelease(quartzScreenCapture);
		quartzScreenCapture = NULL;
		screenshot = nil;
	} else {
		// convert to NSBitmapImageRep
		screenshot = [[NSBitmapImageRep alloc] initWithCGImage:quartzScreenCapture];
		// http://www.cocoadev.com/index.pl?NSBitmapImageRep
		// NSBitmapImageRep does not make a copy of the bitmap planes, it uses them
		// in-place, so make sure not to free them while screenshot is alive.
	}
}

// the user changed the screen resolution (and possibly other settings of
// the monitor). Fade out the mainWindow in this case.
- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
	// adjust size of mainWindow to screen size
    NSRect screenRect = [[NSScreen mainScreen] frame];
	[mainWindow setFrame:screenRect display:YES];
	
	// hide the mainWindow if it is currently visible
	[self fadeOutWindow];
}

// called when the homepage-button in the preferences panel is pressed
-(IBAction)showHomepage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:HOMEPAGE]];
}

// called when the defaults button in the preferences panel is pressed
-(IBAction)prefrencesDefaults:(id)sender
{
	gProtanHotKey = DEFAULTPROTANHOTKEY;
	gDeutanHotKey = DEFAULTDEUTANHOTKEY;
	gTritanHotKey = DEFAULTTRITANHOTKEY;
    gGrayscHotKey = DEFAULTGRAYSCALEHOTKEY;
    
	[protanHotKeyMenu selectItemAtIndex:[self fkey2menu:gProtanHotKey]];
	[deutanHotKeyMenu selectItemAtIndex:[self fkey2menu:gDeutanHotKey]];
	[tritanHotKeyMenu selectItemAtIndex:[self fkey2menu:gTritanHotKey]];
    [grayscaleHotKeyMenu selectItemAtIndex:[self fkey2menu:gGrayscHotKey]];
	
	[self updatePreferencesDefaultsButton];
}

// the preferences dialog, the about dialog, the permission dialog, or the welcome dialog will close.
- (void)windowWillClose:(NSNotification *)aNotification
{
	// hide this app if no window is visible after closing the window that sent this event.
	NSWindow *windowToClose = [aNotification object];
	
	// closing the welcome dialog
	if (windowToClose == welcomeDialog) {
		// send nil as source. This is an ugly hack that makes sure we are not
		// cascading close commands, which makes the app crash. This happens when
		// the dialog is closed by a click in the red button at the top left of
		// the window. If closeWelcomeDialog does [welcomeDialog: close], this
		// method is called again, etc.
		[self closeWelcomeDialog:nil];
		return;
	}
	
	// find all other visible dialogs and bring one of them to the foreground
	NSMutableArray *visibleDialogs = [[NSMutableArray alloc]init];
	if ([permissionDialog isVisible]) {
		[visibleDialogs addObject:permissionDialog];
	}
	if ([preferencesPanel isVisible]) {
		[visibleDialogs addObject:preferencesPanel];
	}
	if ([aboutBox isVisible]) {
		[visibleDialogs addObject:aboutBox];
	}
	[visibleDialogs removeObject: windowToClose];
	if ([visibleDialogs count] == 0) {
		[NSApp hide:self];
	} else {
		[[visibleDialogs firstObject] makeKeyAndOrderFront:nil]; // bring dialog to the foreground
	}
}

-(NSWindow*)preferencesPanel
{
	return preferencesPanel;
}

-(NSWindow*)aboutBox
{
	return aboutBox;
}

// update "launch at login" checkbox
- (void)updateLoginButton:(NSNotification *)notification {
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [loginButton setState: [launchController launchAtLogin]];
}

@end
