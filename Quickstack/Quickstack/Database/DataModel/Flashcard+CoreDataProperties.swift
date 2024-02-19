////
////  Flashcard+CoreDataProperties.swift
////  Quickstack
////
////  Created by BooSung Jung on 29/5/2023.
////
////
//
//import Foundation
//import CoreData
//
//
//extension Flashcard {
//
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flashcard> {
//        return NSFetchRequest<Flashcard>(entityName: "Flashcard")
//    }
//
////    @NSManaged public var question: String?
////    @NSManaged public var image: Data?
////    @NSManaged public var answer: String?
//    @NSManaged public var decks: NSSet?
//
//}
//
//// MARK: Generated accessors for decks
//extension Flashcard {
//
//    @objc(addDecksObject:)
//    @NSManaged public func addToDecks(_ value: Deck)
//
//    @objc(removeDecksObject:)
//    @NSManaged public func removeFromDecks(_ value: Deck)
//
//    @objc(addDecks:)
//    @NSManaged public func addToDecks(_ values: NSSet)
//
//    @objc(removeDecks:)
//    @NSManaged public func removeFromDecks(_ values: NSSet)
//
//}
//
//extension Flashcard : Identifiable {
//
//}
