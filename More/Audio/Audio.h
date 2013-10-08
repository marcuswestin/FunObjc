//
//  Audio.h
//  ivyq
//
//  Created by Marcus Westin on 10/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioGraph.h"

typedef float Pitch; // pitch=[-1,1]

typedef struct AudioEffects* AudioEffects;
struct AudioEffects {
    Pitch pitch;
};

@interface Audio : NSObject

- (BOOL)recordFromMicrophoneToFile:(NSString*)path;
- (void)stopRecordingFromMicrophone;
- (BOOL)playToSpeakerFromFile:(NSString*)path;
- (BOOL)playToSpeakerFromFile:(NSString*)path effects:(AudioEffects)effects;
- (float)readFromFile:(NSString*)fromPath toFile:(NSString*)toPath;
- (float)readFromFile:(NSString*)fromPath toFile:(NSString*)toPath effects:(AudioEffects)effects;

@end
