//
//  AppController.h
//  test
//
//  Created by Bernhard Jenny on 01.09.05.
//  Copyright 2005 Bernhard Jenny. All rights reserved.
//

/* set LSUIElement to 1 in th Info.plist file
 don't use NSBGOnly, no key events are sent with this option! */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import "ClickableImageView.h"
#import "KeyableWindow.h"
#import "RoundedView.h"

@interface AppController : NSObject {
	
	int simulationID;
	NSStatusItem *statusItem;
	KeyableWindow *mainWindow;
	ClickableImageView *imageView;
	NSBitmapImageRep *screenshot;
	CGImageRef quartzScreenCapture;
	NSBitmapImageRep *simulation;
	NSTimer *timer;
	NSApplication *prevActiveApp;
	
	IBOutlet NSMenu *m_menu;
	IBOutlet NSWindow *infoWindow;
	IBOutlet RoundedView *infoView;
	IBOutlet NSPanel *preferencesPanel;
	IBOutlet NSPopUpButton *deutanHotKeyMenu;
	IBOutlet NSPopUpButton *protanHotKeyMenu;
	IBOutlet NSPopUpButton *tritanHotKeyMenu;
	IBOutlet NSButton *startAtLoginSwitch;
	IBOutlet NSPanel *aboutBox;
	IBOutlet NSButton *prefsDefaultsButton;
	IBOutlet NSPanel *welcomeDialog;
	
	unsigned short * rgb2lin_red_LUT;
	unsigned char * lin2rgb_LUT;
	
	unsigned char *screenShotBuffer;
	unsigned screenShotBufferWidth;
	unsigned screenShotBufferHeight;
	
	unsigned char *simulationBuffer;
	unsigned simulationBufferWidth;
	unsigned simulationBufferHeight;
	
	NSLock *loginItemsLock;
	BOOL shouldQuit;
}

-(int)simulationID;
-(IBAction)selItemProtan:(id)sender;
-(IBAction)selItemDeutan:(id)sender;
-(IBAction)selItemTritan:(id)sender;
-(IBAction)selItemGrayscale:(id)sender;
-(IBAction)selItemNormal:(id)sender;
-(IBAction)selItemSave:(id)sender;
-(IBAction)selItemPreferences:(id)sender;
-(IBAction)selItemAbout:(id)sender;
//-(IBAction)selItemHelp:(id)sender;
-(IBAction)selItemQuit:(id)sender;
-(IBAction)protanKey:(id)sender;
-(IBAction)deutanKey:(id)sender;
-(IBAction)tritanKey:(id)sender;
-(IBAction)selStartAtLogin:(id)sender;
-(IBAction)showHomepage:(id)sender;
-(IBAction)prefrencesDefaults:(id)sender;
-(void)updateSimulation;
-(void)takeScreenShot;
-(void)finishFadeOut;
-(NSWindow*)preferencesPanel;
-(NSWindow*)aboutBox;
-(IBAction)closeWelcomeDialog:(id)sender;
/*
-(void)normal;
-(void)deutan;
-(void)protan;
-(void)tritan;
*/
@end
