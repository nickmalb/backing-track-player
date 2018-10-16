//
//  Track.swift
//  BackingTrackPlayer
//
//  Created by Nick Malbraaten on 10/15/18.
//  Copyright © 2018 Nick Malbraaten. All rights reserved.
//

import Foundation

class Track {
    let title: String
    let filePath: String
    let fileType: String
    
    init(title: String, filePath: String, fileType: String) {
        self.title = title
        self.filePath = filePath
        self.fileType = fileType
    }
}
