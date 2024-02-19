//
//  UserProfileTableViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 2/5/2023.
//

import UIKit

class UserProfileTableViewController: UITableViewController, DatabaseListener,UISearchResultsUpdating {
    
    
    var listenerType: ListenerType = .user
    
    weak var databaseController: DatabaseProtocol?
    
    let SECTION_STATS = 0
    let SECTION_DECK = 1
    let CELL_STATS = "statsCell"
    let CELL_DECKS = "decksCell"
    var allDecks: [Deck] = []
    var deletedDecks: [Deck] = []
    var selectedDeck:Deck?
    
    // let destination = self.storyboard?instantiateViewController(identifier
    // self.view.window?.rootViewController = desination
    // makekey
    
    @IBOutlet weak var userName: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_STATS)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        setUsernameField()
        
        
        tableView.reloadData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        
        // Ensure that the navigation bar is not hidden
        navigationController?.navigationBar.isHidden = false
        
        // Control the visibility of the search bar during scrolling
        navigationItem.hidesSearchBarWhenScrolling = true
        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true
        
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
 
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            
            // Reload the table view
            tableView.reloadData()
        } else {
            // If the search text is empty, simply reload the table view
            tableView.reloadData()
        }
    }
    
     // Protocols
    func onSetUserProfile(change: DatabaseChange, decks: [Deck]) {
        //pass
    }
    
    func onSetGame(change: DatabaseChange, flashcards: [Flashcard]) {
        //pass
    }
    
    func onAllDecksChange(change: DatabaseChange, decks: [Deck]) {
        var uniqueDecks = Set<Deck>()
        
        decks.forEach { deck in
            uniqueDecks.insert(deck)
        }
        
        // Remove deleted decks from uniqueDecks
        uniqueDecks.subtract(deletedDecks)
        
        // Convert the set back to an array
        allDecks = Array(uniqueDecks)
        
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        databaseController?.resetForNewLogin()
        tableView.reloadData()
//        print(allDecks)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func setUsernameField(){
        // This section of code sets the UIlable to the username
        databaseController?.getUsername(completion: { username in
                DispatchQueue.main.async {
                    self.userName.text = "Welcome " + username + "!"
                }
            })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
//        case SECTION_STATS:
//            return 1
        case SECTION_DECK:
            return allDecks.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->UITableViewCell {

       
        
        
        if indexPath.section == SECTION_STATS {
//            displayMessage(title: "Party Full", message: "Unable to add more members to party")
            let statsCell = tableView.dequeueReusableCell(withIdentifier: CELL_STATS, for: indexPath)
            var content = statsCell.defaultContentConfiguration()
//            let stats = allFlashcards[indexPath.row]
            content.text = "Stats"
//            content.secondaryText = "score = 0"
            statsCell.contentConfiguration = content
            return statsCell
        }
        else {
            // Configure and return an deck cell instead
            let deckCell = tableView.dequeueReusableCell(withIdentifier: CELL_DECKS, for: indexPath)
            var content = deckCell.defaultContentConfiguration()
            
           
            content.text = allDecks[indexPath.row].name
            
//            print(allDecks[indexPath.row].name)
//            if allDecks.isEmpty {
//                content.text = "No Decks. Tap + to add some." }
//            else {
//                content.text = allDecks[indexPath.row].name
//            }
            deckCell.contentConfiguration = content
            return deckCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        """
currently prepare for segue is being called before didselectRowAt, so selectedDeck is not updated before being segued. 
"""
        if indexPath.section == SECTION_STATS{
            return
        }
        selectedDeck = allDecks[indexPath.row]
        //deckSelectIdentifier
//        print(allDecks[indexPath.row].flashcards)
//        shouldPerformSegue(withIdentifier: "deckSelectIdentifier", sender: self)
        performSegue(withIdentifier: "deckSelectIdentifier", sender: self)
            
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "deckSelectIdentifier" {
                if let flashcardViewController = segue.destination as? FlashCardViewController {
                    // Pass the selected data to the second view controller
                    flashcardViewController.flashcards = selectedDeck?.flashcards
                    flashcardViewController.currentDeck = selectedDeck
//                    print(selectedDeck)
                }
            }
        }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == SECTION_DECK{
            let deck = allDecks[indexPath.row]
            deletedDecks.append(deck)
            allDecks.remove(at: indexPath.row) // Update the data source
            
//            tableView.beginUpdates() // Begin table view updates
            
            tableView.deleteRows(at: [indexPath], with: .fade) // Delete the row from the table view
            
//            tableView.endUpdates() // End table view updates
            
            databaseController?.deleteDeck(deck: deck)
            
//            print(allDecks)
        } else {
            return
        }
    }
    
    override func tableView(_ tableView: UITableView,
                             contextMenuConfigurationForRowAt indexPath: IndexPath,
                             point: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { suggestedActions in

            let location = self.allDecks[indexPath.row]
            
        
            let description = "hi"
            
            
            let shareAction =
            UIAction(title: "Share",
                     image: UIImage(systemName: "square.and.arrow.up")) { action in
                
                let activityViewCOntroller = UIActivityViewController(activityItems: [description], applicationActivities: nil)
                activityViewCOntroller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)?.contentView
                
                
                activityViewCOntroller.excludedActivityTypes = [.message, .postToFacebook]
                
                self.present(activityViewCOntroller, animated: true)
            }
            
            let leaderboardAction =
            UIAction(title: "Leaderboard",
                     image: UIImage(systemName: "trophy")) { action in
                
                let activityViewCOntroller = UIActivityViewController(activityItems: [description], applicationActivities: nil)
                activityViewCOntroller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)?.contentView
                
                
//             let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let leaderboardViewController = self.storyboard!.instantiateViewController(withIdentifier: "LeaderboardViewController") as! LeaderboardTableViewController

                let currentDeck = self.allDecks[indexPath.row]

                self.databaseController?.getLeaderboard(deckId: currentDeck.id!) { [weak self] data in
                    guard let self = self else {
                        return
                    }

                    if !data.isEmpty {
//                        print(data)
                        
                        leaderboardViewController.setLeaderboard(data: data)
                    } else {
                        // Handle the case when the data is empty (no leaderboard data found)
                        // For example, you could display an alert or show a message to the user
                        print("No leaderboard data found")
                    }
                    
                    // Make sure to present the leaderboardViewController on the main thread
                    DispatchQueue.main.async {
                        self.present(leaderboardViewController, animated: true, completion: nil)
                    }
                }

            }

            return UIMenu(title: "", children: [leaderboardAction])
        })
    }
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
