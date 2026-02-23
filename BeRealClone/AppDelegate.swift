//
//  AppDelegate.swift
//  BeRealClone
//
//  Created by Charlie Hieger on 10/29/22.
//

import UIKit
import ParseSwift

// TODO: Pt 1 - Import Parse Swift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Replace these placeholder values with your actual Parse credentials from the Dashboard.
        let applicationId = "Cv0t70gb28gGx6UKAzcTHGRVseaLCChutVMIyoQq"
        let clientKey = "uuuMtFxfl6RZPXxexsD0tzlcNWPOcBJ2ukbnOEn4"
        let serverUrlString = "https://parseapi.back4app.com"

        // Validate the server URL before initializing ParseSwift.
        guard let serverURL = URL(string: serverUrlString), serverURL.scheme != nil, serverURL.host != nil else {
            print("⚠️ Invalid Parse server URL: \(serverUrlString). Please update AppDelegate.swift with a valid server URL (e.g. https://your-parse-server.com/parse) and restart the app.")
            return true
        }

        // Initialize ParseSwift
        ParseSwift.initialize(applicationId: applicationId,
                              clientKey: clientKey,
                              serverURL: serverURL)

        // Sample ParseSwift test save (remove or guard behind DEBUG for production)
        var score = GameScore()
        score.playerName = "Kingsley"
        score.points = 13

        score.save { result in
            switch result {
            case .success(let savedScore):
                print("✅ Parse Object SAVED!: Player: \(String(describing: savedScore.playerName)), Score: \(String(describing: savedScore.points))")
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

        // TODO: Pt 1: - Instantiate and save a test parse object to your server
        // https://github.com/parse-community/Parse-Swift/blob/main/ParseSwift.playground/Sources/Common.swift

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// Create your own value type `ParseObject`.
struct GameScore: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own custom properties.
    // All custom properties must be optional.
    var playerName: String?
    var points: Int?
}

// OPTIONAL: convenience initializer in an extension
extension GameScore {
    init(playerName: String, points: Int) {
        self.playerName = playerName
        self.points = points
    }
}
