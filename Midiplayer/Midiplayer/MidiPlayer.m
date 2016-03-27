//
//  MidiPlayer.m
//  Midiplayer
//
//  Created by Nikita.Kardakov on 25/03/2016.
//  Copyright © 2016 nickk. All rights reserved.
//

#import "MidiPlayer.h"
#import <CoreMidi/CoreMidi.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define kPrefferedMaximumFramesPerSlice 4096
#define kDefaultTempo 120

@interface MidiPlayer() {
    AUGraph graph;
    AudioUnit leftUnit, rightUnit, metronomeUnit, mixerUnit, rioUnit;
    MusicPlayer musicPlayer;
    MusicSequence musicSequence;
    AUNode leftNode, rightNode, metronomeNode, mixerNode, rioNode;
    UInt32 initialTempo;
}

@end

@implementation MidiPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self setupGraph];
        [self loadSampleMaps];
    }
    return self;
}

- (void)setupAudioSession {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)setupGraph {
    OSStatus result = noErr;
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    
    NewAUGraph (&graph);
    
    cd.componentType = kAudioUnitType_MusicDevice;
    cd.componentSubType = kAudioUnitSubType_Sampler;
    
    AUGraphAddNode (graph, &cd, &leftNode);
    AUGraphAddNode (graph, &cd, &rightNode);
    AUGraphAddNode (graph, &cd, &metronomeNode);
    
    cd.componentType = kAudioUnitType_Mixer;
    cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    
    result = AUGraphAddNode(graph, &cd, &mixerNode);
    
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
    result = AUGraphAddNode (graph, &cd, &rioNode);
    
    AUGraphOpen(graph);
    
    AUGraphConnectNodeInput(graph, leftNode, 0, mixerNode, 0);
    AUGraphConnectNodeInput(graph, rightNode, 0, mixerNode, 1);
    AUGraphConnectNodeInput(graph, metronomeNode, 0, mixerNode, 2);
    AUGraphConnectNodeInput(graph, mixerNode, 0, rioNode, 0);
    
    AUGraphNodeInfo(graph, leftNode, 0, &leftUnit);
    AUGraphNodeInfo(graph, rightNode, 0, &rightUnit);
    AUGraphNodeInfo(graph, metronomeNode, 0, &metronomeUnit);
    AUGraphNodeInfo(graph, mixerNode, 0, &mixerUnit);
    AUGraphNodeInfo(graph, rioNode, 0, &rioUnit);
    
    UInt32 maximumFramesPerSlice = kPrefferedMaximumFramesPerSlice;
    
    AudioUnitSetProperty (leftUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice));
    AudioUnitSetProperty (rightUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice));
    AudioUnitSetProperty (metronomeUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice));
    AudioUnitSetProperty (mixerUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice));
    AudioUnitSetProperty (rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, sizeof (maximumFramesPerSlice));
    
    AUGraphInitialize(graph);
    
    AUGraphStart(graph);
}

- (void)play {
    if ( musicPlayer ) {
        MusicPlayerStart(musicPlayer);
    }
}

- (void)pause {
    if ( musicPlayer ) {
        MusicPlayerStop(musicPlayer);
    }
}

- (BOOL)isPlaying {
    if ( musicPlayer ) {
        Boolean isRunning;
        MusicPlayerIsPlaying(musicPlayer, &isRunning);
        return isRunning;
    }
    return NO;
}

- (void) loadSampleMaps {
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"HPiano2" ofType:@"aupreset"]];
    [self loadMapForUrl:presetURL andUnit:leftUnit];
    [self loadMapForUrl:presetURL andUnit:rightUnit];
}

- (void) loadMapForUrl:(NSURL*)url andUnit:(AudioUnit)unit {
    NSError * error;
    
    NSData * data = [NSData dataWithContentsOfURL:url
                                          options:0
                                            error:&error];
    
    CFPropertyListRef presetPropertyList = 0;
    CFPropertyListFormat dataFormat = 0;
    CFErrorRef errorRef = 0;
    presetPropertyList = CFPropertyListCreateWithData (kCFAllocatorDefault, (__bridge CFDataRef)(data), kCFPropertyListImmutable, &dataFormat, &errorRef);
    
    if (presetPropertyList != 0) {
        
        AudioUnitSetProperty(unit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &presetPropertyList, sizeof(CFPropertyListRef) );
        
        CFRelease(presetPropertyList);
    }
}

- (void)loadMidiData:(NSData*)data {
    [self pause];
    
    if ( musicPlayer ) {
        DisposeMusicPlayer(musicPlayer);
    }
    if ( musicSequence ) {
        DisposeMusicSequence(musicSequence);
    }
    
    NewMusicPlayer(&musicPlayer);
    NewMusicSequence(&musicSequence);
    MusicSequenceFileLoadData(musicSequence, (__bridge CFDataRef)data, kMusicSequenceFile_MIDIType, kMusicSequenceLoadSMF_PreserveTracks);
    MusicPlayerSetSequence(musicPlayer, musicSequence);
    
    OSStatus status;
    MusicTrack leftTrack;
    status = MusicSequenceGetIndTrack(musicSequence, 0, &leftTrack);
    
    MusicTrack rightTrack;
    status = MusicSequenceGetIndTrack(musicSequence, 1, &rightTrack);
    
    NSDictionary * dict = (__bridge NSDictionary*)MusicSequenceGetInfoDictionary(musicSequence);
    if ( dict[@"tempo"] ) {
        initialTempo = [dict[@"tempo"] intValue];
    } else {
        initialTempo = kDefaultTempo;
    }
    [self setTempo:initialTempo];
    
    MusicSequenceSetAUGraph(musicSequence, graph);
    
    MusicTrackSetDestNode(leftTrack, leftNode);
    MusicTrackSetDestNode(rightTrack, rightNode);
    
    MusicPlayerPreroll(musicPlayer);
}

- (void)removeTempoEvents:(MusicTrack)track {
    MusicEventIterator tempIter;
    NewMusicEventIterator(track, &tempIter);
    Boolean hasEvent;
    MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent);
    while (hasEvent) {
        MusicTimeStamp stamp;
        MusicEventType type;
        const void *data = NULL;
        UInt32 sizeData;
        
        MusicEventIteratorGetEventInfo(tempIter, &stamp, &type, &data, &sizeData);
        if (type == kMusicEventType_ExtendedTempo){
            MusicEventIteratorDeleteEvent(tempIter);
            MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent);
        }
        else{
            MusicEventIteratorNextEvent(tempIter);
            MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent);
        }
    }
    DisposeMusicEventIterator(tempIter);
}

- (Float32)leftHandVolume {
    Float32 volume;
    UInt32 size = sizeof(volume);
    OSStatus status = AudioUnitGetProperty(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, &volume, &size);
    
    if ( status != noErr ) {
        return 0.5f;
    }
    return volume;
}

- (Float32)rightHandVolume {
    Float32 volume;
    UInt32 size = sizeof(volume);
    OSStatus status = AudioUnitGetProperty(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, &volume, &size);
    
    if ( status != noErr ) {
        return 0.5f;
    }
    return volume;
}

- (Float32)metronomeVolume {
    Float32 volume;
    UInt32 size = sizeof(volume);
    OSStatus status = AudioUnitGetProperty(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 2, &volume, &size);
    
    if ( status != noErr ) {
        return 0.5f;
    }
    return volume;
}

- (void)setLeftHandVolume:(Float32)leftHandVolume {
    AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume,
                          kAudioUnitScope_Input, 0, leftHandVolume, 0);
}

- (void)setRightHandVolume:(Float32)rightHandVolume {
    AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume,
                          kAudioUnitScope_Input, 1, rightHandVolume, 0);
}

- (void)setMetronomeVolume:(Float32)metronomeVolume {
    AudioUnitSetParameter(metronomeUnit, kMultiChannelMixerParam_Volume,
                          kAudioUnitScope_Input, 2, metronomeVolume, 0);
}

- (UInt32)tempo {
    return initialTempo;
}

- (void)setTempo:(UInt32)tempo {
    
    if (tempo <= 0) {
        return;
    }
    
    MusicTrack tempoTrack;
    MusicSequenceGetTempoTrack(musicSequence, &tempoTrack);
    [self removeTempoEvents:tempoTrack];
    MusicTrackNewExtendedTempoEvent(tempoTrack, 0, tempo);
    initialTempo = tempo;
}

- (void)skipRight:(Float32)seconds {
    
}

- (void)skipLeft:(Float32)seconds {
    
}

- (void)setLoopBegin:(BOOL)enabled {
    
}

- (void)setLoopEnd:(BOOL)enabled {
    
}

@end
