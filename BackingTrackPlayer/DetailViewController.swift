//
//  DetailViewController.swift
//  BackingTrackPlayer
//
//  Created by Nick Malbraaten on 6/2/18.
//  Copyright © 2018 Nick Malbraaten. All rights reserved.
//

import UIKit
import AVFoundation

class DetailViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    @IBOutlet weak var trackName: UILabel!
    
    var audioPlayer: AVAudioPlayer?
    var currentTrackIndex: Int = 0
    let tracks = [
        "Sense Control_BT",
        "When Morning Came_BT",
        "In The Pines_BT",
        "Blind_BT",
        "Legacy_BT"
    ]
    let trackDirectory = "Backing Tracks/"

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }
    
    func configureAudioPlayer() {
        loadTrack()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureAudioPlayer()
        configureView()
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
        if (audioPlayer != nil) {
            if (audioPlayer!.isPlaying) {
                audioPlayer?.stop()
                audioPlayer?.currentTime = 0
                currentTrackIndex = currentTrackIndex + 1
                loadTrack()
            } else {
                print("started song")
                audioPlayer?.play()
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished song")
        if (currentTrackIndex == tracks.count - 1) {
            currentTrackIndex = 0
        } else {
            currentTrackIndex = currentTrackIndex + 1
        }
        
        loadTrack()
    }
    
    func loadTrack() {
        do {
            if let fileURL = Bundle.main.path(forResource: trackDirectory + tracks[currentTrackIndex], ofType: "wav") {
                let trackUrl = URL(fileURLWithPath: fileURL)
                audioPlayer = try AVAudioPlayer(contentsOf: trackUrl)
                audioPlayer?.prepareToPlay()
                audioPlayer?.delegate = self
                trackName.text = tracks[currentTrackIndex]
            } else {
                print("No file with specified name exists")
            }
        } catch let error {
            print("Can't play the audio file failed with an error \(error.localizedDescription)")
        }
    }
    
}

