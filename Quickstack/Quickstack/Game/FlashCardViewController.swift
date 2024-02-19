//
//  FlashCardViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 8/5/2023.
//

// Add swipe gesture to go to next card

import UIKit

class FlashCardViewController: UIViewController, DatabaseListener{
    
    let duration: TimeInterval = 5.0 // Time interval for each card
    var userTimeData:[Double] = []
    var animator: UIViewPropertyAnimator?
    var startTime: DispatchTime?
    var currentDeck: Deck?
   
    
    @IBOutlet weak var timerProgressBar: UIProgressView!
    var isButtonPressed = false
    
    var listenerType: ListenerType = .game
    
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var comboLabel: UILabel!
    @IBOutlet weak var flashcardImageView: UIImageView!
    @IBOutlet weak var flashcardView: UIView!
    @IBOutlet weak var flashcardLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    var isAnswer = false
    var score = 0
    var scoreMultiplier = 1
    var questionNum = 0
    
    var flashcards: [Flashcard]?
    var canSwipeRight: Bool = true
    var canSwipeLeft: Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        flashcardView.addGestureRecognizer(swipeGestureRecognizer)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // load the questions
//        print(flashcards)
        getNextFlashcard()
        
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func loadImage(){
        // Make sure the image is blank after cell reuse.
        flashcardImageView.image = nil
        let currentFlashcard = flashcards?[questionNum]
        if let image = currentFlashcard?.image {
            flashcardImageView.image = image
        }
        else if currentFlashcard?.imageIsDownloading == false, let imageURL = currentFlashcard?.imageUrl {
            let requestURL = URL(string: imageURL)
            if let requestURL {
                Task {
                    print("Downloading image: " + imageURL)
                    currentFlashcard?.imageIsDownloading = true
                    do {
                        let (data, response) = try await URLSession.shared.data(from: requestURL)
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            currentFlashcard?.imageIsDownloading = false
                            throw FlashcardError.invalidServerResponse
                        }

                        if let image = UIImage(data: data) {
                            print("Image downloaded: " + imageURL)
                            currentFlashcard?.image = image
                            await MainActor.run {
                                flashcardImageView.image = image
                            }
                        }
                        else {
                            print("Image invalid: " + imageURL)
                            currentFlashcard?.imageIsDownloading = false
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
    }
    
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onSetUserProfile(change: DatabaseChange, decks: [Deck]) {
        // do nothing
    }
    func onAllDecksChange(change: DatabaseChange, decks: [Deck]) {
        //pass
    }
    
    func onSetGame(change: DatabaseChange, flashcards: [Flashcard]) {
        self.flashcards = flashcards
    }
    
    @objc func flashcardViewTapped() {
        // Do something in response to the tap on flashcardView
        print("Flashcard View Tapped!")
        
        if isAnswer {
            flipFlashcard(toQuestion: true)
        } else {
            flipFlashcard(toQuestion: false)
        }
    }

    @objc func handleSwipeGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self.view)
        let velocity = gestureRecognizer.velocity(in: self.view)
        
        if gestureRecognizer.state == .ended {
            if translation.x > 0 && velocity.x > 500 {
                // Swipe right (show answer)
                showAnswer()
                canSwipeRight = false
                canSwipeLeft = true
            } else if translation.x < 0 && velocity.x < -500 {
                // Swipe left (show question)
                showQuestion()
                canSwipeRight = true
                canSwipeLeft = false
            } else {
                // Swipe didn't meet velocity requirements, flip the card
                if isAnswer {
                    showQuestion()
                    canSwipeRight = true
                    canSwipeLeft = false
                } else {
                    showAnswer()
                    canSwipeRight = false
                    canSwipeLeft = true
                }
            }
        }
    }

    func showQuestion() {
//        if canSwipeLeft{
            UIView.transition(with: flashcardView, duration: 0.3, options: .transitionFlipFromRight, animations: {
//                self.flashcardView.backgroundColor = UIColor.white
                print(self.questionNum)
                self.flashcardLabel.text = self.flashcards?[self.questionNum-1].question
            }, completion: nil)
            isAnswer = false
//        }
    }

    func showAnswer() {
//        if canSwipeRight{
            UIView.transition(with: flashcardView, duration: 0.3, options: .transitionFlipFromLeft, animations: {
//                self.flashcardView.backgroundColor = UIColor.systemBlue
                print(self.questionNum)
                self.flashcardLabel.text = self.flashcards?[self.questionNum-1].answer
            }, completion: nil)
            isAnswer = true
//        }
    }

    func flipFlashcard(toQuestion: Bool) {
        let flipAnimation = CATransition()
        flipAnimation.duration = 0.5
        flipAnimation.type = CATransitionType(rawValue: "flip")
        flipAnimation.subtype = toQuestion ? .fromRight : .fromLeft
        flipAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        
        flashcardView.layer.add(flipAnimation, forKey: "flipAnimation")
        
        if toQuestion {
            showQuestion()
        } else {
            showAnswer()
        }
    }
    
    func getNextFlashcard(){
        guard let flashcards = flashcards else {
            // Handle case where flashcards are not available.
            return
        }
        captureTimeData()
        "Every time we get a new flashcard, we need to reset the timer"
        // Stop the current animation, if any


       
       // Customize the appearance of the UIProgressView
       timerProgressBar.progressTintColor = .blue // Customize the progress bar color
       timerProgressBar.trackTintColor = .white // Customize the track color
        timerProgressBar.setProgress(0.0, animated: true)

//        // Stop the current animator, if any
//        animator?.stopAnimation(true)
//        animator?.finishAnimation(at: .current)
//
        // Create a new animator with the desired duration and curve
        animator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            self.timerProgressBar.setProgress(1.0, animated: true)
        }
//
//        // Start the animation
        animator?.startAnimation()
     
        
        
        
        
        if questionNum >= flashcards.count {
            let isFinished = databaseController?.finishGame(userTime: userTimeData, score: score, deckId: currentDeck?.id ?? "Err")
            print(isFinished)
            
            performSegue(withIdentifier: "viewstatsIdentifier", sender: self)
            // If we've reached the end of the flashcard list, display a popup message
            // displayMessage(title: "You're done!", message: "You've reached the end of the flashcard list.")
            
            // No need to schedule the dispatch queue if we've reached the end of the flashcard list
            
            return
        }
        
        // Reset the button pressed flag
        isButtonPressed = false
        
        // Schedule a dispatch queue after the specified time interval
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
//            if let isPressed = self?.isButtonPressed, !isPressed {
//                UIView.animate(withDuration: 0.5, animations: {
//                    // Turn the whole screen red
//                    self?.view.backgroundColor = .red
//                }, completion: { _ in
//                    UIView.animate(withDuration: 0.5) {
//                        // Fade the screen back to the original color
//                        self?.view.backgroundColor = .white
//                    }
//                })
//            }
//        }
        
        // This part animates the flashcards to appear from a smaller size
        // Set the initial scale for the flashcard view
        flashcardView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        // Perform any necessary image loading or updates here
        
        // Animate the flashcard view back to its original size
        UIView.animate(withDuration: 0.5) {
            self.flashcardView.transform = .identity
        }
        
        loadImage()
        flashcardLabel.text = flashcards[questionNum].question
        questionNum += 1
        
    }
    
    func captureTimeData() {
        if let startTime = startTime {
            let endTime = DispatchTime.now()
            let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            let seconds = Double(nanoseconds) / 1_000_000_000
            userTimeData.append(seconds)
            print(seconds)
        }
        
        startTime = DispatchTime.now()
    }
    

    
    @IBAction func wrongBtn(_ sender: Any) {
//        captureTimeData()
        scoreMultiplier = 1
        getNextFlashcard()
    }
    
    
    @IBAction func correctBtn(_ sender: Any) {
        score+=300 * scoreMultiplier
        scoreMultiplier += 1
        comboLabel.text = "Combo " + String(scoreMultiplier)
        animateComboLabel()
        scoreLabel.text = "Score " + String(score)
//        captureTimeData()
        getNextFlashcard()
    }

    func animateComboLabel() {
            // Create a transform for scaling the label
            let scaleTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            
            // Create a random rotation angle between -π/4 and π/4
            let rotationAngle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
            let rotationTransform = CGAffineTransform(rotationAngle: rotationAngle)
            
            // Combine the scale and rotation transforms
            let combinedTransform = scaleTransform.concatenating(rotationTransform)
            
            // Create an animation block
            UIView.animate(withDuration: 0.2, animations: {
                // Apply the combined transform to the label
                self.comboLabel.transform = combinedTransform
            }) { _ in
                // Create a reset transform for returning the label to its original state
                let resetTransform = CGAffineTransform.identity
                
                // Create a second animation block for the reset animation
                UIView.animate(withDuration: 0.2, animations: {
                    // Apply the reset transform to the label
                    self.comboLabel.transform = resetTransform
                })
            }
        }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "viewstatsIdentifier" {
                if let statisticsViewController = segue.destination as? StatisticsViewController {
                    // Pass the selected data to the second view controller
                    statisticsViewController.timeData = userTimeData
                    statisticsViewController.score = score
                }
            }
        }
    

}
