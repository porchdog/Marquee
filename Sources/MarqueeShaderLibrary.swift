//
//  MarqueeShaderLibrary.swift
//
//  Created by Porchdog Software on 12/30/25.
//  Copyright (c) 2025 Porchdog Software. All rights reserved.
//

import SwiftUI

@available(iOS 26, macOS 26, tvOS 26, visionOS 26, *)
@dynamicMemberLookup
public enum MarqueeShaderLibrary {
    public static subscript(dynamicMember name: String) -> ShaderFunction {
        ShaderLibrary.bundle(.marquee)[dynamicMember: name]
    }
}
