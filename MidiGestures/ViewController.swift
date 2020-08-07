//
//  ViewController.swift
//  MidiGestures
//
//  Created by D on 2017-06-21.
//  Copyright © 2017 Diego Lavalle. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    static var initialProgram = 0
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue | UIInterfaceOrientationMask.portraitUpsideDown.rawValue)
    }

    // MIDI and GM constants
    struct MidiConstants {
        static let middlecPitch = UInt8(60)
        static let velocityMax = UInt8(124)
        static let programMin = 0
        static let programMax = 127
        static let gainMin = Float(-90)
        static let gainMax = Float(12)
        static let stereoPanMin = Float(-100)
        static let stereoPanMax = Float(100)
        static let pitchBendScaleMax = Float(1.5) // UInt16
        static let pitchBendScaleMin = Float(0.5)
        static let pitchBendScaleMid = Float(1) // UInt16
        static let pitchBendMax = Float(16383) // UInt16
        static let pitchBendMid = Float(8192)
        static let globalTuningMax = Float(2400) // UInt16
        static let globalTuningMin = Float(-2400)
        static let control:UInt8 = 0xb0
        static let controlModulationWheel:UInt8 = 0x01
        static let controlModulationWheelMax = Float(UInt8.max)
        static let controlModulationWheelMin = Float(UInt8.min)
        static let controlDamperPedal:UInt8 = 0x40//0x40
        static let controlDamperPedalOn:UInt8 = 0x7f
        static let controlDamperPedalOff:UInt8 = 0x00
        static let controlResetAll:UInt8 = 0x79
        static let controlAllNotesOff:UInt8 = 0x7B
    }
    
    static let instrumentNames = ["Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano", "Honky-tonk Piano", "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavi", "Celesta", "Glockenspiel", "Music Box", "Vibraphone", "Marimba", "Xylophone", "Tubular Bells", "Dulcimer", "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ", "Reed Organ", "Accordion", "Harmonica", "Tango Accordion", "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)", "Electric Guitar (jazz)", "Electric Guitar (clean)", "Electric Guitar (muted)", "Overdriven Guitar", "Distortion Guitar", "Guitar harmonics", "Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)", "Fretless Bass", "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2", "Violin", "Viola", "Cello", "Contrabass", "Tremolo Strings", "Pizzicato Strings", "Orchestral Harp", "Timpani", "String Ensemble 1", "String Ensemble 2", "SynthStrings 1", "SynthStrings 2", "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit", "Trumpet", "Trombone", "Tuba", "Muted Trumpet", "French Horn", "Brass Section", "SynthBrass 1", "SynthBrass 2", "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax", "Oboe", "English Horn", "Bassoon", "Clarinet", "Piccolo", "Flute", "Recorder", "Pan Flute", "Blown Bottle", "Shakuhachi", "Whistle", "Ocarina", "Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)", "Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass + lead)", "Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)", "Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)", "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)", "FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)", "Sitar", "Banjo", "Shamisen", "Koto", "Kalimba", "Bag pipe", "Fiddle", "Shanai", "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock", "Taiko Drum", "Melodic Tom", "Synth Drum", "Reverse Cymbal", "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet", "Telephone Ring", "Helicopter", "Applause", "Gunshot"]
    
    // Audio foundation objects
    let audioSession = AVAudioSession.sharedInstance()
    let engine = AVAudioEngine()
    let sampler = AVAudioUnitSampler()
    let soundbank = Bundle.main.url(forResource: "general_midi-2", withExtension: "sf2")
    let melodicBank:UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB)
    var sequencer:AVAudioSequencer!
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    
    // Gestures
    var isPinching = false {
        didSet {
            configureView()
        }
    }
    
    var isPanning = false {
        didSet {
            configureView()
        }
    }
    
    var isTouchingDown = false {
        didSet {
            configureView()
        }
    }
    
    var isLeftPanning = false {
        didSet {
            configureView()
        }
    }
    
    var isRightPanning = false {
        didSet {
            configureView()
        }
    }
    
    var isRotating = false {
        didSet {
            configureView()
        }
    }
    
    var isLongPressing = false {
        didSet {
            configureView()
        }
    }
    
    // Parameters and effects
    var midiInputs = 0 {
        didSet {
            configureView()
        }
    }
    
    var program = ViewController.initialProgram {
        didSet {
            program = (MidiConstants.programMax + 1 + program) % (MidiConstants.programMax + 1)
            loadProgram()
            configureView()
        }
    }
    
    var instrumentName:String {
        return ViewController.instrumentNames[program]
    }
    
    var masterGain = Float(0) {
        didSet {
            //masterGain = masterGain.rounded()
            if masterGain > MidiConstants.gainMax {
                masterGain = MidiConstants.gainMax
            } else if masterGain < MidiConstants.gainMin {
                masterGain = MidiConstants.gainMin
            }
            sampler.masterGain = masterGain
            configureView()
        }
    }
    
    var pitchBend = MidiConstants.pitchBendScaleMid {
        didSet {
            if pitchBend > MidiConstants.pitchBendScaleMax {
                pitchBend = MidiConstants.pitchBendScaleMax
            } else if pitchBend < MidiConstants.pitchBendScaleMin {
                pitchBend = MidiConstants.pitchBendScaleMin
            }
            var midiPitchBend = MidiConstants.pitchBendMid
            if pitchBend > MidiConstants.pitchBendScaleMid {
                let pitchBendBase = MidiConstants.pitchBendMax - MidiConstants.pitchBendMid
                let pitchBendScaleBase = MidiConstants.pitchBendScaleMax - MidiConstants.pitchBendScaleMid
                let pitchBendScaleDelta = pitchBend - MidiConstants.pitchBendScaleMid
                midiPitchBend = MidiConstants.pitchBendMid + pitchBendScaleDelta / pitchBendScaleBase * pitchBendBase
            } else if pitchBend < MidiConstants.pitchBendScaleMid {
                let pitchBendBase = MidiConstants.pitchBendMid - 0
                let pitchBendScaleBase = MidiConstants.pitchBendScaleMid - MidiConstants.pitchBendScaleMin
                let pitchBendScaleDelta = pitchBend - MidiConstants.pitchBendScaleMin
                midiPitchBend = 0 + pitchBendScaleDelta / pitchBendScaleBase * pitchBendBase
            }
            sampler.sendPitchBend(UInt16(midiPitchBend), onChannel: 0)
            configureView()
        }
    }
    
    var globalTuning = Float(0) {
        didSet {
            globalTuning = globalTuning.rounded()
            if globalTuning > MidiConstants.globalTuningMax {
                globalTuning = MidiConstants.globalTuningMax
            } else if globalTuning < MidiConstants.globalTuningMin {
                globalTuning = MidiConstants.globalTuningMin
            }
            sampler.globalTuning = globalTuning
            configureView()
        }
    }
    
    var stereoPan = Float(0) {
        didSet {
            stereoPan = stereoPan.rounded()
            if stereoPan > MidiConstants.stereoPanMax {
                stereoPan = MidiConstants.stereoPanMax
            } else if stereoPan < MidiConstants.stereoPanMin {
                stereoPan = MidiConstants.stereoPanMin
            }
            sampler.stereoPan = stereoPan
            configureView()
        }
    }
    
    var isDamperPedalOn = false {
        didSet {
            sampler.sendController(MidiConstants.controlDamperPedal, withValue: isDamperPedalOn ? MidiConstants.controlDamperPedalOn : MidiConstants.controlDamperPedalOff, onChannel: 0)
            configureView()
        }
    }
    
    var modulation = MidiConstants.controlModulationWheelMin {
        didSet {
            modulation = modulation.rounded()
            if modulation > MidiConstants.controlModulationWheelMax {
                modulation = MidiConstants.controlModulationWheelMax
            } else if modulation < MidiConstants.controlModulationWheelMin {
                modulation = MidiConstants.controlModulationWheelMin
            }
            sampler.sendMIDIEvent(MidiConstants.control, data1: MidiConstants.controlModulationWheel, data2: UInt8(modulation))
            configureView()
        }
    }
    
    @IBOutlet weak var pitchBendContainerView: UIView!
    @IBOutlet weak var modulationWheelContainerView: UIView!
    @IBOutlet weak var masterGainContainerView: UIView!
    @IBOutlet weak var stereoPanContainerView: UIView!
    @IBOutlet weak var globalTuningContainerView: UIView!
    @IBOutlet weak var sustainContainerView: UIView!
    @IBOutlet weak var resetAllContainerView: UIView!
    
    weak var summaryViewController:SummaryViewController!
    weak var modulationWheelViewController:ModulationWheelViewController!
    weak var masterGainViewController:MasterGainViewController!
    weak var stereoPanViewController:StereoPanViewController!
    weak var globalTuningViewController:GlobalTuningViewController!
    weak var sustainViewController:SustainViewController!
    weak var resetAllViewController:ResetAllViewController!
    weak var pitchBendViewController:PitchBendViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.mixWithOthers)
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
        try! audioSession.setActive(true)
        
        program = ViewController.initialProgram
        //loadProgram()
        
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try! engine.start()
        
        sequencer = AVAudioSequencer(audioEngine: engine)
        generateSequence()
        sequencer.prepareToPlay()
        
        MIDINetworkSession.default().isEnabled = true
        MIDINetworkSession.default().connectionPolicy = .anyone

        // We need a MIDI client
        let _ = MIDIClientCreateWithBlock("com.diegolavalle.MidiGestures.MidiClient" as CFString, &midiClient) { [weak self] notificationPointer in
                let notification = notificationPointer.pointee
                switch notification.messageID {
                case .msgObjectAdded: break /*
                    notificationPointer.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
                        let m = $0.pointee
                        if m.childType == .externalSource {
                            self?.midiInputs += 1
                            var entityRef = MIDIEntityRef()
                            let _ = MIDIEndpointGetEntity(m.child, &entityRef)
                            var properties: Unmanaged<CFPropertyList>?
                            let _ = MIDIObjectGetProperties(entityRef, &properties, false)
                            print(properties?.takeUnretainedValue() ?? "nutin")
                            let _ = MIDIPortConnectSource(self!.inputPort, m.child, nil)
                        }
                    }
                */
                case .msgObjectRemoved: break /*
                    notificationPointer.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
                        let m = $0.pointee
                        print(m)
                        print("id \(m.messageID)")
                        print("size \(m.messageSize)")
                        print("child \(m.child)")
                        print("child type \(m.childType)")
                        showMIDIObjectType(m.childType)
                        print("parent \(m.parent)")
                        print("parentType \(m.parentType)")
                        showMIDIObjectType(m.parentType)
                        print("childName \(String(describing: self?.getDeviceName(m.child)))")
                        if m.childType == .externalSource {
                            self?.midiInputs -= 1
                            let _ = MIDIPortDisconnectSource(self!.inputPort, m.child)
                        }
                    }
                */
                case .msgSetupChanged:
                    self?.connectSources()
                case .msgPropertyChanged: fallthrough
                case .msgThruConnectionsChanged: fallthrough
                case .msgSerialPortOwnerChanged: fallthrough
                case .msgIOError: break
                }
        }
        // Input port for receiving MIDI
        let _ = MIDIInputPortCreateWithBlock(midiClient, "com.diegolavalle.MidiGestures.MidiInputPort" as CFString, &inputPort) {
            (packetsPointer, _) in
            
            // Superhack
            UIApplication.shared.isIdleTimerDisabled = !UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = !UIApplication.shared.isIdleTimerDisabled

            let packets = packetsPointer.pointee
            var packetPointer = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
            packetPointer.initialize(to: packets.packet)
            for _ in 0 ..< packets.numPackets {
                self.parsePacket(packetPointer.pointee)
                packetPointer = MIDIPacketNext(packetPointer)
            }
        }
        connectSources() // calls configure view
    }
    
    static func isStatusByte(_ byte: UInt8) -> Bool {
        let statusByteMask = UInt8(0b10000000)
        return byte & statusByteMask == statusByteMask
    }
    
    func playSequence() {
        sequencer.currentPositionInBeats = TimeInterval(0)
        try! sequencer.start()
    }
    
    func parsePacket(_ packet:MIDIPacket) {
        // The next line converts a tuple into an array
        let packetBytes = Mirror(reflecting: packet.data).children.map({$0.value}) as! [UInt8]
        var previousStatus:UInt8! = nil
        var messageData:[UInt8] = []
        var i = 0 // Prepare to iterate the array and extract the MIDI messages
        while i <= packetBytes.count {
            if i == packet.length || ViewController.isStatusByte(packetBytes[i]) {
                switch messageData.count {
                case 1:
                    sampler.sendMIDIEvent(previousStatus ?? packetBytes[i], data1: messageData[0])
                case 2:
                    sampler.sendMIDIEvent(previousStatus ?? packetBytes[i], data1: messageData[0], data2: messageData[1])
                default: break
                }
            }
            if i == packet.length {
                break // We have reached the end of the packet and sent the last message
            }
            if ViewController.isStatusByte(packetBytes[i]) {
                previousStatus = packetBytes[i]
                messageData = []
            } else { // Is a data byte, save it
                messageData.append(packetBytes[i])
            }
            i += 1
        }
    }
    
    func connectSources() {
        midiInputs = MIDIGetNumberOfSources() - 1
        // Connect  external controller to input
        for sourceIndex in 0 ..< MIDIGetNumberOfSources() {
            //print(MIDIGetSource(sourceIndex))
            if sourceIndex == 0 {
                continue
            }
            let _ = MIDIPortConnectSource(inputPort, MIDIGetSource(sourceIndex), nil)
        }
        let sourceEndpoint = MIDIGetSource(0)
        var entityRef = MIDIEntityRef()
        let _ = MIDIEndpointGetEntity(sourceEndpoint, &entityRef)
        var properties: Unmanaged<CFPropertyList>?
        let _ = MIDIObjectGetProperties(entityRef, &properties, false)
        //print(properties?.takeUnretainedValue() ?? "nutin")
        sampler.sendController(MidiConstants.controlAllNotesOff, withValue: 0, onChannel: 0)
    }
    
    func generateSequence() {
        var sequence:MusicSequence?
        let _ = NewMusicSequence(&sequence)
        // Creating a track
        
        var track:MusicTrack? // AVMusicTrack no good
        let _ = MusicSequenceNewTrack(sequence!, &track)
        
        // Adding notes
        var time = MusicTimeStamp(0.0)
        for index:UInt8 in MidiConstants.middlecPitch...63 {
            var note = MIDINoteMessage(channel: 0,
                                       note: index,
                                       velocity: MidiConstants.velocityMax,
                                       releaseVelocity: 0,
                                       duration: 1.5 )
            let _ = MusicTrackNewMIDINoteEvent(track!, time, &note)
            time += 1.5
        }
        
        //var status = OSStatus(noErr)
        var data:Unmanaged<CFData>?
        let _ = MusicSequenceFileCreateData (sequence!, MusicSequenceFileTypeID.midiType, MusicSequenceFileFlags.eraseFile, 480, &data)
        // CheckError(status)
        
        let midiData = data!.takeUnretainedValue() as Data
        
        try! sequencer.load(from: midiData, options: .smfChannelsToTracks)
        data!.release()
    }
    
    func loadProgram() {
        try! sampler.loadSoundBankInstrument(at: soundbank!, program: UInt8(program), bankMSB: melodicBank, bankLSB: UInt8(kAUSampler_DefaultBankLSB))
    }
    
    // Summary and other sub-views
    func configureView() {
        if isPinching && pitchBendContainerView.isHidden {
            pitchBendContainerView.isHidden = false
        }
        if !isPinching && !pitchBendContainerView.isHidden {
            pitchBendContainerView.isHidden = true
        }
        if isPanning && modulationWheelContainerView.isHidden {
            modulationWheelContainerView.isHidden = false
        }
        if !isPanning && !modulationWheelContainerView.isHidden {
            modulationWheelContainerView.isHidden = true
        }
        if isTouchingDown && sustainContainerView.isHidden {
            sustainContainerView.isHidden = false
        }
        if !isTouchingDown && !sustainContainerView.isHidden {
            sustainContainerView.isHidden = true
        }
        if isLeftPanning && stereoPanContainerView.isHidden {
            stereoPanContainerView.isHidden = false
        }
        if !isLeftPanning && !stereoPanContainerView.isHidden {
            stereoPanContainerView.isHidden = true
        }
        if isLongPressing && resetAllContainerView.isHidden {
            resetAllContainerView.isHidden = false
        }
        if !isLongPressing && !resetAllContainerView.isHidden {
            resetAllContainerView.isHidden = true
        }
        if isRotating && globalTuningContainerView.isHidden {
            globalTuningContainerView.isHidden = false
        }
        if !isRotating && !globalTuningContainerView.isHidden {
            globalTuningContainerView.isHidden = true
        }
        if isRightPanning && masterGainContainerView.isHidden {
            masterGainContainerView.isHidden = false
        }
        if !isRightPanning && !masterGainContainerView.isHidden {
            masterGainContainerView.isHidden = true
        }
        summaryViewController.inputsLabel.text = "MIDI Inputs: \(midiInputs)"
        summaryViewController.instrumentLabel.text = "#\(program) \(instrumentName)"
        summaryViewController.masterGainLabel.text = "Master gain: " +  String(format: "%.1f", masterGain)
        masterGainViewController.gainLevelLabel.text = String(format: "%.1f", masterGain)
        summaryViewController.stereoPanLabel.text = "Stereo pan: \(stereoPan)"
        stereoPanViewController.panBalanceLabel.text = "\(stereoPan)"
        summaryViewController.globalTuningLabel.text = "Global tuning: \(globalTuning)"
        globalTuningViewController.tuningValueLabel.text = "\(globalTuning)"
        summaryViewController.sustainLockLabel.text = "Sustain lock: \(isDamperPedalOn ? "On" : "Off")"
        summaryViewController.modulationLabel.text = "Modulation: \(modulation)"
        modulationWheelViewController.levelLabel.text = "\(modulation)"
        pitchBendViewController.pitchLevelLabel.text = "\(pitchBend)"
    }
    
    // Gesture handlers
    @IBAction func doubleTappping(_ sender: UITapGestureRecognizer) {
        // Play/stop test sequence
        if sender.state == .ended {
            if sequencer.isPlaying && sequencer.currentPositionInBeats < 7 {
                sequencer.stop()
            } else {
                playSequence()
            }
        }
    }
    
    @IBAction func pressing(_ sender: UILongPressGestureRecognizer) {
        // Sustain (Damper pedal) temporary on
        if sender.state == .began {
            // print("Fingers down")
            isTouchingDown = true
            isDamperPedalOn = true
        } else if sender.state == .recognized {
            // print("Fingers up")
            isTouchingDown = false
            isDamperPedalOn = false
        }
    }
    
    @IBAction func pinching(_ sender: UIPinchGestureRecognizer) {
        // Pitch bend
        if sender.state == .began {
            isPinching = true
        }
        if sender.state == .began || sender.state == .changed {
            pitchBend = Float(sender.scale)
            pitchBendViewController.indicatorView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
        } else if sender.state == .ended || sender.state == .cancelled {
            pitchBend = 1
        }
        if sender.state == .ended  || sender.state == .cancelled  {
            isPinching = false
        }
    }
    
    @IBAction func twoFingerPanning(_ sender: UIPanGestureRecognizer) {
        // Modulation wheel
        if sender.state == .began {
            isPanning = true
        }
        if sender.state == .began || sender.state == .changed {
             modulationWheelViewController.levelView.levely = sender.location(in: view).y
            
            let ratio = sender.translation(in: view).y / view.bounds.size.height * (-1)
            sender.setTranslation(CGPoint(x: 0,y: 0), in: view)
            modulation += Float(ratio) * (MidiConstants.controlModulationWheelMax - MidiConstants.controlModulationWheelMin) * 1.5
        }
        if sender.state == .ended  || sender.state == .cancelled {
            isPanning = false
        }
    }
    
    var cummulativeRotation = CGFloat(0)
    @IBAction func rotating(_ sender: UIRotationGestureRecognizer) {
        // Global tuning
        if sender.state == .began {
            isRotating = true
        }
        if sender.state == .began || sender.state == .changed {
            cummulativeRotation += sender.rotation
            globalTuningViewController.indicatorView.transform = CGAffineTransform(rotationAngle: cummulativeRotation)
            globalTuning += Float(sender.rotation) / Float.pi * MidiConstants.globalTuningMax / 24
            sender.rotation = 0
            
        }
        if sender.state == .ended  || sender.state == .cancelled {
            cummulativeRotation = 0
            isRotating = false
        }
    }
    
    @IBAction func leftPanning(_ sender: UIScreenEdgePanGestureRecognizer) {
        // Stereo pan
        if sender.state == .began {
            isLeftPanning = true
        }
        if sender.state == .began || sender.state == .changed {
            stereoPanViewController.levelView.levely = sender.location(in: view).y
            let ratio = sender.translation(in: view).y / view.bounds.size.height * (-1)
            sender.setTranslation(CGPoint(x: 0,y: 0), in: view)
            stereoPan += Float(ratio) * (MidiConstants.stereoPanMax - MidiConstants.stereoPanMin) * 1.2
        }
        if sender.state == .ended  || sender.state == .cancelled {
            isLeftPanning = false
        }
    }
    
    @IBAction func rightPanning(_ sender: UIScreenEdgePanGestureRecognizer) {
        // Master gain
        if sender.state == .began {
            isRightPanning = true
        }
        if sender.state == .began || sender.state == .changed {
            masterGainViewController.levelView.levely = sender.location(in: view).y
            let ratio = sender.translation(in: view).y / view.bounds.size.height * (-1)
            sender.setTranslation(CGPoint(x: 0,y: 0), in: view)
            masterGain += Float(ratio) * (MidiConstants.gainMax - MidiConstants.gainMin) * 0.8
        }
        if sender.state == .ended  || sender.state == .cancelled {
            isRightPanning = false
        }
    }
    
    @IBAction func rightSwipe(_ sender: UISwipeGestureRecognizer) {
        // Next instrument (program)
        if sender.state == .ended {
            program += 1
        }
    }
    
    @IBAction func leftSwipe(_ sender: UISwipeGestureRecognizer) {
        // Previous instrument (program)
        if sender.state == .ended {
            program -= 1
        }
    }
    
    @IBAction func upSwipe(_ sender: UISwipeGestureRecognizer) {
        // Instrument fast forward
        if sender.state == .ended {
            program += 10
        }
    }
    
    @IBAction func downSwipe(_ sender: UISwipeGestureRecognizer) {
        // Instrument fast previous
        if sender.state == .ended {
            program -= 10
        }
    }
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        // Sustain lock
        if sender.state == .ended {
            isDamperPedalOn = !isDamperPedalOn
        }
    }
    
    @IBAction func longPressing(_ sender: UILongPressGestureRecognizer) {
        // Reset all parameters
        if sender.state == .began {
            isLongPressing = true
            //print("Sampler gain \(sampler.masterGain) globalTuning \(sampler.globalTuning) stereoPan \(sampler.stereoPan) reverbBlend \(sampler.reverbBlend)")
        } else if sender.state == .recognized {
            // MIDI params
            // Notes off
            sampler.sendController(MidiConstants.controlAllNotesOff, withValue: 0, onChannel: 0)
            // program reset
            program = 0
            modulation = 0
            isDamperPedalOn = false
            // pitchBend = 1
            // Sampler settings
            stereoPan = 0
            masterGain = 0
            globalTuning = 0
            isLongPressing = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "SummarySegue":
            summaryViewController = segue.destination as! SummaryViewController
        case "ModulationWheelSegue":
            modulationWheelViewController = segue.destination as! ModulationWheelViewController
        case "MasterGainSegue":
            masterGainViewController = segue.destination as! MasterGainViewController
        case "StereoPanSegue":
            stereoPanViewController = segue.destination as! StereoPanViewController
        case "GlobalTuningSegue":
            globalTuningViewController = segue.destination as! GlobalTuningViewController
        case "SustainSegue":
            sustainViewController = segue.destination as! SustainViewController
        case "PitchBendSegue":
            pitchBendViewController = segue.destination as! PitchBendViewController
        case "ResetAllSegue":
            resetAllViewController = segue.destination as! ResetAllViewController
        default:
            break
        }
    }

    func getDeviceName(_ endpoint:MIDIEndpointRef) -> String? {
        var cfs: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &cfs)
        if status != noErr {
            print("error getting device name ")
        }
        if let s = cfs {
            return s.takeRetainedValue() as String
        }
        return nil
    }

    func showMIDIObjectType(_ ot: MIDIObjectType) {
        switch ot {
        case .other:
            print("midiObjectType: Other")
            break
            
        case .device:
            print("midiObjectType: Device")
            break
            
        case .entity:
            print("midiObjectType: Entity")
            break
            
        case .source:
            print("midiObjectType: Source")
            break
            
        case .destination:
            print("midiObjectType: Destination")
            break
            
        case .externalDevice:
            print("midiObjectType: ExternalDevice")
            break
            
        case .externalEntity:
            print("midiObjectType: ExternalEntity")
            print("midiObjectType: ExternalEntity")
            break
            
        case .externalSource:
            print("midiObjectType: ExternalSource")
            break
            
        case .externalDestination:
            print("midiObjectType: ExternalDestination")
            break
        }
        
    }
}

