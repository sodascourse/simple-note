//
//  SimpleNote.swift
//  SimpleNote
//
//  Created by sodas on 5/30/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import Foundation
import Alamofire

class SimpleNote {
    var uuid: UUID?
    var title: String = "Untitled"
    var content: String = ""

    init() {}

    init(title: String) {
        self.title = title
    }
}

// MARK: - Note I/O

extension SimpleNote {  // I/O Base
    static let APIEndpoint = URL(string: "https://notes.sodas.tw")!

    static var collectionURL: URL {
        return APIEndpoint.appendingPathComponent("notes")
    }

    static func itemURL(of uuid: UUID) -> URL {
        return APIEndpoint
            .appendingPathComponent("notes")
            .appendingPathComponent("\(uuid)".lowercased())
    }

    static var APIUsername: String? {
        get {
            return UserDefaults.standard
                .string(forKey: "tw.sodas.simple-note.storage-username")
        }
        set {
            UserDefaults.standard.set(newValue,
                                      forKey: "tw.sodas.simple-note.storage-username")
        }
    }

    static var APIPassword: String? {
        get {
            return UserDefaults.standard
                .string(forKey: "tw.sodas.simple-note.storage-password")
        }
        set {
            UserDefaults.standard.set(newValue,
                                      forKey: "tw.sodas.simple-note.storage-password")
        }
    }

    static var hasAPICredential: Bool {
        let username = self.APIUsername ?? ""
        let password = self.APIPassword ?? ""
        return !username.isEmpty && !password.isEmpty
    }

    static var APICredential: URLCredential {
        return URLCredential(user: self.APIUsername ?? "",
                             password: self.APIPassword ?? "",
                             persistence: .forSession)
    }

    static func signUp(username: String, password: String, email: String,
                       completion: ((Bool) -> Void)? = nil) {
        let signUpURL = SimpleNote.APIEndpoint.appendingPathComponent("signup")
        Alamofire
            .request(signUpURL,
                     method: .post,
                     parameters: [
                        "username": username,
                        "password": password,
                        "email": email],
                     encoding: JSONEncoding.default)
            .validate()
            .responseJSON { dataResponse in
                completion?(dataResponse.result.isSuccess)
        }
    }
}

extension SimpleNote {  // I/O Methods

    func save(completion: ((Bool) -> Void)? = nil) {
        if self.uuid == nil {
            self.create(completion: completion)
        } else {
            self.update(completion: completion)
        }
    }

    private func create(completion: ((Bool) -> Void)? = nil) {
        Alamofire
            .request(SimpleNote.collectionURL,
                     method: .post,
                     parameters: ["title": self.title, "content": self.content],
                     encoding: JSONEncoding.default)
            .authenticate(usingCredential: SimpleNote.APICredential)
            .validate()  // Check HTTP status code and content type
            .responseJSON { dataResponse in
                guard dataResponse.result.isSuccess else {
                    completion?(false)
                    return
                }
                // Get UUID from the response,
                // Try to use `SwiftyJSON` if your response data is too complex
                guard let respValue = dataResponse.value as? [String: String],
                    let noteUUIDString = respValue["uuid"],
                    let noteUUID = UUID(uuidString: noteUUIDString) else {
                        fatalError("Cannot get UUID from remote API response")
                }
                self.uuid = noteUUID
                completion?(true)
        }
    }

    private func update(completion: ((Bool) -> Void)? = nil) {
        guard let noteUUID = self.uuid else {
            fatalError("Cannot update a note without UUID. Create it first.")
        }
        Alamofire
            .request(SimpleNote.itemURL(of: noteUUID),
                     method: .patch,
                     parameters: ["title": self.title, "content": self.content],
                     encoding: JSONEncoding.default)
            .authenticate(usingCredential: SimpleNote.APICredential)
            .validate()
            .responseJSON { completion?($0.result.isSuccess) }
    }

    static func open(uuid: UUID, completion: ((SimpleNote?) -> Void)? = nil) {
        Alamofire
            .request(SimpleNote.itemURL(of: uuid), method: .get)
            .authenticate(usingCredential: self.APICredential)
            .validate()
            .responseJSON { dataResponse in
                guard dataResponse.result.isSuccess else {
                    completion?(nil)
                    return
                }
                // Done
                guard let respValue = dataResponse.value as? [String: String],
                    let noteUUIDString = respValue["uuid"],
                    let noteUUID = UUID(uuidString: noteUUIDString),
                    let noteTitle = respValue["title"],
                    let noteContent = respValue["content"] else {
                        fatalError("Failed to get content of note.")
                }
                let fetchedNote = SimpleNote()
                fetchedNote.uuid = noteUUID
                fetchedNote.title = noteTitle
                fetchedNote.content = noteContent
                completion?(fetchedNote)
        }
    }

    static func delete(uuid: UUID, completion: ((Bool) -> Void)? = nil) {
        Alamofire
            .request(SimpleNote.itemURL(of: uuid), method: .delete)
            .authenticate(usingCredential: SimpleNote.APICredential)
            .validate()
            .responseJSON { dataResponse in completion?(dataResponse.result.isSuccess) }
    }
}

// MARK: - Note List

extension SimpleNote {
    typealias GetNotesListHandler = ([(String, UUID)]?) -> Void

    static func getNotesList(completion: GetNotesListHandler?) {
        Alamofire
            .request(SimpleNote.collectionURL, method: .get)
            .authenticate(usingCredential: self.APICredential)
            .validate()
            .responseJSON { dataResponse in
                guard dataResponse.result.isSuccess else {
                    completion?(nil)
                    return
                }
                // Done
                guard let respValue = dataResponse.value as? [[String: String]] else {
                    print("Failed to list notes.")
                    return
                }
                var fetchedNotesList = [(String, UUID)]()
                for item in respValue {
                    guard let title = item["title"],
                        let uuidString = item["uuid"],
                        let uuid = UUID(uuidString: uuidString) else {
                        print("Failed to parse notes list.")
                        return
                    }
                    fetchedNotesList.append((title, uuid))
                }
                completion?(fetchedNotesList)
        }
    }
}
