//
//  AGNSSplitViewDelegate.m
//  AraeliumAppKit
//
//  Created by Seth Willits on 6/16/12.
//  Copyright (c) 2012-2015 Araelium Group. All rights reserved.
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


#import "AGNSSplitViewDelegate.h"



#define SubviewInfo(index) ((AGNSSplitViewDelegateSubviewInfo *)[mSubviewInfos objectAtIndex:index])
#define Subview(index) ((NSView *)[self.splitView.subviews objectAtIndex:index])



@interface AGNSSplitViewDelegateSubviewInfo : NSObject {
	CGFloat mMinSize;
	CGFloat mMaxSize;
	BOOL mCanCollapse;
}
@property (nonatomic, readwrite, assign) CGFloat minSize;
@property (nonatomic, readwrite, assign) CGFloat maxSize;
@property (nonatomic, readwrite, assign) BOOL canCollapse;
@property (nonatomic, readonly) BOOL constrainSize;
@end

@implementation AGNSSplitViewDelegateSubviewInfo
@synthesize minSize = mMinSize;
@synthesize maxSize = mMaxSize;
@synthesize canCollapse = mCanCollapse;

- (BOOL)constrainSize {
	return ((mMinSize > 0) || (mMaxSize > 0));
}

@end




@interface AGNSSplitViewDelegate (Private)
- (AGNSSplitViewDelegateSubviewInfo *)_subviewInfoForSubview:(NSView *)subview;

- (void)_resizeUniform:(NSSize)oldSize;
- (void)_resizeProportional:(NSSize)oldSize;
- (void)_resizePriority:(NSSize)oldSize;

- (void)_getSubviewsResizable:(BOOL *)subviewCanBeResized
						count:(NSUInteger *)numberOfSubviewsThatCanBeResized
				   totalWidth:(CGFloat *)widthOfAllResizableSubviews
						delta:(CGFloat)delta;
- (void)_getSubviewsSizes:(CGFloat *)sizes;
- (void)_setSubviewSizes:(CGFloat *)sizes;
- (void)_repositionSubviews;
@end


@implementation AGNSSplitViewDelegate

- (id)initWithSplitView:(NSSplitView *)splitView
{
	if (!(self = [super init])) {
		return nil;
	}
	
	mSubviewInfos = [[NSMutableArray alloc] init];
	mViewToCollapseByDivider = [[NSMutableDictionary alloc] init];
	mHideDividerOnCollapseByDivider = [[NSMutableDictionary alloc] init];
	self.splitView = splitView;
	
	return self;
}


- (void)dealloc
{
	mSplitView.delegate = nil;
	[mSplitView release];
	[mSubviewInfos release];
	[mViewToCollapseByDivider release];
	[mHideDividerOnCollapseByDivider release];
	[mEffectiveRectHandler release];
	[mAdditionalEffectiveRectHandler release];
	[mPriorityIndexes release];
	[super dealloc];
}




#pragma mark -
#pragma mark Properties

@synthesize resizingStyle = mResizingStyle;
@synthesize effectiveRectHandler = mEffectiveRectHandler;
@synthesize additionalEffectiveRectHandler = mAdditionalEffectiveRectHandler;


- (void)setSplitView:(NSSplitView *)splitView;
{
	if (mSplitView != splitView) {
		if (mSplitView) {
			[mSubviewInfos removeAllObjects];
			[mViewToCollapseByDivider removeAllObjects];
			[mHideDividerOnCollapseByDivider removeAllObjects];
			[mSplitView autorelease];
			mSplitView = nil;
		}
		
		mSplitView = [splitView retain];
		
		if (mSplitView) {
			for (NSUInteger i = 0; i < mSplitView.subviews.count; i++) {
				AGNSSplitViewDelegateSubviewInfo * info = [[[AGNSSplitViewDelegateSubviewInfo alloc] init] autorelease];
				[mSubviewInfos addObject:info];
			}
		}
	}
}


- (NSSplitView *)splitView;
{
	return mSplitView;
}



- (void)setMinSize:(CGFloat)size forSubviewAtIndex:(NSUInteger)viewIndex;
{
	SubviewInfo(viewIndex).minSize = size;
}


- (void)setMaxSize:(CGFloat)size forSubviewAtIndex:(NSUInteger)viewIndex;
{
	SubviewInfo(viewIndex).maxSize = size;
}


- (CGFloat)minSizeForSubviewAtIndex:(NSUInteger)viewIndex;
{
	return SubviewInfo(viewIndex).minSize;
}


- (CGFloat)maxSizeForSubviewAtIndex:(NSUInteger)viewIndex;
{
	return SubviewInfo(viewIndex).maxSize;
}



- (void)setPriorityIndexes:(NSArray *)priorityIndexes;
{
	NSAssert([priorityIndexes count] == self.splitView.subviews.count,
			@"Priority indexes must equal number of splitview subvies.");
	
	[mPriorityIndexes autorelease];
	mPriorityIndexes = [priorityIndexes copy];
}


- (NSArray *)priorityIndexes;
{
	return mPriorityIndexes;
}



- (void)setCanCollapse:(BOOL)canCollapse subviewAtIndex:(NSUInteger)viewIndex;
{
	SubviewInfo(viewIndex).canCollapse = canCollapse;
}


- (BOOL)canCollapseSubviewAtIndex:(NSUInteger)viewIndex;
{
	return SubviewInfo(viewIndex).canCollapse;
}




- (void)setHidesDividerAtIndex:(NSUInteger)dividerIndex whenAdjacentSubviewCollapses:(BOOL)hideDivider;
{
	[mHideDividerOnCollapseByDivider setObject:[NSNumber numberWithBool:hideDivider] forKey:[NSNumber numberWithUnsignedInteger:dividerIndex]];
}


- (BOOL)hidesDividerWhenAdjacentSubviewCollapses:(NSUInteger)dividerIndex;
{
	NSNumber *obj = [mHideDividerOnCollapseByDivider objectForKey:[NSNumber numberWithUnsignedInteger:dividerIndex]];
	if (obj) {
		return [obj boolValue];
	}
	
	return NO;
}




- (void)setCollapseSubviewAtIndex:(NSUInteger)viewIndex forDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;
{
	[mViewToCollapseByDivider setObject:[NSNumber numberWithUnsignedInteger:viewIndex] forKey:[NSNumber numberWithUnsignedInteger:dividerIndex]];
}


- (NSUInteger)subviewIndexToCollapseForDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;
{
	NSNumber *obj = [mViewToCollapseByDivider objectForKey:[NSNumber numberWithUnsignedInteger:dividerIndex]];
	if (obj) {
		return [obj unsignedIntegerValue];
	}
	
	return NSNotFound;
}





#pragma mark -
#pragma mark Delegate Methods

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex;
{
	// Info of the views before and after the divider (left and right, or above and below)
	AGNSSplitViewDelegateSubviewInfo * beforeInfo = SubviewInfo(dividerIndex);
	AGNSSplitViewDelegateSubviewInfo * afterInfo = SubviewInfo(dividerIndex + 1);
	
	if (!beforeInfo.constrainSize && !afterInfo.constrainSize) {
		return proposedMin;
	}
	
	
	NSView * shrinkingSubview = Subview(dividerIndex);
	NSView * growingSubview = Subview(dividerIndex + 1);
	
	
	// The minimum divider coordinate which respects...
	CGFloat beforeMin = 0.0; // ...before's min width
	CGFloat afterMin = 0.0;  // ... after's max width
	
	if (splitView.isVertical) {
		beforeMin = shrinkingSubview.frame.origin.x + (beforeInfo.constrainSize ? beforeInfo.minSize : 0.0);
		if (afterInfo.maxSize > 0.0) {
			afterMin = NSMaxX(growingSubview.frame) - afterInfo.maxSize;
		}
	} else {
		beforeMin = shrinkingSubview.frame.origin.y + (beforeInfo.constrainSize ? beforeInfo.minSize : 0.0);
		if (afterInfo.maxSize > 0.0) {
			afterMin = NSMaxY(growingSubview.frame) - afterInfo.maxSize;
		}
	}
	
	// The MAX of: the before's min width, and the after's max width
	return MAX(beforeMin, afterMin);
}



- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex;
{
	// Info of the views before and after the divider (left and right, or above and below)
	AGNSSplitViewDelegateSubviewInfo * infoOne = SubviewInfo(dividerIndex);
	AGNSSplitViewDelegateSubviewInfo * infoTwo = SubviewInfo(dividerIndex + 1);
	
	CGFloat shrinkMinSize = infoTwo.minSize;
	CGFloat growMaxSize = infoOne.maxSize;
	NSView * growingSubview = Subview(dividerIndex);
	NSView * shrinkingSubview = Subview(dividerIndex + 1);
	CGFloat maxCoordLimitedByShrinkMinSize;
	CGFloat maxCoordLimitedByGrowMaxSize;
	
	if (splitView.isVertical) {
		CGFloat maxCoordPossible       = MAX(NSMaxX(shrinkingSubview.frame), NSMaxX(growingSubview.frame)); // accounts for collapsed views
		maxCoordLimitedByGrowMaxSize   = (growMaxSize > 0.0) ? (NSMinX(growingSubview.frame) + growMaxSize) : proposedMax;
		maxCoordLimitedByShrinkMinSize = maxCoordPossible - shrinkMinSize;
	} else {
		CGFloat maxCoordPossible       = MAX(NSMaxY(shrinkingSubview.frame), NSMaxY(growingSubview.frame)); // accounts for collapsed views
		maxCoordLimitedByGrowMaxSize   = (growMaxSize > 0.0) ? (NSMinY(growingSubview.frame) + growMaxSize) : proposedMax;
		maxCoordLimitedByShrinkMinSize = maxCoordPossible - shrinkMinSize;
	}
	
	return MIN(maxCoordLimitedByGrowMaxSize, maxCoordLimitedByShrinkMinSize);
}



- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)svOldSize;
{
	if (splitView.subviews.count == 0) {
		return;
	}
	
	
	// If the splitview isVertical the dividers are vertical, and the "primary axis" is the X axis.
	// Make sure the subviews' secondary axis fills the split view so that if the primary axis dimensions
	// don't need changed, we've still ensured the views are sized correctly.
	for (NSView * subview in splitView.subviews) {
		if (splitView.isVertical) {
			[subview setFrameSize:NSMakeSize(subview.frame.size.width, splitView.bounds.size.height)];
		} else {
			[subview setFrameSize:NSMakeSize(splitView.bounds.size.width, subview.frame.size.height)];
		}
	}
	
	
	// In the past I assumed that the splitview's subviews were sized to fit svOldSize when this method
	// was called, but that is not the case. That not being the case would lead to problems. So instead
	// of using svNewSize - svOldSize to calculate the "delta" (the total amount of space we need to resize
	// the subviews larger by), we should add up the current space they really do occupy and subtract it
	// from the current size, and resize by that amount.
	
	__block CGFloat oldPrimarySpaceFilled = 0.0;
	
	[splitView.subviews enumerateObjectsUsingBlock:^(NSView * subview, NSUInteger idx, BOOL *stop) {
		BOOL subviewIsCollapsed = [splitView isSubviewCollapsed:subview];
		
		if (!subviewIsCollapsed) {
			if (splitView.isVertical) {
				oldPrimarySpaceFilled += subview.frame.size.width;
			} else {
				oldPrimarySpaceFilled += subview.frame.size.height;
			}
			
			if (idx + 1 < splitView.subviews.count) {
				oldPrimarySpaceFilled += splitView.dividerThickness;
			}
		}
	}];
	
	svOldSize = splitView.isVertical ? NSMakeSize(oldPrimarySpaceFilled, svOldSize.height) : NSMakeSize(svOldSize.width, oldPrimarySpaceFilled);
	
	
	
	// Now having calcualted the svOldSize which would fit to the existing sizes of the subviews, calculate
	// the delta to the svNewSize.
	
	switch (self.resizingStyle) {
		case AGNSSplitViewUniformResizingStyle:
			[self _resizeUniform:svOldSize];
			break;
			
		case AGNSSplitViewProportionalResizingStyle:
			[self _resizeProportional:svOldSize];
			break;
			
		case AGNSSplitViewPriorityResizingStyle:
			[self _resizePriority:svOldSize];
			break;
	}
	
//	#if DEBUG
//	if ([self.splitView respondsToSelector:@selector(_validateSubviewFrames)]) {
//		if (![self.splitView _validateSubviewFrames]) {
//			NSBeep();
//		}
//	}
//	#endif
}





- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview;
{
	return [self _subviewInfoForSubview:subview].canCollapse;
}



- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
{
	NSUInteger viewIndexToCollapse = [self subviewIndexToCollapseForDoubleClickOnDividerAtIndex:dividerIndex];
	NSUInteger viewIndex = [self.splitView.subviews indexOfObject:subview];
	
	// Collapse viewIndex if no user setting, or is equal to user setting
	return ((viewIndexToCollapse == NSNotFound) || (viewIndex == viewIndexToCollapse));
}



- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex;
{
	return [self hidesDividerWhenAdjacentSubviewCollapses:dividerIndex];
}



- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex;
{
	if (self.effectiveRectHandler) {
		return self.effectiveRectHandler(dividerIndex, proposedEffectiveRect, drawnRect);
	}
	
	return proposedEffectiveRect;
}


- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex;
{
	if (self.additionalEffectiveRectHandler) {
		return self.additionalEffectiveRectHandler(dividerIndex);
	}
	
	return NSZeroRect;
}


@end






#pragma mark -
@implementation AGNSSplitViewDelegate (Private)

- (AGNSSplitViewDelegateSubviewInfo *)_subviewInfoForSubview:(NSView *)subview;
{
	NSUInteger viewIndex = [self.splitView.subviews indexOfObject:subview];
	if (viewIndex == NSNotFound) return nil;
	return [mSubviewInfos objectAtIndex:viewIndex];
}



- (void)_getSubviewsResizable:(BOOL *)subviewCanBeResized
						count:(NSUInteger *)numberOfSubviewsThatCanBeResized
				   totalWidth:(CGFloat *)widthOfAllResizableSubviews
						delta:(CGFloat)delta;
{
	for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
		AGNSSplitViewDelegateSubviewInfo * info = [mSubviewInfos objectAtIndex:viewIndex];
		NSView * subview = Subview(viewIndex);
		CGFloat size = (self.splitView.isVertical ? subview.frame.size.width : subview.frame.size.height);
		BOOL canBeResized = YES;
		
		if (delta < 0) {
			if (info.minSize > 0.0) {
				if (fabs(size - info.minSize) < 0.5) {
					canBeResized = NO;
				}
			}
			
		} else if (delta > 0) {
			if (info.maxSize > 0.0) {
				if (fabs(size - info.maxSize) < 0.5) {
					canBeResized = NO;
				}
			}
		}
		
		if ([self.splitView isSubviewCollapsed:subview]) {
			canBeResized = NO;
		}
		
		if (subviewCanBeResized) subviewCanBeResized[viewIndex] = canBeResized;
		if (canBeResized) {
			if (numberOfSubviewsThatCanBeResized) *numberOfSubviewsThatCanBeResized += 1;
			if (widthOfAllResizableSubviews) *widthOfAllResizableSubviews += size;
		}
	}
}



- (void)_getSubviewsSizes:(CGFloat *)sizes;
{
	for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
		NSView * subview = Subview(viewIndex);
		
		if (self.splitView.isVertical) {
			sizes[viewIndex] = subview.frame.size.width;
		} else {
			sizes[viewIndex] = subview.frame.size.height;
		}
	}
}




- (void)_setSubviewSizes:(CGFloat *)sizes;
{
	NSSplitView * splitView = self.splitView;
	
	for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
		NSView * subview = Subview(viewIndex);
		
		if (splitView.isVertical) {
			[subview setFrameSize:NSMakeSize(sizes[viewIndex], splitView.bounds.size.height)];
		} else {
			[subview setFrameSize:NSMakeSize(splitView.bounds.size.width, sizes[viewIndex])];
		}
	}
	
	
	[self _repositionSubviews];
}



- (void)_resizeProportional:(NSSize)svOldSize;
{
	NSSplitView * splitView = self.splitView;
	NSSize svNewSize = splitView.bounds.size;
	CGFloat delta = splitView.isVertical ? (svNewSize.width - svOldSize.width) : (svNewSize.height - svOldSize.height);
	
	NSUInteger numberOfSubviewsThatCanBeResized = 0;
	CGFloat oldWidthOfAllResizableViews = 0.0;
	BOOL * resizable = calloc(sizeof(BOOL) * splitView.subviews.count, 1);
	CGFloat * sizes = calloc(sizeof(CGFloat) * splitView.subviews.count, 1);
	
	
	[self _getSubviewsSizes:sizes];
	[self _getSubviewsResizable:resizable count:&numberOfSubviewsThatCanBeResized totalWidth:&oldWidthOfAllResizableViews delta:delta];
	
	
	// Get proportions to use for resizing
	CGFloat * proportionsForResizableViews = calloc(sizeof(CGFloat) * splitView.subviews.count, 1);
	for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
		if (resizable[viewIndex]) {
			NSView * subview = Subview(viewIndex);
			CGFloat size = (splitView.isVertical ? subview.frame.size.width : subview.frame.size.height);
			proportionsForResizableViews[viewIndex] = (size / oldWidthOfAllResizableViews);
		}
	}
	
	
	// Proportionally increment/decrement subview size
	// Need to loop because if we hit min/max of a subview, there'll be left over delta.
	while (fabs(delta) > 0.5) {
		__block CGFloat deltaRemaining = delta;
		
		for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
			AGNSSplitViewDelegateSubviewInfo * info = [mSubviewInfos objectAtIndex:viewIndex];
			
			BOOL canNoLongerResize = NO;
			CGFloat oldSize = sizes[viewIndex];
			CGFloat newSize = oldSize;
			CGFloat subviewDelta = 0.0;
			
			if (proportionsForResizableViews[viewIndex] > 0.0) {
				
				// Determine appropriate delta for this subview
				subviewDelta = round(proportionsForResizableViews[viewIndex] * delta);
				
				// Resize it (respecting max/min)
				newSize += subviewDelta;
				if (info.minSize > 0) {
					
					// If at min limit and asked to resize smaller, note that we can't resize
					if (newSize <= info.minSize && delta < 0) {
						canNoLongerResize = YES;
					}
					
					newSize = MAX(info.minSize, newSize);
				}
				
				if (info.maxSize > 0) {
					
					// If at max limit and asked to resize larger, note that we can't resize
					if (newSize >= info.maxSize && delta > 0) {
						canNoLongerResize = YES;
					}
					
					newSize = MIN(info.maxSize, newSize);
				}
				sizes[viewIndex] = newSize;
				
				
				
				// Redistribute resize proportion to all other views
				if (canNoLongerResize) {
					CGFloat p = proportionsForResizableViews[viewIndex];
					CGFloat fakeOnePointZero = 1.0 - p;
					
					proportionsForResizableViews[viewIndex] = 0.0;
					
					for (NSUInteger otherViewIndex = 0; otherViewIndex < splitView.subviews.count; otherViewIndex++) {
						if (otherViewIndex != viewIndex) {
							proportionsForResizableViews[otherViewIndex] += (proportionsForResizableViews[otherViewIndex] / fakeOnePointZero * p);
						}
					}
				}
				
				
				// Reduce delta
				deltaRemaining -= (newSize - oldSize);
				if (fabs(deltaRemaining) <= 0.5) break;
			}
		}
		
		delta = deltaRemaining;
	}
	
	
	[self _setSubviewSizes:sizes];
	free(sizes);
	free(proportionsForResizableViews);
	free(resizable);
}




- (void)_resizeUniform:(NSSize)svOldSize;
{
	NSSplitView * splitView = self.splitView;
	NSSize svNewSize = splitView.bounds.size;
	__block CGFloat delta = splitView.isVertical ? (svNewSize.width - svOldSize.width) : (svNewSize.height - svOldSize.height);
	
	__block NSUInteger numberOfSubviewsThatCanBeResized = 0;
	BOOL * resizable = calloc(sizeof(BOOL) * splitView.subviews.count, 1);
	[self _getSubviewsResizable:resizable count:&numberOfSubviewsThatCanBeResized totalWidth:nil delta:delta];
	
	CGFloat * sizes = calloc(sizeof(CGFloat) * splitView.subviews.count, 1);
	[self _getSubviewsSizes:sizes];
	
	
	// We loop because it's possible that the first time through, we hit min/max size,
	// which then causes not all of the delta to be used. Since this is uniform, if
	// we loop, the remaining is uniformly split over the views which can still resize.
	while (fabs(delta) > 0.5) {
		
		// This is the amount we will resize each view by to start with
		CGFloat deltaPerSubview = (delta / (double)numberOfSubviewsThatCanBeResized);
		if (deltaPerSubview < 0) deltaPerSubview = floor(deltaPerSubview);
		if (deltaPerSubview > 0) deltaPerSubview = ceil(deltaPerSubview);
		
		// Resize each of the subviews by a uniform amount (may be off by a teen bit in the last one due to rounding)
		for (NSUInteger viewIndex = 0; viewIndex < self.splitView.subviews.count; viewIndex++) {
			AGNSSplitViewDelegateSubviewInfo * info = [mSubviewInfos objectAtIndex:viewIndex];
			if (resizable[viewIndex]) {
				CGFloat oldSize = sizes[viewIndex];
				CGFloat newSize = oldSize;
				
				// Resize it (respecting max/min)
				newSize += deltaPerSubview;
				if ((info.minSize > 0) && (newSize < info.minSize)) {
					numberOfSubviewsThatCanBeResized--;
					resizable[viewIndex] = NO;
					newSize = info.minSize;
				}
				
				if ((info.maxSize > 0) && (newSize > info.maxSize)) {
					numberOfSubviewsThatCanBeResized--;
					resizable[viewIndex] = NO;
					newSize = info.maxSize;
				}
				
				sizes[viewIndex] = newSize;
				
				
				delta -= (newSize - oldSize);
				if (fabs(delta) <= 0.5) break;
			}
		}
	}
	
	
	[self _setSubviewSizes:sizes];
	free(sizes);
	free(resizable);
}




- (void)_resizePriority:(NSSize)svOldSize;
{
	NSSplitView * splitView = self.splitView;
	NSSize svNewSize = splitView.bounds.size;
	CGFloat delta = splitView.isVertical ? (svNewSize.width - svOldSize.width) : (svNewSize.height - svOldSize.height);
	
	
	// Resize the primary axis of each subview, using priority, by "delta"
	CGFloat lastDelta;
	do {
		lastDelta = delta;
		
		for (NSNumber * viewIndexNumber in self.priorityIndexes) {
			NSInteger viewIndex = [viewIndexNumber integerValue];
			NSView * subview = Subview(viewIndex);
			CGFloat min = SubviewInfo(viewIndex).minSize;
			CGFloat max = SubviewInfo(viewIndex).maxSize;
			CGFloat oldSize = (splitView.isVertical ? subview.frame.size.width : subview.frame.size.height);
			CGFloat newSize = 0;
			if (max == 0.0) max = CGFLOAT_MAX;
			
			if (![splitView isSubviewCollapsed:subview]) {
				newSize = MAX(min, MIN(max, oldSize + delta));
				delta -= (newSize - oldSize);
				
				if (splitView.isVertical) {
					[subview setFrameSize:NSMakeSize(newSize, splitView.bounds.size.height)];
				} else {
					[subview setFrameSize:NSMakeSize(splitView.bounds.size.width, newSize)];
				}
			}
			
			if (fabs(delta) <= 0.1) break;
		}
		
	} while (fabs(delta) > 0.1 && delta	!= lastDelta);
	
	
	
	// We're now certain the views are *sized* correctly, so now position them correctly
	[self _repositionSubviews];
}



- (void)_repositionSubviews;
{
	NSSplitView * splitView = self.splitView;
	NSUInteger subviewIndex = 0;
	NSUInteger dividerIndex = 0;
	CGFloat offset = 0;
	
	for (NSView * subview in splitView.subviews) {
		BOOL subviewIsCollapsed = [splitView isSubviewCollapsed:subview];
		
		if (!subviewIsCollapsed) {
			NSRect viewFrame = subview.frame;
			
			if (splitView.isVertical) {
				viewFrame.origin.x = offset;
				viewFrame.origin.y = 0;
				viewFrame.size.height = splitView.bounds.size.height;
				offset += viewFrame.size.width;
				
			} else {
				viewFrame.origin.x = 0;
				viewFrame.origin.y = offset;
				viewFrame.size.width = splitView.bounds.size.width;
				offset += viewFrame.size.height;
			}
			
			[subview setFrame:viewFrame];
		}
		
		
		BOOL hidesFollowingDivider = [self hidesDividerWhenAdjacentSubviewCollapses:dividerIndex];
		BOOL followingSubviewIsCollapsed = ((subviewIndex + 1 < splitView.subviews.count) && [splitView isSubviewCollapsed:[splitView.subviews objectAtIndex:subviewIndex + 1]]);
		
		if ((subviewIsCollapsed && hidesFollowingDivider) || (hidesFollowingDivider && followingSubviewIsCollapsed)) {
			// The divider after this subview is hidden
		} else {
			offset += splitView.dividerThickness;
		}
		
		
		dividerIndex++;
		subviewIndex++;
	}
}

@end

