//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by Jason Wedepohl on 2017/07/03.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {
	
	//MARK: Constants
	
	private struct Constants {
		static let SlowRate: Float? = 0.5
		static let FastRate: Float? = 1.5
		static let HighPitch: Float? = 1000
		static let LowPitch: Float? = -1000
	}
	
	// MARK: Outlets
	
	@IBOutlet weak var snailButton: UIButton!
	@IBOutlet weak var chipmunkButton: UIButton!
	@IBOutlet weak var rabbitButton: UIButton!
	@IBOutlet weak var vaderButton: UIButton!
	@IBOutlet weak var echoButton: UIButton!
	@IBOutlet weak var reverbButton: UIButton!
	@IBOutlet weak var stopButton: UIButton!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var transcriptionTextView: UITextView!
	
	// MARK: Properties
	
	var recordedAudioURL: URL!
	var transcribedText: String!
	var audioFile:AVAudioFile!
	var audioEngine:AVAudioEngine!
	var audioPlayerNode: AVAudioPlayerNode!
	var stopTimer: Timer!
	
	enum ButtonType: Int { case slow = 0, fast, chipmunk, vader, echo, reverb }
	
	// MARK: UIViewController overrides
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initialiseAudioFile()
		transcriptionTextView.text = transcribedText
        
        //stop buttons from being squished in landscape mode
        snailButton.imageView?.contentMode = .scaleAspectFit
        chipmunkButton.imageView?.contentMode = .scaleAspectFit
        rabbitButton.imageView?.contentMode = .scaleAspectFit
        vaderButton.imageView?.contentMode = .scaleAspectFit
        echoButton.imageView?.contentMode = .scaleAspectFit
        reverbButton.imageView?.contentMode = .scaleAspectFit
        stopButton.imageView?.contentMode = .scaleAspectFit
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        configureUI(playing: false)
	}
	
	// MARK: Actions
	
	@IBAction func playSoundForButton(_ sender: UIButton) {
		guard let buttonType = ButtonType(rawValue: sender.tag) else
		{
			print("Unexpected button tag value \(sender.tag)")
			return
		}
        
        configureUI(playing: true)
		
		switch(buttonType) {
		case .slow:
			playSound(rate: Constants.SlowRate)
		case .fast:
			playSound(rate: Constants.FastRate)
		case .chipmunk:
			playSound(pitch: Constants.HighPitch)
		case .vader:
			playSound(pitch: Constants.LowPitch)
		case .echo:
			playSound(echo: true)
		case .reverb:
			playSound(reverb: true)
		}
	}
	
	@IBAction func stopButtonPressed(_ sender: AnyObject) {
        configureUI(playing: false)
		stopAudio()
	}
    
    /*
     
     transcribeFile(url:) is unused. It's from an unsuccessful attempt to transcribe speech from the recorded audio file.
     It works fine for test files, but not for the files that get saved by the AVAudioRecorder, for some reason.
    
    fileprivate func transcribeFile(url: URL) {
        guard let recognizer = SFSpeechRecognizer() else {
            print("Speech recognition not available for specified locale")
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) {(result, error) in
            guard let result = result else {
                print("There was an error transcribing that file: \(error!)")
                return
            }
            if result.isFinal {
                print(result.bestTranscription.formattedString)
            }
        }
    }
    */
}
