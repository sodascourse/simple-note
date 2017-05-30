//
//  RemoteNoteListViewController.swift
//  SimpleNote
//
//  Created by sodas on 5/30/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

class RemoteNoteListViewController: UITableViewController, RemoteNoteViewControllerDelegate {

    var notesList = [(String, UUID)]() {
        didSet {
            guard self.isViewLoaded else { return }
            self.tableView.reloadData()
        }
    }

    func updateNoteTitles(completion: ((Bool) -> Void)? = nil) {
        SimpleNote.getNotesList { fetchedNotesList in
            guard let notesList = fetchedNotesList else {
                completion?(false)
                let alertController = UIAlertController(title: "Failed to update note list",
                                                        message: nil,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alertController, animated: true)
                return
            }
            self.notesList = notesList
            completion?(true)
        }
    }

    @IBAction func updateTableViewContent(_ sender: UIRefreshControl) {
        self.updateNoteTitles { _ in
            sender.endRefreshing()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateNoteTitles()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return self.notesList.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let (noteTitle, _) = self.notesList[indexPath.row]
        cell.textLabel?.text = noteTitle
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.removeNote(at: indexPath)
        }
    }

    func removeNote(at indexPath: IndexPath) {
        let (_, noteUUID) = self.notesList[indexPath.row]
        SimpleNote.delete(uuid: noteUUID) { success in
            guard success else { return }
            self.tableView.beginUpdates()
            self.updateNoteTitles { success in
                defer { self.tableView.endUpdates() }
                guard success else { return }
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }

    // MARK: - Storyboard Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenNote" {
            guard let cell = sender as? UITableViewCell else {
                fatalError("Mis-configured storyboard! The sender should be a cell.")
            }
            self.prepareOpeningNote(for: segue, sender: cell)
        } else if segue.identifier == "CreateNote" {
            self.prepareCreatingNote(for: segue)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    func prepareOpeningNote(for segue: UIStoryboardSegue, sender: UITableViewCell) {
        let noteViewController = segue.destination as! RemoteNoteViewController
        let senderIndexPath = self.tableView.indexPath(for: sender)!
        let (_, selectedNoteUUID) = self.notesList[senderIndexPath.row]
        noteViewController.noteUUID = selectedNoteUUID
        noteViewController.delegate = self
    }

    func prepareCreatingNote(for segue: UIStoryboardSegue) {
        let noteViewController = segue.destination as! RemoteNoteViewController
        noteViewController.delegate = self
    }

    // MARK: - NoteViewControllerDelegate

    func noteViewController(_ noteViewController: RemoteNoteViewController,
                            didClose note: SimpleNote) {
        note.save { success in
            if !success {
                // Maybe retry again? or save to local disk and save again later
                let alertController = UIAlertController(title: "Failed to save note",
                                                        message: nil,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alertController, animated: true)
                return
            }
            self.updateNoteTitles()
        }
    }

    // MARK: - Account

    @IBAction func openAccountMenu(_ sender: Any) {
        let accountMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for action in self.accountActions() {
            accountMenu.addAction(action)
        }
        self.present(accountMenu, animated: true, completion: nil)
    }

    func accountActions() -> [UIAlertAction] {
        var result = [UIAlertAction]()
        if SimpleNote.hasAPICredential {
            result.append(UIAlertAction(title: "Sign out", style: .destructive) { _ in
                self.signOut()
            })
        } else {
            result.append(UIAlertAction(title: "Sign in", style: .default) { _ in
                self.promptForSignIn()
            })
            result.append(UIAlertAction(title: "Sign up", style: .default) { _ in
            })
        }
        result.append(UIAlertAction(title: "Cancel", style: .cancel))
        return result
    }

    func promptForSignIn() {
        let credentialPrompt = UIAlertController(title: "Sign in for remote storage",
                                                 message: nil,
                                                 preferredStyle: .alert)
        credentialPrompt.addTextField { textField in
            textField.tag = 1
            textField.placeholder = "Username"
            textField.autocorrectionType = .no
            textField.keyboardType = .asciiCapable
        }
        credentialPrompt.addTextField { textField in
            textField.tag = 2
            textField.placeholder = "Password"
            textField.autocorrectionType = .no
            textField.keyboardType = .asciiCapable
            textField.isSecureTextEntry = true
        }
        credentialPrompt.addAction(UIAlertAction(title: "Sign in", style: .default) { _ in
            for textField in credentialPrompt.textFields! {
                if textField.tag == 1 {
                    SimpleNote.APIUsername = textField.text ?? ""
                } else if textField.tag == 2 {
                    SimpleNote.APIPassword = textField.text ?? ""
                }
            }
            self.updateNoteTitles(completion: { success in
                if !success {
                    self.signOut()  // Clean wrong username/password
                }
            })
        })
        credentialPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(credentialPrompt, animated: true)
    }

    func promptForSignUp() {
        let credentialPrompt = UIAlertController(title: "Sign up for remote storage", message: nil,
                                                 preferredStyle: .alert)
        credentialPrompt.addTextField { textField in
            textField.tag = 1
            textField.placeholder = "Username"
            textField.autocorrectionType = .no
            textField.keyboardType = .asciiCapable
        }
        credentialPrompt.addTextField { textField in
            textField.tag = 2
            textField.placeholder = "Email"
            textField.autocorrectionType = .no
            textField.keyboardType = .emailAddress
        }
        credentialPrompt.addTextField { textField in
            textField.tag = 3
            textField.placeholder = "Password"
            textField.autocorrectionType = .no
            textField.keyboardType = .asciiCapable
            textField.isSecureTextEntry = true
        }
        credentialPrompt.addAction(UIAlertAction(title: "Sign up", style: .default) { _ in
            var username: String = "", password: String = "", email: String = ""
            for textField in credentialPrompt.textFields! {
                if textField.tag == 1 {
                    username = textField.text ?? ""
                } else if textField.tag == 2 {
                    email = textField.text ?? ""
                } else if textField.tag == 3 {
                    password = textField.text ?? ""
                }
            }
            SimpleNote.signUp(username: username, password: password, email: email) { success in
                if success {
                    SimpleNote.APIUsername = username
                    SimpleNote.APIPassword = password
                    self.updateNoteTitles()
                } else {
                    let alertController = UIAlertController(title: "Failed to sign up",
                                                            message: nil,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alertController, animated: true)
                }
            }
        })
        credentialPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(credentialPrompt, animated: true)
    }

    func signOut() {
        SimpleNote.APIUsername = nil
        SimpleNote.APIPassword = nil
        self.notesList = []
    }

}
