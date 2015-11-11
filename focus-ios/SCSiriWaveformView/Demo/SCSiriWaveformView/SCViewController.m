//
//  SCViewController.m
//  SCSiriWaveformView
//
//  Created by Stefan Ceriu on 13/04/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "SCSiriWaveformView.h"

typedef NS_ENUM(NSUInteger, SCSiriWaveformViewInputType) {
	SCSiriWaveformViewInputTypeRecorder,
	SCSiriWaveformViewInputTypePlayer
};

@interface SCViewController ()

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;

@property (nonatomic, assign) SCSiriWaveformViewInputType selectedInputType;

@end

@implementation SCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
	NSError *error;
	NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
	self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
	
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
	
	self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"m4a"] error:&error];
	if(error) {
		NSLog(@"Ups, could not create player %@", error);
		return;
	}
	
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
		return;
    }
	
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.waveformView setWaveColor:[UIColor whiteColor]];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
	
	[self setSelectedInputType:SCSiriWaveformViewInputTypeRecorder];
}

- (void)setSelectedInputType:(SCSiriWaveformViewInputType)selectedInputType
{
	_selectedInputType = selectedInputType;
	
	switch (selectedInputType) {
		case SCSiriWaveformViewInputTypeRecorder: {
			[self.player stop];
			
			[self.recorder prepareToRecord];
			[self.recorder setMeteringEnabled:YES];
			[self.recorder record];
			break;
		}
		case SCSiriWaveformViewInputTypePlayer: {
			[self.recorder stop];
			
			[self.player prepareToPlay];
			[self.player setMeteringEnabled:YES];
			[self.player play];
			break;
		}
	}
}

- (IBAction)onSegmentedControlValueChanged:(UISegmentedControl *)sender
{
	[self setSelectedInputType:(SCSiriWaveformViewInputType)sender.selectedSegmentIndex];
}

- (void)updateMeters
{
	CGFloat normalizedValue;
	switch (self.selectedInputType) {
		case SCSiriWaveformViewInputTypeRecorder: {
			[self.recorder updateMeters];
			normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.recorder averagePowerForChannel:0]];
			break;
		}
		case SCSiriWaveformViewInputTypePlayer: {
			[self.player updateMeters];
			normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.player averagePowerForChannel:0]];
			break;
		}
	}
    
    [self.waveformView updateWithLevel:normalizedValue];
}

#pragma mark - Private

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
	if (decibels < -60.0f || decibels == 0.0f) {
		return 0.0f;
	}
	
	return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

@end
