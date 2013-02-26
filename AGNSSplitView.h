//
//  AGNSSplitView.h
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2008-2013 Araelium Group. All rights reserved.
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
