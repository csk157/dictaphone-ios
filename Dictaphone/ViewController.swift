//
//  ViewController.swift
//  Dictaphone
//
//  Created by Ceslovas Lopan on 12/12/15.
//  Copyright © 2015 Ceslovas Lopan. All rights reserved.
//

import UIKit
import AVFoundation
import FontAwesome

enum RecordingState {
    case Recording, Paused, None
}

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView: UITableView!
    var recorder: AVAudioRecorder!
    var fileList: [AudioFile]!

    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!

    var currentAction: RecordingState = .None {
        didSet {
            switch currentAction {
            case .Recording:
                recButton.hidden = true
                pauseButton.hidden = false
                stopButton.hidden = false
                resumeButton.hidden = true
            case .Paused:
                recButton.hidden = true
                pauseButton.hidden = true
                stopButton.hidden = false
                resumeButton.hidden = false
            default:
                recButton.hidden = false
                pauseButton.hidden = true
                stopButton.hidden = true
                resumeButton.hidden = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Dictaphone"
        currentAction = .None
        tableView.dataSource = self
        tableView.delegate = self

        recButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        recButton.setTitle("\(String.fontAwesomeIconWithName(.Circle)) Rec", forState: .Normal)

        pauseButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        pauseButton.setTitle(String.fontAwesomeIconWithName(.Pause), forState: .Normal)

        stopButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        stopButton.setTitle(String.fontAwesomeIconWithName(.Stop), forState: .Normal)

        resumeButton.titleLabel?.font = UIFont.fontAwesomeOfSize(40)
        resumeButton.setTitle(String.fontAwesomeIconWithName(.PlayCircle), forState: .Normal)

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)

            session.requestRecordPermission() { [unowned self] (allowed: Bool) in
                dispatch_async(dispatch_get_main_queue()) {
                    if !allowed {
                        ViewController.showError(self, message: "Application doesn't have the persmission to record")
                    }
                }
            }
        } catch {
            ViewController.showError(self, message: "There was an error while setting up the audio session")
        }
    }
    @IBAction func recordTapped(sender: AnyObject) {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
        let documentsDir: NSString = path[0]
        let currentDate = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .MediumStyle)
        var fileName = "Rec \(currentDate).m4a"
        fileName = fileName.stringByReplacingOccurrencesOfString(",", withString: "").stringByReplacingOccurrencesOfString("/", withString: "-").stringByReplacingOccurrencesOfString(":", withString: "_").stringByReplacingOccurrencesOfString(" ", withString: "_")

        let filePath = documentsDir.stringByAppendingPathComponent(fileName)

        print("Recording to \(filePath)")
        let URL = NSURL(fileURLWithPath: filePath)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(URL: URL, settings: settings)
            recorder.delegate = self
            recorder.record()

            currentAction = .Recording
        } catch {
            finishRecording(success: false)
        }
    }
    @IBAction func resumeTapped(sender: AnyObject) {
        resumeRecording()
    }

    @IBAction func pauseTapped(sender: AnyObject) {
        pauseRecording()
    }

    @IBAction func stopTapped(sender: AnyObject) {
        finishRecording(success: true)
    }

    override func viewWillAppear(animated: Bool) {
        fileList = listFiles()
        tableView.reloadData()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.isKindOfClass(FileViewController.self) {
            let fwCtrl = segue.destinationViewController as! FileViewController

            if let selectedRow = tableView.indexPathForSelectedRow {
                fwCtrl.file = fileList[selectedRow.item]
            }
        }
    }

    func listFiles() -> [AudioFile] {
        let documentsUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!

        do {
            let directoryUrls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())

            let m4aFiles = directoryUrls.filter() { $0.pathExtension == "m4a" }.map() {
                AudioFile(URL: $0)
            }

            return m4aFiles
        } catch {
            print(error)
        }

        return []
    }

    func pauseRecording() {
        if recorder != nil {
            recorder.pause()
            currentAction = .Paused
        }
    }

    func resumeRecording() {
        if recorder != nil {
            recorder.record()
            currentAction = .Recording
        }
    }

    func finishRecording(success success: Bool) {
        if recorder != nil {
            recorder.stop()
            recorder = nil
        }

        if success {
            fileList = listFiles()
            tableView.reloadData()
        }

        currentAction = .None
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let file = fileList[indexPath.item]
        cell.textLabel?.text = file.fileName
        cell.detailTextLabel?.text = "\(file.formatedLength) \(file.formatedSize)"

        return cell
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do {
                let file = fileList[indexPath.item]
                try file.delete()
                fileList.removeAtIndex(indexPath.item)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            } catch {
                ViewController.showError(self, message: "File could not be deleted")
            }
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    static func showError(controller: UIViewController, message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        controller.presentViewController(ac, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
