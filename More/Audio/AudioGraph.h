//
//  AudioGraph.h
//  ivyq
//
//  Created by Marcus Westin on 10/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Audio.h"
#import "FunObjc.h"

const AudioUnitElement RIOInputFromMic;
const AudioUnitElement RIOInputFromApp;
const AudioUnitElement RIOOutputToSpeaker;
const AudioUnitElement RIOOutputToApp;

@interface AudioGraphFileInfo : NSObject
@property (readonly) AudioStreamBasicDescription fileFormat;
@property (readonly) UInt64 numPackets;
@property (readonly) AUNode fileNode;
@end

@interface AudioGraph : NSObject
@property (nonatomic,assign,readonly) AUNode ioNode;
@property (nonatomic,assign,readonly) AudioUnit ioUnit;

- (id) initWithSpeaker;
- (id) initWithSpeakerAndMicrophoneInput;
- (id) initWithSpearkAndVoiceInput;
- (id) initWithOfflineIO;
- (id) initWithNoIO;

- (BOOL) start;
- (BOOL) stop;

- (AUNode) addNodeNamed:(NSString*)nodeName type:(OSType)type subType:(OSType)subType;
- (AUNode) getNodeNamed:(NSString*)nodeName;
- (AudioUnit) getUnit:(AUNode)node;
- (AudioUnit) getUnitNamed:(NSString*)nodeName;

- (BOOL) connectNode:(AUNode)nodeA bus:(UInt32)busA toNode:(AUNode)nodeB bus:(UInt32)busB;

- (AudioGraphFileInfo*) readFile:(NSString*)filepath toNode:(AUNode)node bus:(AudioUnitElement)bus;
- (void) recordFromNode:(AUNode)node bus:(AudioUnitElement)bus toFile:(NSString *)filepath;
- (void) stopRecordingToFileAndScheduleStop;
- (void) cleanupRecording;

BOOL audioSetOutputStreamFormat(AudioUnit unit, AudioUnitElement bus, AudioStreamBasicDescription asbd);
BOOL audioSetInputStreamFormat(AudioUnit unit, AudioUnitElement bus, AudioStreamBasicDescription asbd);
AudioStreamBasicDescription audioGetInputStreamFormat(AudioUnit unit, AudioUnitElement bus);
AudioStreamBasicDescription audioGetOutputStreamFormat(AudioUnit unit, AudioUnitElement bus);
AVAudioSession* audioCreateSession(NSString* category);
BOOL audioCheck(NSString* str, OSStatus status);
@end

@interface AudioGraphEnpoints : NSObject
@property AudioGraph* graph;
@property (assign) AUNode firstNode;
@property (assign) AUNode lastNode;
@property (readonly) AudioUnit firstUnit;
@property (readonly) AudioUnit lastUnit;
@property (readonly) AudioStreamBasicDescription lastFormat;
@property (readonly) AudioStreamBasicDescription firstFormat;
+ (instancetype) withGraph:(AudioGraph*)graph firstNode:(AUNode)firstNode lastNode:(AUNode)lastNode;
@end
