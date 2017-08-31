//
//  RecordSoundsViewController-SpeechToText.swift
//  PitchPerfect
//
//  Created by Jason Wedepohl on 2017/08/29.
//

import AVFoundation
import Speech

extension RecordSoundsViewController: AVAudioRecorderDelegate {
    
    func initialiseRecorder() {
        if (Utilities.runningInSimulator()) {
            return
        }
        
        //get the output file URL for the recording
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let pathArray = [dirPath, Constants.RecordingFileName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        //configure audio session
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)

        //create and prepare audio recorder
        do {
            try audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        }
        catch {
            print("\(error)")
        }
        
        audioEngine = AVAudioEngine()
        
        //create speech recogniser
        speechRecognitionIsOn = false
        
        guard let speechRecogniser = SFSpeechRecognizer() else {
            prepareAudioEngineWithoutSpeechRecognition()
            return
        }
        
        //speech recogniser might not be available for some locales, since it guesses the language from the locale
        if !speechRecogniser.isAvailable {
            prepareAudioEngineWithoutSpeechRecognition()
            return
        }
        
        self.speechRecogniser = speechRecogniser
        
        //create a speech recognition request
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let node = audioEngine.inputNode else {
            prepareAudioEngineWithoutSpeechRecognition()
            return
        }
        
        //hook up the speech recognition request to the audio engine input node
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.speechRecognitionRequest?.append(buffer)
        }
        
        speechRecognitionIsOn = true
        
        audioEngine.prepare()
    }
    
    private func prepareAudioEngineWithoutSpeechRecognition() {
        print("Speech recognition is off.")
        transcribedText = Constants.AlertTranscriptionUnsuccessful
        transcribedTextView.text = Constants.AlertTranscriptionUnsuccessful
        audioEngine.prepare()
    }
    
    func requestSpeechRecognitionPermission() {
        if (Utilities.runningInSimulator()) {
            //audio features are disabled in simulator
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            //don't do anything here - the speech recognition setup will handle lack of permission
        }
    }
    
    func startSpeechRecognitionTask() {
        if !speechRecognitionIsOn {
            return
        }
        
        //transcription can be unsuccessful if the speech recogniser is unavailable, for example
        guard speechRecognitionRequest != nil && speechRecogniser != nil else {
            transcribedText = Constants.AlertTranscriptionUnsuccessful
            print(Constants.AlertTranscriptionUnsuccessful)
            return
        }
        
        //the recognition task calls Apple's speech recognition servers (the same technology used for Siri)
        //Apple enforces a limit of 60 seconds - if the user hasn't stopped the recording by then, the transcription will stop anyway!
        recognitionTask = speechRecogniser!.recognitionTask(with: speechRecognitionRequest!) { result, error in
            
            /*
                The recognitionTask does not stop when this closure executes.
                This closure will execute multiple times as the speech is transcribed bit by bit.
                Each time this closure is executed, it is passed the full transcription within the "result" parameter.
                
                e.g. suppose "Mary had a little lamb" is transcribed in two batches: "Mary had" and "a little lamb". This closure will execute twice:
                1st execution: result.bestTranscription.formattedString = "Mary had"
                2nd execution: result.bestTranscription.formattedString = "Mary had a little lamb"
             
                So we just need to update the UI with the full transcription each time.
            */
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                print(self.transcribedText)
            } else if let error = error {
                if self.recognitionTask != nil && !self.recognitionTask!.isCancelled {
                    self.transcribedText = Constants.AlertTranscriptionUnsuccessful
                    print("Transcription error: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.transcribedTextView.text = self.transcribedText
            }
        }
    }
    
    //MARK: AVAudioRecorderDelegate implementation
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            segueToPlaybackScreen()
        } else {
            print(Constants.AlertRecordingUnsuccessful)
        }
    }
}

