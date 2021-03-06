//
//  NoteListViewController.swift
//  SimpleNote
//
//  Created by sodas on 5/7/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

class NoteListViewController: UITableViewController, NoteViewControllerDelegate {

    var noteTitles = [String]() {
        didSet {
            if self.isViewLoaded {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateNoteTitles()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(NoteListViewController.pureTextNoteDidUpdate(_:)),
                                               name: .PureTextNoteDidUpdate,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func pureTextNoteDidUpdate(_ notification: Notification) {
        self.updateNoteTitles()
    }

    @IBAction func updateTableViewContent(_ sender: UIRefreshControl) {
        self.updateNoteTitles {
            sender.endRefreshing()
        }
    }

    func updateNoteTitles(completion: (() -> Void)? = nil) {
        PureTextNote.getTitleOfSavedNotes { noteTitles in
            self.noteTitles = noteTitles
            completion?()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return self.noteTitles.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let noteTitle = self.noteTitles[indexPath.row]
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
        let noteTitle = self.noteTitles[indexPath.row]

        self.tableView.beginUpdates()
        defer { self.tableView.endUpdates() }
        do {
            try PureTextNote.remove(title: noteTitle)
            self.updateNoteTitles()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch {
            fatalError("Cannot delete note: \(noteTitle)")
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
        let noteViewController = segue.destination as! NoteViewController
        let senderIndexPath = self.tableView.indexPath(for: sender)!
        let selectedTitle = self.noteTitles[senderIndexPath.row]
        noteViewController.note = try? PureTextNote.open(title: selectedTitle)
        noteViewController.delegate = self
    }

    func prepareCreatingNote(for segue: UIStoryboardSegue) {
        let noteViewController = segue.destination as! NoteViewController
        noteViewController.note = PureTextNote()
        noteViewController.delegate = self
    }

    // MARK: - NoteViewController Delegate

    func noteViewController(_ noteViewController: NoteViewController, didCloseNote note: PureTextNote) {
        note.save()
    }

}
