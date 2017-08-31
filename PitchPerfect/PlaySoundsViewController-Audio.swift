//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Created by Jason Wedepohl on 2017/07/03.
//

import UIKit
import AVFoundation

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState { case playing, stopped }
	
    // MARK: Audio Functions
    
    func initialiseAudioFile() {
        if (Utilities.runningInSimulator()) {
            return
        }
        
        // initialize audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
	func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        if (Utilities.runningInSimulator()) {
            return
        }
        
		if audioPlayerNode == nil {
			initialiseAudio(rate: rate, pitch: pitch, echo: echo, reverb: reverb)
		}
		
		audioPlayerNode.play()
    }
	
	func stopAudio() {
        if (Utilities.runningInSimulator()) {
            return
        }
        
		if let audioPlayerNode = audioPlayerNode {
			audioPlayerNode.stop()
			self.audioPlayerNode = nil
		}
		
		if let stopTimer = stopTimer {
			stopTimer.invalidate()
		}
		
		if let audioEngine = audioEngine {
			audioEngine.stop()
			audioEngine.reset()
		}
	}
	
	private func initialiseAudio(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        if (Utilities.runningInSimulator()) {
            return
        }
        
		// initialize audio engine components
		audioEngine = AVAudioEngine()
		var audioNodes = [AVAudioNode]()
		
		// node for playing audio
		audioPlayerNode = AVAudioPlayerNode()
		audioEngine.attach(audioPlayerNode)
		audioNodes.append(audioPlayerNode)
		
		// node for adjusting rate/pitch
		let changeRatePitchNode = AVAudioUnitTimePitch()
		if let pitch = pitch {
			changeRatePitchNode.pitch = pitch
		}
		if let rate = rate {
			changeRatePitchNode.rate = rate
		}
		audioEngine.attach(changeRatePitchNode)
		audioNodes.append(changeRatePitchNode)
		
		// node for echo
		if echo {
			let echoNode = AVAudioUnitDistortion()
			echoNode.loadFactoryPreset(.multiEcho1)
			audioEngine.attach(echoNode)
			audioNodes.append(echoNode)
		}
		
		// node for reverb
		if reverb {
			let reverbNode = AVAudioUnitReverb()
			reverbNode.loadFactoryPreset(.cathedral)
			reverbNode.wetDryMix = 50
			audioEngine.attach(reverbNode)
			audioNodes.append(reverbNode)
		}
		
		audioNodes.append(audioEngine.outputNode)
		
		// connect list of audio nodes
		for nodeIndex in 0..<audioNodes.count-1 {
			audioEngine.connect(audioNodes[nodeIndex], to: audioNodes[nodeIndex+1], format: audioFile.processingFormat)
		}
		
		// schedule to play and start the engine!
		audioPlayerNode.stop()
		audioPlayerNode.scheduleFile(audioFile, at: nil) {
			
			var delayInSeconds: Double = 0
			
			if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
				
				if let rate = rate {
					delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
				} else {
					delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
				}
			}
			
			// schedule a stop timer for when audio finishes playing
			self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
			RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
		}
		
		do {
			try audioEngine.start()
		} catch {
			showAlert(Alerts.AudioEngineError, message: String(describing: error))
			return
		}
	}
	
    // MARK: UI Functions

    func configureUI(playing: Bool) {
        snailButton.isEnabled = !playing
        chipmunkButton.isEnabled = !playing
        rabbitButton.isEnabled = !playing
        vaderButton.isEnabled = !playing
        echoButton.isEnabled = !playing
        reverbButton.isEnabled = !playing
        
        stopButton.isEnabled = playing
    }

    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
