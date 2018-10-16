//
//  TrackPlayer.swift
//  BackingTrackPlayer
//
//  Created by Nick Malbraaten on 10/15/18.
//  Copyright © 2018 Nick Malbraaten. All rights reserved.
//

import Foundation
import AVFoundation

class TrackPlayer: NSObject, AVAudioPlayerDelegate {
    weak var delegate: TrackPlayerDelegate?
    
    private var audioPlayer: AVAudioPlayer?
    private var currentTrackIndex: Int = 0
    
    var tracks: Array<Track>
    public var currentTrack: Track
    
    init(tracks: Array<Track>) {
        self.tracks = tracks
        self.currentTrack = tracks[currentTrackIndex]
        
        // Since we're adopting the AVAudioPlayerDelegate, and that inherits from NSObjectProtocol,
        // we have to inherit from NSObject as well and call super.init() here
        super.init()

        self.loadTrack(track: self.currentTrack)
    }

    func loadTrack(track: Track) {
        do {
            if let fileURL = Bundle.main.path(forResource: track.filePath, ofType: track.fileType) {
                let trackUrl = URL(fileURLWithPath: fileURL)
                audioPlayer = try AVAudioPlayer(contentsOf: trackUrl)
                audioPlayer?.prepareToPlay()
                // This is what causes the audioPlayerDidFinishPlayer() method to be called
                audioPlayer?.delegate = self
            } else {
                print("No file with specified name exists")
            }
        } catch let error {
            print("Can't play the audio file failed with an error \(error.localizedDescription)")
        }
    }
    
    // When a track finishes playing, we want to load the next track in the playlist
    // If we're at the end of the playlist, load the first track again
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        fastForward()
        delegate?.trackPlayerDidFinishPlaying()
    }
    
    func play() {
        if (audioPlayer != nil && !audioPlayer!.isPlaying) {
            audioPlayer?.play()
        }
    }
    
    func stop() {
        if (audioPlayer != nil && audioPlayer!.isPlaying) {
            audioPlayer?.stop()
        }
    }
    
    func fastForward() {
        if (audioPlayer != nil) {
            stop()
            if (currentTrackIndex == tracks.count - 1) {
                currentTrackIndex = 0
            } else {
                currentTrackIndex = currentTrackIndex + 1
            }
            currentTrack = tracks[currentTrackIndex]
            loadTrack(track: currentTrack)
        }
    }
    
    func rewind() {
        if (audioPlayer != nil) {
            stop()
            audioPlayer?.currentTime = 0
        }
    }
    
    func isPlaying() -> Bool {
        return audioPlayer!.isPlaying
    }
}
