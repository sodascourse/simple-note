//
//  RemoteNoteViewController.swift
//  SimpleNote
//
//  Created by sodas on 5/30/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

protocol RemoteNoteViewControllerDelegate: AnyObject {
    func noteViewController(_ noteViewController: RemoteNoteViewController, didClose note: SimpleNote)
}

class RemoteNoteViewController: UIViewController, UITextViewDelegate {

    weak var delegate: RemoteNoteViewControllerDelegate?

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!

    var noteUUID: UUID?
    var note: SimpleNote! {
        didSet {
            self.titleTextField.text = self.note.title
            self.contentTextView.text = self.note.content
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadNote()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.noteViewController(self, didClose: self.note)
    }

    func loadNote() {
        guard self.note == nil else { return }
        if self.noteUUID == nil {
            self.note = SimpleNote(title: "Untitled")
            return
        }
        self.loadingIndicatorView.startAnimating()
        SimpleNote.open(uuid: self.noteUUID!) { fetchedNote in
            defer { self.loadingIndicatorView.stopAnimating() }
            guard let note = fetchedNote else {
                let alertController = UIAlertController(title: "Failed to open note",
                                                        message: nil,
                                                        preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                alertController.addAction(dismissAction)
                self.present(alertController, animated: true)
                return
            }
            self.note = note
        }
    }

    // MARK: - UI Delegates

    func textViewDidChange(_ textView: UITextView) {
        self.note.content = textView.text
    }

    @IBAction func titleTextFieldChanged(_ textField: UITextField) {
        self.note.title = textField.text ?? ""
    }

}
