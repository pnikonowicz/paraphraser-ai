//
//  MessagesViewController.swift
//  ParaphraserAI MessagesExtension
//
//  Created by paul nikonowicz on 8/3/25.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    private let textView = UITextView()
    private let submitButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = UIColor.systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8.0
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)

        view.addSubview(textView)
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 100),

            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 120),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func submitButtonTapped() {
        guard let conversation = activeConversation else { return }
        let text = textView.text ?? ""
        textView.resignFirstResponder() // Dismiss the keyboard
        conversation.insertText(text) { error in
            if let error = error {
                print("Error inserting text: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.textView.text = ""
                }
            }
        }
    }
    
    // ...existing code...

}
