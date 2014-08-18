//
//  Audio.m
//  ivyq
//
//  Created by Marcus Westin on 10/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Audio.h"

static AVAudioSession* _session;
static AudioGraph* _graph;
static AudioPlaybackProgressCallback _progressCallback;

@implementation AudioEffects
+ (instancetype)withPitch:(Pitch)pitch {
    AudioEffects* instance = [AudioEffects new];
    instance.pitch = pitch;
    return instance;
}
@end

@implementation AudioPlayer {
    AudioPlaybackProgressCallback _progressCallback;
    Block _completeCallback;
}

- (BOOL)play {
    [self _loopProgressCallback];
    return [super play];
}

- (void)setProgress:(float)progress {
    self.currentTime = self.duration * CLIP(progress, 0.0, 1.0);
}


- (void)setPlaybackProgressCallback:(AudioPlaybackProgressCallback)progressCallback {
    _progressCallback = progressCallback;
}

- (void)setPlaybackCompleteCallback:(Block)completeCallback {
    _completeCallback = completeCallback;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!_completeCallback) { return; }
    _completeCallback();
}

- (void)_loopProgressCallback {
    every(0.01, ^(BOOL *stop) {
        if (!_progressCallback) { return; }
        float progress = self.currentTime / self.duration;
        if (self && self.playing) {
            _progressCallback(NO, progress);
        } else {
            _progressCallback(YES, progress);
            *stop = YES;
        }
    });
}
@end

@implementation Audio

+ (void)loadUrl:(NSString *)url callback:(AudioPlayerCallback)callback {
    NSString* cacheName = [Files sanitizeName:url];
    NSData* data = [Files readCache:cacheName];
    if (data) {
        [self _loadData:data callback:callback];
    } else {
        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
            if (err) { return error(err); }
            [Files writeCache:cacheName data:data];
            [self _loadData:data callback:callback];
        }];
    }
}

+ (void)_loadData:(NSData*)data callback:(AudioPlayerCallback)callback {
    [self setSessionToPlayback];
    NSError* err;
    AudioPlayer* player = [[AudioPlayer alloc] initWithData:data error:&err];
    if (err) {
        return error(err);
    }
    player.delegate = player;
    callback(player);
}

/*
 
 Audio Unit types
 http://developer.apple.com/library/ios/#documentation/AudioUnit/Reference/AudioUnitParametersReference/Reference/reference.html
 
 kAudioUnitType_Output            = 'auou',
 kAudioUnitType_MusicDevice       = 'aumu',
 kAudioUnitType_MusicEffect       = 'aumf',
 kAudioUnitType_FormatConverter   = 'aufc',
 kAudioUnitType_Effect            = 'aufx',
 kAudioUnitType_Mixer             = 'aumx',
 kAudioUnitType_Panner            = 'aupn',
 kAudioUnitType_OfflineEffect     = 'auol',
 kAudioUnitType_Generator         = 'augn',
 
 
 Audio Unit Parameter Event Types
 kParameterEvent_Immediate = 1,
 kParameterEvent_Ramped    = 2
 
 
 Converter Audio Unit Subtypes
 
 kAudioUnitSubType_AUConverter        = 'conv', linear PCM conversions, such as changes to sample rate, bit depth, or interleaving.
 ! kAudioUnitSubType_NewTimePitch       = 'nutp', independent control of both playback rate and pitch.
 ! kAudioUnitSubType_TimePitch          = 'tmpt', independent control of playback rate and pitch
 kAudioUnitSubType_DeferredRenderer   = 'defr', acquires audio input from a separate thread than the thread on which its render method is called
 kAudioUnitSubType_Splitter           = 'splt', duplicates the input signal to each of its two output buses.
 kAudioUnitSubType_Merger             = 'merg', merges the two input signals to the single output.
 ! kAudioUnitSubType_Varispeed          = 'vari', control playback rate. As the playback rate increases, so does pitch.
 ! kAudioUnitSubType_AUiPodTime         = 'iptm', simple, limited control over playback rate and time.
 kAudioUnitSubType_AUiPodTimeOther    = 'ipto'  ???
 
 
 Effect Audio Unit Subtypes
 
 kAudioUnitSubType_PeakLimiter          = 'lmtr', enforces an upper dynamic limit on an audio signal.
 kAudioUnitSubType_DynamicsProcessor    = 'dcmp', provides dynamic compression or expansion.
 ! kAudioUnitSubType_Reverb2              = 'rvb2', reverb unit for iOS.
 kAudioUnitSubType_LowPassFilter        = 'lpas', cuts out frequencies below a specified cutoff
 kAudioUnitSubType_HighPassFilter       = 'hpas', cuts out frequencies above a specified cutoff
 kAudioUnitSubType_BandPassFilter       = 'bpas', cuts out frequencies outside specified upper and lower cutoffs
 kAudioUnitSubType_HighShelfFilter      = 'hshf', suitable for implementing a treble control in an audio playback or recording system.
 kAudioUnitSubType_LowShelfFilter       = 'lshf', suitable for implementing a bass control in an audio playback or recording system.
 kAudioUnitSubType_ParametricEQ         = 'pmeq', a filter whose center frequency, boost/cut level, and Q can be adjusted.
 ! kAudioUnitSubType_Delay                = 'dely', introduces a time delay to a signal.
 ! kAudioUnitSubType_Distortion           = 'dist', provides a distortion effect.
 kAudioUnitSubType_AUiPodEQ             = 'ipeq', provides a graphic equalizer in iPhone OS.
 kAudioUnitSubType_NBandEQ              = 'nbeq'  multi-band equalizer with specifiable filter type for each band.
 
 
 Mixer Audio Unit Subtypes
 
 ! kAudioUnitSubType_MultiChannelMixer      = 'mcmx', multiple input buses, one output bus always with two channels.
 kAudioUnitSubType_MatrixMixer            = 'mxmx', like MultiChannelMixer but configurable mixing
 kAudioUnitSubType_AU3DMixerEmbedded      = '3dem', 3D stuff
 
 
 Generator Audio Unit Subtypes
 
 kAudioUnitSubType_ScheduledSoundPlayer  = 'sspl', schedule slices of audio to be played at specified times.
 ! kAudioUnitSubType_AudioFilePlayer       = 'afpl', play a file.
 
 
 Audio Unit Parameters:
 http://developer.apple.com/library/ios/#documentation/AudioUnit/Reference/AudioUnitPropertiesReference/Reference/reference.html
 
 */

+ (void)addEffects:(AudioEffects*)effects {
    if (!effects) { return; }
    AudioUnit unit = [_graph getUnitNamed:@"pitch"];
    float pitch = effects.pitch * 2400; // [-1,1] -> [-2400,2400]
    audioCheck(@"Set pitch", AudioUnitSetParameter(unit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0));
}

+ (float)readFromFile:(NSString *)fromPath toFile:(NSString *)toPath {
    return [self readFromFile:fromPath toFile:toPath effects:NULL];
}

+ (float)readFromFile:(NSString *)fromPath toFile:(NSString *)toPath effects:(AudioEffects*)effects {
    _session = audioCreateSession(AVAudioSessionCategoryAudioProcessing);
    
    _graph = [[AudioGraph alloc] initWithNoIO];
    AudioGraphEnpoints* endpoints = [self addEffectChain:_graph];
    [self addEffects:effects];
    
    // Read from file
    AudioGraphFileInfo* fileInfo = [_graph readFile:fromPath toNode:endpoints.firstNode bus:0];
    AudioUnit fileUnit = [_graph getUnit:fileInfo.fileNode];
    audioSetOutputStreamFormat(fileUnit, 0, endpoints.firstFormat);
    // Write to file
    [_graph recordFromNode:[_graph getNodeNamed:@"record"] bus:0 toFile:toPath];
    
    // Render the audio until done (this is instead of the typical [graph start])
    AudioUnitRenderActionFlags flags = kAudioOfflineUnitRenderAction_Render;
    AudioBufferList bufferList;
    UInt32 numFrames = (UInt32)(fileInfo.fileFormat.mFramesPerPacket * fileInfo.numPackets);
    UInt32 framesPerBuffer = 1024;
    bufferList.mNumberBuffers = endpoints.lastFormat.mChannelsPerFrame;
    for (int i=0; i<endpoints.lastFormat.mChannelsPerFrame; i++) {
        bufferList.mBuffers[i].mNumberChannels = 1;
        bufferList.mBuffers[i].mDataByteSize = framesPerBuffer * endpoints.lastFormat.mBytesPerFrame;
        bufferList.mBuffers[i].mData = NULL;
    }
    for (UInt32 i=0; i*framesPerBuffer<=numFrames; i++) {
        AudioTimeStamp audioTimeStamp = {0};
        memset (&audioTimeStamp, 0, sizeof(audioTimeStamp));
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        audioTimeStamp.mSampleTime = i * framesPerBuffer;
        audioCheck(@"Render audio",
              AudioUnitRender(endpoints.lastUnit, &flags, &audioTimeStamp, 0, framesPerBuffer, &bufferList));
    }
    [_graph cleanupRecording];
    
    return (numFrames / fileInfo.fileFormat.mSampleRate * 1000);
}

+ (BOOL)playToSpeakerFromFile:(NSString *)path {
    return [self playToSpeakerFromFile:path effects:NULL];
}

+ (void)setSessionToPlayback {
    _session = audioCreateSession(AVAudioSessionCategoryPlayback);
}

+ (BOOL)playToSpeakerFromFile:(NSString *)path effects:(AudioEffects*)effects {
    [self setSessionToPlayback];
    
    _graph = [[AudioGraph alloc] initWithSpeaker];
    AudioGraphEnpoints* endpoints = [self addEffectChain:_graph];
    [self addEffects:effects];
    
    // Read from file
    AudioGraphFileInfo* fileInfo = [_graph readFile:path toNode:endpoints.firstNode bus:0];
    audioSetOutputStreamFormat([_graph getUnit:fileInfo.fileNode], 0, endpoints.firstFormat);
    // Write to speaker
    audioSetInputStreamFormat(_graph.ioUnit, RIOInputFromApp, endpoints.lastFormat);
    [_graph connectNode:endpoints.lastNode bus:0 toNode:_graph.ioNode bus:RIOInputFromApp];
    
    return [_graph start];
}

+ (BOOL)recordFromMicrophoneToFile:(NSString *)path {
    _session = audioCreateSession(AVAudioSessionCategoryPlayAndRecord);
    if (!_session.inputAvailable) {
        DLog(@"Audio: WARNING Requested input is not available");
        return NO;
    }

    _graph = [[AudioGraph alloc] initWithSpeakerAndMicrophoneInput];
    AudioGraphEnpoints* endpoints = [self addEffectChain:_graph];
    [self addEffects:NULL];

    // Read from mic
    audioSetOutputStreamFormat(_graph.ioUnit, RIOOutputToApp, endpoints.firstFormat);
    [_graph connectNode:_graph.ioNode bus:RIOOutputToApp toNode:endpoints.firstNode bus:0];
    // Write to file
    [_graph recordFromNode:[_graph getNodeNamed:@"record"] bus:0 toFile:path];
    // Connect to speaker for IO pull, but set volume to 0
    [_graph connectNode:endpoints.lastNode bus:0 toNode:_graph.ioNode bus:RIOInputFromApp];
    audioSetInputStreamFormat(_graph.ioUnit, RIOInputFromApp, endpoints.lastFormat);
    [self setVolume:0];
    
    return [_graph start];
}

+ (void) stopRecordingFromMicrophone:(Block)callback {
    [_graph stopRecordingToFile:callback];
}

//////////////////
+ (AudioGraphEnpoints*) addEffectChain:(AudioGraph*)graph {
    // Create pitch node
    AUNode pitchNode = [graph addNodeNamed:@"pitch" type:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_NewTimePitch];
    AudioUnit pitchUnit = [graph getUnit:pitchNode];
    // Create recording node
    AUNode recordNode = [graph addNodeNamed:@"record" type:kAudioUnitType_Mixer subType:kAudioUnitSubType_MultiChannelMixer];
    AudioUnit recordUnit = [graph getUnit:recordNode];
    // Create volume node
    AUNode volumeNode = [graph addNodeNamed:@"volume" type:kAudioUnitType_Mixer subType:kAudioUnitSubType_MultiChannelMixer];
    AudioUnit volumeUnit = [graph getUnit:volumeNode];
    
    // Connect pitch node -> record node -> volume node
    audioSetInputStreamFormat(recordUnit, 0, audioGetOutputStreamFormat(pitchUnit, 0));
    [graph connectNode:pitchNode bus:0 toNode:recordNode bus:0];
    audioSetInputStreamFormat(volumeUnit, 0, audioGetOutputStreamFormat(recordUnit, 0));
    [graph connectNode:recordNode bus:0 toNode:volumeNode bus:0];
    
    return [AudioGraphEnpoints withGraph:graph firstNode:pitchNode lastNode:volumeNode];
}

+ (void) setVolume:(float)volumeFraction { // 0 - 1
    AudioUnit unit = [_graph getUnitNamed:@"volume"];
    AudioUnitSetParameter(unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, volumeFraction, 0);
}

+ (NSTimeInterval)getDurationForFile:(NSString *)path {
    AVAudioPlayer * sound = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
    return sound.duration;
}

@end






