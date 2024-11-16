//
//  AddStationViewController.swift
//  BCycle
//
//  Created by Thomas Traylor on 1/1/24.
//

import UIKit
import MapKit
import Combine

protocol AddStationViewControllerDelegate: AnyObject {
    func addStationViewController(_ controller: AddStationViewController, didAddStationAt placemark: CLPlacemark)
}

class AddStationViewController: UIViewController {

    var placemark: CLPlacemark?
    
    weak var delegate: AddStationViewControllerDelegate?
    
    private var viewModel = AddStationViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var cancelButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!
    
//    private var scrollView: UIScrollView = {
//        let view = UIScrollView(frame: .zero)
//        view.autoresizesSubviews = true
//        return view
//    }()
//    
//    private var textFieldView: UIView = {
//        let view = UIView(frame: .zero)
//        return view
//    }()
//    
    private var nameTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "Name"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var streetTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "Street"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var cityTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "City"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var stateTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "State"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var zipTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "Zip"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var docksTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "Docks"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private var activeTextField: UITextField?
    
    override func loadView() {
        view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        
        cancelButton = UIBarButtonItem(title: "Cancel",
                                       style: .plain,
                                       target: self,
                                       action: #selector(cancelStation(_:)))
        cancelButton.tintColor = .systemRed
        
        saveButton = UIBarButtonItem(title: "Save", 
                                     style: .plain,
                                     target: self,
                                     action: #selector(saveStation(_:)))
        saveButton.tintColor = .systemRed
        saveButton.isEnabled = false
        
//        view.addSubview(scrollView)
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        
//        scrollView.addSubview(textFieldView)
//        textFieldView.translatesAutoresizingMaskIntoConstraints = false
        
        let contentViews = [nameTextField, streetTextField, 
                            cityTextField, stateTextField,
                            zipTextField, docksTextField]
        contentViews.forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
//        let scrollViewConstraints = [
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
//        ]
//        
//        let contentViewContraints = [
//            textFieldView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            textFieldView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: textFieldView.bottomAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: textFieldView.trailingAnchor)
//        ]
        
        let nameTextFieldConstraints = [
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0),
            nameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor, constant: 16.0)
        ]
        
        let streetTextFieldConstraints = [
            streetTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 12.0),
            streetTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            streetTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor)
        ]
        
        let cityTextFieldConstraints = [
            cityTextField.topAnchor.constraint(equalTo: streetTextField.bottomAnchor, constant: 12.0),
            cityTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor)
        ]
        
        let stateTextFieldConstraints = [
            stateTextField.topAnchor.constraint(equalTo: streetTextField.bottomAnchor, constant: 12.0),
            stateTextField.leadingAnchor.constraint(equalTo: cityTextField.trailingAnchor, constant: 12.0),
            stateTextField.bottomAnchor.constraint(equalTo: cityTextField.bottomAnchor),
            stateTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor)
        ]
        
        let zipTextFieldConstraints = [
            zipTextField.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 12.0),
            zipTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            zipTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 97.0),
        ]
        
        let docksTextFieldConstraints = [
            docksTextField.topAnchor.constraint(equalTo: zipTextField.bottomAnchor, constant: 12.0),
            docksTextField.leadingAnchor.constraint(equalTo: zipTextField.leadingAnchor),
            docksTextField.trailingAnchor.constraint(equalTo: zipTextField.trailingAnchor)
        ]
        
        [
            // scrollViewConstraints, contentViewContraints,
            nameTextFieldConstraints,
            streetTextFieldConstraints, 
            cityTextFieldConstraints,
            stateTextFieldConstraints, 
            zipTextFieldConstraints,
            docksTextFieldConstraints
        ].forEach(NSLayoutConstraint.activate(_:))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.systemRed]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemRed]
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.compactAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.compactScrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .white

        setNeedsStatusBarAppearanceUpdate()
        title = "Submit a Station"

        navigationItem.setRightBarButton(cancelButton, animated: true)
        navigationItem.setLeftBarButton(saveButton, animated: true)
        
        nameTextField.delegate = self
        streetTextField.delegate = self
        cityTextField.delegate = self
        stateTextField.delegate = self
        zipTextField.delegate = self
        docksTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let location = placemark?.location {
            viewModel.location = location
        }
        
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: nameTextField)
                .map { ($0.object as! UITextField).text ?? "" }
                .assign(to: \.name, on: viewModel)
                .store(in: &cancellables)
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: streetTextField)
                .map { ($0.object as! UITextField).text ?? "" }
                .assign(to: \.street, on: viewModel)
                .store(in: &cancellables)
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: cityTextField)
                .map { ($0.object as! UITextField).text ?? "" }
                .assign(to: \.city, on: viewModel)
                .store(in: &cancellables)
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: stateTextField)
                .map { ($0.object as! UITextField).text ?? "" }
                .assign(to: \.zip, on: viewModel)
                .store(in: &cancellables)
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: zipTextField)
                .map { ($0.object as! UITextField).text ?? "" }
                .assign(to: \.zip, on: viewModel)
                .store(in: &cancellables)
        NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: docksTextField)
                .map { Int(($0.object as! UITextField).text ?? "0") ?? 0 }
                .assign(to: \.docks, on: viewModel)
                .store(in: &cancellables)
        
        viewModel.isSubmitEnabled
            .assign(to: \.isEnabled, on: saveButton)
            .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let name = placemark?.name {
            nameTextField.text = name
            viewModel.name = name
        }
        
        if let subThoroughfare = placemark?.subThoroughfare, let thoroughfare = placemark?.thoroughfare {
            streetTextField.text = "\(subThoroughfare) \(thoroughfare)"
            viewModel.street = "\(subThoroughfare) \(thoroughfare)"
        }
        
        if let city = placemark?.locality {
            cityTextField.text = city
            viewModel.city = city
        }
        
        if let state = placemark?.administrativeArea {
            stateTextField.text = state
            viewModel.state = state
        }
        
        if let zip = placemark?.postalCode {
            zipTextField.text = zip
            viewModel.zip = zip
        }
        
    }

    // MARK: - Actions
    @objc private func cancelStation(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func saveStation(_ barButtonItem: UIBarButtonItem) {
        saveButton.isEnabled = false
        cancelButton.isEnabled = false
        viewModel.saveStation {
            DispatchQueue.main.async {
                if let placemark = self.placemark {
                    self.delegate?.addStationViewController(self, didAddStationAt: placemark)
                }
                
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc private func hideKeyboard(_ sender: UITapGestureRecognizer) {
        activeTextField?.resignFirstResponder()
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension AddStationViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
