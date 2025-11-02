import UIKit

class ContextSelectionView : UIView {

    private let grammarButton = UIButton(type: .system)
    private let shakespeareButton = UIButton(type: .system)
    private let pirateButton = UIButton(type: .system)
    private let styleSelectionView = UIView()

    var onContextSelected: ((String, String) -> Void)?

    func setup(parentView: UIView, onContextSelected: @escaping (String, String) -> Void) {
        self.onContextSelected = onContextSelected

        styleSelectionView.translatesAutoresizingMaskIntoConstraints = false
        grammarButton.translatesAutoresizingMaskIntoConstraints = false
        shakespeareButton.translatesAutoresizingMaskIntoConstraints = false
        pirateButton.translatesAutoresizingMaskIntoConstraints = false

        grammarButton.setTitle("Grammar", for: .normal)
        shakespeareButton.setTitle("Shakespeare Poet", for: .normal)
        pirateButton.setTitle("Pirate", for: .normal)

        [grammarButton, shakespeareButton, pirateButton].forEach {
            $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            $0.backgroundColor = UIColor.systemBlue
            $0.setTitleColor(.white, for: .normal)
            $0.layer.cornerRadius = 8.0
            styleSelectionView.addSubview($0)
        }

        grammarButton.addTarget(self, action: #selector(styleButtonTapped(_:)), for: .touchUpInside)
        shakespeareButton.addTarget(self, action: #selector(styleButtonTapped(_:)), for: .touchUpInside)
        pirateButton.addTarget(self, action: #selector(styleButtonTapped(_:)), for: .touchUpInside)

        parentView.addSubview(styleSelectionView)

        NSLayoutConstraint.activate([
            styleSelectionView.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 40),
            styleSelectionView.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            styleSelectionView.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            styleSelectionView.heightAnchor.constraint(equalToConstant: 200),

            grammarButton.topAnchor.constraint(equalTo: styleSelectionView.topAnchor),
            grammarButton.leadingAnchor.constraint(equalTo: styleSelectionView.leadingAnchor),
            grammarButton.trailingAnchor.constraint(equalTo: styleSelectionView.trailingAnchor),
            grammarButton.heightAnchor.constraint(equalToConstant: 44),

            shakespeareButton.topAnchor.constraint(equalTo: grammarButton.bottomAnchor, constant: 20),
            shakespeareButton.leadingAnchor.constraint(equalTo: styleSelectionView.leadingAnchor),
            shakespeareButton.trailingAnchor.constraint(equalTo: styleSelectionView.trailingAnchor),
            shakespeareButton.heightAnchor.constraint(equalToConstant: 44),

            pirateButton.topAnchor.constraint(equalTo: shakespeareButton.bottomAnchor, constant: 20),
            pirateButton.leadingAnchor.constraint(equalTo: styleSelectionView.leadingAnchor),
            pirateButton.trailingAnchor.constraint(equalTo: styleSelectionView.trailingAnchor),
            pirateButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func styleButtonTapped(_ sender: UIButton) {
        var context = ""
        var title = ""
        switch sender {
        case grammarButton:
            context = "Make this text succinct and more clear. Do not add too many words, just replace and fix grammar where appropriate. Try to maintain the original author's personality."
            title = "Grammar"
        case shakespeareButton:
            context = "Rewrite this text in the style of a Shakespearean poet. Use poetic and old English language."
            title = "Shakespeare Poet"
        case pirateButton:
            context = "Rewrite this text as if spoken by a pirate. Use pirate slang and style."
            title = "Pirate"
        default:
            context = "Make this text succinct and more clear. Do not add too many words, just replace and fix grammar where appropriate. Try to maintain the original author's personality."
            title = "Grammar"
        }
        onContextSelected?(context, title)
    }

    func show() {
        self.styleSelectionView.isHidden = false
    }

    func hide() {
        self.styleSelectionView.isHidden = true
    }
}
