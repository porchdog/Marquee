//
//  shader.metal
//
//  Created by Porchdog Software on 12/30/25.
//  Copyright (c) 2025 Porchdog Software. All rights reserved.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 marqueeEffect(float2 position, SwiftUI::Layer layer, float4 bounds) {
	const float threshold = 15.0;

	half4 current_color = layer.sample(position);
	if ((position.x > threshold && position.x < (bounds.z - threshold))) {
		return current_color;
	}
	half4 new_color = current_color;
	float2 normalized_position = position;
	if (position.x > threshold) {
		normalized_position = (bounds.z - position.x);
	}

	auto fade = ((1 - (normalized_position.x / threshold)) * 5);
	if (fade < 1.0) {
		fade = 1.0;
	}

	new_color = new_color / fade;

	return half4(new_color);
}
