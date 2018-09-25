//
//  LaptopModel.swift
//  Test
//
//  Created by Claudio Vega on 9/13/18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import Foundation
import Unbox

public struct LaptopModel {
    let title: String
    let description: String
    let imageURL: URL?
    
}

extension LaptopModel: Unboxable {
    public init(unboxer: Unboxer) throws {
        title = try unboxer.unbox(key: "title")
        description = try unboxer.unbox(key: "description")
        imageURL = unboxer.unbox(key: "image")
    }
}
