//
//  FileViewController.swift
//  Dictaphone
//
//  Created by Ceslovas Lopan on 05/01/16.
//  Copyright © 2016 Ceslovas Lopan. All rights reserved.
//

import UIKit
import FontAwesome
import AVFoundation

class FileViewController: UIViewController {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var totalLengthLabel: UILabel!
    @IBOutlet weak var currentPositionLabel: UILabel!
    @IBOutlet weak var lengthSlider: UISlider!

    var file: AudioFile!

    override func viewDidLoad() {
        super.viewDidLoad()

        playButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        playButton.setTitle(String.fontAwesomeIconWithName(.Play), forState: .Normal)

        pauseButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        pauseButton.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)

        navigationItem.title = file.fileName
        totalLengthLabel.text = file.formatedLength
        lengthSlider.maximumValue = Float(file.length)

        // Consider using property observer for file.currentTime instead
        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timeUpdate:", userInfo: nil, repeats: true)
    }

    @objc
    func timeUpdate(timer: NSTimer) {
        self.currentPositionLabel.text = file.formatedCurrentTime
        self.lengthSlider.value = Float(file.currentTime)

        if file.isPlaying  {
            pauseButton.hidden = false
            playButton.hidden = true
        } else {
            pauseButton.hidden = true
            playButton.hidden = false
        }
    }

    func delete() {
        do {
            try self.file.delete()
        } catch {
            ViewController.showError(self, message: "File could not be deleted")
        }
    }

    @IBAction func deleteTapped(sender: AnyObject) {
        let ac = UIAlertController(title: "Delete", message: "Are you sure, you want to delete this recording?", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .Destructive) { [unowned self] (_) in
            self.delete()
            self.navigationController?.popToRootViewControllerAnimated(true)

        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)

    }

    @IBAction func pauseTapped(sender: AnyObject) {
        pauseButton.hidden = true
        playButton.hidden = false

        file.pause()
    }

    @IBAction func playTapped(sender: AnyObject) {
        pauseButton.hidden = false
        playButton.hidden = true

        do {
            try file.play()
        } catch {
            ViewController.showError(self, message: "File cannot be played")
        }
    }

    @IBAction func lengthValueChanged(sender: UISlider) {
        do {
            try file.setTime(Double(lengthSlider.value))
        } catch {
            print("Error: Could not set time")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
