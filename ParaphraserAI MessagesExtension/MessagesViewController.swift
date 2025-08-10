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
    private let spinner = UIActivityIndicatorView(style: .medium)
    
    private var apiKey: String = ""
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
        setupUI()
        apiKey = MessagesViewController.loadAPIKey()
        if apiKey.isEmpty {
            textView.text = "Error: API key not found. Please add your API key to Secrets.json."
            submitButton.isEnabled = false
        }
    }
    
    private func setupUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = UIColor.systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8.0
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)

        spinner.hidesWhenStopped = true
        
        view.addSubview(textView)
        view.addSubview(submitButton)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 100),

            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 120),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 16)
        ])
    }
    
    @objc private func submitButtonTapped() {
        guard let conversation = activeConversation else { return }
        let text = textView.text ?? ""
        textView.resignFirstResponder() // Dismiss the keyboard
        spinner.startAnimating()
        submitButton.isEnabled = false

        sendToOpenAI(text: text) { [weak self] result in
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
                        }
                    }
                case .failure(let error):
                    self?.textView.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendToOpenAI(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key not found."])))
            return
        }
        // Gemini API endpoint and model
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        let context = "Make this text succinct and more clear. Do not add too many words, just replace and fix grammar where appropriate. Try to maintain the original author's personality."
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(context)\n\n\(text)"]
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
