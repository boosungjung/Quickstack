//
//  Flashcard.swift
//  Quickstack
//
//  Created by BooSung Jung on 2/5/2023.
//

import UIKit

enum FlashcardError: Error {
    case invalidServerResponse
    case invalidFlashcardImageURL
}

class Flashcard: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case answer
        case question
        case imageUrl
    }
    
    var question: String?
    var answer: String?
    var imageUrl: String?
    
    // Used to track image downloads:
    var image: UIImage?
    var imageIsDownloading: Bool = false
    var imageShown = true
    
    convenience override init() {
        self.init(question: nil, answer: nil, imageUrl: nil)
    }
        
    init(question: String?, answer: String?, imageUrl: String?) {
        self.question = question
        self.answer = answer
        self.imageUrl = imageUrl
        // ... other initialization code
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.question = try container.decode(String.self, forKey: .question)
        self.answer = try container.decode(String.self, forKey: .answer)
        self.imageUrl = try? container.decode(String.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.question, forKey: .question)
        try container.encode(self.answer, forKey: .answer)
        try container.encode(self.imageUrl, forKey: .imageUrl)
    }
    var dictionaryRepresentation: [String: Any] {
            var dictionary: [String: Any] = [:]
            dictionary["question"] = question
            dictionary["answer"] = answer
            dictionary["imageUrl"] = imageUrl
            return dictionary
        }
}
