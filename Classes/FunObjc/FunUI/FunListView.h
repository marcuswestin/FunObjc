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
typedef NSInteger ListIndex;
typedef id ListGroupId;

enum ListViewLocation { TOP=1, BOTTOM=2 };
typedef enum ListViewLocation ListViewLocation;

enum ListViewDirection { UP=-1, DOWN=1 };
typedef enum ListViewDirection ListViewDirection;

// Delegate
///////////
@protocol FunListViewDelegate <NSObject>
@required
- (BOOL) hasViewForIndex:(ListIndex)index;
- (UIView*) listViewForIndex:(ListIndex)index width:(CGFloat)width location:(ListViewLocation)location;
- (void) listSelectIndex:(ListIndex)index view:(UIView*)view;
@optional
- (void) listRenderEmptyInView:(UIView*)view isFirst:(BOOL)isFirst;
- (ListIndex) listStartIndex;
- (ListViewLocation) listStartLocation;
- (id) listGroupIdForIndex:(ListIndex)index;
- (UIView*) listViewForGroupHead:(ListGroupId)groupId withIndex:(ListIndex)index width:(CGFloat)width;
- (UIView*) listViewForGroupFoot:(ListGroupId)groupId withIndex:(ListIndex)index width:(CGFloat)width;
- (void) listTopGroupDidChangeTo:(ListGroupId)newTopGroupId withIndex:(ListIndex)index from:(ListGroupId)previousTopGroupId;
- (void) listBottomGroupDidChangeTo:(ListGroupId)newBottomGroupId withIndex:(ListIndex)index from:(ListGroupId)previousBottomGroupId;
- (void) listSelectGroupWithId:(ListGroupId)groupId withIndex:(ListIndex)index;
- (BOOL) listShouldMoveWithKeyboard;
- (void) listDidScroll:(CGFloat)offsetChange;
- (void) listViewWasRemoved:(UIView*)view location:(ListViewLocation)location index:(ListIndex)index;
@end

// Stickies
///////////
@interface FunListViewStickyGroup : NSObject
- (UIView*)newView;
@property (readonly) CGFloat height;
@property (readonly) BOOL isEmpty;
@end

// List View
////////////
@interface FunListView : UIView <UIScrollViewDelegate>
//@property UIView* listView;
@property UIScrollView* scrollView;
@property UIEdgeInsets listGroupMargins;
@property UIEdgeInsets listItemMargins;
@property (weak) id<FunListViewDelegate> delegate;
@property (readonly) ListIndex topListIndex;
@property (readonly) ListIndex bottomListIndex;
@property (readonly) ListGroupId topGroupId;
@property (readonly) ListGroupId bottomGroupId;
@property NSString* loadingMessage;
@property NSString* emptyMessage;
+ (void) insetAll:(UIEdgeInsets)insets;
- (void) reloadDataForList;
- (void) stopScrollingList;
- (void) appendToListCount:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex;
- (void) prependToListCount:(NSUInteger)numItems;
- (void) moveListWithKeyboard:(CGFloat)keyboardHeightChange;
- (CGFloat) setHeight:(CGFloat)height forVisibleViewWithIndex:(ListIndex)index;
- (void) selectVisibleIndex:(ListIndex)index;
- (void) extendBottom;
- (UIView*) visibleViewWithIndex:(ListIndex)index;
- (FunListViewStickyGroup*) stickyGroupWithPosition:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset;
- (UIView*) makeTopViewWithHeight:(CGFloat)height;
@end
