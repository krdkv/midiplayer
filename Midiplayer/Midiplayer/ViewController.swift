//
//  ViewController.swift
//  Midiplayer
//
//  Created by Nikita.Kardakov on 25/03/2016.
//  Copyright © 2016 nickk. All rights reserved.
//

import UIKit
import CoreMIDI
import AudioToolbox

class ViewController: UIViewController {
    
    var midiPlayer:MidiPlayer = MidiPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let midURL = NSBundle.mainBundle().pathForResource("Bach Inv No 8", ofType: "mid") {
            let data = NSFileManager.defaultManager().contentsAtPath(midURL)
            midiPlayer.loadMidiData(data)
            
            midiPlayer.tempo = 280
            
            midiPlayer.play()
        }
        
        
    }
    
    func tick() {
        midiPlayer.tempo = 30
    }
}

