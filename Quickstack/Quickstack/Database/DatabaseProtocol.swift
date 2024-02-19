//
//  DatabaseProtocol.swift
//  Quickstack
//
//  Created by BooSung Jung on 26/4/2023.
//

import Foundation

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case user
    case game
    case deck
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onSetUserProfile(change:DatabaseChange, decks:[Deck])
    func onSetGame(change:DatabaseChange, flashcards:[Flashcard])
    func onAllDecksChange(change:DatabaseChange, decks:[Deck])
}

protocol DatabaseProtocol: AnyObject {
    
    func cleanup()
    func addListener(listener: DatabaseListener)
    func addFlashcard(answer:String, imageUrl:String, question:String) -> Flashcard
    func addDeck(flashcards:[Flashcard], name:String) -> Bool
    func removeListener(listener: DatabaseListener)
    func loadUser(userName: String)
    func getUsername(completion: @escaping (String) -> Void)
    func getLeaderboard(deckId: String, completion: @escaping ([[String: Int]]) -> Void)
    func deleteDeck(deck: Deck)
    func finishGame(userTime:[Double], score:Int, deckId: String) -> Bool
    func resetForNewLogin()
    
}
