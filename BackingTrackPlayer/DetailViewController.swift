//
//  DetailViewController.swift
//  BackingTrackPlayer
//
//  Created by Nick Malbraaten on 6/2/18.
//  Copyright © 2018 Nick Malbraaten. All rights reserved.
//

import UIKit
import AVFoundation

class DetailViewController: UIViewController, TrackPlayerDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var trackPlayer: TrackPlayer?

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
        playButton.setTitle("", for: .normal)
        let playImage = UIImage(systemName: "play.fill")
        playImage?.accessibilityIdentifier = "play"
        playButton.setImage(playImage, for: .normal)
        
        rewindButton.setTitle("", for: .normal)
        let rewindImage = UIImage(systemName: "backward.end.fill")
        rewindImage?.accessibilityIdentifier = "rewind"
        rewindButton.setImage(rewindImage, for: .normal)
        
        skipButton.setTitle("", for: .normal)
        let skipImage = UIImage(systemName: "forward.end.fill")
        skipImage?.accessibilityIdentifier = "skip"
        skipButton.setImage(skipImage, for: .normal)
    }
    
    func configureTrackPlayer() {
        self.trackPlayer = TrackPlayer(tracks: self.getTracks())
        self.trackPlayer?.delegate = self
        updateTitleLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureTrackPlayer()
        configureView()
    }
    
    // This will need to be rewritten when we're not hardcoding track titles/locations
    // (e.g. getting them from the device's music library, etc.)
    func getTracks() -> Array<Track> {
        let trackTitles = [
            "Sense Control_BT",
            "When Morning Came_BT",
            "In The Pines_BT",
            "Blind_BT",
            "Legacy_BT"
        ]
        let trackRootPath = "Backing Tracks/"
        let trackFileType = "wav"
        
        var tracks: Array<Track> = []
        for title in trackTitles {
            tracks.append(Track(title: title, filePath: trackRootPath + title, fileType: trackFileType))
        }
        return tracks
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    @IBAction func playSong(_ sender: UIButton) {
        if (trackPlayer != nil) {
            if (trackPlayer!.isPlaying()) {
                trackPlayer!.stop()
            } else {
                trackPlayer!.play()
            }
            togglePlayButtonLabel()
        }
    }
    
    @IBAction func skipToNextSong(_ sender: Any) {
        if (trackPlayer != nil) {
            if (trackPlayer!.isPlaying()) {
                togglePlayButtonLabel()
            }
            
            trackPlayer!.fastForward()
            updateTitleLabel()
        }
    }
    
    @IBAction func rewindSong(_ sender: Any) {
        if (trackPlayer != nil) {
            if (trackPlayer!.isPlaying()) {
                togglePlayButtonLabel()
            }
            
            trackPlayer!.rewind()
        }
    }
    
    func trackPlayerDidFinishPlaying() {
        updateTitleLabel()
    }
    
    func updateTitleLabel() {
        trackName.text = trackPlayer?.currentTrack.title
    }
    
    func togglePlayButtonLabel() {
        let buttonMode = playButton.image(for: .normal)?.accessibilityIdentifier;
        if (buttonMode == "play") {
            let playImage = UIImage(systemName: "pause.circle.fill")
            playImage?.accessibilityIdentifier = "pause"
            playButton.setImage(playImage, for: .normal)
        } else {
            let playImage = UIImage(systemName: "play.fill")
            playImage?.accessibilityIdentifier = "play"
            playButton.setImage(playImage, for: .normal)
        }
    }
}

