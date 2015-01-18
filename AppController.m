//
//  AppController.m
//
//  Created by Bernhard Jenny on 01.09.05.
//  Copyright 2005 Bernhard Jenny. All rights reserved.
//  OpenGL code from http://www.idevapps.com/forum/showthread.php?t=5240
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

#import <OpenGL/gl.h>
#include "WindowLevel.h"
#import "AppController.h"
#import "ClickableImageView.h"
#import "KeyableWindow.h"
#include "InfoText.h"
#include "LoginItemsAE.h"

/* Web site for this project */
#define HOMEPAGE @"http://colororacle.org/"

/* Duration of the pause for the threat that is periodically checking for changes
in the list of login items. In seconds.*/
#define PREFS_THREAD_SLEEP 0.5

/* The priority of the thread that is periodically checking for changes
in the list of login items. Range of possible values [0..1]. */
#define PREFS_THREAD_PRIORITY 0.05

/* wait this long for the menu to hide */
#define MILLISEC_TO_HIDE_MENU 50

/* interval for animating the menu icon while displaying the welcome dialog. 
In seconds */
#define WELCOME_ANIMATION_INTERVAL 0.1

enum simulation {normalView, protan, deutan, tritan, grayscale};

// fading speed
#define FADETIMEINTERVAL 0.05
#define FADETRANSPARENCYSTEP 0.4

// Gamma for converting from screen rgb to linear rgb and back again.
// The publication describing the algorithm uses a gamma value of 2.2, which
// is the standard value on windows system and for sRGB. Macs mostly use a 
// gamma value of 1.8. Differences between the two gamma settings are
// hardly visible though.
#define GAMMA 1.8

enum {keyNone = -1, f1 = 0x7A, f2 = 0x78, f3 = 0x63, f4 = 0x76, f5 = 0x60, 
	f6 = 0x61, f7 = 0x62, f8 = 0x64, f9 = 0x65, f10 = 0x6D, f11 = 0x67,
	f12 = 0x6F, f13 = 0x69, f14 = 0x6B, f15 = 0x71, f16 = 0x6A};

#define DEFAULTDEUTANHOTKEY f5
#define DEFAULTPROTANHOTKEY f6
#define DEFAULTTRITANHOTKEY keyNone

// A bunch of defines to handle hotkeys
const UInt32 kHotKeyIdentifier='blnd';
UInt32 gProtanHotKey;
UInt32 gDeutanHotKey;
UInt32 gTritanHotKey;
EventHotKeyRef gProtanHotKeyRef;
EventHotKeyRef gDeutanHotKeyRef;
EventHotKeyRef gTritanHotKeyRef;
EventHotKeyID gProtanHotKeyID;
EventHotKeyID gDeutanHotKeyID;
EventHotKeyID gTritanHotKeyID;
EventHandlerUPP gAppHotKeyFunction;

EventHotKeyID gWindowsCloseHotKeyID;
const UInt32 kWindowsCloseHotKey = 0xd;	// 'w'
EventHotKeyRef gWindowsCloseHotKeyRef;


// This routine is called when a hotkey is pressed.
pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
	// We can assume our hotkey was pressed
	AppController *app = (AppController*)userData;
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
		case 4:	// close a window
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

-(int)menu2fkey:(int)menuItemID
{
	switch (menuItemID) {
		case 0:
			return keyNone;
		case 2:
			return f1;
		case 3:
			return f2;
		case 4:
			return f3;
		case 5:
			return f4;
		case 6:
			return f5;
		case 7:
			return f6;
		case 8:
			return f7;
		case 9:
			return f8;
		case 10:
			return f9;
		case 11:
			return f10;
		case 12:
			return f11;
		case 13:
			return f12;
		case 14:
			return f13;
		case 15:
			return f14;
		case 16:
			return f15;
		case 17:
			return f16;
	}
	return keyNone;
}

-(int)fkey2menu:(int)fkey
{
	switch (fkey) {
		case keyNone:
			return 0;
		case f1:
			return 2;
		case f2:
			return 3;
		case f3:
			return 4;
		case f4:
			return 5;
		case f5:
			return 6;
		case f6:
			return 7;
		case f7:
			return 8;
		case f8:
			return 9;
		case f9:
			return 10;
		case f10:
			return 11;
		case f11:
			return 12;
		case f12:
			return 13;
		case f13:
			return 14;
		case f14:
			return 15;
		case f15:
			return 16;
		case f16:
			return 17;
	}
	return -1;
}

-(NSString*)fkey2String:(int)fkey
{
	switch (fkey) {
		case f1:
			return @"F1";
		case f2:
			return @"F2";
		case f3:
			return @"F3";
		case f4:
			return @"F4";
		case f5:
			return @"F5";
		case f6:
			return @"F6";
		case f7:
			return @"F7";
		case f8:
			return @"F8";
		case f9:
			return @"F9";
		case f10:
			return @"F10";
		case f11:
			return @"F11";
		case f12:
			return @"F12";
		case f13:
			return @"F13";
		case f14:
			return @"F14";
		case f15:
			return @"F15";
		case f16:
			return @"F16";
	}
	return @"-";
}

-(long)fkey2Unicode:(int)fkey
{
	switch (fkey) {
		case f1:
			return NSF1FunctionKey;
		case f2:
			return NSF2FunctionKey;
		case f3:
			return NSF3FunctionKey;
		case f4:
			return NSF4FunctionKey;
		case f5:
			return NSF5FunctionKey;
		case f6:
			return NSF6FunctionKey;
		case f7:
			return NSF7FunctionKey;
		case f8:
			return NSF8FunctionKey;
		case f9:
			return NSF9FunctionKey;
		case f10:
			return NSF10FunctionKey;
		case f11:
			return NSF11FunctionKey;
		case f12:
			return NSF12FunctionKey;
		case f13:
			return NSF13FunctionKey;
		case f14:
			return NSF14FunctionKey;
		case f15:
			return NSF15FunctionKey;
		case f16:
			return NSF16FunctionKey;
	}
	return keyNone;
}


// from OverlayWindow.m in FunkyOverlayWindow sample code 
-(void)installHotKeys
{
	EventTypeSpec eventType;
    
    gAppHotKeyFunction = NewEventHandlerUPP(hotKeyHandler);
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(gAppHotKeyFunction,1,&eventType,self,NULL);
    
	// install first deutan, then protan, then tritan.
	// if two hot-keys use the same key, the first installed will be executed.
	
	if (gDeutanHotKey != keyNone) {
		gDeutanHotKeyID.signature=kHotKeyIdentifier;
		gDeutanHotKeyID.id=1;
		RegisterEventHotKey(gDeutanHotKey, 0, gDeutanHotKeyID, GetApplicationEventTarget(), 0, &gDeutanHotKeyRef);
	}
	
	if (gProtanHotKey != keyNone) {
		gProtanHotKeyID.signature=kHotKeyIdentifier;
		gProtanHotKeyID.id=2;
    	RegisterEventHotKey(gProtanHotKey, 0, gProtanHotKeyID, GetApplicationEventTarget(), 0, &gProtanHotKeyRef);
	}
	
	if (gTritanHotKey != keyNone) {
		gTritanHotKeyID.signature=kHotKeyIdentifier;
		gTritanHotKeyID.id=3;
		RegisterEventHotKey(gTritanHotKey, 0, gTritanHotKeyID, GetApplicationEventTarget(), 0, &gTritanHotKeyRef);
	}
}

-(void)removeHotKeys
{
	UnregisterEventHotKey (gProtanHotKeyRef);
	UnregisterEventHotKey (gDeutanHotKeyRef);
	UnregisterEventHotKey (gTritanHotKeyRef);
}

-(void)installCloseWindowsHotKey
{
	// add hot key handler for closing windows (preferences panel and about box)
    gWindowsCloseHotKeyID.signature=kHotKeyIdentifier;
    gWindowsCloseHotKeyID.id=4;
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
		&& gTritanHotKey == DEFAULTTRITANHOTKEY)
		[prefsDefaultsButton setEnabled:NO];
	else
		[prefsDefaultsButton setEnabled:YES];
}

-(OSStatus) appFSRef:(FSRef*) fsRefPtr
{
	// get path to application bundle
	NSBundle * bundle = [NSBundle mainBundle];
	const char * cpath = [[bundle bundlePath] fileSystemRepresentation];
	// The returned C string will be automatically freed just as a returned object
	// would be released;
	
	// convert path to FSRef
	Boolean isDirectory;
	return FSPathMakeRef((const UInt8 *)cpath, fsRefPtr, &isDirectory);
}

-(int) loginItemIndex
{
	FSRef		appFSRef;
	
	OSStatus err = [self appFSRef: &appFSRef];
	if (err != noErr)
		return - 1;
	
	return findLoginItemIndex(&appFSRef);
}

// a thread that adds this application to the login items
-(void) addToLoginItemsThread:(id)owner
{
	// a thread has to allocate its own NSAutoreleasePool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// grab loginItemsLock, so that the thread that is periodically 
	// updating the "Start Color Oracle at Login" switch will not interfere. 
	[loginItemsLock lock];
	
	// get the FSRef of this application
	FSRef fsRef;
	OSStatus err = [self appFSRef: &fsRef];
	if (err != noErr)
		return;
	
	// register FSRef as login item
	err = LIAEAddRefAtEnd(&fsRef, FALSE);
	
	// release the lock again
	[loginItemsLock unlock];
	
	// release the NSAutoreleasePool
	[pool release];
}

// a thread that removes this application from the login items
-(void) removeFromLoginItemsThread:(id)owner
{
	// a thread has to allocate its own NSAutoreleasePool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// grab loginItemsLock, so that the thread that is periodically 
	// updating the "Start Color Oracle at Login" switch will not interfere.
	[loginItemsLock lock];
	
	// get the position of this application in the list of login items
	int itemIndex = [self loginItemIndex];
	
	// remove this app, if it is a registered login item
	if (itemIndex >= 0)
		LIAERemove(itemIndex);
		
	// release the lock again
	[loginItemsLock unlock];
	
	// release the NSAutoreleasePool
	[pool release];
}

// a thread that periodically checks if this app is a registered login item
// and updates the "Start Color Oracle at Login" switch accordingly.
// This thread is running during the whole life of this app.
-(void)configurePrefsThread:(id) ownwer
{
	// a thread has to allocate its own NSAutoreleasePool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// assign very low priority to this thread
	[NSThread setThreadPriority: PREFS_THREAD_PRIORITY];
	
	// periodically check Login Items and configure the "Start Color Oracle at Login" 
	// switch accordingly
	while (true) {
		// only work if lock is not busy. This is the case when 
		// another thread adds or removes this app as a login item. 
		if ([loginItemsLock tryLock]) {
			// get the position of this app in the list of login items
			int loginItemIndex = [self loginItemIndex];
			
			// update the "Start Color Oracle at Login" switch
			if (loginItemIndex >= 0)
				[startAtLoginSwitch setState:NSOnState];
			else 
				[startAtLoginSwitch setState:NSOffState];
			
			// release the lock
			[loginItemsLock unlock];
			
			// enable the "Start Color Oracle at Login" switch, 
			// which is disabled before the preferences panel is made visible.
			[startAtLoginSwitch setEnabled:YES];
		}
				
		// take a nap
		[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow:PREFS_THREAD_SLEEP]];
		
		// test if the preferences panel is still visible (after taking a nap).
		// if not, exit this loop and this thread.
		if ([preferencesPanel isVisible] == NO || shouldQuit == YES) {
			break;
		}
	}
	
	// release the NSAutoreleasePool
	[pool release];
}

-(NSOpenGLContext*)createOpenGLContext
{
	NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAFullScreen,
        NSOpenGLPFASingleRenderer,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAScreenMask,
        CGDisplayIDToOpenGLDisplayMask(CGMainDisplayID()),
        0
    };
	
    NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc]
        initWithAttributes:attributes] autorelease];
    if (pixelFormat == nil)
        return NULL;
    
    return [[NSOpenGLContext alloc] initWithFormat:pixelFormat
											   shareContext:nil];
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
	statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];		
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
	[statusItem setMenu:m_menu];
	[statusItem setToolTip:TOOLTIPTEXT];
}

- (id)init
{
	[super init];
	if (self) {
		
		[self initLUTs];
		simulationID = normalView;
		screenshot = nil;
		quartzScreenCapture = nil;
		shouldQuit = NO;
		screenShotBuffer = nil;
		simulationBuffer = nil;
		
		gDeutanHotKey = f5;
		gProtanHotKey = f6;
		gTritanHotKey = keyNone;
		
		loginItemsLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{	
	[aboutBox center];
	[preferencesPanel center];
	[self initWindows];
	[self initMenu];
}

- (void)dealloc
{
	[statusItem release];
	[mainWindow release];
	[imageView release];
	[screenshot release];
	[simulation release];
		
	if (rgb2lin_red_LUT)
		free (rgb2lin_red_LUT);
	if (rgb2lin_red_LUT)
		free (rgb2lin_red_LUT);
	
	if (screenShotBuffer)
		free (screenShotBuffer);
	if (simulationBuffer)
		free (simulationBuffer);
    [super dealloc];
}

-(IBAction)selStartAtLogin:(id)sender
{
	if ([startAtLoginSwitch state] == NSOnState)
		[NSThread detachNewThreadSelector:@selector(addToLoginItemsThread:)
								 toTarget:self
							   withObject:self];
	else
		[NSThread detachNewThreadSelector:@selector(removeFromLoginItemsThread:)
								 toTarget:self
							   withObject:self];
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
	
	// OpenGL screen capture has to be vertically inverted, Quartz capture not.
	int invertImage = CGDisplayCreateImage == NULL;
	
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
	
	int rows = [screenshot pixelsHigh];
	int cols = [screenshot pixelsWide];
	int bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	if (invertImage)
		srcBitmapData += (rows - 1) * bytesPerRow;
	
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
	
	long *dstBitmapData = (long*)simulationBuffer;
	
	long prevSrc = 0;
	long color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			if (*((long*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color;
			} else {
				prevSrc = *((long*)srcPtr);
				
				// get linear rgb values in the range 0..2^15-1
				double red = rgb2lin_red_LUT[srcPtr[0 + alphaFirst]] / 32767.;
				double green = rgb2lin_red_LUT[srcPtr[1 + alphaFirst]] / 32767.;
				double blue = rgb2lin_red_LUT[srcPtr[2 + alphaFirst]] / 32767.;
				
				/* Convert to LMS (dot product with transform matrix) */
				double redOld   = red;
				double greenOld = green;
				red   = redOld * 0.05059983 + greenOld * 0.08585369 + blue * 0.00952420;
				green = redOld * 0.01893033 + greenOld * 0.08925308 + blue * 0.01370054;
				blue  = redOld * 0.00292202 + greenOld * 0.00975732 + blue * 0.07145979;
				
				double tmp = green / red;
				
				/* See which side of the inflection line we fall... */
				if (tmp < inflection)
					blue = -(a1 * red + b1 * green) / c1;
				else
					blue = -(a2 * red + b2 * green) / c2;
				
				/* Convert back to RGB (cross product with transform matrix) */
				redOld   = red;
				greenOld = green;
				long ired   = (int)(255. * (redOld * 30.830854 - 
											greenOld * 29.832659 + blue * 1.610474));
				long igreen = (int)(255. * (-redOld * 6.481468 + 
											greenOld * 17.715578 - blue * 2.532642));
				long iblue  = (int)(255. * (-redOld * 0.375690 - 
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
		if (invertImage)
			srcBitmapData-=bytesPerRow;
		else
			srcBitmapData+=bytesPerRow;
	}
}	

-(void)compute:(long) k1 k2:(long)k2 k3:(long)k3 
{
	int r, c;
	
	// OpenGL screen capture has to be vertically inverted, Quartz capture not.
	int invertImage = CGDisplayCreateImage == NULL;
	
	// RGBA (OpenGL capture) or ARGB (Quartz capture)?
	int alphaFirst = [screenshot bitmapFormat] & NSAlphaFirstBitmapFormat;
	
	int rows = [screenshot pixelsHigh];
	int cols = [screenshot pixelsWide];
	int bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	if (invertImage)
		srcBitmapData += (rows - 1) * bytesPerRow;
	
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
	
	long *dstBitmapData = (long*)simulationBuffer;
	
	long prevSrc = 0;
	long color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			// this version has been optimized for speed.
			// see at the begining of this file for a more readable version.
			if (*((long*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color; // re-use cached previous value
			} else {
				prevSrc = *((long*)srcPtr);
				
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
				const long red = lin2rgb_LUT[r_blind];
				const long blue = lin2rgb_LUT[b_blind];
				
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
		if (invertImage)
			srcBitmapData-=bytesPerRow;
		else
			srcBitmapData+=bytesPerRow;
	}
}

-(void)computeGrayscale
{
	/* Code for grayscale computation, modified from computeTritan.
	 Based on https://en.wikipedia.org/wiki/Grayscale#Colorimetric_.28luminance-preserving.29_conversion_to_grayscale
	 Tim van Werkhoven 20140318
	 */
	
	// OpenGL screen capture has to be vertically inverted, Quartz capture not.
	int invertImage = CGDisplayCreateImage == NULL;
	
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
	
	int r, c;
	
	int rows = [screenshot pixelsHigh];
	int cols = [screenshot pixelsWide];
	int bytesPerRow = [screenshot bytesPerRow];
	unsigned char *srcBitmapData = [screenshot bitmapData];
	if (srcBitmapData == nil)
		return;
	if (invertImage)
		srcBitmapData += (rows - 1) * bytesPerRow;
	
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
	
	long *dstBitmapData = (long*)simulationBuffer;
	
	long prevSrc = 0;
	long color = 0x000000ff;
	
	for (r = 0; r < rows; r++) {
		const unsigned char * srcPtr = srcBitmapData;
		for (c = 0; c < cols; c++) {
			if (*((long*)srcPtr) == prevSrc) {
				*(dstBitmapData++) = color;
			} else {
				prevSrc = *((long*)srcPtr);
				
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
				long ired   = (int)(255. * luminance);
				long igreen = (int)(255. * luminance);
				long iblue  = (int)(255. * luminance);
				
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
		if (invertImage)
			srcBitmapData-=bytesPerRow;
		else
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
			[self computeGrayscale];
			break;
		case grayscale:
			[self computeGrayscale];
			break;
	}
	
	int rows = [screenshot pixelsHigh];
	int cols = [screenshot pixelsWide];
	
	[simulation release];
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
	NSImage *image = [[[NSImage alloc] init] autorelease];
	[image addRepresentation:simulation];
	[image setFlipped:NO];
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
	
	NSString *deutanKeyStr = [self fkey2String:gDeutanHotKey];
	NSString *protanKeyStr = [self fkey2String:gProtanHotKey];
	NSString *tritanKeyStr = [self fkey2String:gTritanHotKey];
	
	NSString *deutanStr = @"";
	if (gDeutanHotKey != keyNone) {
		deutanStr = [NSString stringWithFormat: INFOMESSAGEPRESS_DEUTAN, deutanKeyStr];
		if (gProtanHotKey != keyNone && gTritanHotKey != keyNone)
			deutanStr = [deutanStr stringByAppendingString: @","];
		else if (gProtanHotKey != keyNone || gTritanHotKey != keyNone)
			deutanStr = [deutanStr stringByAppendingString: @" and"];
	}
	
	NSString *protanStr = @"";
	if (gProtanHotKey != keyNone) {
		protanStr = [NSString stringWithFormat: INFOMESSAGEPRESS_PROTAN, protanKeyStr];
		if (gTritanHotKey != keyNone)
			protanStr = [protanStr stringByAppendingString: @" and"];
	}
	
	NSString *tritanStr = gTritanHotKey == keyNone ? @"" :
		[NSString stringWithFormat: INFOMESSAGEPRESS_TRITAN, tritanKeyStr];
	
	NSString *fKeyStr = @"";
	if (gDeutanHotKey != keyNone || gProtanHotKey != keyNone || gTritanHotKey != keyNone)
		fKeyStr = [NSString stringWithFormat: INFOMESSAGEPRESS,
			deutanStr, protanStr, tritanStr];
	
	
	NSString *infoStr = [NSString stringWithFormat: INFOMESSAGE, fKeyStr];
	[infoView setInfo2:infoStr];
}

-(int)simulationID
{
	return simulationID;
}

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
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
		return YES;
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
		return YES;
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
		return YES;
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
    timer = [[NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL 
											  target:self 
											selector:@selector(fadeIn:) 
											userInfo:nil repeats:YES] retain];
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
        [timer release];
        timer = nil;
		
		[self finishFadeIn];
	}
}

-(void) fadeOutWindow
{
	if ([mainWindow isVisible] == NO || timer != nil)
		return;
	
	// Set up the timer to periodically call the fadeOut: method.
	timer = [[NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL 
											  target:self 
											selector:@selector(fadeOut:) 
											userInfo:nil repeats:YES] retain];
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
        [timer release];
        timer = nil;
		[self finishFadeOut];
	}
}

-(void)finishFadeOutAndSave
{
	[mainWindow orderOut:self];
	
	// setup the save panel
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"Save Image"];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"tif", @"tiff", nil]];

	if (simulationID == protan)
		[savePanel setMessage:@"Save the screen with simulated protan color vision to a TIFF file."];
	else if (simulationID == deutan)
		[savePanel setMessage:@"Save the screen with simulated deutan color vision to a TIFF file."];
	else if (simulationID == tritan)
		[savePanel setMessage:@"Save the screen with simulated tritan color vision to a TIFF file."];
	
	// setNameFieldStringValue available with OS X 10.6 or newer
	if ([savePanel respondsToSelector:@selector(setNameFieldStringValue:)]) {
		if (simulationID == protan)
			[savePanel setNameFieldStringValue: @"Protanopia.tif"];
		else if (simulationID == deutan)
			[savePanel setNameFieldStringValue: @"Deuteranopia.tif"];
		else if (simulationID == tritan)
			[savePanel setNameFieldStringValue: @"Tritanopia.tif"];
	}
	
	simulationID = normal;
	
	[savePanel setLevel:WINDOWLEVEL];
	[savePanel orderFront:self];
	[savePanel runModal];
	
	// get path to new file
	NSURL *url = [savePanel URL];
	
	// hides this app when no dialog is visible
	[self finishFadeOut];
	
	// test for canceling by user
	if ( url == NULL )
		return;
	
	// write to tiff file
	NSData *tiff = [simulation TIFFRepresentation];
	[tiff writeToURL:url atomically:YES];
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
        [timer release];
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
	timer = [[NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL 
											  target:self 
											selector:@selector(fadeOutPanelsAndTakeScreenshot:) 
											userInfo:nil repeats:YES] retain];
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
        [timer release];
        timer = nil;
		[self finishfadeOutPanelsAndTakeScreenshot];
	}
}

-(void)updateSimulation
{
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

-(void)takeScreenshotAndUpdateSimulation
{
	// take a screenshot
	[self takeScreenShot];
	[self updateSimulation];
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

/* sender == self indicates that this method is being called from an AppleScript */
-(IBAction)selItemProtan:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	simulationID = protan;
	[statusItem setImage:[NSImage imageNamed:@"menuIconProtan"]];
	
	// hide the menu if this method was called from the menu
	if (sender != nil && sender != self)
		[self hideMenu];
		
	// set the level of the main window to normal level if this method is called 
	// from an AppleScript, set it to a level covering the dock otherwise.
	[mainWindow setLevel:sender == self ? kCGNormalWindowLevel : WINDOWLEVEL];
	
	[self takeScreenshotAndUpdateSimulation];
}

/* sender == self indicates that this method is being called from an AppleScript */
-(IBAction)selItemDeutan:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	simulationID = deutan;
	[statusItem setImage:[NSImage imageNamed:@"menuIconDeutan"]];
	
	// hide the menu if this method was called from the menu
	if (sender != nil && sender != self)
		[self hideMenu];
	
	// set the level of the main window to normal level if this method is called 
	// from an AppleScript, set it to a level covering the dock otherwise.
	[mainWindow setLevel:sender == self ? kCGNormalWindowLevel : WINDOWLEVEL];
	
	[self takeScreenshotAndUpdateSimulation];
}

/* sender == self indicates that this method is being called from an AppleScript */
-(IBAction)selItemTritan:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	simulationID = tritan;
	[statusItem setImage:[NSImage imageNamed:@"menuIconTritan"]];
	
	// hide the menu if this method was called from the menu
	if (sender != nil && sender != self)
		[self hideMenu];
	
	// set the level of the main window to normal level if this method is called 
	// from an AppleScript, set it to a level covering the dock otherwise.
	[mainWindow setLevel:sender == self ? kCGNormalWindowLevel : WINDOWLEVEL];
	
	[self takeScreenshotAndUpdateSimulation];
}

/* sender == self indicates that this method is being called from an AppleScript */
-(IBAction)selItemGrayscale:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	simulationID = grayscale;
	//[statusItem setImage:[NSImage imageNamed:@"menuIconTritan"]]; Ignore this for now
	
	// hide the menu if this method was called from the menu
	if (sender != nil && sender != self)
		[self hideMenu];
	
	// set the level of the main window to normal level if this method is called
	// from an AppleScript, set it to a level covering the dock otherwise.
	[mainWindow setLevel:sender == self ? kCGNormalWindowLevel : WINDOWLEVEL];
	
	[self takeScreenshotAndUpdateSimulation];
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
	timer = [[NSTimer scheduledTimerWithTimeInterval:FADETIMEINTERVAL 
											  target:self 
											selector:@selector(fadeOutAndSave:) 
											userInfo:nil repeats:YES] retain];
}

/*
 -(IBAction)selItemHelp:(id)sender
 {
	// close welcome dialog, should it still be open
	 [self closeWelcomeDialog:self];
	 simulationID = normalView;
	 [self fadeOutWindow];
	 NSBundle * appBundle = [NSBundle mainBundle];
	 NSString * nsPath = [appBundle pathForResource: [NSString stringWithCString: "help"]
											 ofType:[NSString stringWithCString: "html"] 
										inDirectory:[NSString stringWithCString: "help"]];
	 if (nsPath)
		 AHGotoPage (NULL, (CFStringRef)nsPath, NULL); 
 }
 */

-(IBAction)selItemPreferences:(id)sender
{
	// close welcome dialog, should it still be open
	[self closeWelcomeDialog:self];
	
	// if simulation window is visible, first hide the simulation window
	if ([mainWindow isVisible])
		[self selItemNormal:self];
	
	[NSApp activateIgnoringOtherApps: YES];
	
	// bring the about box to the foreground if it is visible
	if ([aboutBox isVisible])
		[aboutBox orderFront:self];
	
	// only configure GUI of preferences panel if the panel is not visible yet.
	if ([preferencesPanel isVisible] == NO) {
		// configure menus for selecting function keys
		[protanHotKeyMenu selectItemAtIndex:[self fkey2menu:gProtanHotKey]];
		[deutanHotKeyMenu selectItemAtIndex:[self fkey2menu:gDeutanHotKey]];
		[tritanHotKeyMenu selectItemAtIndex:[self fkey2menu:gTritanHotKey]];
		
		// disable "Start Color Oracle at Login" switch
		// it will be enabled by another thread that periodically checks if
		// this application is registered as a login item
		[startAtLoginSwitch setEnabled:NO];
		
		// enable / disable button for resetting preferences to default values.
		[self updatePreferencesDefaultsButton];
		
		[NSThread detachNewThreadSelector:@selector(configurePrefsThread:)
								 toTarget:self 
							   withObject:self];
	}
	
	// bring the preferences panel ot the foreground
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
		
	[NSApp activateIgnoringOtherApps: YES];
	
	// bring the preferencesPanel to the foreground if it is visible
	if ([preferencesPanel isVisible])
		[preferencesPanel orderFront:self];
	
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
	[self selItemNormal:self];
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
	NSString *newName = [NSString stringWithFormat:@"%i", imageID];
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
		[timer release];
		timer = nil;
	}
	
	// make sure the icon is the default menu icon
	[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// retrieve the hot keys from the preference file
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	gProtanHotKey = [defaults integerForKey:@"protanHotKey"];
	if (gProtanHotKey == 0)
		gProtanHotKey = DEFAULTPROTANHOTKEY;
	gDeutanHotKey = [defaults integerForKey:@"deutanHotKey"];
	if (gDeutanHotKey == 0)
		gDeutanHotKey = DEFAULTDEUTANHOTKEY;
	gTritanHotKey = [defaults integerForKey:@"tritanHotKey"];
	if (gTritanHotKey == 0)
		gTritanHotKey = DEFAULTTRITANHOTKEY;
	[self installHotKeys];
	
	// get position of infoWindow from preferences file
	int boxH = [defaults integerForKey:@"boxH"];
	int boxV = [defaults integerForKey:@"boxV"];
    if (boxH == 0 || boxV == 0)
		[infoWindow center];
	else
		[infoWindow setFrameOrigin:NSMakePoint(boxH, boxV)];
	
	// set height of infoWindow from preferences file
	int height = [defaults integerForKey:@"boxHeight"];
	if (height > 0) {
		NSRect frame = [infoWindow frame];
		frame.size.height = height;
		[infoWindow setFrame:frame display:YES];
	}
	
	// make sure the infoWindow is visible on the screen
	NSRect screenRect = [[infoWindow screen] frame];
	if (NSContainsRect(screenRect, [infoWindow frame]) == NO)
		[infoWindow center];
	
	// show welcome dialog if this is the first time Color Oracle is launched
	// test for the protan hot key (could be any other item in the defaults).
	BOOL launchedBefore = [defaults boolForKey:@"launchedBefore"];
	if (launchedBefore == NO) {	
		[welcomeDialog center];
		[welcomeDialog setLevel:WINDOWLEVEL];
		[welcomeDialog makeKeyAndOrderFront:self];
		timer = [[NSTimer scheduledTimerWithTimeInterval:WELCOME_ANIMATION_INTERVAL 
												  target:self 
												selector:@selector(animateMenuIcon:) 
												userInfo:nil repeats:YES] retain];
		[defaults setBool:YES forKey:@"launchedBefore"];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// store the hot keys in the preference file
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:gProtanHotKey forKey:@"protanHotKey"];
	[defaults setInteger:gDeutanHotKey forKey:@"deutanHotKey"];
	[defaults setInteger:gTritanHotKey forKey:@"tritanHotKey"];
	
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

/* Takes a screenshot with Quartz Display Services to capture a screen, using 
 CGDisplayCreateImage. This code works starting with OSX 10.6. It does not work 
 with OSX 10.5 or earlier.
 */
-(void)takeQuartzScreenShot
{
	// release previous screen capture, first the NSBitmapImageRep then the CGImage
	if (screenshot != NULL)
		[screenshot release];
	if (quartzScreenCapture != NULL)
		CGImageRelease(quartzScreenCapture);
	
	// an alternative screen could be specified here
	quartzScreenCapture = CGDisplayCreateImage(kCGDirectMainDisplay);
	// The caller of CGDisplayCreateImage is responsible for releasing the image
	// by calling CGImageRelease.
	if (quartzScreenCapture == NULL)
		return;
	
	// convert to NSBitmapImageRep
	screenshot = [[NSBitmapImageRep alloc] initWithCGImage:quartzScreenCapture];
	// http://www.cocoadev.com/index.pl?NSBitmapImageRep
	// NSBitmapImageRep does not make a copy of the bitmap planes, it uses them
	// in-place, so make sure not to free them while screenshot is alive.
}

/* Takes a screenshot using OpenGL. This code is based on the 
 OpenGLScreenSnapshot code example. This current version is not the most
 efficient one.
 It works with OSX verions until 10.6. It does not work on OSX 10.7.
 */
-(void)takeOpenGLScreenShot
{
	NSOpenGLContext * openGLContext = [self createOpenGLContext];
	if (openGLContext == NULL)
		return;
	[openGLContext setFullScreen];
    [openGLContext makeCurrentContext];
    
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    unsigned width = viewport[2];
    unsigned height = viewport[3];
    
	// recycle the buffer if it has been allocated before and if it's 
	// the right size.
	if (width != screenShotBufferWidth || height != screenShotBufferHeight
		|| screenShotBuffer == nil) {
		if (screenShotBuffer != nil)
			free (screenShotBuffer);
		screenShotBuffer = malloc(width * height * 4);
		screenShotBufferWidth = width;
		screenShotBufferHeight = height;
	}
	
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
	/* glReadPixels is very slow*/
	/*
	 http://www.idevgames.com/forum/archive/index.php/t-7463.html
	 Use a native pixel format to avoid CPU bit swizzling.
	 
	 glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV, pixels);
	 or
	 glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, pixels);
	 
	 make sure the rowbytes is a multiple of 32, in case DMA alignment is an issue.
	 
	 Also see http://www.opengl.org/resources/faq/technical/performance.htm
	 */
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, screenShotBuffer);
    
    [openGLContext clearDrawable];
    
	[screenshot release];
    screenshot = [[NSBitmapImageRep alloc]
				  initWithBitmapDataPlanes:&screenShotBuffer
				  /* NSBitmapImageRep will only reference the image data; it won’t copy it. 
				   The buffers won’t be freed when the NSBitmapImageRep is freed. */
				  pixelsWide:width
				  pixelsHigh:height
				  bitsPerSample:8
				  samplesPerPixel:4
				  hasAlpha:YES
				  isPlanar:NO
				  colorSpaceName:NSDeviceRGBColorSpace
				  bytesPerRow:width * 4
				  bitsPerPixel:32];
	
	[openGLContext release];
}

/* Takes a screenshot. */
-(void)takeScreenShot
{
	// don't take screenshot when the main window is visible
	if ([mainWindow isVisible] == YES)
		return;
	
	if ([preferencesPanel isVisible] == YES || [aboutBox isVisible] == YES) {
		[self fadeOutPanelsAndTakeScreenshot];
		return;
	}
	
	// the deployment target of this project is 10.4
	// the target SDK is the latest available (i.e. 10.6 or later)
	// XCode is using weak links in this case. That is, CGDisplayCreateImage is
	// weakly linked. The presence of CGDisplayCreateImage has to be tested
	// before it is called in this case.
	// http://developer.apple.com/library/mac/#documentation/MacOSX/Conceptual/BPFrameworks/Concepts/WeakLinking.html
	if (CGDisplayCreateImage == NULL) {
		[self takeOpenGLScreenShot];
	} else {
		[self takeQuartzScreenShot];
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

	[protanHotKeyMenu selectItemAtIndex:[self fkey2menu:gProtanHotKey]];
	[deutanHotKeyMenu selectItemAtIndex:[self fkey2menu:gDeutanHotKey]];
	[tritanHotKeyMenu selectItemAtIndex:[self fkey2menu:gTritanHotKey]];
	
	[self updatePreferencesDefaultsButton];
}

// the prefs panel or the about box or the welcome dialog will close
- (void)windowWillClose:(NSNotification *)aNotification
{
	// hide this app if no window is visible after closing the window that sent this event.
	NSWindow *window = [aNotification object];
	
	// closing the welcome dialog
	if (window == welcomeDialog) {
		// send nil as source. This is an ugly hack that makes sure we are not
		// cascading close commands, which makes the app crash. This happens when
		// the dialog is closed by a click in the red button at the top left of 
		// the window. If closeWelcomeDialog does [welcomeDialog: close], this
		// method is called again, etc.
		[self closeWelcomeDialog:nil];
		return;
	}
	
	if ((window == aboutBox && [preferencesPanel isVisible] == NO)
		|| (window == preferencesPanel && [aboutBox isVisible] == NO))
		[NSApp hide:self];
	// bring the remaining window to the foreground
	else if (window == aboutBox)
		[preferencesPanel makeKeyAndOrderFront:nil];
	else
		[aboutBox makeKeyAndOrderFront:nil];
}

-(NSWindow*)preferencesPanel
{
	return preferencesPanel;
}

-(NSWindow*)aboutBox
{
	return aboutBox;
}

/* return whether a applescript hanlder is supported */
- (BOOL)application:(NSApplication *)sender 
 delegateHandlesKey:(NSString *)key
{
    if ([key isEqual:@"simulation"]) {
        return YES;
    } else {
        return NO;
    }
}

// for AppleScript support
- (NSString *)simulation
{
	switch (simulationID) {
		case normalView:
			return @"normal";
		case protan:
			return @"protan";
		case deutan:
			return @"deutan";
		case tritan:
			return @"tritan";
	}
    return nil;
}

// for AppleScript support
- (void)setSimulation:(NSString *)key
{
	if (key == nil)
		return;
	
	// test case insensitive for first 6 characters of key.
	// i.e. 'deutan', 'deutanope', 'Deuteranopia' are all valid keys.
	NSRange range = NSMakeRange (0, 6);
	
	if ([key compare:@"normal" options:NSCaseInsensitiveSearch range:range] == NSOrderedSame) {
		[statusItem setImage:[NSImage imageNamed:@"menuIcon"]];
		simulationID = normalView;
		
		// don't call [self finishFadeOut], which would call [NSApp hide:nil] to deactivate the app.
		// Hiding this app will be done by the scripting engine.
		// Instead, just order the mainWindow out. 
		[mainWindow orderOut:self];
		return;
	}
		
	if ([key compare:@"deutan" options:NSCaseInsensitiveSearch range:range] == NSOrderedSame) {
		[self selItemDeutan:self];
		return;
	}
	
	if ([key compare:@"protan" options:NSCaseInsensitiveSearch range:range] == NSOrderedSame) {
		[self selItemProtan:self];
		return;
	}
	
	if ([key compare:@"tritan" options:NSCaseInsensitiveSearch range:range] == NSOrderedSame) {
		[self selItemTritan:self];
		return;
	}
}

@end
