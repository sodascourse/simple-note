//
//  PureTextNote.swift
//  SimpleNote
//
//  Created by sodas on 5/2/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import Foundation
import Async

struct PureTextNote {

    var title: String = PureTextNote.defaultTitle()
    var content: String = {
        let templatePath = Bundle.main.url(forResource: "template", withExtension: "txt")!
        guard let templateContent = try? String(contentsOf: templatePath, encoding: .utf8) else { exit(1) }
        return templateContent
    }()

    var fileURL: URL {
        return PureTextNote.fileURL(of: self.title)
    }

    func save() {
        // Use `Dispatch` (part of Foundation) directly
        // Disk I/O is slow, so we should perform those tasks in background queue
        DispatchQueue.global(qos: .background).async {
            try? self.content.write(to: self.fileURL, atomically: true, encoding: .utf8)
            // We usually post notification or call delegate in main queue
            DispatchQueue.main.async {
                PureTextNote.postDidUpdateNotification()
            }
        }
    }

}

// MARK: - Notification methods

extension Notification.Name {
    static let PureTextNoteDidUpdate = Notification.Name("PureTextNoteDidUpdate")
}

extension PureTextNote {
    fileprivate static func postDidUpdateNotification() {
        let notification = Notification(name: .PureTextNoteDidUpdate)
        NotificationQueue.default.enqueue(notification, postingStyle: .asap)
    }
}

// MARK: - Storage methods

extension PureTextNote {
    /*
     In this simple note struct, we use the file name (without extension) as the title of a note.
     */

    // MARK: Storage location

    static let storageURL: URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    static func fileName(of title: String) -> String {
        return "\(title).txt"
    }

    // MARK: File name

    static func title(from url: URL) -> String {
        // Get the file name of the URL without file extension (this is the definition of the "title".)
        return url.deletingPathExtension().lastPathComponent
    }

    static func fileURL(of title: String) -> URL {
        return self.storageURL.appendingPathComponent(self.fileName(of: title))
    }

    static func defaultTitle() -> String {
        let date = Date()
        let dateString = PureTextNote.fileNameDateFormatter.string(from: date)
        return "Untitled \(dateString)"
    }

    private static let fileNameDateFormatter: DateFormatter = {
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

    // MARK: I/O

    static func getTitleOfSavedNotes(completion: (([String]) -> Void)? = nil) {
        Async.background {
            var result = [String]()
            guard let noteURLs = try? FileManager.default
                .contentsOfDirectory(at: PureTextNote.storageURL,
                                     includingPropertiesForKeys: nil) else { return [] }
            for noteURL in noteURLs {
                guard noteURL.pathExtension == "txt" else { continue }
                result.append(self.title(from: noteURL))
            }
            return result
        }.main { result in
            completion?(result)
        }
    }

    static func open(title: String) throws -> PureTextNote {
        let noteContent = try String(contentsOf: self.fileURL(of: title), encoding: .utf8)
        return PureTextNote(title: title, content: noteContent)
    }

    static func remove(title: String) throws {
        try FileManager.default.removeItem(at: self.fileURL(of: title))
        self.postDidUpdateNotification()
    }
}
