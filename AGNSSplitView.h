//
//  AGNSSplitView.h
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef void (^AGNSSplitViewDrawDividerBlock)(NSRect rect);

@interface AGNSSplitView : NSSplitView {
	BOOL mDrawsDivider;
	BOOL mOverridingThickness;
	CGFloat mDividerThickness;
	NSColor * mDividerColor;
	NSRectEdge mDividerLineEdge;
	BOOL mDrawsDividerHandle;
	AGNSSplitViewDrawDividerBlock mDrawBlock;
}

@property (readwrite, assign) CGFloat dividerThickness;
@property (readwrite, assign) BOOL drawsDivider;
@property (readwrite, retain) NSColor * dividerColor;
@property (readwrite, assign) NSRectEdge dividerLineEdge;
@property (readwrite, assign) BOOL drawsDividerHandle;
@property (readwrite, copy) AGNSSplitViewDrawDividerBlock drawBlock;

// add a convenience method for collapsing, uncollapsing

@end
