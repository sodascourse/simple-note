//
//  NoteViewController.swift
//  SimpleNote
//
//  Created by sodas on 5/7/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

protocol NoteViewControllerDelegate: AnyObject {
    func noteViewController(_ noteViewController: NoteViewController, didCloseNote note: PureTextNote)
}

class NoteViewController: UIViewController {

    weak var delegate: NoteViewControllerDelegate?

    @IBOutlet weak var contentTextView: UITextView!
    var titleLabel: UILabel! {
        return self.navigationItem.titleView as! UILabel
    }

    var note: PureTextNote? {
        didSet {
            guard self.isViewLoaded else { return }
            self.updateUIElements()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIElements()
    }

    func updateUIElements() {
        self.titleLabel.text = self.note?.title
        self.contentTextView.text = self.note?.content
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.note?.content = self.contentTextView.text ?? ""
        if self.note != nil {
            self.delegate?.noteViewController(self, didCloseNote: self.note!)
        }
    }

    // MARK: - Gesture Regcognizer

    @IBAction func titleDidDoubleClicked(_ sender: UITapGestureRecognizer) {
        let titlePrompt = UIAlertController(title: "New Note Title",
                                            message: nil,
                                            preferredStyle: .alert)
        titlePrompt.addTextField { (titleTextField) in
            titleTextField.autocapitalizationType = .words
            titleTextField.text = self.note?.title
        }

        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned titlePrompt] _ in
            let newTitle = titlePrompt.textFields!.first!.text!
            print("New title is '\(newTitle)'")
        }
        titlePrompt.addAction(okAction)
        titlePrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(titlePrompt, animated: true)
    }

}
