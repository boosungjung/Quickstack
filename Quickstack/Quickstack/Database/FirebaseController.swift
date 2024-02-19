//
//  FirebaseController.swift
//  Quickstack
//
//  Created by BooSung Jung on 26/4/2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirebaseController: NSObject, DatabaseProtocol{
    
    var allDecks: [Deck]
    var allFlashcards: [Flashcard]
    var userDecks: [Deck]
    var listeners = MulticastDelegate<DatabaseListener>()
    var authController: Auth
    var database: Firestore
    var currentUser: FirebaseAuth.User?
    var userRef: CollectionReference?
    var deckRef: CollectionReference?
    var username = "null"
    var defaultDeck: Deck
    var currentDeckID: String

    
    func cleanup() {
        // do nothing
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .user{
//            listener.onSetUserProfile(change: .update, decks: userDecks)
            listener.onAllDecksChange(change: .update, decks: userDecks)
        }
        if listener.listenerType == .game {
            listener.onSetGame(change: .update, flashcards: allFlashcards)
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    override init(){
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        defaultDeck = Deck(flashcards: [], name: "")
        allDecks = []
        allFlashcards = []
        userDecks = []
        currentDeckID = ""
        super.init()
        setupDeckListener()
        setupUserListener()
    }
    
    func resetForNewLogin(){
        userDecks = []
        setupUserListener()
    }
    
    func finishGame(userTime: [Double], score: Int, deckId: String) -> Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return false // User is not logged in
        }
        
        let deckRef = Firestore.firestore().collection("decks").document(deckId)
        
        let leaderboardData: [String: Any] = [
            "userID": currentUserID,
            "username": username,
            "score": score,
            "userTime": userTime
        ]
        
        // Update the leaderboard array in the deck document
        deckRef.updateData(["leaderboard": FieldValue.arrayUnion([leaderboardData])]) { error in
            if let error = error {
                print("Error updating leaderboard array: \(error)")
            } else {
                // Update successful
            }
        }
        
        return true
    }
    
    func loadUser(userName: String) {
        Auth.auth().addStateDidChangeListener { auth, user in
            if Auth.auth().currentUser?.uid != nil {
                // user is logged in
                self.currentUser = Auth.auth().currentUser
                let userID = Auth.auth().currentUser!.uid
                self.userRef = self.database.collection("users")
                self.addUser(userId: userID, userName: userName)
            } else {
                // user is not logged in
            }
        }
    }
    
    
    func addFlashcard(answer: String, imageUrl: String, question: String) -> Flashcard{
        // Get a reference to the specific deck document
//        guard let currentDeckID = currentDeckID else {
//            return
//        }
        let deckRef = Firestore.firestore().collection("decks").document(currentDeckID)
        
        // Create a new flashcard object and set its properties
        let flashcard = Flashcard()
        flashcard.answer = answer
        flashcard.imageUrl = imageUrl
        flashcard.question = question
        
        // Get a reference to the collection of flashcards inside the deck document
        let flashcardsCollectionRef = deckRef.collection("flashcards")
        
        // Add the flashcard data to the flashcards collection
        flashcardsCollectionRef.addDocument(data: flashcard.dictionaryRepresentation) { (error) in
            if let error = error {
                print("Error adding flashcard: \(error)")
            } else {
                print("Flashcard added successfully")
            }
        }
        return flashcard
    }


    
    func addDeck(flashcards: [Flashcard], name: String) -> Bool {
        let deck = Deck(flashcards: flashcards, name: name)
        
        do {
            // Add the deck to the main collection of decks
            let deckRef = try Firestore.firestore().collection("decks").addDocument(from: deck)
            deck.id = deckRef.documentID
            currentDeckID = deck.id!
            
            guard let userID = Auth.auth().currentUser?.uid else{
                return false
            }
//            print(userID)
            // Get a reference to the user document
            let userRef = Firestore.firestore().collection("users").document(userID)
            
            // Create a reference to the deck document
            let deckReference = Firestore.firestore().collection("decks").document(deckRef.documentID)
            deckReference.setData(["leaderboard":[],
                                   "name":name])
            
            // Update the userDecks array field in the user document
            userRef.updateData(["userDecks": FieldValue.arrayUnion([deckReference])]) { error in
                if let error = error {
                    print("Error updating userDecks array: \(error)")
                } else {
                    // Update successful
                }
            }
        } catch {
            print("Failed to serialize deck")
            return false
        }
        return true
    }
    
    
    
    func addUser(userId: String, userName: String) {
        // Create a reference to the users collection
        let usersRef = self.database.collection("users")

        // Create a new user document with the user's ID
        let userDocRef = usersRef.document(userId)

        userDocRef.getDocument { [weak self] (document, error) in
            guard self != nil else {
                return
            }
            
            if let document = document, document.exists {
                // User already exists, return or handle accordingly
                return
            } else {
                // Set the name and stats fields on the user document
                userDocRef.setData(["name": userName,
                                    "userDecks": []])
                
                // User added successfully, continue with any necessary actions
                // For example, you could display a success message or perform additional operations
                print("User added successfully")
            }
        }
    }
    
    func getUsername(completion: @escaping (String) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
                return // No user signed in
            }
        database.collection("users").document(userUID).getDocument { snapshot, error in
            if error != nil {
//                print("Failed to get username")
                completion(self.username)
            } else {
                self.username = snapshot?.get("name") as? String ?? self.username
//                print(self.username)
                completion(self.username)
            }
        }
    }
    
    func getLeaderboard(deckId: String, completion: @escaping ([[String: Int]]) -> Void) {
        let deckRef = database.collection("decks").document(deckId)
        
        deckRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let leaderboardArray = document.data()?["leaderboard"] as? [[String: Any]] {
        
                    var leaderboardData: [[String: Int]] = []
                    
                    for leaderboardEntry in leaderboardArray {
                        
                        if let lbUsername = leaderboardEntry["username"] as? String,
                           let score = leaderboardEntry["score"] as? Int {
                            leaderboardData.append([lbUsername: score])
//                            print("inside")
                        }
                    }
                    
                    completion(leaderboardData) // Pass the leaderboardData to the completion handler
                } else {
                    print("No leaderboard data found")
                    completion([]) // Pass an empty array if no leaderboard data found
                }
            } else {
                print("Document does not exist")
                completion([]) // Pass an empty array if the document does not exist
            }
        }
    }

    func setupDeckListener(){
        deckRef = database.collection("decks")
        deckRef?.addSnapshotListener() { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            self.parseDecksSnapshot(snapshot: querySnapshot)
            if self.deckRef == nil {
                self.setupDeckListener()
            }
        }
    }
    
    func setupUserListener() {
        
        guard let userID = Auth.auth().currentUser?.uid else{
            print("User id Error")
            return
        }
        
        print("current user ",userID)
        let userRef = database.collection("users").document(userID)
        userRef.addSnapshotListener { (documentSnapshot, error) in
            guard let documentSnapshot = documentSnapshot, documentSnapshot.exists else {
                print("Error fetching user document")
                return
            }
            
            if let userDecks = documentSnapshot.data()?["userDecks"] as? [DocumentReference] {
                self.fetchUserDecks(userDecks)
            }
        }
    }

    func fetchUserDecks(_ deckRefs: [DocumentReference]) {
        for deckRef in deckRefs {
            if let deck = self.getDeckByID(deckRef.documentID) {
                self.userDecks.append(deck)
            }
            else {
                print("Error fetching deck document")
            }
        }
    }



    
//    func setupUserListener(){
//
//        userRef = database.collection("users")
//        userRef?.addSnapshotListener() { (querySnapshot, error) in
//            guard let querySnapshot = querySnapshot, let deckSnapshot = querySnapshot.documents.first else {
//                print("Error fetching decks: \(error!)")
//                return
//            }
//            self.parseUserDecksSnapshot(snapshot: deckSnapshot)
//        }
//    }
    
//    func setupUserListener() {
//        guard let currentUserID = Auth.auth().currentUser?.uid else {
//            return
//        }
//        let currUserRef = database.collection("users").document(currentUserID)
//
//        currUserRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
//            guard let self = self, let documentSnapshot = documentSnapshot as? QueryDocumentSnapshot else {
//                return
//            }
//
//            self.parseUserDecksSnapshot(snapshot: documentSnapshot)
//        }
//    }
    
    func parseUserDecksSnapshot(snapshot: DocumentSnapshot) {
        if let deckRefs = snapshot.data()?["userDecks"] as? [DocumentReference] {
            for deckRef in deckRefs {
                deckRef.getDocument { (deckSnapshot, error) in
                    if let deckDocument = deckSnapshot, deckDocument.exists {
                        if let deck = self.getDeckByID(deckDocument.documentID) {
                            self.userDecks.append(deck)
                        }
                    } else {
                        print("Error fetching deck document")
                    }
                }
            }
        }
    }
//            listeners.invoke { (listener) in
//                if listener.listenerType == ListenerType.team || listener.listenerType == ListenerType.all{
//                    listener.onTeamChange(change: .update, teamHeroes: defaultTeam.heroes)
//                }
//            }
            

    
    func parseFlashcardsSnapshot(snapshot: QuerySnapshot, currentDeck: Deck){
        snapshot.documentChanges.forEach { (change) in
            var parsedFlashcard: Flashcard?
            do {
//                let data = change.document.data()
//                print(data.debugDescription)
         
                parsedFlashcard = try change.document.data(as: Flashcard.self)
                guard let flashcard = parsedFlashcard else {
                    print("Document doesn't exist")
                    return;
                }
//                print("YAY")
                currentDeck.flashcards.append(flashcard)
//                print(flashcard.imageUrl)
                
//                listeners.invoke { (listener) in
//                    if listener.listenerType == ListenerType.deck {
//                        listener.onAllDecksChange(change: .update, decks: [defaultDeck])
//                    }
//                }

            } catch {
                print("Unable to decode Flashcard")
                return
            }

        }
    }
    
    func parseDecksSnapshot(snapshot: QuerySnapshot) {
        """
        In firestore we have
        Collection:
            users
            decks -> Document -> Collection:
                                    flashcards -> answer:str, image:str, question:str
                                Field:
                                    name: string
        Therefore, once we get the parsedDeck and check if the document exists we then call parseFlashcardsSnapshot() in order
        to go through the collection of flashcards
        """
        snapshot.documentChanges.forEach { (change) in
                var parsedDeck: Deck?
                do {
                    parsedDeck = try change.document.data(as: Deck.self)
                    let subcollectionRef = change.document.reference.collection("flashcards")
                    guard let deck = parsedDeck else {
                        print("Document doesn't exist")
                        return
                    }
                    subcollectionRef.addSnapshotListener { (querySnapshot, error) in
                        guard let querySnapshot = querySnapshot else {
                            print("Failed to fetch documents with error: \(String(describing: error))")
                            return
                        }
                        self.parseFlashcardsSnapshot(snapshot: querySnapshot, currentDeck: deck)
                    }
                    deck.id = change.document.documentID
                    
                    
                    // Check if the deck already exists in the allDecks array
                    if let existingDeckIndex = allDecks.firstIndex(where: { $0.id == deck.id }) {
                        // Update the existing deck if it's modified
                        if change.type == .modified {
                            allDecks[existingDeckIndex] = deck
                        } else if change.type == .removed {
                            allDecks.remove(at: existingDeckIndex)
                        }
                        
                    } else {
                        // Add the deck to the allDecks array if it doesn't already exist
                        if change.type == .added {
                            allDecks.insert(deck, at: Int(change.newIndex))
                        }
                    }
                } catch {
                    print("Unable to decode deck. Is the deck malformed?")
                    return
                }
            }
    }
    
    
    func getDeckByID(_ id: String) -> Deck?{
        print(id)
        for deck in allDecks{
            if deck.id == id {
                return deck
            }
        }
        return nil
    }
//    func deleteDeckReference(userDocumentRef: DocumentReference, deckReference: DocumentReference) {
//        // Retrieve the user document
//        userDocumentRef.getDocument { (document, error) in
//            if let error = error {
//                print("Error retrieving user document: \(error)")
//                return
//            }
//
//            guard let document = document,
//                  document.exists,
//                  var userDecks = document.data()?["userDecks"] as? [DocumentReference] else {
//                print("User document or userDecks array not found")
//                return
//            }
//
//            // Remove the specific deck reference from the userDecks array
//            userDecks.removeAll { $0.path == deckReference.path }
//
//            // Update the user document with the modified userDecks array
//            userDocumentRef.updateData(["userDecks": userDecks]) { error in
//                if let error = error {
//                    print("Error updating user document: \(error)")
//                    return
//                }
//
//                // Deck reference deleted successfully
//                print("Deck reference deleted successfully")
//            }
//        }
//    }
    func deleteDeck(deck: Deck) {
        if let deckID = deck.id {
            let deckDocumentRef = deckRef?.document(deckID)
//            deleteDeckReference(userDocumentRef: userRef, deckReference: userRef?.document("userDecks"))
            
//            // Fetch the user document
//            guard let userUID = Auth.auth().currentUser?.uid else {
//                    return // No user signed in
//                }
//            userRef?.document(userUID).getDocument { (snapshot, error) in
//                if let error = error {
//                    // Handle the error
//                    print("Error fetching user document: \(error)")
//                    return
//                }
//
//                // Check if the user document exists
//                guard let document = snapshot, document.exists else {
//                    print("User document not found")
//                    return
//                }
//
//                // Retrieve the current userDecks array
//                var userDecks = document.data()?["userDecks"] as? [String] ?? []
//
//                // Remove the specific documentID from userDecks
//                userDecks.removeAll { $0 == deckID }
//
//                // Update the user document with the modified userDecks array
//                self.userRef?.document(userUID).updateData(["userDecks": userDecks]) { error in
//                    if let error = error {
//                        // Handle the error
//                        print("Error updating user document: \(error)")
//                    } else {
//                        // Deletion successful
//                        print("Document ID deleted from userDecks successfully")
//                    }
//                }
//            }
            
            // Delete the deck document
            deckDocumentRef?.delete(completion: { (error) in
                if let error = error {
                    print("Error deleting deck document: \(error)")
                    return
                }
                
                // Delete the flashcards subcollection
                deckDocumentRef?.collection("flashcards").getDocuments(completion: { (querySnapshot, error) in
                    if let error = error {
                        print("Error retrieving flashcards subcollection: \(error)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found in flashcards subcollection")
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit(completion: { (error) in
                        if let error = error {
                            print("Error deleting flashcards subcollection: \(error)")
                        } else {
                            print("Flashcards subcollection deleted successfully")
                        }
                    })
                })
            })
            
            
//            listeners.invoke { (listener) in
//                    listener.onAllDecksChange(change: .remove, decks: [deck])
//                
//            }
            
        }
           
    }

    
    func parseStatsSnapshot(snapshot: QuerySnapshot){
        //pass
    }
    
    
}
