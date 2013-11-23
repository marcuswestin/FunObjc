//
//  ListViewController.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

typedef NSInteger ListIndex;
typedef id ListGroupId;

enum ListViewLocation { TOP=1, BOTTOM=2 };
typedef enum ListViewLocation ListViewLocation;

enum ListViewDirection { UP=-1, DOWN=1 };
typedef enum ListViewDirection ListViewDirection;

@interface ListView : UIView
@property ListGroupId groupId;
@property ListIndex index;
@property BOOL isGroupHead;
@property BOOL isGroupFoot;
- (BOOL)isGroupView;
- (BOOL)isItemView;
+ (ListView*)withFrame:(CGRect)frame index:(ListIndex)index;
+ (ListView*)withFrame:(CGRect)frame footGroupId:(ListGroupId)groupId;
+ (ListView*)withFrame:(CGRect)frame headGroupId:(ListGroupId)groupId;
@end

@protocol ListViewDelegate <NSObject>
@required

- (UIView*) listViewForIndex:(ListIndex)index width:(CGFloat)width;
- (void) listSelectIndex:(ListIndex)index view:(UIView*)view;

@optional
- (ListIndex)listStartIndex;
- (id) listGroupIdForIndex:(ListIndex)index;

- (UIView*) listHeadViewForGroupId:(ListGroupId)groupId withIndex:(ListIndex)index width:(CGFloat)width;
- (UIView*) listFootViewForGroupId:(ListGroupId)groupId withIndex:(ListIndex)index width:(CGFloat)width;

- (void) listTopGroupDidChangeTo:(ListGroupId)newTopGroupId withIndex:(ListIndex)index from:(ListGroupId)previousTopGroupId;
- (void) listBottomGroupDidChangeTo:(ListGroupId)newBottomGroupId withIndex:(ListIndex)index from:(ListGroupId)previousBottomGroupId;

- (void) listSelectGroupWithId:(ListGroupId)groupId withIndex:(ListIndex)index;
- (BOOL) listShouldMoveWithKeyboard;
@end


@interface ListViewController : ViewController <UIScrollViewDelegate>
@property UIView* listView;
@property UIScrollView* scrollView;
@property UIEdgeInsets listGroupMargins;
@property UIEdgeInsets listItemMargins;
@property ListViewLocation listStartLocation;
@property (weak) id<ListViewDelegate> delegate;

/////////////////
// API methods //
/////////////////
- (void) reloadDataForList;
- (void) stopScrollingList;
- (void) appendCountToList:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex;
- (void) moveListWithKeyboard:(CGFloat)keyboardHeight;
- (void) setHeight:(CGFloat)height forVisibleViewWithIndex:(ListIndex)index;
@end
