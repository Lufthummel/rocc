//
//  Apeture.swift
//  Rocc
//
//  Created by Simon Mitchell on 26/04/2018.
//  Copyright © 2018 Simon Mitchell. All rights reserved.
//

import Foundation

/// Functions for controlling the Aperture (F Stop) of the camera
public struct Aperture: CameraFunction {
    
    public var function: _CameraFunction
    
    public typealias SendType = String
    
    public typealias ReturnType = String
    
    /// Set's the aperture of the camera
    public static let set = Aperture(function: .setAperture)
    
    /// Returns the current aperture of the camera
    public static let get = Aperture(function: .getAperture)
}
