//
//  AGNSSplitViewDelegate.h
//  AraeliumAppKit
//
//  Created by Seth Willits on 6/16/12.
//  Copyright (c) 2012-2014 Araelium Group. All rights reserved.
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



enum {
	// Default behavior of NSSplitView
	AGNSSplitViewProportionalResizingStyle = 0,
	
	// Resize all subviews by distributing equal shares of space simultaeously
	AGNSSplitViewUniformResizingStyle,
	
	// Resize each subview in priority order. Must set priorityIndexes too.
	AGNSSplitViewPriorityResizingStyle
};
typedef NSUInteger AGNSSplitViewResizingStyle;


typedef NSRect (^AGNSSplitViewEffectiveRectHandler)(NSInteger dividerIndex, NSRect proposedEffectiveRect, NSRect drawnRect);
typedef NSRect (^AGNSSplitViewAdditionalEffectiveRectHandler)(NSInteger dividerIndex);




@interface AGNSSplitViewDelegate : NSObject <NSSplitViewDelegate>
{
	NSSplitView * mSplitView;
	AGNSSplitViewResizingStyle mResizingStyle;
	NSMutableArray * mSubviewInfos;
	NSArray * mPriorityIndexes;
	NSMutableDictionary * mViewToCollapseByDivider;
	NSMutableDictionary * mHideDividerOnCollapseByDivider;
	
	AGNSSplitViewEffectiveRectHandler mEffectiveRectHandler;
	AGNSSplitViewAdditionalEffectiveRectHandler mAdditionalEffectiveRectHandler;
}

@property (nonatomic, readwrite, retain) NSSplitView * splitView;
@property (nonatomic, readwrite, assign) AGNSSplitViewResizingStyle resizingStyle;
@property (nonatomic, readwrite, copy) NSArray * priorityIndexes;
@property (nonatomic, readwrite, copy) AGNSSplitViewEffectiveRectHandler effectiveRectHandler;
@property (nonatomic, readwrite, copy) AGNSSplitViewAdditionalEffectiveRectHandler additionalEffectiveRectHandler;

- (id)initWithSplitView:(NSSplitView *)splitView;

- (void)setMinSize:(CGFloat)size forSubviewAtIndex:(NSUInteger)viewIndex;
- (void)setMaxSize:(CGFloat)size forSubviewAtIndex:(NSUInteger)viewIndex;
- (void)setCanCollapse:(BOOL)canCollapse subviewAtIndex:(NSUInteger)viewIndex;
- (void)setHidesDividerAtIndex:(NSUInteger)dividerIndex whenAdjacentSubviewCollapses:(BOOL)hideDivider;

- (CGFloat)minSizeForSubviewAtIndex:(NSUInteger)viewIndex;
- (CGFloat)maxSizeForSubviewAtIndex:(NSUInteger)viewIndex;
- (BOOL)canCollapseSubviewAtIndex:(NSUInteger)viewIndex;
- (BOOL)hidesDividerWhenAdjacentSubviewCollapses:(NSUInteger)dividerIndex;

- (void)setCollapseSubviewAtIndex:(NSUInteger)viewIndex forDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;
- (NSUInteger)subviewIndexToCollapseForDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;

@end

