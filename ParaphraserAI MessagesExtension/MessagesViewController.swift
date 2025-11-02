//
//  MessagesViewController.swift
//  ParaphraserAI MessagesExtension
//
//  Created by paul nikonowicz on 8/3/25.
//

import UIKit
import Messages


class MessagesViewController: MSMessagesAppViewController {
    private let styleSelectionView = ContextSelectionView()
    private let paraphraseView = ParaphraseView()
    
    private var apiKey: String = ""
    private var selectedContext: String?

    static func loadAPIKey() -> String {
        guard let secretsURL = Bundle.main.url(forResource: "Secrets", withExtension: "json") else {
            return ""
        }
        do {
            let data = try Data(contentsOf: secretsURL)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let key = json["API_KEY"] as? String {
                return key
            }
        } catch {
            print("Error loading API key: \(error)")
        }
        return ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleSelectionView.setup(parentView: self.view, onContextSelected: self.animateTheParaphraseView)
        
        paraphraseView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paraphraseView)
        NSLayoutConstraint.activate([
            paraphraseView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            paraphraseView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paraphraseView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paraphraseView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        paraphraseView.isHidden = true

        apiKey = MessagesViewController.loadAPIKey()
        paraphraseView.configure(apiKey: apiKey, onCopyToChatButtonClicked: self.copyToChatButtonClicked)

        if apiKey.isEmpty {
            let alert = UIAlertController(title: "API Key Error", message: "API key not found. Please add your API key to Secrets.json.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            paraphraseView.setSubmitEnabled(false)
        }

        // Add swipe gesture to paraphraseView to handle right swipe
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.animateTheStyleSelectionView))
        swipeRight.direction = .right
        self.paraphraseView.addGestureRecognizer(swipeRight)

        styleSelectionView.show()
    }

    func animateTheParaphraseView(context style: String) {
            self.styleSelectionView.hide()
            self.paraphraseView.show(context: style)
    }

    @objc func animateTheStyleSelectionView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.paraphraseView.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            self.paraphraseView.alpha = 0
            self.styleSelectionView.transform = .identity
        }, completion: { _ in
            self.paraphraseView.hide()
            self.paraphraseView.transform = .identity
            self.paraphraseView.alpha = 1
            self.styleSelectionView.show()
        })
    }

    func copyToChatButtonClicked(_ view: ParaphraseView, context message: String) {
        // Insert the paraphrased message directly into the iMessage input field
        self.activeConversation?.insertText(message, completionHandler: { error in
            if let error = error {
            print("Error inserting message: \(error)")
            }
        })
        
        // close the controller. work is done.
        self.dismiss()

    }
}
