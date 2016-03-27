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
    
    @IBOutlet weak var leftVolumeSlider:UISlider?
    @IBOutlet weak var rightVolumeSlider:UISlider?
    @IBOutlet weak var tempoSlider:UISlider?
    @IBOutlet weak var tempoLabel:UILabel?
    
    var midiPlayer:MidiPlayer = MidiPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let midURL = NSBundle.mainBundle().pathForResource("Bach Inv No 8", ofType: "mid") {
            let data = NSFileManager.defaultManager().contentsAtPath(midURL)
            midiPlayer.loadMidiData(data)
            
            tempoSlider?.continuous = false
            tempoLabel?.text = "\(midiPlayer.tempo)"
            tempoSlider?.value = Float(midiPlayer.tempo)
            
            leftVolumeSlider?.value = midiPlayer.leftHandVolume
            rightVolumeSlider?.value = midiPlayer.rightHandVolume
            
            midiPlayer.play()
        }                
    }
    
    @IBAction func leftVolumeChange(slider:UISlider) {
        midiPlayer.leftHandVolume = slider.value
    }
    
    @IBAction func rightVolumeChange(slider:UISlider) {
        midiPlayer.rightHandVolume = slider.value
    }
    
    @IBAction func tempoChange(slider:UISlider) {
        midiPlayer.tempo = UInt32(slider.value)
        tempoLabel?.text = "\(midiPlayer.tempo)"
    }
    
}

