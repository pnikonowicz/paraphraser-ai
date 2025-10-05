//
//  MessagesViewController.swift
//  ParaphraserAI MessagesExtension
//
//  Created by paul nikonowicz on 8/3/25.
//

import UIKit
import Messages


class MessagesViewController: MSMessagesAppViewController, StyleSelectionViewDelegate {
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
        styleSelectionView.setup(parentView: self.view)
        styleSelectionView.onButtonTapped = self
        
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
        paraphraseView.configure(apiKey: apiKey, getContext: { [weak self] in self?.selectedContext }, onSuccess: { [weak self] in
            self?.paraphraseView.resetText()
            self?.styleSelectionView.show()
        })

        if apiKey.isEmpty {
            let alert = UIAlertController(title: "API Key Error", message: "API key not found. Please add your API key to Secrets.json.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            paraphraseView.setSubmitEnabled(false)
        }

        styleSelectionView.show()
    }

    func contextButtonClicked(_ view: ContextSelectionView, context style: String) {
        selectedContext = style
        showParaphraseView()
    }

    private func showParaphraseView() {
        styleSelectionView.hide()
        paraphraseView.isHidden = false
        paraphraseView.resetText()
    }
}