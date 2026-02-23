//
//  FeedViewController.swift
//  BeRealClone
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import ParseSwift


class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }

    // Pagination & loading state
    private let pageSize = 10
    private var isLoading = false
    private var hasMore = true
    private var refreshControl = UIRefreshControl()

    private lazy var loadingFooter: UIView = {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 60))
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.center = footer.center
        indicator.startAnimating()
        footer.addSubview(indicator)
        return footer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        // Pull to refresh
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load initial posts
        loadInitialPosts()
    }

    @objc private func refreshPulled() {
        // Reset pagination and reload
        hasMore = true
        loadInitialPosts()
    }

    private func loadInitialPosts() {
        posts = []
        tableView.tableFooterView = nil
        fetchPosts(skip: 0)
    }

    private func fetchPosts(skip: Int) {
        guard !isLoading else { return }
        isLoading = true
        if skip > 0 {
            tableView.tableFooterView = loadingFooter
        }

        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(pageSize)
            .skip(skip)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                self.refreshControl.endRefreshing()
                self.tableView.tableFooterView = nil

                switch result {
                case .success(let newPosts):
                    if skip == 0 {
                        self.posts = newPosts
                    } else {
                        self.posts.append(contentsOf: newPosts)
                    }
                    // If fewer than pageSize returned, we've reached the end
                    self.hasMore = newPosts.count == self.pageSize
                case .failure(let error):
                    self.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    // Load next page when needed
    private func loadMoreIfNeeded(currentIndex: Int) {
        let thresholdIndex = posts.count - 3
        if currentIndex >= thresholdIndex && hasMore && !isLoading {
            fetchPosts(skip: posts.count)
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        // Trigger pagination when nearing the end
        loadMoreIfNeeded(currentIndex: indexPath.row)
        return cell
    }
}

extension FeedViewController: UITableViewDelegate { }
