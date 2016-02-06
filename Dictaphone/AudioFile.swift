//
//  AudioFile.swift
//  Dictaphone
//
//  Created by Ceslovas Lopan on 11/01/16.
//  Copyright © 2016 Ceslovas Lopan. All rights reserved.
//

import UIKit
import AVFoundation

class AudioFile {
    var URL: NSURL!
    var length: Double!
    var size: UInt64!
    var player: AVAudioPlayer! = nil
    var isPlaying: Bool {
        get {
            if player != nil {
                return player.playing
            }

            return false
        }
    }

    var currentTime: Double {
        get {
            if player != nil {
                return player.currentTime
            }

            return 0
        }
    }

    var fileName: String {
        get {
            return URL.lastPathComponent!
        }
    }

    var formatedLength: String {
        get {
            return AudioFile.formatTime(length)
        }
    }

    var formatedCurrentTime: String {
        return AudioFile.formatTime(currentTime)
    }

    var formatedSize: String {
        get {
            var size: Double = Double(self.size)
            var units: String = "bytes"

            if self.size < 1024 * 1024 {
                size = Double(self.size) / 1024.0
                units = "KB"
            } else if self.size < 1024 * 1024 * 1024 {
                size = Double(self.size) / 1024.0 / 1024.0 / 1024.0
                units = "MB"
            } else if self.size < 1024 * 1024 * 1024 * 1024 {
                size = Double(self.size) / 1024.0 / 1024.0 / 1024.0 / 1024.0
                units = "GB"
            }

            return "\(NSString(format: "%.02f", size))\(units)"
        }
    }

    init(URL: NSURL!) {
        self.URL = URL
        calculateLength()
        calculateFileSize()
    }

    static func formatTime(l: Double) -> String {
        let totalSeconds: Int = Int(ceil(l))
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        let strHours = hours > 9 ? String(hours) : "0" + String(hours)
        let strMinutes = minutes > 9 ? String(minutes) : "0" + String(minutes)
        let strSeconds = seconds > 9 ? String(seconds) : "0" + String(seconds)

        if hours > 0 {
            return "\(strHours):\(strMinutes):\(strSeconds)"
        } else {
            return "\(strMinutes):\(strSeconds)"
        }
    }

    func play() throws {
        if player == nil {
            player = try AVAudioPlayer(contentsOfURL: URL)
        }

        player.prepareToPlay()
        player.play()
    }

    func pause() {
        if player == nil {
            return
        }

        player.pause()
    }

    func setTime(t: Double) throws {
        if player == nil {
            player = try AVAudioPlayer(contentsOfURL: URL)
        }

        if !isPlaying {
            player.prepareToPlay()
        }

        player.currentTime = t
    }

    func delete() throws {
        let fm = NSFileManager.defaultManager()
        try fm.removeItemAtURL(URL)
    }

    private func calculateLength() {
        do {
            let pl = try AVAudioPlayer(contentsOfURL: URL)
            length = pl.duration
        } catch {
            print("Could not get audio length of ", URL)
        }
    }

    private func calculateFileSize() {
        do {
            let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(URL.path!)
            if let fileSize = fileAttributes[NSFileSize] {
                size = (fileSize as! NSNumber).unsignedLongLongValue
            } else {
                print("Failed to get a size attribute from path: \(URL.path!)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(URL.path) with error: \(error)")
        }
    }

}
