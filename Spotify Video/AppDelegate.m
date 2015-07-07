//
//  AppDelegate.m
//  Spotify Video
//
//  Created by Yannick Weiss on 03/07/15.
//  Copyright © 2015 Yannick Weiss. All rights reserved.
//

#import "AppDelegate.h"
#import <ScriptingBridge/SBApplication.h>
#import "Spotify.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>


@interface AppDelegate ()
@property (weak) IBOutlet AVPlayerView *playerView;
@property (weak) IBOutlet NSWindow *window;
@end

/* Notes
 * example implementation: https://gist.github.com/kwylez/5337918
 * URL format: https://www.youtube.com/watch?v=dQw4w9WgXcQ
 * add a bit delay to the video so it matches spotify
 */

@implementation AppDelegate {
  NSDate *startTime;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)updateTrackInfoFromSpotify:(NSNotification *)notification {
  startTime = [NSDate date];
  NSString *playerState = [notification.userInfo valueForKey:@"Player State"];
  NSString *artist = [notification.userInfo valueForKey:@"Artist"];
  NSString *name = [notification.userInfo valueForKey:@"Name"];
  NSNumber *position = [notification.userInfo valueForKey:@"Playback Position"];
  NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
  AVPlayer *player = self.playerView.player;
  
  if ([playerState isEqualToString:@"Playing"])  {
    if ([position intValue] == 0) {
      NSLog(@"search song: %@", songDetails);
      NSString *videoID = [self videoIDforSong:songDetails];
      [self playYoutubeVideo:videoID];
    } else {
      [player play];
    }
  } else if ([playerState isEqualToString:@"Paused"])  {
    [player pause];
  } else if ([playerState isEqualToString:@"Stopped"])  {
    [player pause];
  } else {
    NSLog(@"new state %@", playerState);
  }
}

- (NSString *)videoIDforSong:(NSString *)songDetails {
  NSString *apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"apiKey"];
  songDetails = [songDetails stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
  NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&videoDefinition=high&order=viewCount&type=video&key=%@&q=%@", apiKey, songDetails];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  NSURLResponse* response = nil;
  NSError *error = nil;
  NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
  
  // TODO: more error checking like http://stackoverflow.com/a/7794561/279890
  NSDictionary *results = [NSJSONSerialization
               JSONObjectWithData:data
               options:0
               error:&error];
  NSArray *items = [results objectForKey:@"items"];
  if ([items count] == 0) {
    NSLog(@"no video found");
    return @"GqkWnriHGUc";
  }
  
  return [items[0] valueForKeyPath:@"id.videoId"];
}

- (void)playYoutubeVideo:(NSString *)videoID {
  [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoID completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    if (video) {
      if (self.playerView.player) {
        [self.playerView.player removeObserver:self forKeyPath:@"status"];
      }
      
      NSDictionary *streamURLs = video.streamURLs;
      NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
      AVPlayer *player = [AVPlayer playerWithURL:url];
      
      [player addObserver:self forKeyPath:@"status" options:0 context:nil];
      player.volume = 0;
      self.playerView.player = player;
      [player play];
    } else {
      [[NSAlert alertWithError:error] runModal];
    }
  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
  AVPlayer *player = self.playerView.player;
  if (object == player && [keyPath isEqualToString:@"status"]) {
    if (player.status == AVPlayerStatusReadyToPlay) {
      NSTimeInterval diff = [startTime timeIntervalSinceNow] * -1;
      CMTime t = player.currentTime;
      t.value += diff;
      [player seekToTime:t];
    }
  }
}

@end
