//
//  Marquee.swift
//
//  Created by Porchdog Software on 12/30/25.
//  Copyright (c) 2025 Porchdog Software. All rights reserved.
//

import SwiftUI

private struct MarqueeLayout: Layout {
	let contentSize: CGSize
	let spacing: Double
	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {
		if subviews.count != 1 {
			fatalError("Must have one subview")
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
			fatalError("Must have one subview")
		}

		subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading, proposal: .unspecified)
	}
}

private struct HorizontalMarqueeContainer<Content: View>: View {
	struct MarqueeStackLayout: Layout {
		let size: CGSize
		let spacing: CGFloat
		let offset: CGFloat
		let reset: () -> Void

		func sizeThatFits(
			proposal: ProposedViewSize,
			subviews: Subviews,
			cache: inout ()
		) -> CGSize {
			if subviews.count != 2 {
				fatalError("Must be 2 subviews")
			}

			return CGSize(width: size.width + size.width + spacing, height: size.height)
		}

		func placeSubviews(
			in bounds: CGRect,
			proposal: ProposedViewSize,
			subviews: Subviews,
			cache: inout ()
		) {
			if subviews.count != 2 {
				fatalError("Must be 2 subviews")
			}

			let leadingX = bounds.minX
			var trailingX = bounds.minX + size.width + spacing

			subviews[0].place(at: CGPoint(x: leadingX, y: bounds.minY), anchor: .topLeading, proposal: proposal)
			subviews[1].place(at: CGPoint(x: trailingX, y: bounds.minY), anchor: .topLeading, proposal: proposal)

			trailingX += offset
			if trailingX.sign == .minus {
				DispatchQueue.main.async {
					reset()
				}
			 }
		}
	}

	@State private var containerSize: CGSize = .zero
	@State private var start: Date = Date()
	var spacing: Double
	var speed: Double
	var content: Content

	func offset(for date: Date) -> CGFloat {
		-((date.timeIntervalSince1970 - start.timeIntervalSince1970) * speed)
	}

	var body: some View {
		// If the content doesn't fit in the container, then animate.
		// Otherwise render the content.
		Measure(content: content) { contentSize in
			MarqueeLayout(contentSize: contentSize, spacing: spacing) {
				if contentSize.width > containerSize.width {
					TimelineView(.animation) { context in
						MarqueeStackLayout(size: contentSize, spacing: spacing, offset: offset(for: context.date), reset: {
							start = Date()
						}) {
							content
								.offset(x: offset(for: context.date))
							content
								.offset(x: offset(for: context.date))
						}
					}.clipped()
					 .layerEffect(MarqueeShaderLibrary.horizontalMarqueeEffect(.boundingRect), maxSampleOffset: .zero)
				} else {
					content
				}
			}
		}.onGeometryChange(for: CGSize.self) { proxy in
			proxy.size
		} action: { newValue in
			containerSize = newValue
		}
	}
}

private struct VerticalMarqueeContainer<Content: View>: View {
	struct MarqueeStackLayout: Layout {
		let size: CGSize
		let spacing: CGFloat
		let offset: CGFloat
		let reset: () -> Void

		func sizeThatFits(
			proposal: ProposedViewSize,
			subviews: Subviews,
			cache: inout ()
		) -> CGSize {
			if subviews.count != 2 {
				fatalError("Must be 2 subviews")
			}

			return CGSize(width: size.width, height: size.height + size.height + spacing)
		}

		func placeSubviews(
			in bounds: CGRect,
			proposal: ProposedViewSize,
			subviews: Subviews,
			cache: inout ()
		) {
			if subviews.count != 2 {
				fatalError("Must be 2 subviews")
			}

			let leadingY = bounds.minY
			var trailingY = bounds.minY + size.height + spacing

			subviews[0].place(at: CGPoint(x: bounds.minX, y: leadingY), anchor: .topLeading, proposal: proposal)
			subviews[1].place(at: CGPoint(x: bounds.minY, y: trailingY), anchor: .topLeading, proposal: proposal)

			trailingY += offset
			if trailingY.sign == .minus {
				DispatchQueue.main.async {
					reset()
				}
			}
		}
	}

	@State private var containerSize: CGSize = .zero
	@State private var start: Date = Date()
	var spacing: Double
	var speed: Double
	var content: Content

	func offset(for date: Date) -> CGFloat {
		-((date.timeIntervalSince1970 - start.timeIntervalSince1970) * speed)
	}

	var body: some View {
		// If the content doesn't fit in the container, then animate.
		// Otherwise render the content.
		Measure(content: content) { contentSize in
			MarqueeLayout(contentSize: contentSize, spacing: spacing) {
				if contentSize.height > containerSize.height {
					TimelineView(.animation) { context in
						MarqueeStackLayout(size: contentSize, spacing: spacing, offset: offset(for: context.date), reset: {
							start = Date()
						}) {
							content
								.offset(y: offset(for: context.date))
							content
								.offset(y: offset(for: context.date))
						}
					}.clipped()
						.layerEffect(MarqueeShaderLibrary.verticalMarqueeEffect(.boundingRect), maxSampleOffset: .zero)
				} else {
					content
				}
			}
		}.onGeometryChange(for: CGSize.self) { proxy in
			proxy.size
		} action: { newValue in
			containerSize = newValue
		}
	}
}

private struct Measure<Content: View, Child: View>: View {
	@Environment(\.displayScale) private var displayScale
	var content: Content
	@ViewBuilder var child: (CGSize) -> Child

	var body: some View {
		child(measure)
	}

	var measure: CGSize {
		let renderer = ImageRenderer(content: content)
		renderer.scale = displayScale
		guard let cgImage = renderer.cgImage else {
			print("Unable to render image from content")
			return .zero
		}
		return CGSize(width: Double(cgImage.width) / displayScale, height: Double(cgImage.height) / displayScale)
	}
}

public struct Marquee<Content: View>: View {
	public enum Orientation {
		case horizontal
		case vertical
	}
	public var orientation: Orientation
	public var speed: Double
	public var spacing: Double
	public var content: Content

	public init(orientation: Orientation = .horizontal, speed: Double = 80, spacing: Double = 150, @ViewBuilder _ content: () -> Content) {
		self.orientation = orientation
		self.speed = speed
		self.spacing = spacing
		self.content = content()
	}

	public var body: some View {
		if self.orientation == .horizontal {
			HorizontalMarqueeContainer(spacing: spacing, speed: speed, content: content)
			.clipped()
		} else {
			VerticalMarqueeContainer(spacing: spacing, speed: speed, content: content)
			.clipped()
		}
	}
}
