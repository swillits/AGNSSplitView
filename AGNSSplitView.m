//
//  AGNSSplitView.m
//  AraeliumAppKit
//
//  Created by Seth Willits on 8/20/08.
//  Copyright 2008 Araelium Group. All rights reserved.
//

#import "AGNSSplitView.h"


@implementation AGNSSplitView

@synthesize drawBlock = mDrawBlock;

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
	[mDrawBlock release];
	[super dealloc];
}




#pragma mark -
#pragma mark Properties

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

- (void)drawDividerInRect:(NSRect)aRect
{
	if (mDrawBlock) {
		mDrawBlock(aRect);
		return;
	}

	if ([self drawsDivider]) {
		
		if ([self dividerStyle] == NSSplitViewDividerStyleThin) {
			[[self dividerColor] set];
			NSRectFill(aRect);
		} else {
			
			if ([self drawsDividerHandle]) {
				NSColor * dividerColor = mDividerColor;
				mDividerColor = [NSColor clearColor];
				[super drawDividerInRect:aRect];
				mDividerColor = dividerColor;
			}
			
			[[self dividerColor] set];
			
			switch (mDividerLineEdge) {
			case NSMaxYEdge:
				aRect.origin.y += aRect.size.height - 1.0;
				aRect.size.height = 1.0;
				break;
			case NSMinYEdge:
				aRect.size.height = 1.0;
				break;
			case NSMaxXEdge:
				aRect.origin.x += aRect.size.width - 1.0;
				aRect.size.width = 1.0;
				break;
			case NSMinXEdge:
				aRect.size.width = 1.0;
				break;
			}
			
			NSRectFill(aRect);
		}
	}
}

@end
