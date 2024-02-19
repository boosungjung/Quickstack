//
//  Deck.swift
//  Quickstack
//
//  Created by BooSung Jung on 3/5/2023.
//

import Foundation
import FirebaseFirestoreSwift

class Deck: NSObject, Codable {
    
    @DocumentID var id: String?
    var name: String?
    var flashcards: [Flashcard] = []
    var leaderboard: [[String:Int]] = [[:]]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case flashcards
    }
    
//    convenience override init() {
//        self.init(flashcards:nil,name: nil)
//    }
//
    init(flashcards:[Flashcard], name:String) {
        self.flashcards = flashcards
        self.name = name
        // ... other initialization code
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
//        self.flashcards = try container.decodeIfPresent([Flashcard].self, forKey: .flashcards)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encodeIfPresent(self.flashcards, forKey: .flashcards)
    }
}
