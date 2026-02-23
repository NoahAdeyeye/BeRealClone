//
//  PostViewController.swift
//  BeRealClone
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import PhotosUI
import ParseSwift

class PostViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?
    // Stretch: captured metadata from the picked photo
    private var pickedPhotoTime: Date?
    private var pickedPhotoLocation: ParseGeoPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        // Present Image picker using PHPickerViewController
        var config = PHPickerConfiguration()
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {

        // Dismiss Keyboard
        view.endEditing(true)

        // Create and save Post
        // Unwrap optional pickedImage and convert to JPEG data with compression
        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            showAlert(description: "Please select an image before sharing.")
            return
        }

        // Create a ParseFile with the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Create Post object and set properties
        var post = Post()
        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.user = User.current
        // Attach captured metadata if available
        post.photoTime = pickedPhotoTime
        post.location = pickedPhotoLocation

        // Save Post asynchronously
        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPost):
                    print("✅ Post Saved! \(savedPost)")
                    // Return to previous screen
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }

    }

    @IBAction func onViewTapped(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

// PHPickerViewController delegate - handle picked image
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Make sure we have a non-nil item provider and it can load UIImage
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Attempt to fetch PHAsset metadata (creationDate, location) using the assetIdentifier
        if let assetId = results.first?.assetIdentifier {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            if let asset = assets.firstObject {
                // Capture creation date
                self.pickedPhotoTime = asset.creationDate
                // Capture location as ParseGeoPoint if available
                if let loc = asset.location {
                    self.pickedPhotoLocation = ParseGeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                } else {
                    self.pickedPhotoLocation = nil
                }
            }
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            // Check for and handle any errors first
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(description: error.localizedDescription)
                }
                return
            }

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else {
                DispatchQueue.main.async {
                    self?.showAlert()
                }
                return
            }

            // UI updates should be done on main thread
            DispatchQueue.main.async {
                // Set image on preview image view
                self?.previewImageView.image = image

                // Set image to use when saving post
                self?.pickedImage = image
            }
        }
    }
}
