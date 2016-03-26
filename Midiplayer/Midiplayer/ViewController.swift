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
        
        midiPlayer.play()
    }
}

