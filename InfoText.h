/*
 *  InfoText.h
 *
 *  Created by Bernhard Jenny on 13.03.06.
 *
 */

#define _I10NS(nsstr) NSLocalizedStringFromTable(nsstr, @"InfoText", nil)

#define DEUTANTEXT _I10NS(@"Deuteranopia")
#define PROTANTEXT _I10NS(@"Protanopia")
#define TRITANTEXT _I10NS(@"Tritanopia")
#define GRAYSCTEXT _I10NS(@"Grayscale")

#define DEUTANINFOTEXT _I10NS(@"Common.\nGreen deficiency affects about 5% of all males.")
#define PROTANINFOTEXT _I10NS(@"Rare.\nRed deficiency affects about 2.5% of all males.")
#define TRITANINFOTEXT _I10NS(@"Extremely rare.\nBlue deficiency affects about 0.5% of all males.")
#define GRAYSCINFOTEXT _I10NS(@"Luminance-preserving grayscale simulation.\n")

#define TOOLTIPTEXT _I10NS(@"Color Oracle - Simulate Color Blind Vision")

#define INFO_MESSAGE_PART1 _I10NS(@"Press → or ← to switch modes")

#define INFO_MESSAGE_PART2 _I10NS(@"Click and drag to move this panel.\nClick the mouse or press any other key to return to normal vision.")

#define INFOMESSAGEPRESS_DEUTAN _I10NS(@" %@ for deutan")
#define INFOMESSAGEPRESS_PROTAN _I10NS(@" %@ for protan")
#define INFOMESSAGEPRESS_TRITAN _I10NS(@" %@ for tritan")
#define INFOMESSAGEPRESS_GRAYSC _I10NS(@" %@ for grayscale")
