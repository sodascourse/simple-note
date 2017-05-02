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
        print("----------------------------")
        let titleList = PureTextNote.titleOfSavedNotes()
        print("Now we have \(titleList)")
        print("----------------------------")
        guard let firstNote = try? PureTextNote.open(title: titleList.first!) else { exit(1) }
        print(firstNote.content)

        var newNote = PureTextNote()
        newNote.content = "Hello! This is a new note.!"
        try? newNote.save()

        return true
    }
}
