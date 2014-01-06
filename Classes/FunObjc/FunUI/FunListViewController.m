//
//  FunListViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunListViewController.h"
#import "UIView+FunStyle.h"
#import "FunBase.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"
#import "UIScrollView+Fun.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "NSArray+Fun.h"

//////////////////////////////////////////////////////////
// Custom subviews - differentiate head/foot/item views //
//////////////////////////////////////////////////////////
@interface ListContentView : UIView
@property ListGroupId groupId;
@property ListIndex index;
@property BOOL isGroupHead;
@property BOOL isGroupFoot;
- (BOOL)isGroupView;
- (BOOL)isItemView;
- (UIView*)content;
+ (ListContentView*)withFrame:(CGRect)frame index:(ListIndex)index;
+ (ListContentView*)withFrame:(CGRect)frame footGroupId:(ListGroupId)groupId;
+ (ListContentView*)withFrame:(CGRect)frame headGroupId:(ListGroupId)groupId;
@end
@implementation ListContentView
+ (ListContentView *)withFrame:(CGRect)frame index:(ListIndex)index {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.index = index;
    return view;
}
+ (ListContentView *)withFrame:(CGRect)frame headGroupId:(ListGroupId)groupId {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.groupId = groupId;
    view.isGroupHead = YES;
    return view;
}
+ (ListContentView *)withFrame:(CGRect)frame footGroupId:(ListGroupId)groupId {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.groupId = groupId;
    view.isGroupFoot = YES;
    return view;
}
- (BOOL)isGroupView {
    return _isGroupFoot || _isGroupHead;
}
- (BOOL)isItemView {
    return !_isGroupFoot && !_isGroupHead;
}
- (UIView *)content {
    return self.subviews.firstObject;
}
@end

///////////////////////////
// FunListViewController //
///////////////////////////

@interface FunViewController ()
- (void)_funViewControllerRender:(BOOL)animated;
@end

@interface FunListViewStickyGroup ()
- (id)initWithViewController:(FunListViewController*)vc point:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset;
- (void)onInitialContentRendered;
- (void)onContentMoved:(ListViewDirection)direction;
- (void)onDidAddView:(ListContentView*)view location:(ListViewLocation)location;
- (void)onListViewChangeInHeight:(CGFloat)changeInHeight;
@end

@implementation FunListViewController {
    NSUInteger _withoutScrollEventStack;
    BOOL _hasReachedTheVeryTop;
    BOOL _hasReachedTheVeryBottom;
    ListViewLocation _listStartLocation;
    ListIndex _topListIndex;
    ListIndex _bottomItemIndex;
    ListGroupId _bottomGroupId;
    ListGroupId _topGroupId;
    CGFloat _previousContentOffsetY;
    CGFloat _topY;
    CGFloat _bottomY;
    BOOL _scrollViewPurged;
    NSMutableArray* _stickyGroups;
    UIView* _emptyView;
    BOOL _hasContent;
    BOOL _hasCalledEmpty;
}

static CGFloat MAX_Y = 9999999.0f;
static CGFloat START_Y = 99999.0f;

/////////////////
// API methods //
/////////////////

- (UIView *)visibleViewWithIndex:(ListIndex)index {
    for (ListContentView* view in [self _views]) {
        if (view.isGroupView) { continue; }
        if (view.index == index) {
            return view.content;
        }
    }
    return nil;
}

- (void)reloadDataForList {
    [self _renderInitialContent];
    
    // Top should start scrolled down below the navigation bar
    if (_listStartLocation == TOP && !_hasReachedTheVeryBottom) {
        [_scrollView addContentOffset:-self.navigationController.navigationBar.y2 animated:NO];
    } else if (_listStartLocation == BOTTOM) {
        // TODO Check if there is a visible status bar
        // TODO Check if there is a visible navigation bar
        [_scrollView addContentOffset:20 animated:NO];
    }
}

- (void)stopScrollingList {
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
}

- (void)prependToListCount:(NSUInteger)numItems {
    if (numItems == 0) {
        return;
    }
    
    if (!_hasContent) {
        [self _renderInitialContent];
        return;
    }
    
    _topListIndex += numItems;
    _bottomItemIndex += numItems;
    for (ListContentView* view in [self _views]) {
        view.index += numItems;
    }
    
    if (_hasReachedTheVeryTop) {
        [self _fixContentTopByAdding:START_Y];
        _hasReachedTheVeryTop = NO;
    }
    
    // If the current top view is a group head, we may have prepended an item
    // above current top group above when it should have gone inside the group
    ListContentView* topView = [self _topView];
    if (topView.isGroupHead) {
        [topView removeFromSuperview];
        _topY += topView.height;
    }
    
    [self _extendTop];
}

- (void)appendToListCount:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex {
    if (numItems == 0) {
        return;
    }
    
    if (_hasContent && firstIndex <= _bottomItemIndex) {
        [NSException raise:@"Invalid state" format:@"Appended item with index <= current bottom item index"];
        return;
    }

    if (!_hasContent) {
        [self _renderInitialContent];
        return;
    }

    CGFloat changeInHeight = 0;
    
    CGFloat screenVisibleFold = (_scrollView.height - _scrollView.contentInset.bottom);
    CGFloat offsetVisibleFold = (_scrollView.contentOffset.y + screenVisibleFold);
    
    for (NSUInteger i=0; i<numItems; i++) {
        ListIndex index = firstIndex + i;
        ListContentView* view = [self _getViewForIndex:index location:BOTTOM];
        changeInHeight += view.height;
    }
    
    [_scrollView addContentHeight:changeInHeight];
    
    CGFloat scrollAmount = (_bottomY + changeInHeight) - offsetVisibleFold;
    if (scrollAmount > 0) {
        [_scrollView addContentOffset:scrollAmount animated:YES];
    } else {
        [self extendBottom];
    }
}

- (void)moveListWithKeyboard:(CGFloat)heightChange {
    [_scrollView addContentInsetTop:heightChange];
    [_listView moveByY:-heightChange];
}

- (void)makeRoomForKeyboard:(CGFloat)keyboardHeight {
    [_scrollView addContentInsetBottom:keyboardHeight];
}

- (void)setHeight:(CGFloat)height forVisibleViewWithIndex:(ListIndex)index {
    CGFloat __block dHeight = 0;
    for (ListContentView* view in self._views) {
        if (view.isGroupView) {
            view.y += dHeight;
        } else {
            if (view.index == index) {
                dHeight = (height - view.height) + _listItemMargins.bottom + _listItemMargins.top;
                view.height += dHeight;
            } else {
                view.y += dHeight;
            }
        }
    }
    _bottomY += dHeight;
    [_scrollView addContentHeight:dHeight];
}

- (FunListViewStickyGroup*)stickyGroupWithPosition:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset {
    id group = [[FunListViewStickyGroup alloc] initWithViewController:self point:y height:height viewOffset:viewOffset];
    [_stickyGroups addObject:group];
    return group;
}

//////////////////////
// Setup & Teardown //
//////////////////////

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent) { return; }
    _scrollView.delegate = nil;
}

- (void)_funViewControllerRender:(BOOL)animated {
    [self _beforeRender];
    [super _funViewControllerRender:animated];
    [self _afterRender];
}

- (void)_beforeRender {
    if (!_delegate) {
        if ([self conformsToProtocol:@protocol(FunListViewDelegate)]) {
            _delegate = (id<FunListViewDelegate>)self;
        } else {
            [NSException raise:@"Error" format:@"Make sure your FunListViewController subclass implements the FunListViewDelegate protocol"];
        }
    }
    _listStartLocation = TOP;
    if ([_delegate respondsToSelector:@selector(listStartLocation)]) {
        _listStartLocation = [_delegate listStartLocation];
    }
    
    _listView = [[UIView alloc] initWithFrame:self.view.bounds];
    _scrollView = [[UIScrollView alloc] initWithFrame:_listView.bounds];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical = YES;
    [_scrollView appendTo:_listView];
    
    _stickyGroups = [NSMutableArray array];
}

- (void)_handleKeyboardEvent:(KeyboardEventInfo*)info {
    if ([self _shouldMoveWithKeyboard]) {
        [self moveListWithKeyboard:info.heightChange];
    } else {
        [self makeRoomForKeyboard:info.heightChange];
    }
}

- (BOOL)_shouldMoveWithKeyboard {
    if ([_delegate respondsToSelector:@selector(listShouldMoveWithKeyboard)]) {
        return [_delegate listShouldMoveWithKeyboard];
    } else {
        return YES;
    }
}

static UIEdgeInsets insetsForAll;
static BOOL insetsForAllSet;
+ (void)insetAll:(UIEdgeInsets)insets {
    if (insetsForAllSet) {
        [NSException raise:@"Error" format:@"FunListViewController insetAll: called twice"];
    }
    insetsForAll = insets;
    insetsForAllSet = YES;
}

- (void)_afterRender {
    if (insetsForAllSet) {
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.top += insetsForAll.top;
        insets.right += insetsForAll.right;
        insets.bottom += insetsForAll.bottom;
        insets.left += insetsForAll.left;
        self.scrollView.contentInset = insets;
    }
    
    [self reloadDataForList];
    
    [self _setupScrollview];
    [self.view insertSubview:_listView atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Keyboard onWillShow:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            [self _handleKeyboardEvent:info];
        }];
    }];
    [Keyboard onWillHide:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            [self _handleKeyboardEvent:info];
        }];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Keyboard offWillShow:self];
    [Keyboard offWillHide:self];
}

- (void)_setupScrollview {
    [_scrollView setDelegate:self];
    [_scrollView onTap:^(UITapGestureRecognizer *sender) {
        CGPoint tapPoint = [sender locationInView:_scrollView];
        NSInteger index = _topListIndex;
        for (ListContentView* view in self._views) {
            if (CGRectContainsPoint(view.frame, tapPoint)) {
                if (view.isGroupView) {
                    if ([_delegate respondsToSelector:@selector(listSelectGroupWithId:withIndex:)]) {
                        ListGroupId groupId = [self _groupIdForIndex:index];
                        [_delegate listSelectGroupWithId:groupId withIndex:index];
                    }
                    
                } else {
                    [_delegate listSelectIndex:index view:view.content];
                }
                break;
            }
            if (!view.isGroupView) {
                index += 1; // Don't count group heads against item indices.
            }
        }
    }];
}

- (void)selectVisibleIndex:(ListIndex)index {
    for (ListContentView* view in [self _views]) {
        if ([view isItemView] && view.index == index) {
            [_delegate listSelectIndex:index view:view.content];
            return;
        }
    }
}

- (void)_renderEmpty {
    if (_emptyView) {
        [_emptyView removeAndClean];
    }
    _emptyView = [UIView.appendAfter(_listView, _scrollView).fill render];
    _hasContent = NO;
    if ([_delegate respondsToSelector:@selector(listRenderEmptyInView:isFirst:)]) {
        [_delegate listRenderEmptyInView:_emptyView isFirst:!_hasCalledEmpty];
    } else {
        [UILabel.appendTo(_emptyView).text(_hasCalledEmpty ? @"Nothing here" : @"Loading").size.center render];
    }
    _hasCalledEmpty = YES;
}

- (void)_renderInitialContent {
    [self.scrollView empty];

    [self _withoutScrollEvents:^{
        _scrollView.contentSize = CGSizeMake(_listView.width, MAX_Y);
        _scrollView.contentOffset = CGPointMake(0, START_Y);
        _previousContentOffsetY = START_Y;
    }];


    ListIndex startIndex = ([_delegate respondsToSelector:@selector(listStartIndex)] ? [_delegate listStartIndex] : 0);
    ListGroupId startGroupId = [self _groupIdForIndex:startIndex];
    
    if (![_delegate hasViewForIndex:startIndex]) {
        [self _renderEmpty];
        return; // Empty list
    }

    if (_listStartLocation == TOP) {
        // Starting at the top, render items downwards
        _topY = _bottomY = START_Y;
        _topListIndex = startIndex;
        _bottomItemIndex = startIndex - 1;
        _bottomGroupId = startGroupId;
        {
            ListIndex previousIndex = _topListIndex - 1;
            ListGroupId previousGroupId = [self _groupIdForIndex:previousIndex];
            BOOL hasPreviousView = [_delegate hasViewForIndex:previousIndex];
            if (!hasPreviousView || !previousGroupId || ![startGroupId isEqual:previousGroupId]) {
                [self _addGroupHeadViewForIndex:startIndex withGroupId:startGroupId atLocation:TOP];
            }
        }
        [self extendBottom];
        [self _extendTop];
        
    } else if (_listStartLocation == BOTTOM) {
        // Starting at the bottom, render items upwards
        _topY = _bottomY = START_Y + _listView.height;
        _bottomItemIndex = startIndex;
        _topListIndex = startIndex + 1;
        _topGroupId = startGroupId;
        {
            ListIndex nextIndex = _bottomItemIndex + 1;
            ListGroupId nextGroupId = [self _groupIdForIndex:nextIndex];
            BOOL hasNextView = [_delegate hasViewForIndex:nextIndex];
            if (!hasNextView || !nextGroupId || ![startGroupId isEqual:nextGroupId]) {
                [self _addGroupFootViewForIndex:startIndex withGroupId:startGroupId atLocation:BOTTOM];
            }
        }
        [self _extendTop];
        [self extendBottom];
        
    } else {
        [NSException raise:@"Bad" format:@"Invalid listStartLocation %d", _listStartLocation];
    }
    
    [_emptyView removeAndClean];
    _hasContent = YES;
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onInitialContentRendered];
    }
}

///////////////////////////////////////////
// Extend list up/down & as view scrolls //
///////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (contentOffsetY > _previousContentOffsetY) {
        // scrolled down
        [self extendBottom];
        for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
            [stickyGroup onContentMoved:UP];
        }
        
    } else if (contentOffsetY < _previousContentOffsetY) {
        // scrolled up
        [self _extendTop];
        for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
            [stickyGroup onContentMoved:DOWN];
        }
        
    } else {
        // no change (contentOffsetY == _previousContentOffsetY)
        return;
    }
    
    CGFloat offsetChange = scrollView.contentOffset.y - _previousContentOffsetY;
    _previousContentOffsetY = scrollView.contentOffset.y;
    if ([_delegate respondsToSelector:@selector(listDidScroll:)]) {
        [_delegate listDidScroll:offsetChange];
    }
}

- (void)extendBottom {
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    while (_bottomY < targetY) {
        BOOL didAddView = [self _listAddNextViewDown];
        if (!didAddView) {
            [self _onDidReachTheVeryBottom];
            break;
        }
    }
    [self _cleanupTop];
}

- (void)_extendTop {
    CGFloat targetY = _scrollView.contentOffset.y;
    while (_topY > targetY) {
        BOOL didAddView = [self _listAddNextViewUp];
        if (!didAddView) {
            [self _onDidReachTheVeryTop];
            break;
        }
    }
    [self _cleanupBottom];
}

- (BOOL)_listAddNextViewDown {
    NSInteger index = _bottomItemIndex + 1;
    BOOL hasView = [_delegate hasViewForIndex:index];
    
    if (!hasView) {
        // There are no more items to display at the bottom.
        // Last thing: add a group view at the bottom.
        if ([self _bottomView].isGroupView) {
            return NO; // All done!
            
        } else {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:BOTTOM];
            return YES;
        }
    }
    
    // Check if the new item falls outside of the group of the current bottom-most item.
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_bottomGroupId]) {
        // This item is the first of a new group.
        // First time around, add a foot view for the current bottom group
        // Second time around, add a head view for the next bottom group
        // After these two have happened, the actual item view is added (see below)
        
        ListContentView* bottomView = [self _bottomView];
        if (bottomView.isItemView) {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:BOTTOM];
            return YES;
            
        } else if (!_hasContent || bottomView.isGroupFoot) {
            [self _addGroupHeadViewForIndex:index withGroupId:groupId atLocation:BOTTOM];
            return YES;
            
        } else if (bottomView.isGroupHead) {
            [NSException raise:@"Error" format:@"If `bottomView.isGroupHead`, then the next groupId should equal bottomGroupId"];
        } else {
            [NSException raise:@"Error" format:@"bottomView should always be an item, foot or head view."];
        }
    }
    
    ListContentView* view = [self _getViewForIndex:index location:BOTTOM];
    [self _addView:view at:BOTTOM];
    _bottomItemIndex = index;
    return YES;
}

- (BOOL)_listAddNextViewUp {
    ListContentView* topView = [self _topView];
    if (_topListIndex == 0) {
        // There are no more items to display at the top.
        // Last thing: add a group head view at the top.
        if (topView.isGroupHead) {
            return NO; // All done!
            
        } else {
            [self _addGroupHeadViewForIndex:_topListIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
        }
    }
    
    NSInteger index = _topListIndex - 1;
    if (![_delegate hasViewForIndex:index]) {
        [NSException raise:@"Error" format:@"hasViewForIndex returned NO for index %d", index];
    }
    
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_topGroupId]) {
        // This item is the first of a new group. In order, add:
        // 1) A head view for the current top group
        // 2) A foot view for the next top group
        // 3) The item view
        
        if (topView.isItemView) {
            [self _addGroupHeadViewForIndex:_topListIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
            
        } else if (topView.isGroupHead) {
            [self _addGroupFootViewForIndex:index withGroupId:groupId atLocation:TOP];
            return YES;
            
        } else if (topView.isGroupFoot) {
            [NSException raise:@"Error" format:@"If `topView.isGroupFoot`, then the previous groupId should equal _topGroupId"];
        } else {
            [NSException raise:@"Error" format:@"topView should always be an item, foot or head view."];
        }
    }
    
    ListContentView* view = [self _getViewForIndex:index location:TOP];
    if (!view) {
        [NSException raise:@"Error" format:@"Got nil view for list index %d", index];
    }
    [self _addView:view at:TOP];
    _topListIndex = index;
    return YES;
}

- (void) _cleanupTop {
    // Clean up views at the top that are now out of sight
    CGFloat targetY = _scrollView.contentOffset.y;
    ListContentView* view;
    while ((view = [self _topView]) && CGRectGetMaxY(view.frame) < targetY) {
        [view removeAndClean];
        _topY += view.height;
        if (view.isItemView) {
            if ([_delegate respondsToSelector:@selector(listViewWasRemoved:location:index:)]) {
                [_delegate listViewWasRemoved:view location:TOP index:_topListIndex];
            }
            _topListIndex += 1;
        } else if (view.isGroupFoot) {
            [self _setTopGroupId:[self _groupIdForIndex:_topListIndex] index:_topListIndex];
        }
    }
}

- (void) _cleanupBottom {
    // Clean up views at the bottom that are now out of sight
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    ListContentView* view;
    while ((view = [self _bottomView]) && CGRectGetMinY(view.frame) > targetY) {
        [view removeAndClean];
        _bottomY -= view.height;
        if (view.isItemView) {
            if ([_delegate respondsToSelector:@selector(listViewWasRemoved:location:index:)]) {
                [_delegate listViewWasRemoved:view location:BOTTOM index:_bottomItemIndex];
            }
            _bottomItemIndex -= 1;
        } else if (view.isGroupHead) {
            [self _setBottomGroupId:[self _groupIdForIndex:_bottomItemIndex] index:_bottomItemIndex];
        }
    }
}

//////////////////////////////////
// Item & Group Head/Foot Views //
//////////////////////////////////
- (CGFloat)_widthForItemView {
    return _listView.width - (_listGroupMargins.left + _listGroupMargins.right + _listItemMargins.left + _listItemMargins.right);
}

- (ListContentView*)_getViewForIndex:(ListIndex)index location:(ListViewLocation)location {
    UIView* content = [_delegate listViewForIndex:index width:[self _widthForItemView] location:location];
    if (!content) { return nil; }
    CGRect frame = content.bounds;
    frame.size.height += _listItemMargins.top + _listItemMargins.bottom;
    frame.size.width = _listView.width;
    content.y = _listItemMargins.top;
    content.x = _listItemMargins.left + _listGroupMargins.left;
    ListContentView* view = [ListContentView withFrame:frame index:index];
    [view addSubview:content];
    return view;
}

- (CGFloat)_widthForGroupView {
    return _listView.width - (_listGroupMargins.left + _listGroupMargins.right);
}

- (void) _addGroupFootViewForIndex:(ListIndex)index withGroupId:(id)groupId atLocation:(ListViewLocation)location {
    CGFloat width = [self _widthForGroupView];
    UIView* view = ([_delegate respondsToSelector:@selector(listViewForGroupFoot:withIndex:width:)]
                    ? [_delegate listViewForGroupFoot:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = 0;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.bottom;
    ListContentView* groupView = [ListContentView withFrame:frame footGroupId:groupId];
    [groupView addSubview:view];
    
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void) _addGroupHeadViewForIndex:(ListIndex)index withGroupId:(ListGroupId)groupId atLocation:(ListViewLocation)location {
    CGFloat width = [self _widthForGroupView];
    UIView* view = ([_delegate respondsToSelector:@selector(listViewForGroupHead:withIndex:width:)]
                    ? [_delegate listViewForGroupHead:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = _listGroupMargins.top;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.top;
    ListContentView* groupView = [ListContentView withFrame:frame headGroupId:groupId];
    [groupView addSubview:view];
    
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void)_addView:(ListContentView*)view at:(ListViewLocation)location {
    if (location == TOP) {
        _topY -= view.height;
        view.y = _topY;
        [_scrollView insertSubview:view atIndex:0];
    } else {
        view.y = _bottomY;
        _bottomY += view.height;
        [_scrollView addSubview:view];
    }
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onDidAddView:view location:location];
    }
}

////////////////
// Misc stuff //
////////////////

- (ListGroupId)_groupIdForIndex:(ListIndex)index {
    if ([_delegate respondsToSelector:@selector(listGroupIdForIndex:)]) {
        return [_delegate listGroupIdForIndex:index];
    } else {
        return @1;
    }
}

- (void)_setTopGroupId:(ListGroupId)topGroupId index:(ListIndex)index {
    ListGroupId previousTopGroupId = _topGroupId;
    _topGroupId = topGroupId;
    if ([_delegate respondsToSelector:@selector(listTopGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listTopGroupDidChangeTo:topGroupId withIndex:index from:previousTopGroupId];
    }
}

- (void)_setBottomGroupId:(ListGroupId)bottomGroupId index:(ListIndex)index {
    ListGroupId previousBottomGroupId = _bottomGroupId;
    _bottomGroupId = bottomGroupId;
    if ([_delegate respondsToSelector:@selector(listBottomGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listBottomGroupDidChangeTo:bottomGroupId withIndex:index from:previousBottomGroupId];
    }
}

- (void)_onDidReachTheVeryBottom {
    _hasReachedTheVeryBottom = YES;
    _scrollView.contentSize = CGSizeMake(_scrollView.width, CGRectGetMaxY([self _bottomView].frame));
}

- (void)_onDidReachTheVeryTop {
    _hasReachedTheVeryTop = YES;
    CGFloat changeInHeight = CGRectGetMinY([self _topView].frame);
    if (changeInHeight == 0) { return; }
    [self _fixContentTopByAdding:-changeInHeight];
}

- (void)_fixContentTopByAdding:(CGFloat)changeInHeight {
    _topY += changeInHeight;
    _bottomY += changeInHeight;
    _previousContentOffsetY += changeInHeight;
    [self _withoutScrollEvents:^{
        [_scrollView addContentOffset:changeInHeight];
        [_scrollView addContentHeight:changeInHeight];
        for (UIView* subView in self._views) {
            [subView moveByY:changeInHeight];
        }
    }];
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onListViewChangeInHeight:changeInHeight];
    }
}

- (void)_withoutScrollEvents:(Block)block {
    if (_withoutScrollEventStack == 0) {
        _scrollView.delegate = nil;
    }
    _withoutScrollEventStack += 1;
    block();
    _withoutScrollEventStack -= 1;
    if (_withoutScrollEventStack == 0) {
        _scrollView.delegate = self;
    }
}

- (NSArray*)_views {
    if (!_scrollViewPurged) {
        for (UIView* view in _scrollView.subviews) {
            if (![view isKindOfClass:[ListContentView class]]) {
                [view removeAndClean];
            }
        }
        _scrollViewPurged = YES;
    }
    if (!_scrollView.subviews || !_scrollView.subviews.count) { return @[]; }
    return _scrollView.subviews;
}
- (ListContentView*)_topView {
    return self._views.firstObject;
}
- (ListContentView*)_bottomView {
    return self._views.lastObject;
}
@end

//////////////
// Stickies //
//////////////

@interface ListStickyView : UIView
@property CGFloat naturalOffset;
@property ListStickyView* viewAbove;
@property ListStickyView* viewBelow;
@end
@implementation ListStickyView
@end

@implementation FunListViewStickyGroup {
    ListStickyView* _topmost;
    ListStickyView* _current;
    ListStickyView* _bottommost;
    NSMutableArray*  _stickiesAddedForView;
    UIView* _stickiesContainerNonInteractive;
    CGFloat _y1;
    CGFloat _y2;
    CGFloat _height;
    CGFloat _viewOffset;
    FunListViewController* __weak _vc;
}

- (id)initWithViewController:(FunListViewController *)vc point:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset {
    _vc = vc;
    _y1 = y;
    _y2 = y + height;
    _height = height;
    _viewOffset = viewOffset;
    _stickiesAddedForView = [NSMutableArray array];
    _stickiesContainerNonInteractive = [UIView.appendTo(_vc.listView) render];
    _isEmpty = YES;
    return self;
}

- (UIView *)newView {
    CGFloat left = _vc.listGroupMargins.left + _vc.listItemMargins.left;
    CGFloat right = _vc.listGroupMargins.right + _vc.listItemMargins.right;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(left, 0, _vc.listView.width - left - right, 0)];
    [_stickiesAddedForView addObject:view];
    return view;
}

- (void)onDidAddView:(ListContentView*)view location:(ListViewLocation)location {
    if (!view.isItemView) { return; } // TODO Handle stickies for group views
    if (!_stickiesAddedForView.count) { return; }
    ListStickyView* stickyView = [ListStickyView.appendTo(_stickiesContainerNonInteractive).h(_height) render];
    for (UIView* view in _stickiesAddedForView) {
        [stickyView addSubview:view];
    }
    stickyView.naturalOffset = view.y + _viewOffset;
    stickyView.y = stickyView.naturalOffset - _vc.scrollView.contentOffset.y;
    [_stickiesAddedForView removeAllObjects];
    
    if (_isEmpty) {
        // First sticky
        [self _stickyMakeTopmost:stickyView];
        [self _stickyMakeBottommost:stickyView];
        _isEmpty = NO;
    } else if (location == TOP) {
        [self _stickyMakeTopmost:stickyView];
    } else if (location == BOTTOM) {
        [self _stickyMakeBottommost:stickyView];
    }
}

- (void)onInitialContentRendered {
    if (_isEmpty) {
        if (_y1 || _y2) {
            [NSException raise:@"Error" format:@"Expected at least one sticky to be rendered in list view"];
        }
        return;
    }
    // Elect a first sticky
    ListStickyView* closest = _topmost;
    CGFloat distance = 999999;
    CGFloat point = _y1 + (_y2 - _y1)/2;
    ListStickyView* view = closest;
    while ((view = view.viewBelow)) {
        if (abs(view.center.y - point) < distance) {
            distance = abs(view.center.y - point);
            closest = view;
        }
    }
    _current = closest;
    _current.y = _y1;
}

- (void)onContentMoved:(ListViewDirection)contentMoved {
    CGFloat offset = _vc.scrollView.contentOffset.y;
    
    ListStickyView* stickyView = _topmost;
    while (stickyView) {
        if (stickyView != _current) {
            stickyView.y = stickyView.naturalOffset - offset;
        }
        stickyView = stickyView.viewBelow;
    }

    ListStickyView* enroaching;
    
    // From below
    enroaching = _current.viewBelow;
    while (enroaching && enroaching.y < _y2) {
        // a view from below is overlapping with the current
        if (enroaching.y > _y1) {
            // the enroaching view is partially overlapping the current
            _current.y2 = enroaching.y;
        } else {
            // the enroaching view is completely pushing out the current
            _current.naturalOffset = offset + _y1 - _height;
            _current.y = _current.naturalOffset - offset;
            _current = enroaching;
            _current.y = _y1;
        }
        enroaching = enroaching.viewBelow;
    }
    // From above
    enroaching = _current.viewAbove;
    while (enroaching && enroaching.y2 > _y1) {
        // a view from above is overlapping with the current
        if (enroaching.y2 < _y2) {
            // the enroaching view is partially overlapping the current
            _current.y = enroaching.y2;
        } else {
            // the enroaching view is completely pushing out the current
            _current.naturalOffset = offset + _y2;
            _current.y = _current.naturalOffset - offset;
            _current = enroaching;
            _current.y = _y1;
        }
        enroaching = enroaching.viewAbove;
    }

    if (contentMoved == UP) {
        [self _stickiesCleanupTop];
        
    } else if (contentMoved == DOWN) {
        [self _stickiesCleanupBottom];
    }
}

- (void)onListViewChangeInHeight:(CGFloat)changeInHeight {
    ListStickyView* stickyView = _topmost;
    while (stickyView) {
        stickyView.naturalOffset += changeInHeight;
        stickyView = stickyView.viewBelow;
    }
}

// Stickies linked list
///////////////////////
- (void)_stickyMakeBottommost:(ListStickyView*)stickyView {
    _bottommost.viewBelow = stickyView;
    stickyView.viewAbove = _bottommost;
    _bottommost = stickyView;
}
- (void)_stickyMakeTopmost:(ListStickyView*)stickyView {
    stickyView.viewBelow = _topmost;
    _topmost.viewAbove = stickyView;
    _topmost = stickyView;
}
- (void)_stickiesCleanupTop {
    CGFloat targetY = 0;
    while (_topmost != _current && _topmost.y2 < targetY) {
        [_topmost removeAndClean];
        _topmost = _topmost.viewBelow;
        _topmost.viewAbove = nil;
        if (!_topmost) {
            [NSException raise:@"Error" format:@"Should always have a _topmost"];
        }
    }
}
- (void)_stickiesCleanupBottom {
    CGFloat targetY = _vc.listView.y2;
    while (_bottommost != _current && _bottommost.y > targetY) {
        [_bottommost removeAndClean];
        _bottommost = _bottommost.viewAbove;
        _bottommost.viewBelow = nil;
        if (!_bottommost) {
            [NSException raise:@"Error" format:@"Should always have a _bottommost"];
        }
    }
}

@end
