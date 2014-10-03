//
//  FunListView.h
//  Dogo iOS
//
//  Created by Marcus Westin on 1/28/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data types
/////////////
typedef long ListViewIndex;
typedef id ListGroupId;

typedef enum ListViewOrientation ListViewOrientation;
enum ListViewOrientation {
    ListViewOrientationVertical=1,
    ListViewOrientationHorizontal=2,
};

typedef enum ListViewLocation ListViewLocation;
enum ListViewLocation {
    ListViewLocationTop=1,
    ListViewLocationBottom=2,
    ListViewLocationLeft=ListViewLocationTop,
    ListViewLocationRight=ListViewLocationBottom,
};

typedef enum ListViewDirection ListViewDirection;
enum ListViewDirection {
    ListViewDirectionUp=-1,
    ListViewDirectionDown=1,
    ListViewDirectionLeft=ListViewDirectionUp,
    ListViewDirectionRight=ListViewDirectionDown,
};

// Delegate
///////////
@protocol FunListViewDelegate <NSObject>
@required
- (BOOL) listHasIndex:(ListViewIndex)index;
- (void) listPopulate:(UIView*)view forIndex:(ListViewIndex)index location:(ListViewLocation)location;
- (void) listSelect:(ListViewIndex)index view:(UIView*)view pointInView:(CGPoint)point;
@optional
- (void) listRenderEmptyInView:(UIView*)view isFirst:(BOOL)isFirst;
- (id) listGroupIdForIndex:(ListViewIndex)index;
- (void) listPopulateHead:(UIView*)view forGroup:(ListGroupId)groupId withIndex:(ListViewIndex)index;
- (void) listPopulateFoot:(UIView*)view forGroup:(ListGroupId)groupId withIndex:(ListViewIndex)index;
- (void) listTopGroupDidChangeTo:(ListGroupId)newTopGroupId withIndex:(ListViewIndex)index from:(ListGroupId)previousTopGroupId;
- (void) listBottomGroupDidChangeTo:(ListGroupId)newBottomGroupId withIndex:(ListViewIndex)index from:(ListGroupId)previousBottomGroupId;
- (void) listSelectGroup:(ListGroupId)groupId withIndex:(ListViewIndex)index;
- (void) listDidScroll:(CGFloat)offsetChange;
- (void) listViewWasRemoved:(UIView*)view location:(ListViewLocation)location index:(ListViewIndex)index;
@end

// Stickies
///////////
@interface FunListViewStickyGroup : NSObject
- (UIView*)newView;
@property (readonly) CGFloat height;
@property (readonly) BOOL hasContent;
@end

// List View
////////////
@interface FunListView : UIView <UIScrollViewDelegate>
@property UIScrollView* scrollView;
@property UIEdgeInsets groupMargins;
@property UIEdgeInsets itemMargins;
@property (weak) id<FunListViewDelegate> delegate;
@property (readonly) ListViewIndex topListViewIndex;
@property (readonly) ListViewIndex bottomListViewIndex;
@property (readonly) ListGroupId topGroupId;
@property (readonly) ListGroupId bottomGroupId;
@property NSString* loadingMessage;
@property NSString* emptyMessage;
@property (copy) BOOL (^shouldScrollToTopHandler)();
@property ListViewIndex startIndex;
@property ListViewLocation startLocation;
@property ListViewOrientation orientation;

+ (void) insetAll:(UIEdgeInsets)insets;
+ (void) shouldScrollToTopOnStatusBarTapByDefault:(BOOL)defaultValue;
- (void) reloadDataForList;
- (void) stopScrollingList;
- (void) appendToListCount:(NSUInteger)numItems startingAtIndex:(ListViewIndex)firstIndex;
- (void) prependToListCount:(NSUInteger)numItems;
- (CGFloat) setHeight:(CGFloat)height forVisibleViewWithIndex:(ListViewIndex)index;
- (CGFloat) setWidth:(CGFloat)width forVisibleViewWithIndex:(ListViewIndex)index;
- (void) extendBottom;
- (UIView*) visibleViewWithIndex:(ListViewIndex)index;
- (FunListViewStickyGroup*) stickyGroupWithPosition:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset;
- (UIView*) makeTopViewWithHeight:(CGFloat)height;
- (ListViewIndex) indexForVisibleItemViewAtPoint:(CGPoint)point;
- (BOOL) isAtBottom;
- (void) expandToSizeOfContent;
@end
