//
//  AGNSSplitView.m
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2008-2013 Araelium Group. All rights reserved.
//

#import "AGNSSplitView.h"


@implementation AGNSSplitView

- (id)initWithFrame:(NSRect)frame;
{
	if (!(self = [super initWithFrame:frame])) {
		return nil;
	}
	
	mDrawsDivider = YES;
	mDrawsDividerHandle = YES;
	mDividerThickness = 1.0;
	mDividerLineEdge = NSMaxYEdge;
	mDividerColor = [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] retain];
	
	return self;
}


- (id)initWithCoder:(NSCoder *)coder;
{
	if (!(self = [super initWithCoder:coder])) {
		return nil;
	}
	
	mDrawsDivider = YES;
	mDrawsDividerHandle = YES;
	mDividerThickness = 1.0;
	mDividerLineEdge = NSMaxYEdge;
	mDividerColor = [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] retain];
	
	return self;
}


- (void)dealloc;
{
	[mDividerColor release];
	[mDividerDrawingHandler release];
	[super dealloc];
}




#pragma mark -
#pragma mark Properties

@synthesize dividerDrawingHandler = mDividerDrawingHandler;
@synthesize drawsDivider = mDrawsDivider;
@synthesize dividerLineEdge = mDividerLineEdge;
@synthesize drawsDividerHandle = mDrawsDividerHandle;


- (void)setDrawsDivider:(BOOL)draws;
{
	mDrawsDivider = draws;
	self.needsDisplay = YES;
}


- (void)setDividerColor:(NSColor *)color;
{
	[color retain];
	[mDividerColor release];
	mDividerColor = color;
}


- (NSColor *)dividerColor;
{
	return (mDividerColor ? : super.dividerColor);
}


- (void)setDividerThickness:(CGFloat)dividerThickness;
{
	mOverridingThickness = YES;
	mDividerThickness = dividerThickness;
	[self adjustSubviews];
}


- (CGFloat)dividerThickness;
{
	return (mOverridingThickness ? mDividerThickness : super.dividerThickness);
}


- (void)setDividerLineEdge:(NSRectEdge)edge;
{
	mDividerLineEdge = edge;
	self.needsDisplay = YES;
}


- (void)setDrawsDividerHandle:(BOOL)drawsHandle;
{
	mDrawsDividerHandle = drawsHandle;
	self.needsDisplay = YES;
}







#pragma mark -
#pragma mark Drawing

- (void)drawDividerInRect:(NSRect)dividerRect
{
	if (!self.drawsDivider) {
		return;
	}
	
	if (self.dividerDrawingHandler) {
		self.dividerDrawingHandler(dividerRect);
		return;
	}
	
	
	switch (self.dividerStyle) {
		
		// Assuming a 1 point thin divider
		case NSSplitViewDividerStyleThin:
			[self.dividerColor set];
			NSRectFill(dividerRect);
			break;
		
		// The divider is thicker than 1 point, but a separator
		// line is drawn 1 point wide on the dividerLineEdge.
		case NSSplitViewDividerStyleThick:
		case NSSplitViewDividerStylePaneSplitter:
		default:
			
			if (self.drawsDividerHandle) {
				NSColor * dividerColor = mDividerColor;
				mDividerColor = [NSColor clearColor];
				[super drawDividerInRect:dividerRect];
				mDividerColor = dividerColor;
			}
			
			[self.dividerColor set];
			
			switch (mDividerLineEdge) {
				case NSMaxYEdge:
					dividerRect.origin.y += dividerRect.size.height - 1.0;
					dividerRect.size.height = 1.0;
					break;
				case NSMinYEdge:
					dividerRect.size.height = 1.0;
					break;
				case NSMaxXEdge:
					dividerRect.origin.x += dividerRect.size.width - 1.0;
					dividerRect.size.width = 1.0;
					break;
				case NSMinXEdge:
					dividerRect.size.width = 1.0;
					break;
			}
			
			NSRectFill(dividerRect);
			break;
	}
}

@end
