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
		var size = subviews[0].sizeThatFits(.unspecified)
		if let width = proposal.width, width < size.width {
			size.width = width
		}
		if let height = proposal.height, height < size.height {
			size.height = height
		}
		return size
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

		subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading, proposal: .unspecified)
	}
}

private struct HorizontalMarqueeContainer: View {
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
		}.ignoresSafeArea()
		 .layerEffect(MarqueeShaderLibrary.horizontalMarqueeEffect(.boundingRect), maxSampleOffset: .zero, isEnabled: view.width > size.width)
		 .onGeometryChange(for: CGSize.self) { proxy in
			 proxy.size
		 } action: { newValue in
			 size = newValue
		 }
	}
}

private struct VerticalMarqueeContainer: View {
	@State private var size: CGSize = .zero
	@State private var start: Date = Date()
	var speed: Double
	var spacing: Double
	var view: RenderedView

	var body: some View {
		MarqueeLayout {
			// If the content doesn't fit in the container, then animate.
			// Otherwise render the content.
			if view.height > size.height {
				TimelineView(.animation) { date in
					let diff = date.date.timeIntervalSince1970 - start.timeIntervalSince1970
					let offset_leading = -(diff * speed)
					let	offset_trailing = offset_leading + view.height + spacing

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
							.offset(y: offset_leading)
							.clipped()

						view.image
							.offset(y: offset_trailing)
							.clipped()
					}
				}
			} else {
				view.image
			}
		}.layerEffect(MarqueeShaderLibrary.verticalMarqueeEffect(.boundingRect), maxSampleOffset: .zero, isEnabled: view.height > size.height)
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
	let height: CGFloat
	let width: CGFloat

	init?<Content: View>(displayScale: CGFloat, @ViewBuilder _ content: () -> Content) {
		let renderer = ImageRenderer(content: content())
		renderer.scale = displayScale
		guard let cgImage = renderer.cgImage else {
			print("Unable to render image from content")
			return nil
		}
		self.image = Image(decorative: cgImage, scale: displayScale)
		self.height = CGFloat(cgImage.height) / displayScale
		self.width = CGFloat(cgImage.width) / displayScale
	}
}

public struct Marquee<Content: View>: View {
	@Environment(\.displayScale) private var displayScale
	public enum Orientation {
		case horizontal
		case vertical
	}
	public var orientation: Orientation
	public var speed: Double
	public var spacing: Double
	@ViewBuilder public var content: () -> Content

	public init(orientation: Orientation = .horizontal, speed: Double = 80, spacing: Double = 50, @ViewBuilder _ content: @escaping () -> Content) {
		self.orientation = orientation
		self.speed = speed
		self.spacing = spacing
		self.content = content
	}

	public var body: some View {
		if let view = RenderedView(displayScale: displayScale, content) {
			if self.orientation == .horizontal {
				HorizontalMarqueeContainer(speed: speed, spacing: spacing, view: view)
					.clipped()
			} else {
				VerticalMarqueeContainer(speed: speed, spacing: spacing, view: view)
					.clipped()
			}
		} else {
			content()
		}
	}
}
