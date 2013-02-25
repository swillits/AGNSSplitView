//
//  AGNSSplitViewDelegate.m
//  AraeliumAppKit
//
//  Created by Seth Willits on 6/16/12.
//  Copyright (c) 2012 Araelium Group. All rights reserved.
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
	self.splitView = splitView;
	
	return self;
}


- (void)dealloc
{
	mSplitView.delegate = nil;
	[mSplitView release];
	[mSubviewInfos release];
	[mViewToCollapseByDivider release];
	[super dealloc];
}




#pragma mark -
#pragma mark Properties

@synthesize resizingStyle = mResizingStyle;


- (void)setSplitView:(NSSplitView *)splitView;
{
	if (mSplitView) {
		[mSubviewInfos removeAllObjects];
		[mViewToCollapseByDivider removeAllObjects];
		[mSplitView autorelease];
		mSplitView = nil;
	}
	
	mSplitView = [splitView retain];
	
	if (mSplitView) {
		for (NSView * subview in mSplitView.subviews) {
			AGNSSplitViewDelegateSubviewInfo * info = [[[AGNSSplitViewDelegateSubviewInfo alloc] init] autorelease];
			[mSubviewInfos addObject:info];
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

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)viewIndex;
{
	AGNSSplitViewDelegateSubviewInfo * info = SubviewInfo(viewIndex);
	if (!info.constrainSize) return proposedMin;
	
	NSRect subviewFrame = Subview(viewIndex).frame;
	CGFloat frameOrigin;
	
	if (splitView.isVertical) {
		frameOrigin = subviewFrame.origin.x;
	} else {
		frameOrigin = subviewFrame.origin.y;
	}
	
	return frameOrigin + info.minSize;
}



- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)viewIndex;
{
	AGNSSplitViewDelegateSubviewInfo * infoTwo = SubviewInfo(viewIndex + 1);
	AGNSSplitViewDelegateSubviewInfo * infoOne = SubviewInfo(viewIndex);
	
	if (!infoOne.constrainSize || !infoTwo.constrainSize) {
		return proposedMax;
	}
	
	CGFloat shrinkMinSize = infoTwo.minSize;
	CGFloat growMaxSize = infoOne.maxSize;
	NSView * growingSubview = Subview(viewIndex);
	NSView * shrinkingSubview = Subview(viewIndex + 1);
	CGFloat maxCoordLimitedByShrinkMinSize;
	CGFloat maxCoordLimitedByGrowMaxSize;
	
	if (splitView.isVertical) {
		maxCoordLimitedByGrowMaxSize = (NSMinX(growingSubview.frame) + growMaxSize);
		maxCoordLimitedByShrinkMinSize = (NSMaxX(growingSubview.frame) + (shrinkingSubview.frame.size.width - shrinkMinSize));
	} else {
		maxCoordLimitedByGrowMaxSize   = (NSMinY(growingSubview.frame) + growMaxSize);
		maxCoordLimitedByShrinkMinSize = (NSMaxY(growingSubview.frame) + (shrinkingSubview.frame.size.height - shrinkMinSize));
	}
	
	return MIN(maxCoordLimitedByGrowMaxSize, maxCoordLimitedByShrinkMinSize);
}



- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize;
{
	switch (self.resizingStyle) {
		case AGNSSplitViewUniformResizingStyle:
			[self _resizeUniform:oldSize];
			break;
			
		case AGNSSplitViewProportionalResizingStyle:
			[self _resizeProportional:oldSize];
			break;
			
		case AGNSSplitViewPriorityResizingStyle:
			[self _resizePriority:oldSize];
			break;
	}
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
	[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
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
		
		if (subviewCanBeResized) subviewCanBeResized[viewIndex] = canBeResized;
		if (canBeResized) {
			if (numberOfSubviewsThatCanBeResized) *numberOfSubviewsThatCanBeResized += 1;
			if (widthOfAllResizableSubviews) *widthOfAllResizableSubviews += size;
		}
	}];
}



- (void)_getSubviewsSizes:(CGFloat *)sizes;
{
	[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
		NSView * subview = Subview(viewIndex);
		
		if (self.splitView.isVertical) {
			sizes[viewIndex] = subview.frame.size.width;
		} else {
			sizes[viewIndex] = subview.frame.size.height;
		}
	}];
}




- (void)_setSubviewSizes:(CGFloat *)sizes;
{
	NSSplitView * splitView = self.splitView;
	
	[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
		NSView * subview = Subview(viewIndex);
		
		if (splitView.isVertical) {
			[subview setFrameSize:NSMakeSize(sizes[viewIndex], splitView.bounds.size.height)];
		} else {
			[subview setFrameSize:NSMakeSize(splitView.bounds.size.width, sizes[viewIndex])];
		}
	}];
	
	
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
	[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
		if (resizable[viewIndex]) {
			NSView * subview = Subview(viewIndex);
			CGFloat size = (splitView.isVertical ? subview.frame.size.width : subview.frame.size.height);
			proportionsForResizableViews[viewIndex] = (size / oldWidthOfAllResizableViews);
		}
	}];
	
	
	// Proportionally increment/decrement subview size
	// Need to loop because if we hit min/max of a subview, there'll be left over delta.
	while (fabs(delta) > 0.5) {
		__block CGFloat deltaRemaining = delta;
		
		[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
			
			CGFloat oldSize = sizes[viewIndex];
			CGFloat newSize = oldSize;
			CGFloat subviewDelta = 0.0;
			
			// Determine appropriate delta for this subview
			subviewDelta = round(proportionsForResizableViews[viewIndex] * delta);
			
			// Resize it (respecting max/min)
			newSize += subviewDelta;
			if (info.minSize > 0) newSize = MAX(info.minSize, newSize);
			if (info.maxSize > 0) newSize = MIN(info.maxSize, newSize);
			sizes[viewIndex] = newSize;
			
			// Reduce delta
			deltaRemaining -= (newSize - oldSize);
			if (fabs(deltaRemaining) <= 0.5) *stop = YES;
		}];
		
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
		[mSubviewInfos enumerateObjectsUsingBlock:^(AGNSSplitViewDelegateSubviewInfo * info, NSUInteger viewIndex, BOOL *stop) {
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
				if (fabs(delta) <= 0.5) *stop = YES;
			}
		}];
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
	}
	
	[self _repositionSubviews];
}



- (void)_repositionSubviews;
{
	NSSplitView * splitView = self.splitView;
	CGFloat offset = 0;
	
	for (NSView * subview in splitView.subviews) {
		if (![splitView isSubviewCollapsed:subview]) {
			NSRect viewFrame = subview.frame;
			
			if (splitView.isVertical) {
				viewFrame.origin.x = offset;
				viewFrame.origin.y = 0;
				viewFrame.size.height = splitView.bounds.size.height;
				
			} else {
				viewFrame.origin.x = 0;
				viewFrame.origin.y = offset;
				viewFrame.size.width = splitView.bounds.size.width;
			}
			
			[subview setFrame:viewFrame];
			offset += viewFrame.size.width + splitView.dividerThickness;
		}
	}
}

@end

