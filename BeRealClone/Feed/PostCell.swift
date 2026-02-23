//
//  PostCell.swift
//  BeRealClon
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import Alamofire
import AlamofireImage
import CoreLocation

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    private var imageDataRequest: DataRequest?
    private var geocoder: CLGeocoder?

    func configure(with post: Post) {
        // Username
        if let user = post.user {
            usernameLabel.text = user.username
        } else {
            usernameLabel.text = ""
        }

        // Image
        postImageView.image = nil
        imageDataRequest?.cancel()
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                }
            }
        }

        // Caption
        captionLabel.text = post.caption

        // Date and location: prefer photoTime if available
        geocoder?.cancelGeocode()
        geocoder = nil

        var dateText: String = ""
        if let date = post.photoTime ?? post.createdAt {
            dateText = DateFormatter.postFormatter.string(from: date)
            dateLabel.text = dateText
        } else {
            dateLabel.text = ""
        }

        // If we have a location, attempt to reverse-geocode and append a short place name
        if let geo = post.location {
            let location = CLLocation(latitude: geo.latitude, longitude: geo.longitude)
            geocoder = CLGeocoder()
            geocoder?.reverseGeocodeLocation(location, completionHandler: { [weak self] placemarks, error in
                guard let self = self else { return }
                if let placemark = placemarks?.first {
                    var placeParts = [String]()
                    if let locality = placemark.locality { placeParts.append(locality) }
                    if let admin = placemark.administrativeArea { placeParts.append(admin) }
                    let place = placeParts.joined(separator: ", ")
                    DispatchQueue.main.async {
                        if place.isEmpty {
                            self.dateLabel.text = dateText
                        } else {
                            self.dateLabel.text = "\(dateText) • \(place)"
                        }
                    }
                }
            })
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()
        imageDataRequest = nil

        // Cancel any pending geocoding
        geocoder?.cancelGeocode()
        geocoder = nil
    }
}
