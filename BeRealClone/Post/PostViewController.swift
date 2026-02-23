//
//  PostViewController.swift
//  BeRealClone
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import PhotosUI
import ParseSwift
import UniformTypeIdentifiers

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
        // The ParseFile initializer is non-throwing in this SDK version; initialize directly.
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

        // Make sure we have a non-nil item provider (we'll attempt multiple loading strategies below)
        guard let provider = results.first?.itemProvider else { return }

        // Attempt to fetch PHAsset metadata (creationDate, location) using the assetIdentifier.
        // If we have an assetIdentifier, preferentially use PhotoKit to request image data which handles many representations reliably.
        if let assetId = results.first?.assetIdentifier {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            if let asset = assets.firstObject {
                // Capture creation date
                self.pickedPhotoTime = asset.creationDate
                // Capture location as ParseGeoPoint if available
                if let loc = asset.location {
                    // ParseGeoPoint initializer may throw in some SDK versions; use `try?` to safely handle failures.
                    self.pickedPhotoLocation = try? ParseGeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                } else {
                    self.pickedPhotoLocation = nil
                }

                // Request image data via PhotoKit which returns the original image data regardless of provider representation.
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                // First try requestImage to get a UIImage directly (works well for most images including PNG).
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { [weak self] image, info in
                    DispatchQueue.main.async {
                        if let img = image {
                            self?.previewImageView.image = img
                            self?.pickedImage = img
                        }
                    }
                }
                // Also request image data (keeps original behavior) in case you need the raw bytes.
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, dataUTI, orientation, info in
                    DispatchQueue.main.async {
                        if let data = data, let img = UIImage(data: data) {
                            // Prefer the already set image but ensure pickedImage is populated
                            if self?.pickedImage == nil {
                                self?.previewImageView.image = img
                                self?.pickedImage = img
                            } else {
                                self?.pickedImage = img
                            }
                        }
                    }
                }
                // We attempted PhotoKit request; still continue to provider fallback in case PhotoKit failed to return data synchronously.
            }
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            // If we got a UIImage directly, use it. Otherwise try a data-representation fallback before showing an alert.
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.previewImageView.image = image
                    self?.pickedImage = image
                }
                return
            }

            // Attempt fallback: try common image type identifiers first, then any registered identifiers.
            var prioritized: [String] = []
            if let jpeg = UTType.jpeg.identifier as String? { prioritized.append(jpeg) }
            if let png = UTType.png.identifier as String? { prioritized.append(png) }
            if let image = UTType.image.identifier as String? { prioritized.append(image) }
            // Append provider registered identifiers but avoid duplicates
            for id in provider.registeredTypeIdentifiers where !prioritized.contains(id) {
                prioritized.append(id)
            }
            let typeIdentifiersToTry = prioritized

            // Helper to try identifiers sequentially.
            func tryIdentifier(at index: Int) {
                guard index < typeIdentifiersToTry.count else {
                    // Exhausted all options — report error.
                    DispatchQueue.main.async {
                        let errMsg = error?.localizedDescription ?? "Cannot load selected image."
                        self?.showAlert(description: errMsg)
                    }
                    return
                }

                let typeId = typeIdentifiersToTry[index]
                print("[PostViewController] trying type identifier: \(typeId) (index: \(index))")

                // First try loadDataRepresentation
                provider.loadDataRepresentation(forTypeIdentifier: typeId) { data, dataError in
                    if let data = data, let img = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.previewImageView.image = img
                            self?.pickedImage = img
                        }
                        return
                    }
                    if let dataError = dataError {
                        print("[PostViewController] loadDataRepresentation failed for \(typeId): \(dataError.localizedDescription)")
                    } else {
                        print("[PostViewController] loadDataRepresentation returned no data for \(typeId)")
                    }

                    // If data representation failed, try file representation
                    provider.loadFileRepresentation(forTypeIdentifier: typeId) { url, fileError in
                        if let url = url {
                            print("[PostViewController] loadFileRepresentation returned URL for \(typeId): \(url)")
                            // First try to read the file directly. Some URLs require security-scoped access.
                            var didAccess = false
                            if url.startAccessingSecurityScopedResource() {
                                didAccess = true
                            }
                            defer {
                                if didAccess { url.stopAccessingSecurityScopedResource() }
                            }

                            // Try direct read
                            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self?.previewImageView.image = img
                                    self?.pickedImage = img
                                }
                                return
                            }
                            print("[PostViewController] direct read failed for URL: \(url)")

                            // If direct read failed, fall back to copying the file to a temp location with a unique name.
                            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)
                            do {
                                if FileManager.default.fileExists(atPath: tmpURL.path) {
                                    try FileManager.default.removeItem(at: tmpURL)
                                }
                                try FileManager.default.copyItem(at: url, to: tmpURL)
                                if let data = try? Data(contentsOf: tmpURL), let img = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self?.previewImageView.image = img
                                        self?.pickedImage = img
                                    }
                                    return
                                }
                            } catch {
                                print("[PostViewController] copy fallback failed for URL: \(url) with error: \(error.localizedDescription)")
                                // ignore and fall through to try next identifier
                            }
                        } else if let fileError = fileError {
                            print("[PostViewController] loadFileRepresentation returned no URL for \(typeId), error: \(fileError.localizedDescription)")
                        }

                        // As a last resort for this type identifier, try the older loadItem API which can return Data/URL/UIImage
                        provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, itemError in
                            if let url = item as? URL {
                                print("[PostViewController] loadItem returned URL for \(typeId): \(url)")
                                // Try reading URL contents
                                var didAccess = false
                                if url.startAccessingSecurityScopedResource() {
                                    didAccess = true
                                }
                                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                                if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self?.previewImageView.image = img
                                        self?.pickedImage = img
                                    }
                                    return
                                }
                                print("[PostViewController] loadItem URL read failed for \(typeId)")
                            } else if let data = item as? Data, let img = UIImage(data: data) {
                                print("[PostViewController] loadItem returned Data for \(typeId)")
                                DispatchQueue.main.async {
                                    self?.previewImageView.image = img
                                    self?.pickedImage = img
                                }
                                return
                            } else if let img = item as? UIImage {
                                print("[PostViewController] loadItem returned UIImage for \(typeId)")
                                DispatchQueue.main.async {
                                    self?.previewImageView.image = img
                                    self?.pickedImage = img
                                }
                                return
                            }

                            // Nothing worked for this identifier — move to next
                            print("[PostViewController] all attempts failed for \(typeId) — trying next")
                            tryIdentifier(at: index + 1)
                        }
                    }
                }

                tryIdentifier(at: 0)
                 // End provider.loadObject completion
             }
        }
    }
}
