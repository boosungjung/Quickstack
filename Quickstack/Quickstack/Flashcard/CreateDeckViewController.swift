//
//  CreateDeckViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 13/5/2023.
//

import UIKit

class CreateDeckViewController: UIViewController, ImageSearchDelegate {
    
    @IBOutlet weak var deckNameField: UITextField!
    @IBOutlet weak var answerField: UITextField!
    @IBOutlet weak var questionField: UITextField!
    var imageUrl:String?
    var newflashcards:[Flashcard] = []
    weak var databaseController: DatabaseProtocol?
    let imageSearchVC = ImageSearchTableViewController()
    @IBOutlet weak var flashcardImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.hidesBackButton = true
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
    }
    
    func loadImage(){
        // Make sure the image is blank after cell reuse.
        flashcardImageView?.image = nil
        let imageURL = imageUrl ?? ""
        
        let requestURL = URL(string: imageURL) // code from labs
        if let requestURL {
            Task {
                print("Downloading image: " + imageURL)
                
                do {
                    let (data, response) = try await URLSession.shared.data(from: requestURL)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        
                        throw FlashcardError.invalidServerResponse
                    }

                    if let image = UIImage(data: data) {
                        print("Image downloaded: " + imageURL)
                        flashcardImageView?.image = image
                        await MainActor.run {
                            flashcardImageView.image = image
                        }
                    }
                    else {
                        print("Image invalid: " + imageURL)
                    
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
    
    @IBAction func done(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func createFlashcard(_ sender: Any) {
        let flashcard = Flashcard()
        
        if let answer = answerField.text, !answer.isEmpty {
            flashcard.answer = answer
        } else {
            showErrorAlert(message: "Please enter an answer.")
            return
        }
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            flashcard.imageUrl = imageUrl
        }
        
        if let question = questionField.text, !question.isEmpty {
            flashcard.question = question
        } else {
            showErrorAlert(message: "Please enter a question.")
            return
        }
        
        let flashcardAdded = databaseController?.addFlashcard(answer: flashcard.answer ?? "", imageUrl: flashcard.imageUrl ?? "placeholder", question: flashcard.question ?? "")

//        print(imageUrl)
        // reset all values
        answerField.text = ""
        questionField.text = ""
        newflashcards.append(flashcard)
        
    }
    
    @IBAction func createDeck(_ sender: Any) {
        guard let deckname = deckNameField.text, !deckname.isEmpty else{
            showErrorAlert(message: "Deck name is required.")
            return
        }
        let deckAdded = databaseController?.addDeck(flashcards: newflashcards, name: deckname) ?? false
        if deckAdded {
            navigationController?.popViewController(animated: false)
            return
        }
    }
    @IBAction func addFlashcardToDeck(_ sender: Any) {
        
        
    }
    
    @IBAction func getImage(_ sender: Any) {

    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageSearchSegue"{
            
            let destination = segue.destination as? ImageSearchTableViewController
            destination?.delegate = self
        }
    }
    
    func didSelectImage(_ url: String) {
        imageUrl = url
        loadImage()
//        dismiss(animated: true, completion: nil)
    }
    
    func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
