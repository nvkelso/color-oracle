/*
 *  Milliseconds.h
 *  test
 *
 *  Created by Bernhard Jenny on 13.03.06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

UnsignedWide get_Mac_microseconds(void)
{
	UnsignedWide microsec;	/* 
	* microsec.lo and microsec.hi are
				 * unsigned long's, and are the two parts
				 * of a 64 bit unsigned integer 
				 */
	
	Microseconds(&microsec);	/* get time in microseconds */
	return microsec;
}

UnsignedWide time_diff(UnsignedWide t1, UnsignedWide t2)
/* This function takes the difference t1 - t2 of two 64 bit
integers, represented by the 32 bit lo and hi words.
if t1 < t2, returns 0. */
{
	UnsignedWide diff;
	
	if (t1.hi < t2.hi) { /* something is wrong...t1 < t2! */
		diff.hi = diff.lo = 0;
		return diff;
	} else
		diff.hi = t1.hi - t2.hi;

	if (t1.lo < t2.lo) {
		if (diff.hi > 0)
	       diff.hi -= 1; /* carry */
		else { /* something is wrong...t1 < t2! */
	       diff.hi = diff.lo = 0;
	       return diff;
		}
	}

	diff.lo = t1.lo - t2.lo;

	return diff;
}
