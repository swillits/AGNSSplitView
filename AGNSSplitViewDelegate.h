//
//  AGNSSplitViewDelegate.h
//  AraeliumAppKit
//
//  Created by Seth Willits on 6/16/12.
//  Copyright (c) 2012 Araelium Group. All rights reserved.
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

- (CGFloat)minSizeForSubviewAtIndex:(NSUInteger)viewIndex;
- (CGFloat)maxSizeForSubviewAtIndex:(NSUInteger)viewIndex;
- (BOOL)canCollapseSubviewAtIndex:(NSUInteger)viewIndex;

- (void)setCollapseSubviewAtIndex:(NSUInteger)viewIndex forDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;
- (NSUInteger)subviewIndexToCollapseForDoubleClickOnDividerAtIndex:(NSUInteger)dividerIndex;

@end

