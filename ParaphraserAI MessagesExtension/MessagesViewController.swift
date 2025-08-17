//
//  MessagesViewController.swift
//  ParaphraserAI MessagesExtension
//
//  Created by paul nikonowicz on 8/3/25.
//

import UIKit
import Messages


class MessagesViewController: MSMessagesAppViewController, StyleSelectionViewDelegate {
    private let textView = UITextView()
    private let submitButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let styleSelectionView = ContextSelectionView()
    private let paraphraseView = UIView()
    
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
        
        setupParaphraseView()
        
        apiKey = MessagesViewController.loadAPIKey()
        if apiKey.isEmpty {
            textView.text = "Error: API key not found. Please add your API key to Secrets.json."
            submitButton.isEnabled = false
        }

        paraphraseView.isHidden = true
        styleSelectionView.show()
    }

    func contextButtonClicked(_ view: ContextSelectionView, context style: String) {
        selectedContext = style
        showParaphraseView()
    }

    private func setupParaphraseView() {
        // Configure textView
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.clipsToBounds = true
        textView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        // Configure submitButton
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Paraphrase", for: .normal)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // StackView for vertical layout
        let stackView = UIStackView(arrangedSubviews: [textView, submitButton])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add stackView to paraphraseView
        paraphraseView.translatesAutoresizingMaskIntoConstraints = false
        paraphraseView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: paraphraseView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: paraphraseView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: paraphraseView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: paraphraseView.bottomAnchor, constant: -20)
        ])

        // Add paraphraseView to main view if not already added
        if paraphraseView.superview == nil {
            view.addSubview(paraphraseView)
            NSLayoutConstraint.activate([
                paraphraseView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                paraphraseView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                paraphraseView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                paraphraseView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    private func showParaphraseView() {
        styleSelectionView.hide()
        paraphraseView.isHidden = false
        textView.text = ""
    }

    @objc private func submitButtonTapped() {
        guard let conversation = activeConversation else { return }
        let text = textView.text ?? ""
        textView.resignFirstResponder()
        spinner.startAnimating()
        submitButton.isEnabled = false

        sendToOpenAI(text: text, style: selectedContext) { [weak self] result in
            DispatchQueue.main.async {
                self?.spinner.stopAnimating()
                self?.submitButton.isEnabled = true
                switch result {
                case .success(let paraphrased):
                    conversation.insertText(paraphrased) { error in
                        if let error = error {
                            print("Error inserting text: \(error)")
                        } else {
                            self?.textView.text = ""
                            self?.styleSelectionView.show()
                        }
                    }
                case .failure(let error):
                    self?.textView.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func sendToOpenAI(text: String, style: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key not found."])))
            return
        }
        
        // Gemini API endpoint and model
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(selectedContext)\n\n\(text)"]
                    ]
                ]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Gemini response error: \(responseString)")
                    }
                    completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            } catch {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Gemini response error: \(responseString)")
                }
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
