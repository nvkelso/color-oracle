/*
 *  WindowLevel.h
 *  ColorOracle
 *
 *  Created by Bernhard Jenny on 16.03.06.
 *  Copyright 2006 Institute of Cartography, ETH Zurich. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

// Defines the window level for windows covering the dock, but not the menu.

// NSFloatingWindowLevel and NSModalPanelWindowLevel do not cover the 
// dock, which is not what we want.
// We have to use window level kCGDockWindowLevel (=20) to cover the dock.
// The dock should be covered, otherwise the user can resize the dock
// while the simulation window is visible. A gost-dock and the resized
// dock would be visible in this case.
// NSMainMenuWindowLevel (=24) is reserved for the application’s main menu.
// NSStatusWindowLevel (=25) also covers the menu, which is not what we want.
// So use 23: this covers the dock plus the names that appear when the mouse
// hovers over icons in the dock (which seem to use 22)
#define WINDOWLEVEL 23
