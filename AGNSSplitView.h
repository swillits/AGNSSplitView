//
//  AGNSSplitView.h
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2014 Araelium Group. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// 1) The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// 2) The Software is provided "as is", without warranty of any kind, express or implied, including
// but not limited to the warranties of merchantability, fitness for a particular purpose and
// noninfringement. In no event shall the authors or copyright holders be liable for any claim,
// damages or other liability, whether in an action of contract, tort or otherwise, arising from,
// out of or in connection with the Software or the use or other dealings in the Software.
// 

#import <Cocoa/Cocoa.h>


typedef void (^AGNSSplitViewDividerDrawingHandler)(NSRect dividerRect);

@interface AGNSSplitView : NSSplitView {
	BOOL mDrawsDivider;
	BOOL mOverridingThickness;
	CGFloat mDividerThickness;
	NSColor * mDividerColor;
	NSRectEdge mDividerLineEdge;
	BOOL mDrawsDividerHandle;
	AGNSSplitViewDividerDrawingHandler mDividerDrawingHandler;
}

@property (nonatomic, readwrite, assign) CGFloat dividerThickness;
@property (nonatomic, readwrite, assign) BOOL drawsDivider;
@property (nonatomic, readwrite, retain) NSColor * dividerColor;
@property (nonatomic, readwrite, assign) NSRectEdge dividerLineEdge;
@property (nonatomic, readwrite, assign) BOOL drawsDividerHandle;
@property (nonatomic, readwrite, copy) AGNSSplitViewDividerDrawingHandler dividerDrawingHandler;

// add a convenience method for collapsing, uncollapsing

@end
