//
//  Utilities.swift
//  PitchPerfect
//
//  Created by Jason Wedepohl on 2017/08/30.
//

import Foundation

public class Utilities {
    
    /*
        AVAudioEngine was really unstable in the simulator, throwing several different cryptic errors.
        Online solutions to these errors were very hard, if not impossible, to find.
        Eventually I decided to disable all audio features in simulator so that UI layout and state changes could still be tested.
    */
    static func runningInSimulator() -> Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #else
            return false
        #endif
    }
}
