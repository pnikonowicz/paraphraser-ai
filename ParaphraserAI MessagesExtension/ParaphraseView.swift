import UIKit

class ParaphraseView: UIView {
    private let userMessageTextView = UITextView()
    private let additionalContextTextView = UITextView()
    private let paraPhraseSubmit = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var apiKey: String = ""
    private var style: String = ""
    private var onCopyToChat: ((ParaphraseView, String) -> Void)?

    func configure(apiKey: String, onCopyToChatButtonClicked: @escaping (ParaphraseView, String) -> Void) {
        self.apiKey = apiKey
        self.onCopyToChat = onCopyToChatButtonClicked
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupParaphraseView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupParaphraseView()
    }

    private func setupParaphraseView() {
        backgroundColor = .clear

        let userMessageTextLabel = UILabel()
        userMessageTextLabel.text = "What do you want to say"
        userMessageTextLabel.font = UIFont.boldSystemFont(ofSize: 16)
        userMessageTextLabel.textColor = .label
        userMessageTextLabel.translatesAutoresizingMaskIntoConstraints = false

        userMessageTextView.translatesAutoresizingMaskIntoConstraints = false
        userMessageTextView.font = UIFont.systemFont(ofSize: 16)
        userMessageTextView.layer.cornerRadius = 8
        userMessageTextView.layer.borderWidth = 1
        userMessageTextView.layer.borderColor = UIColor.systemGray4.cgColor
        userMessageTextView.clipsToBounds = true
        userMessageTextView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let additionalContextLabel = UILabel()
        additionalContextLabel.text = "Last thing they said"
        additionalContextLabel.font = UIFont.boldSystemFont(ofSize: 16)
        additionalContextLabel.textColor = .label
        additionalContextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        additionalContextTextView.translatesAutoresizingMaskIntoConstraints = false
        additionalContextTextView.font = UIFont.systemFont(ofSize: 16)
        additionalContextTextView.layer.cornerRadius = 8
        additionalContextTextView.layer.borderWidth = 1
        additionalContextTextView.layer.borderColor = UIColor.systemGray4.cgColor
        additionalContextTextView.clipsToBounds = true
        additionalContextTextView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        paraPhraseSubmit.translatesAutoresizingMaskIntoConstraints = false
        paraPhraseSubmit.setTitle("Paraphrase", for: .normal)
        paraPhraseSubmit.addTarget(self, action: #selector(paraphraseTapped), for: .touchUpInside)
        paraPhraseSubmit.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // add a submit button that says copy to chat
        let copyToChatButton = UIButton(type: .system)
        copyToChatButton.setTitle("Copy to Chat", for: .normal)
        copyToChatButton.translatesAutoresizingMaskIntoConstraints = false
        copyToChatButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        copyToChatButton.addTarget(self, action: #selector(copyToChatTapped), for: .touchUpInside)

        // add a button that clears the userMessageTextView
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        // Create a horizontal stack for the submit and copy buttons
        let buttonStack = UIStackView(arrangedSubviews: [paraPhraseSubmit, copyToChatButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        // Create a horizontal stack for the clearButton and messageTextLabel with the clearButton float to the right
        let labelAndClearStack = UIStackView(arrangedSubviews: [userMessageTextLabel, clearButton])
        labelAndClearStack.axis = .horizontal
        labelAndClearStack.spacing = 8
        labelAndClearStack.alignment = .center
        labelAndClearStack.distribution = .fill

        // Add a constraint to push the clearButton to the right
        userMessageTextLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [
            labelAndClearStack, userMessageTextView,
            buttonStack, spinner])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }

    @objc private func copyToChatTapped() {
        let text = userMessageTextView.text ?? ""
        onCopyToChat?(self, text)
    }

    @objc private func clearTapped() {
        userMessageTextView.text = ""
    }

    @objc private func paraphraseTapped() {
        let text = userMessageTextView.text ?? ""
        let additionalContext = additionalContextTextView.text ?? ""
        userMessageTextView.resignFirstResponder()
        setLoading(true)
        sendToOpenAI(text: text, additionalContext: additionalContext, style: self.style) { result in
            DispatchQueue.main.async {
                self.setLoading(false)

                switch result {
                case .success(let paraphrased):
                    self.userMessageTextView.text = paraphrased
                case .failure(let error):
                    let responseString = (error as NSError).userInfo["response"] as? String ?? ""
                    self.userMessageTextView.text = "Error: \(error.localizedDescription)\n\nResponse: \(responseString)"
                }
            }
        }
    }

    private func sendToOpenAI(text: String, additionalContext: String, style: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key not found."])))
            return
        }
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=\(apiKey)")!
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": """
Paraphrase the following text in the specified style. The last thing that the target person said is provided to help with the paraphrasing. Provide an answer that can be copied and pasted directly without any additional parsing. If the "last thing that was said" section is populated, then generate additional text in order to fill in the reply. 
Style: \(style ?? "")
Text: \(text)
Last thing that was said: \(additionalContext)
"""]
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
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid response",
                        "response": responseString
                    ])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    // Utility methods for MessagesViewController
    func setLoading(_ loading: Bool) {
        if loading {
            spinner.startAnimating()
            paraPhraseSubmit.isEnabled = false
        } else {
            spinner.stopAnimating()
            paraPhraseSubmit.isEnabled = true
        }
    }

    func setSubmitEnabled(_ enabled: Bool) {
        paraPhraseSubmit.isEnabled = enabled
    }

    func resetText() {
        userMessageTextView.text = ""
    }

    func show(context style: String) {
        self.isHidden = false
        self.style = style
        self.resetText()
    }
}
