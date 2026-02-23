# Project 2 - BEREALCLONE

Submitted by: **Noah Adeyeye**

**SnapFeed** is an iOS social media app that allows users to create an account, log in, upload photo posts with optional captions, and view a feed of posts from all users. The app uses user authentication and persistent login to provide a seamless social feed experience.

Time spent: **X** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] Users see an app icon in the home screen and a styled launch screen.
- [x] User can register a new account
- [x] User can log in with newly created account
- [x] App has a feed of posts when user logs in
- [x] User can upload a new post which takes in a picture from photo library and an optional caption	
- [x] User is able to logout	
 
The following **optional** features are implemented:

- [x] Users can pull to refresh their feed and see a loading indicator
- [ ] Users can infinite-scroll in their feed to see past the 10 most recent photos
- [x] Users can see location and time of photo upload in the feed	
- [x] User stays logged in when app is closed and open again	

The following **additional** features are implemented:

- [x] Clean and responsive UI layout
- [x] Error handling for login and registration failures
- [x] Activity indicator during network requests

## Video Walkthrough

Here is a walkthrough of implemented features:

<!-- Replace with your Loom or YouTube link -->
[Video Walkthrough]((https://www.loom.com/share/7861cc7cf80a45739ddd181916e339e6))

## Notes

One of the main challenges in building this app was properly configuring user authentication and ensuring that session persistence worked correctly when the app was closed and reopened. Managing asynchronous network requests while updating the UI required careful handling on the main thread.

Another challenge was structuring the feed using a UITableView and ensuring posts loaded efficiently without blocking the interface. Debugging login and logout flows also required careful navigation management between view controllers.

This project significantly improved my understanding of user authentication, backend integration, table view data handling, and managing state in an iOS application.

## License

    Copyright 2026 Noah Adeyeye

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
