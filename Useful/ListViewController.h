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
- (void) appendToList:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex;
- (void) moveListWithKeyboard:(CGFloat)keyboardHeight;
@end
