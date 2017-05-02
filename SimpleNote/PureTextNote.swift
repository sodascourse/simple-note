//
//  PureTextNote.swift
//  SimpleNote
//
//  Created by sodas on 5/2/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import Foundation

struct PureTextNote {
    /*
     In this simple note struct, we use the file name (without extension) as the title of a note.
     */

    static let storageURL: URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    static func titleOfSavedNotes() -> [String] {
        var result = [String]()
        guard let noteURLs = try?
            FileManager.default.contentsOfDirectory(at: PureTextNote.storageURL,
                                                    includingPropertiesForKeys: nil) else { return [] }
        for noteURL in noteURLs {
            // Get the file name of the URL without file extension (this is the definition of the "title".)
            let title = noteURL.deletingPathExtension().lastPathComponent
            result.append(title)
        }
        return result
    }

    static let fileNameDateFormatter: DateFormatter = {
        /*
         We use date formatter to convert `Date` instances to String
         And then we can use it as the default note name.
         */
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return dateFormatter
    }()

    static func open(title: String) throws -> PureTextNote {
        let fileURL = PureTextNote.storageURL.appendingPathComponent("\(title).txt")
        let noteContent = try String(contentsOf: fileURL, encoding: .utf8)
        return PureTextNote(title: title, content: noteContent)
    }

    var title: String = {
        let date = Date()
        let dateString = PureTextNote.fileNameDateFormatter.string(from: date)
        return "Untitled \(dateString)"
    }()
    var content: String = ""

    var fileURL: URL {
        return PureTextNote.storageURL.appendingPathComponent("\(self.title).txt")
    }

    func save() throws {
        try self.content.write(to: self.fileURL, atomically: true, encoding: .utf8)
    }

}
