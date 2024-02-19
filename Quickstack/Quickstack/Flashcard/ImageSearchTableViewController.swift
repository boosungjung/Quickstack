//
//  ImageSearchTableViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 29/5/2023.
//

import UIKit

enum ImageError: Error {
    case invalidServerResponse
    case invalidShowURL
    case invalidImageURL
}

protocol ImageSearchDelegate: AnyObject {
    func didSelectImage(_ url: String)
}

class ImageSearchTableViewController: UITableViewController, UISearchResultsUpdating {
    
    weak var delegate: ImageSearchDelegate?

    let REQUEST_STRING = "https://api.pexels.com/v1/search"
    var indicator = UIActivityIndicatorView()
    
    weak var databaseController: DatabaseProtocol?
    let apiKey = "1uxldbIqcyOYcLxXd2AVEQxTtIUvBx95PTahsarMwKHQfNPxGXyNHKAu"

    // Construct the request URL
    let baseUrl = "https://api.pexels.com/v1"
    let endpoint = "/search?query=example"
    
    var images: [[Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        // This view controller decides how the search controller is presented
        definesPresentationContext = true

//        callApiRequest(query:"dog")
    }
    
    func callApiRequest(query:String){
        let perPage = 15
        images = []
        let urlString = "https://api.pexels.com/v1/search?query=\(query)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dict = json as? [String: Any],
                      let photos = dict["photos"] as? [[String: Any]] else {
                    print("Invalid JSON format")
                    return
                }

                // You can now parse the photo data and store it in a list or array
                for photo in photos {
                    if self.images.count > 20{
                        break
                    }
                    if let id = photo["id"] as? Int,
                       let src = photo["src"] as? [String: Any],
                       let urlString = src["tiny"] as? String,
                       let url = URL(string: urlString) {
                        // Store the photo data as needed
//                        print("ID: \(id)")
//                        print("URL: \(url)")
                        self.images.append([urlString, false, nil])
                    }
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }

        task.resume()
        tableView.reloadData()
//        completion()
        
    }
    func showActivityIndicator() {
        // Create and configure the activity indicator view
        indicator.style = .large
        indicator.color = .gray
        indicator.center = tableView.center
        indicator.startAnimating()
        
        // Add the activity indicator view as a subview of the table view
        tableView.addSubview(indicator)
    }

    func hideActivityIndicator() {
        // Stop and remove the activity indicator view
        indicator.stopAnimating()
        indicator.removeFromSuperview()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            // Show the activity indicator
            showActivityIndicator()
            
            // Perform the API request asynchronously
            callApiRequest(query: searchText)
            
            // Hide the activity indicator
            hideActivityIndicator()
            
            // Reload the table view
            tableView.reloadData()
        } else {
            // If the search text is empty, simply reload the table view
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 150.0
        }



    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return images.count
    }
    
//    override func viewWillLayoutSubviews() {
//        self.tableView(<#T##tableView: UITableView##UITableView#>, heightForHeaderInSection: <#T##Int#>)
//    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageSearchTableViewCell
        let imageURL = images[indexPath.row][0] as! String
        var imageDownloading = images[indexPath.row][1] as! Bool
        var currentImage = images[indexPath.row][2] as? UIImage
//        cell.imageUrl = imageURL
       


        // Make sure the image is blank after cell reuse.
        cell.imageSearchView?.image = nil

        if let image = currentImage {
            cell.imageSearchView?.image = image
        }
        else if imageDownloading == false{
            let requestURL = URL(string: imageURL)
            if let requestURL {
                Task {
//                    print("Downloading image: " + imageURL)
                    images[indexPath.row][1] = true
                    do {
                        let (data, response) = try await URLSession.shared.data(from: requestURL)
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw ImageError.invalidServerResponse
                        }
                        
                        if let image = UIImage(data: data) {
//                            print("Image downloaded: " + imageURL)
                            images[indexPath.row][2] = image
                            cell.imageSearchView?.image = image
                            await MainActor.run {
                                tableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                        else {
                            print("Image invalid: " + imageURL)
                            images[indexPath.row][1] = false
                        }
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                    
                }
            }
            else {
                print("Error: URL not valid: " + imageURL)
                
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = images[indexPath.row][0] as! String
        delegate?.didSelectImage(url)
        navigationController?.popViewController(animated: true)
    }
    
    // Call this method when an image is selected
    func imageSelected(_ url: String) {
        delegate?.didSelectImage(url)
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
