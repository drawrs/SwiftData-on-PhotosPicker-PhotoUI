//
//  Feed.swift
//  PhotosPicker PhotoUI
//
//  Created by Rizal Hilman on 27/06/24.
//

import Foundation
import SwiftData

@Model
class Feed {
    @Attribute(.externalStorage)
    var image: Data?
    var caption: String
    var createdDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Tag.feeds)
    var tags: [Tag]?
    
    init(image: Data? = nil, caption: String) {
        self.image = image
        self.caption = caption
        self.createdDate = Date.now
    }
}
