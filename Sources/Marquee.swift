//
//  Marquee.swift
//
//  Created by Porchdog Software on 12/30/25.
//  Copyright (c) 2025 Porchdog Software. All rights reserved.
//

import SwiftUI

private struct MarqueeLayout: Layout {
	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {
		if subviews.count != 1 {
			return .zero
		}

		// If something asked for this to be a certain size, then that's the size it's going to be
		if let width = proposal.width, let height = proposal.height {
			return CGSize(width: width, height: height)
		} else {
			let size = subviews[0].sizeThatFits(.unspecified)
			return CGSize(width: size.width, height: size.height)
		}
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {
		if subviews.count != 1 {
			fatalError("Only works with a single subview")
		}

		// Position the subview
		subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .unspecified)
	}
}

private struct MarqueeContainer: View {
	@State private var size: CGSize = .zero
	@State private var start: Date = Date()
	var speed: Double
	var spacing: Double
	var view: RenderedView

	var body: some View {
		MarqueeLayout {
			// If the content doesn't fit in the container, then animate.
			// Otherwise render the content.
			if view.width > size.width {
				TimelineView(.animation) { date in
					let diff = date.date.timeIntervalSince1970 - start.timeIntervalSince1970
					let offset_leading = -(diff * speed)
					let	offset_trailing = offset_leading + view.width + spacing

					// If the offset of the second image is now negative, that means
					// we want to reset the animation by updating start to the current
					// date. That will effectively cause the initial state to be
					// restored.
					if offset_trailing.sign == .minus {
						DispatchQueue.main.async {
							start = Date()
						}
					}

					return ZStack {
						view.image
							.offset(x: offset_leading)
							.containerRelativeFrame([.horizontal], alignment: .leading)
							.clipped()

						view.image
							.offset(x: offset_trailing)
							.containerRelativeFrame([.horizontal], alignment: .leading)
							.clipped()
					}
				}
			} else {
				view.image
			}
		}.layerEffect(ShaderLibrary.marqueeEffect(.boundingRect), maxSampleOffset: .zero, isEnabled: view.width > size.width)
		 .onGeometryChange(for: CGSize.self) { proxy in
			 proxy.size
		 } action: { newValue in
			 size = newValue
		 }
	}
}

@MainActor
private struct RenderedView: Equatable {
	let image: Image
	let width: CGFloat

	init<Content: View>(displayScale: CGFloat, @ViewBuilder _ content: () -> Content) {
		let renderer = ImageRenderer(content: content())
		renderer.scale = displayScale
		guard let cgImage = renderer.cgImage else {
			fatalError("cant make image")
		}
		self.image = Image(decorative: cgImage, scale: displayScale)
		self.width = CGFloat(cgImage.width) / displayScale
	}
}

public struct Marquee<Content: View>: View {
	@Environment(\.displayScale) private var displayScale
	public var speed: Double
	public var spacing: Double
	@ViewBuilder public var content: () -> Content

	public init(speed: Double = 80, spacing: Double = 50, @ViewBuilder _ content: @escaping () -> Content) {
		self.speed = speed
		self.spacing = spacing
		self.content = content
	}

	public var body: some View {
		MarqueeContainer(speed: speed, spacing: spacing, view: RenderedView(displayScale: displayScale) {
			content()
		})
		.clipped()
	}
}
