//
//  AGNSSplitView.m
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2008 Araelium Group. All rights reserved.
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
	mDrawsDivider = YES;
	mDrawsDividerHandle = YES;
	mDividerThickness = 1.0;
	mDividerLineEdge = NSMaxYEdge;
	mDividerColor = [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] retain];
	
	if (!(self = [super initWithCoder:coder])) {
		return nil;
	}
	
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

- (void)setDrawsDivider:(BOOL)draws;
{
	mDrawsDivider = draws;
	[self setNeedsDisplay:YES];
}


- (BOOL)drawsDivider;
{
	return mDrawsDivider;
}


- (void)setDividerColor:(NSColor *)color;
{
	[color retain];
	[mDividerColor release];
	mDividerColor = color;
}


- (NSColor *)dividerColor;
{
	if (!mDividerColor) {
		if ([super respondsToSelector:@selector(dividerColor)]) {
			return [super performSelector:@selector(dividerColor)];
		}
	}
	
	return mDividerColor;
}


- (void)setDividerThickness:(CGFloat)dividerThickness;
{
	mOverridingThickness = YES;
	mDividerThickness = dividerThickness;
	[self adjustSubviews];
}

- (CGFloat)dividerThickness;
{
	if (!mOverridingThickness) return [super dividerThickness];
	return mDividerThickness;
}


- (void)setDividerLineEdge:(NSRectEdge)edge;
{
	mDividerLineEdge = edge;
	[self setNeedsDisplay:YES];
}


- (NSRectEdge)dividerLineEdge;
{
	return mDividerLineEdge;
}


- (void)setDrawsDividerHandle:(BOOL)drawsHandle;
{
	mDrawsDividerHandle = drawsHandle;
	[self setNeedsDisplay:YES];
}


- (BOOL)drawsDividerHandle;
{
	return mDrawsDividerHandle;
}




#pragma mark -
#pragma mark Drawing

- (void)drawDividerInRect:(NSRect)dividerRect
{
	if ([self drawsDivider]) {
		
		if (self.dividerDrawingHandler) {
			self.dividerDrawingHandler(dividerRect);
			return;
		}
		
		if ([self dividerStyle] == NSSplitViewDividerStyleThin) {
			[[self dividerColor] set];
			NSRectFill(dividerRect);
		} else {
			
			if ([self drawsDividerHandle]) {
				NSColor * dividerColor = mDividerColor;
				mDividerColor = [NSColor clearColor];
				[super drawDividerInRect:dividerRect];
				mDividerColor = dividerColor;
			}
			
			[[self dividerColor] set];
			
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
		}
	}
}

@end
