import UIKit

class ParaphraseView: UIView {
    private let textView = UITextView()
    private let submitButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var apiKey: String = ""
    private var getContext: (() -> String?)?
    private var onSuccess: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupParaphraseView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupParaphraseView()
    }

    func configure(apiKey: String, getContext: @escaping () -> String?, onSuccess: @escaping () -> Void) {
        self.apiKey = apiKey
        self.getContext = getContext
        self.onSuccess = onSuccess
    }

    private func setupParaphraseView() {
        backgroundColor = .clear

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.clipsToBounds = true
        textView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Paraphrase", for: .normal)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        let stackView = UIStackView(arrangedSubviews: [textView, submitButton, spinner])
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

    @objc private func submitButtonTapped() {
        let text = textView.text ?? ""
        textView.resignFirstResponder()
        setLoading(true)
        sendToOpenAI(text: text, style: getContext?()) { result in
            DispatchQueue.main.async {
                self.setLoading(false)

                switch result {
                case .success(let paraphrased):
                    self.textView.text = paraphrased
                case .failure(let error):
                    self.textView.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func sendToOpenAI(text: String, style: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key not found."])))
            return
        }
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(style ?? "")\n\n\(text)"]
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
                    completion(.failure(NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
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
            submitButton.isEnabled = false
        } else {
            spinner.stopAnimating()
            submitButton.isEnabled = true
        }
    }

    func setSubmitEnabled(_ enabled: Bool) {
        submitButton.isEnabled = enabled
    }

    func resetText() {
        textView.text = ""
    }
}
