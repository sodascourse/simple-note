//
//  AppDelegate.swift
//  SimpleNote
//
//  Created by sodas on 4/30/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        print("Notes would be saved in '\(PureTextNote.storageURL.path)'.")
        return true
    }
}
