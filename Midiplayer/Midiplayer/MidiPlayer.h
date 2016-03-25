//
//  MidiPlayer.h
//  Midiplayer
//
//  Created by Nikita.Kardakov on 25/03/2016.
//  Copyright © 2016 nickk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MidiPlayerDelegate

- (void)progress:(Float32)progress;

@end

@interface MidiPlayer : NSObject

- (void)play;

- (void)pause;

- (BOOL)isPlaying;

- (void)loadMidiData:(NSData*)data;

@property (nonatomic, assign) Float32 leftHandVolume;
@property (nonatomic, assign) Float32 rightHandVolume;
@property (nonatomic, assign) Float32 metronomeVolume;

@property (nonatomic, assign) UInt32 tempo;

- (void)skipRight:(Float32)seconds;
- (void)skipLeft:(Float32)seconds;

- (void)setLoopBegin:(BOOL)enabled;
- (void)setLoopEnd:(BOOL)enabled;

@property (nonatomic, weak) id<MidiPlayerDelegate> delegate;

@end
