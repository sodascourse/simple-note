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

    static func fileURL(of title: String) -> URL {
        return self.storageURL.appendingPathComponent("\(title).txt")
    }

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
         
         Usually we would share the instance of `DateFormatter` since
         it's expensive to create it.
         */
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return dateFormatter
    }()

    static func open(title: String) throws -> PureTextNote {
        let noteContent = try String(contentsOf: self.fileURL(of: title), encoding: .utf8)
        return PureTextNote(title: title, content: noteContent)
    }

    static func remove(title: String) throws {
        try FileManager.default.removeItem(at: self.fileURL(of: title))
    }

    var title: String = {
        let date = Date()
        let dateString = PureTextNote.fileNameDateFormatter.string(from: date)
        return "Untitled \(dateString)"
    }()
    var content: String = {
        let templatePath = Bundle.main.url(forResource: "template", withExtension: "txt")!
        guard let templateContent = try? String(contentsOf: templatePath, encoding: .utf8) else { exit(1) }
        return templateContent
    }()

    var fileURL: URL {
        return PureTextNote.fileURL(of: self.title)
    }

    func save() throws {
        try self.content.write(to: self.fileURL, atomically: true, encoding: .utf8)
    }

}
