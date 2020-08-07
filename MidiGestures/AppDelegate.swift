//
//  AppDelegate.swift
//  MidiGestures
//
//  Created by D on 2017-06-21.
//  Copyright © 2017 Diego Lavalle. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let initialProgramAsString = UserDefaults.standard.string(forKey: "initial_program") ?? "0"
        ViewController.initialProgram = Int(initialProgramAsString)!
        let preventSleep = UserDefaults.standard.bool(forKey: "prevent_sleep")
        UIApplication.shared.isIdleTimerDisabled = preventSleep
        return true
    }
}


