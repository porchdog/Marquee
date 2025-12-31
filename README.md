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

# Usage

Add this repository (https://github.com/porchdog/Marquee) as a Swift Package Dependency to your project. You find the option in Xcode unter "File > Swift Packages > Add Package Dependency...".

import SwiftUI
import Marquee

```
struct ContentView: View {    
    var body: some View {
     Marquee {
       Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
         .font(.system(size: 24))
				 .foregroundStyle(Color.black)
				 .lineLimit(1)
     }
   }
}
```
