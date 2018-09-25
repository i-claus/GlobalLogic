//
//  TableViewController.swift
//  Test
//
//  Created by Claudio Vega on 14-09-18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    private struct statics {
        static let cellIdentifier = "cellIdentifier"
    }

    private var isRefreshing = false
    var dataSource: [LaptopModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Laptops"
        tableView.register(UINib(nibName: String(describing: LaptopTableViewCell.self), bundle: nil), forCellReuseIdentifier: statics.cellIdentifier)
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        refreshControl = UIRefreshControl(frame: .zero)
        refreshControl?.addTarget(self, action: #selector(TableViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func refreshData() {
        if isRefreshing { return }
        isRefreshing = true
        refreshControl?.beginRefreshing()
        APIClient.shared.getList(completionHandler: {
            (success, laptpos) in
            if success {
                self.dataSource = laptpos
                self.tableView.reloadData()
            }
            self.refreshControl?.endRefreshing()
            self.isRefreshing = false
        })
    }

    // MARK: - Control Actions

    @objc func refreshControlValueChanged(_ sender: Any) {
        refreshData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: statics.cellIdentifier, for: indexPath) as! LaptopTableViewCell
        let laptop = dataSource[indexPath.row]
        cell.titleLabel.text = laptop.title
        cell.descriptionLabel.text = laptop.description
        if let imageURL = laptop.imageURL {
            cell.thumbImageView.image = AssetsClient.shared.image(dataForURL: imageURL)
            if cell.thumbImageView.image == nil {
                AssetsClient.shared.fetch(URL: imageURL, completionHandler: {
                    (data: Data?) in
                    if let data = data, let image = UIImage(data: data), let someCell = tableView.dequeueReusableCell(withIdentifier: statics.cellIdentifier, for: indexPath) as? LaptopTableViewCell {
                        someCell.thumbImageView.image = image
                    }
                })
            }
        }
        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let laptop = dataSource[indexPath.count]
        let controller = DetailsController()
        controller.laptop = laptop
        navigationController?.pushViewController(controller, animated: true)
    }
}
