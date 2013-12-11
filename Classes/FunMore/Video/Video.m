//
//  Videos.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/1/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Video.h"
#import <MediaPlayer/MediaPlayer.h>

static Video* instance;

@implementation Video {
    MPMoviePlayerController* _moviePlayer;
    StringErrorCallback _playbackCallback;
}

- initWithUrl:(NSString*)url fromView:(UIView*)fromView callback:(StringErrorCallback)callback {
    _moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:url]];
//    _moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    [_moviePlayer prepareToPlay];
    [_moviePlayer.view setFrame:fromView.bounds];
    [fromView addSubview:_moviePlayer.view];
    
    _playbackCallback = callback;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayer];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    [_moviePlayer setFullscreen:YES animated:YES];
//    [_moviePlayer play];
    return self;
}

+ (instancetype)playVideo:(NSString *)url fromView:(UIView*)fromView callback:(StringErrorCallback)callback {
    return instance = [[Video alloc] initWithUrl:url fromView:fromView callback:callback];
}

- (void) _playbackDidFinish:(NSNotification*)notification {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    [_moviePlayer setFullscreen:NO animated:YES];
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        _playbackCallback(nil, @"Playback ended");
    } else if (reason == MPMovieFinishReasonUserExited) {
        _playbackCallback(nil, @"User exited");
    } else if (reason == MPMovieFinishReasonPlaybackError) {
        _playbackCallback(makeError(@"Playback error"), nil);
    }
}

@end
