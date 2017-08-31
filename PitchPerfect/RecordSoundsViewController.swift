//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Jason Wedepohl on 2017/06/29.
//

import UIKit
import AVFoundation
import Speech

class RecordSoundsViewController : UIViewController {
	
	// MARK: Constants
	
	struct Constants {
		static let StopRecordingSegue = "stopRecording"
        static let RecordingFileName = "recordedVoice.wav"
		static let AlertRecordingInProgress = "Recording in Progress"
		static let AlertTapToRecord = "Tap to Record"
		static let AlertRecordingUnsuccessful = "Recording was not successful"
		static let AlertRecordingPaused = "Recording Paused"
        static let AlertTranscriptionUnsuccessful = "We couldn't transcribe the audio."
        static let AlertRunningInSimulator = "Audio features won't work in the simulator but the UI will still function."
		static let DefaultTranscriptionText = "Transcribed text will appear here if you are connected to the internet."
        static let AlertWaitingForTranscription = "Give it a moment for transcription to start..."
	}
	
	// MARK: Outlets
	
	@IBOutlet weak var recordingLabel: UILabel!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var stopRecordingButton: UIButton!
	@IBOutlet weak var transcribedTextView: UITextView!
	
	// MARK: Properties
	
	var audioRecorder: AVAudioRecorder!
	var audioEngine: AVAudioEngine!
	var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
	var speechRecogniser: SFSpeechRecognizer?
	var transcribedText: String!
	var recognitionTask: SFSpeechRecognitionTask?
    var speechRecognitionIsOn = false
	
	private enum RecordingState { case recording, stopped, paused }
	
	// MARK: UIViewController overrides
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initialiseRecorder()
        requestSpeechRecognitionPermission()
		stopRecordingButton.isEnabled = false
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        if (Utilities.runningInSimulator()) {
            transcribedText = Constants.AlertRunningInSimulator
            transcribedTextView.text = Constants.AlertRunningInSimulator
        } else {
            transcribedText = Constants.DefaultTranscriptionText
            transcribedTextView.text = Constants.DefaultTranscriptionText
        }
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == Constants.StopRecordingSegue {
			guard let playSoundsViewController = segue.destination as? PlaySoundsViewController else {
				print("Expected segue destination to be PlaySoundsViewController but was \(String(describing: segue.destination))")
				return
			}
			
			guard let data = sender as? [Any] else {
				print("Expected sender to be an array of Any but was \(String(describing: sender))")
				return
			}
			
			guard data.count == 2 else {
				print("Expected sender data to contain two elements.")
				return
			}
			
            if (!Utilities.runningInSimulator()) {
                guard let recordedAudioURL = data[0] as? URL else {
                    print("Expected sender data first element to be a URL but was \(String(describing: data[0]))")
                    return
                }
                playSoundsViewController.recordedAudioURL = recordedAudioURL
            }
			
			guard let transcribedText = data[1] as? String else {
				print("Expected sender data second element to be a String but was \(String(describing: data[1]))")
				return
			}
			
			playSoundsViewController.transcribedText = transcribedText
		}
	}
	
	//MARK: Actions
	
	@IBAction func recordAudio(_ sender: Any) {
        if (Utilities.runningInSimulator()) {
            configureUI(recordingState: .recording)
            return
        }
		
		if audioRecorder.isRecording {
			configureUI(recordingState: .paused)
            
			audioRecorder.pause()
			audioEngine.pause()
		} else {
			configureUI(recordingState: .recording)
            
			audioRecorder.record()
			
			if recognitionTask == nil {
                transcribedTextView.text = Constants.AlertWaitingForTranscription
				startSpeechRecognitionTask()
			}
			
			do {
				try audioEngine.start()
			}
			catch {
				print(error)
			}
		}
	}
	
	@IBAction func stopRecording(_ sender: Any) {
		configureUI(recordingState: .stopped)
        
        if (Utilities.runningInSimulator()) {
            segueToPlaybackScreen()
            return
        }
		
		audioRecorder.stop()
		
		recognitionTask?.cancel()
		recognitionTask = nil
		audioEngine.stop()
		
		let audioSession = AVAudioSession.sharedInstance()
		try! audioSession.setActive(false)
	}
    
    func segueToPlaybackScreen() {
        let audioFileUrl = Utilities.runningInSimulator() ? URL(string:"") : audioRecorder.url
        performSegue(withIdentifier: Constants.StopRecordingSegue, sender: [audioFileUrl as Any, transcribedText])
    }
	
	private func configureUI(recordingState: RecordingState) {
		switch recordingState
		{
		case .recording:
			recordingLabel.text = Constants.AlertRecordingInProgress
			stopRecordingButton.isEnabled = true
			recordButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
		case .paused:
			recordingLabel.text = Constants.AlertRecordingPaused
			stopRecordingButton.isEnabled = true
			recordButton.setImage(nil, for: .normal)
		case .stopped:
			recordingLabel.text = Constants.AlertTapToRecord
			transcribedTextView.text = Constants.DefaultTranscriptionText
			stopRecordingButton.isEnabled = false
			recordButton.setImage(nil, for: .normal)
		}
	}
}

