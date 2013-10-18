//
//  ListViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "ListViewController.h"
#import "UIView+FunStyle.h"
#import "FunTypes.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"
#import "UIScrollView+Fun.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "NSArray+Fun.h"

// Used to differentiate group head views from item views
@interface ListGroupHeadView : UIView;
@end
@implementation ListGroupHeadView
@end

@interface ListItemView : UIView;
@end
@implementation ListItemView
@end

static CGFloat MAX_Y = 9999999.0f;
static CGFloat START_Y = 99999.0f;

@implementation ListViewController {
    UIView* _topGroupView;
    NSUInteger _withoutScrollEventStack;
    BOOL _hasReachedTheVeryTop;
    BOOL _hasReachedTheVeryBottom;
    id<ListViewDelegate> _delegate;
    NSInteger _topItemIndex;
    NSInteger _bottomItemIndex;
    CGFloat _previousContentOffsetY;
    id _bottomGroupId;
    id _topGroupId;
    CGFloat _topY;
    CGFloat _bottomY;

}

- (void)beforeRender:(BOOL)animated {
    if (!_delegate) {
        _delegate = (id<ListViewDelegate>)self;
    }
    if (!_listStartLocation) {
        _listStartLocation = TOP;
    }
    
    self.view.backgroundColor = WHITE;
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical = YES;
    
    [self _setupScrollview];
    [self.view insertSubview:_scrollView atIndex:0];
}

- (void)afterRender:(BOOL)animated {
    [self reloadData];
    [Keyboard onWillShow:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            if ([self shouldMoveWithKeyboard]) {
                [_scrollView addContentInsetTop:info.keyboardHeight];
                [self.view moveByY:-info.keyboardHeight];
            } else {
                [_scrollView addContentInsetBottom:info.keyboardHeight];
            }
        }];
    }];
    [Keyboard onWillHide:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            if ([self shouldMoveWithKeyboard]) {
                [_scrollView addContentInsetTop:-info.keyboardHeight];
                [self.view moveByY:info.keyboardHeight];
            } else {
                [_scrollView addContentInsetBottom:-info.keyboardHeight];
            }
        }];
    }];
}

- (BOOL)shouldMoveWithKeyboard {
    return ([_delegate respondsToSelector:@selector(listShouldMoveWithKeyboard)] && [_delegate listShouldMoveWithKeyboard]);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Keyboard offWillShow:self];
    [Keyboard offWillHide:self];
}

- (void)reloadData {
    [self _withoutScrollEvents:^{
        [self.scrollView empty];

        _topY = START_Y;
        _bottomY = START_Y;
        _scrollView.contentSize = CGSizeMake(self.view.width, MAX_Y);
        _scrollView.contentOffset = CGPointMake(0, START_Y);
        _previousContentOffsetY = _scrollView.contentOffset.y;
        _bottomGroupId = nil;
        _topGroupId = nil;
        
        if (_listStartLocation == TOP) {
            // Starting at the top, render items downwards
            _topItemIndex = [self _getStartIndex];
            _bottomItemIndex = _topItemIndex - 1;
            BOOL didAddFirstView = [self _listAddNextBottomView];
            
            if (didAddFirstView) {
                _bottomGroupId = _topGroupId = [self groupIdForItem:[_delegate listItemForIndex:_topItemIndex]];

                [self _setTopGroupItem:[_delegate listItemForIndex:_topItemIndex] withDirection:DOWN];
                
                [self _extendBottom];
                [self _extendTop];
            }
            
        } else if (_listStartLocation == BOTTOM) {
            // Starting at the bottom, render items upwards
            _bottomItemIndex = [self _getStartIndex];
            _topItemIndex = _bottomItemIndex + 1;
            BOOL didAddFirstView = [self _listAddNextTopView];
            
            if (didAddFirstView) {
                _bottomGroupId = _topGroupId = [self groupIdForItem:[_delegate listItemForIndex:_bottomItemIndex]];

                [self _extendTop];
                [self _extendBottom];
                
                [self _setTopGroupItem:[_delegate listItemForIndex:_topItemIndex] withDirection:UP];
            }
            
        } else {
            [NSException raise:@"Bad" format:@"Invalid listStartLocation %d", _listStartLocation];
        }
    }];
    if ([self _getStartIndex] == 0 && _scrollView.contentInset.top != 0) {
        _scrollView.contentOffset = CGPointMake(0, -_scrollView.contentInset.top);
    }
}

- (ListItemIndex)_getStartIndex {
    if ([_delegate respondsToSelector:@selector(listStartIndex)]) {
        return [_delegate listStartIndex];
    } else {
        return 0;
    }
}

- (void)_setupScrollview {
    [_scrollView setDelegate:self];
    [_scrollView onTap:^(UITapGestureRecognizer *sender) {
        CGPoint tapPoint = [sender locationInView:_scrollView];
        NSInteger itemIndex = _topItemIndex;
        for (UIView* view in self.views) {
            BOOL isGroupView = [self _isGroupView:view];
            if (CGRectContainsPoint(view.frame, tapPoint)) {
                id item = [_delegate listItemForIndex:itemIndex];
                if (isGroupView) {
                    id groupId = [self groupIdForItem:item];
                    if ([_delegate respondsToSelector:@selector(listSelectGroupWithId:withItem:)]) {
                        [_delegate listSelectGroupWithId:(id)groupId withItem:(id)item];
                    }
                } else {
                    [_delegate listSelectItem:item index:itemIndex view:view];
                }
                break;
            }
            if (!isGroupView) {
                itemIndex += 1; // Don't count group heads against item indices.
            }
        }
    }];
}

- (void)_setTopGroupItem:(id)item withDirection:(ListViewDirection)direction {
    _topGroupId = [self groupIdForItem:item];
    if ([_delegate respondsToSelector:@selector(listTopGroupDidChange:withDirection:)]) {
        [_delegate listTopGroupDidChange:item withDirection:direction];
    }
}

- (BOOL)_isGroupView:(UIView*)view {
    return [view isMemberOfClass:[ListGroupHeadView class]];
}

- (BOOL)_listAddNextBottomView {
    NSInteger index = _bottomItemIndex + 1;
    id item = [_delegate listItemForIndex:index];
    if (!item) { return NO; }
    
    // Check if the new item falls outside of the group of the current bottom-most item.
    id groupId = [self groupIdForItem:item];
    if (![groupId isEqual:_bottomGroupId]) {
        // We reached the beginning of the next-to-be-displayed group at the bottom of the view
        [self _addGroupViewForItem:item withGroupId:groupId atLocation:BOTTOM];
    }
    
    UIView* view = [self _getViewForItem:item atIndex:index];
    [self _addView:view at:BOTTOM];
    
    _bottomItemIndex = index;
    return YES;
}

- (BOOL)_listAddNextTopView {
    NSInteger nextTopItemIndex = _topItemIndex - 1;
    id nextTopItem = [_delegate listItemForIndex:nextTopItemIndex];
    if (!nextTopItem) {
        if (![self _isGroupView:[self topView]]) {
            // There should always be a group view at the very top
            [self _listRenderTopGroup];
            return YES;
        }

        return NO; // We're at the very top
    }
    
    // Check if the new item falls outside of the group of the current top-most item.
    id groupId = [self groupIdForItem:nextTopItem];
    if (![groupId isEqual:_topGroupId]) {
        if ([self _isGroupView:[self topView]]) {
            // The group view was just rendered in the previous _listAddNewTopView call
            _topGroupId = groupId;
        } else {
            // We reached the top of the currently displayed top-most group.
            [self _listRenderTopGroup];
            return YES;
        }
    }
    
    UIView* view = [self _getViewForItem:nextTopItem atIndex:nextTopItemIndex];
    [self _addView:view at:TOP];
    _topItemIndex = nextTopItemIndex;
    return YES;
}

- (UIView*)_getViewForItem:(id)item atIndex:(NSInteger)itemIndex {
    UIView* content = [_delegate listViewForItem:item atIndex:itemIndex withWidth:[self _listWidthForView]];
    CGRect frame = content.bounds;
    frame.size.height += _listItemMargins.top + _listItemMargins.bottom;
    content.y = _listItemMargins.top;
    content.x = _listItemMargins.left + _listGroupMargins.left;
    ListItemView* view = [[ListItemView alloc] initWithFrame:frame];
    [view addSubview:content];
    return view;
}

- (UIView*)_listRenderTopGroup {
    id previousTopItem = [_delegate listItemForIndex:_topItemIndex];
    return [self _addGroupViewForItem:previousTopItem withGroupId:_topGroupId atLocation:TOP];
}

- (CGFloat)_listWidthForView {
    return self.view.width - (_listGroupMargins.left + _listGroupMargins.right + _listItemMargins.left + _listItemMargins.right);
}

- (UIView*) _addGroupViewForItem:(id)item withGroupId:(id)groupId atLocation:(ListViewLocation)location {
    UIView* view;
    if ([_delegate respondsToSelector:@selector(listViewForGroupId:withItem:withWidth:)]) {
        view = [_delegate listViewForGroupId:groupId withItem:item withWidth:[self _listWidthForView]];
    } else {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self _listWidthForView], 0)];
    }
    [view moveToX:_listGroupMargins.left y:_listGroupMargins.top + _listGroupMargins.bottom];
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.top + _listGroupMargins.bottom;
    ListGroupHeadView* groupView = [[ListGroupHeadView alloc] initWithFrame:frame];
    [groupView addSubview:view];
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupItem:item withDirection:UP];
    } else {
        _bottomGroupId = groupId;
    }
    [self _checkTopGroupView];
    return groupView;
}

- (void) _checkTopGroupView {
    _topGroupView = [self.views pickOne:^BOOL(id view, NSUInteger i) {
        return [self _isGroupView:view];
    }];
}

- (void)_addView:(UIView*)view at:(ListViewLocation)location {
    if (location == TOP) {
        _topY -= view.height;
        [view moveToY:_topY];
        [_scrollView insertSubview:view atIndex:0];
    } else {
        [view moveToY:_bottomY];
        _bottomY += view.height;
        [_scrollView addSubview:view];
    }
}

- (void)_extendBottom {
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    while (_bottomY < targetY) {
        BOOL didAddView = [self _listAddNextBottomView];
        if (!didAddView) {
            [self _didReachTheVeryBottom];
            break;
        }
    }
    [self _cleanupTop];
}

- (void)_extendTop {
    CGFloat targetY = _scrollView.contentOffset.y;
    while (_topY > targetY) {
        BOOL didAddView = [self _listAddNextTopView];
        if (!didAddView) {
            [self _didReachTheVeryTop];
            break;
        }
    }
    [self _cleanupBottom];
}

- (void)_cleanupTop {
    CGFloat targetY = _scrollView.contentOffset.y;
    UIView* view;
    while ((view = [self topView]) && CGRectGetMaxY(view.frame) < targetY) {
        [view removeFromSuperview];
        _topY += view.height;
        if ([self _isGroupView:view]) {
            id item = [_delegate listItemForIndex:_topItemIndex];
            [self _setTopGroupItem:item withDirection:DOWN];
            [self _checkTopGroupView];
        } else {
            _topItemIndex += 1;
        }
    }
}

- (void) _cleanupBottom {
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    UIView* view;
    while ((view = [self bottomView]) && CGRectGetMinY(view.frame) > targetY) {
        [view removeFromSuperview];
        _bottomY -= view.height;
        if ([self _isGroupView:view]) {
            id item = [_delegate listItemForIndex:_bottomItemIndex];
            _bottomGroupId = [self groupIdForItem:item];
        } else {
            _bottomItemIndex -= 1;
        }
    }
}

- (id)groupIdForItem:(id)item {
    if ([_delegate respondsToSelector:@selector(listGroupIdForItem:)]) {
        return [_delegate listGroupIdForItem:item];
    } else {
        return nil;
    }
}

- (void)_didReachTheVeryBottom {
    _hasReachedTheVeryBottom = YES;
    _scrollView.contentSize = CGSizeMake(_scrollView.width, CGRectGetMaxY([self bottomView].frame));
}

- (void)_didReachTheVeryTop {
    _hasReachedTheVeryTop = YES;
    
    CGFloat changeInHeight = CGRectGetMinY([self topView].frame);
    if (changeInHeight == 0) { return; }
    _topY -= changeInHeight;
    _bottomY -= changeInHeight;
    [self _withoutScrollEvents:^{
        _scrollView.contentOffset = CGPointMake(0, _scrollView.contentOffset.y - changeInHeight);
        _scrollView.contentSize = CGSizeMake(self.view.width,  _scrollView.contentSize.height - changeInHeight);
        for (UIView* subView in self.views) {
            [subView moveByY:-changeInHeight];
        }
    }];
}

- (void)listAppendItemsStartingAtIndex:(ListItemIndex)firstIndex count:(NSUInteger)count {
    if (count == 0) {
        return;
    }
    
    if (firstIndex <= _bottomItemIndex) {
        [NSException raise:@"Invalid state" format:@"Appended item with index <= current bottom item index"];
        return;
    }
    
    CGFloat changeInHeight = 0;
    
    CGFloat screenVisibleFold = (_scrollView.height - _scrollView.contentInset.bottom);
    CGFloat offsetVisibleFold = (_scrollView.contentOffset.y + screenVisibleFold);
    
    for (NSUInteger i=0; i<count; i++) {
        ListItemIndex itemIndex = firstIndex + i;
        id item = [_delegate listItemForIndex:itemIndex];
        UIView* view = [self _getViewForItem:item atIndex:itemIndex];
        changeInHeight += view.height;
    }
    
    [_scrollView addContentHeight:changeInHeight];
    
    CGFloat scrollAmount = (_bottomY + changeInHeight) - offsetVisibleFold;
    if (scrollAmount > 0) {
        [_scrollView addContentOffset:scrollAmount animated:YES];
    } else {
        [self _extendBottom];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (contentOffsetY > _previousContentOffsetY) {
        [self _extendBottom];
    } else if (contentOffsetY < _previousContentOffsetY) {
        [self _extendTop];
    } else { // contentOffsetY == _previousContentOffsetY
        return;
    }
    
    _previousContentOffsetY = scrollView.contentOffset.y;
    
    if (_topGroupView && [_delegate respondsToSelector:@selector(listTopGroupViewDidMove:)]) {
        CGRect frame = _topGroupView.frame;
        frame.origin.y -= _scrollView.contentOffset.y;
        [_delegate listTopGroupViewDidMove:frame];
    }
}

- (void)stopScrolling {
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
}

- (NSArray*)views {
    if (!_scrollView.subviews || !_scrollView.subviews.count) { return @[]; }
    return [_scrollView.subviews filter:^BOOL(UIView* view, NSUInteger i) {
        // Why is a random UIImageView hanging in the scroll view? Asch.
        return ![view isKindOfClass:UIImageView.class];
    }];
}
- (UIView*)topView {
    return self.views.firstObject;
}
- (UIView*)bottomView {
    return self.views.lastObject;
}

@end
