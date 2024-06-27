//
//  Tag.swift
//  PhotosPicker PhotoUI
//
//  Created by Rizal Hilman on 27/06/24.
//

import SwiftData

@Model
class Tag {
    var label: String
    
    var feeds: [Feed]?
    
    init(label: String) {
        self.label = label
    }
}
