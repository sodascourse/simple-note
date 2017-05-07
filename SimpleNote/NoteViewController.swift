//
//  NoteViewController.swift
//  SimpleNote
//
//  Created by sodas on 5/7/17.
//  Copyright © 2017 sodastsai. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextView!

    var note: PureTextNote? {
        didSet {
            if self.isViewLoaded {
                self.updateUIElements()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIElements()
    }

    func updateUIElements() {
        self.navigationItem.title = self.note?.title
        self.contentTextView.text = self.note?.content
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.note?.content = self.contentTextView.text ?? ""
        try? self.note?.save()
    }

}
