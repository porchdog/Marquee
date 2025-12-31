# Marquee
A Marquee view for SwiftUI

There's a handful of Marquee views out there and I'm not sure this one is any better than those, but I couldn't find one that did everything I wanted so I wrote my own.

* Will run a marquee on any kind of view, not just text.
* Can specify spacing between animating views.
* Doesn't have weird geometry that makes it hard to compose into other views.
* Configurable speed.
* Fader for the leading and trailing edges of the view.

There are things this doesn't have that other implementations do have as well:

* Animation curve. This one is strictly linear.

