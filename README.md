# iosMath
`iosMath` is a library for displaying beautifully rendered math equations
in iOS applications. It typesets formulae written using the LaTeX in a
`UILabel` equivalent class. It uses the same typesetting rules as LaTeX
and so the equations are rendered exactly as LaTeX would render them.

It is similar to [MathJax](https://www.mathjax.org) or
[KaTeX](https://github.com/Khan/KaTeX) for the web but for native iOS
applications without having to use a `UIWebView` and Javascript and
significantly faster than using it.

## Examples
Here are some formulae that you could render with this library:

![Quadratic Formula](img/quadratic.png)
 
## Requirements
`iosMath` works on iOS 6+ and requires ARC to build. It depends on
the following Apple frameworks:

* Foundation.framework
* UIKit.framework
* CoreGraphics.framework
* QuartzCore.framework
* CoreText.framework

## Installation

### Cocoapods

iosMath is available through [CocoaPods](http://cocoapods.org). To install
it:

1. Add a entry for iosMath to your Podfile: `pod 'iosMath'`.
2. Install the pod by running `pod install`.

### Static library

You can also add iosMath as a static library to your project or
workspace.

1. Download the [latest code version](https://github.com/kostub/iosMath/downloads) or add the
repository as a git submodule to your git-tracked project.
2. Open your project in Xcode, then drag and drop
   `iosMath.xcodeproj` onto your project or workspace (use the
"Product Navigator view").
3. Select your target and go to the Build phases tab. In the Link Binary
   With Libraries section select the add button. On the sheet find and
add `libIosMath.a`. You might also need to add `iosMath` to
the Target Dependencies list.
4. Add the `MathFontBundle` to the list of `Copy Bundle Resources`.
5. Include IosMath wherever you need it with `#import <IosMath/IosMath.h>`.

## Usage

The library provides a class `MTMathUILabel` which is a `UIView` that
supports rendering math equations. To display an equation simply create
an `MTMathUILabel` as follows:

```objective-c
#import "MTMathUILabel.h"
#import "MTMathListBuilder.h"

MTMathULabel* Iabel = [[MTMathUILabel alloc] init];
label.mathList = [MTMathListBuilder buildFromString:@"x = \\frac{-b + \\sqrt{b^2-4ac}}{2a}"];

```
Adding `MTMathUILabel` as a sub-view of your `UIView` as will render the
quadratic formula example shown above.

### Example

There is a sample app included in this project that shows how to use the
app and the different equations that you can render. To run the sample
app, clone the repository, and run `pod install` first. Then run the
__iosMathExample__ app.

### Advanced configuration

`MTMathUILabel` supports some advanced configuration options:

##### Math mode

You can change the mode of the `MTMathUILabel` between Display Mode
(equivalent to `$$` or `\[` in LaTeX') and Text Mode (equivalent to `$`
or `\(` in LaTeX). The default style is Display. To switch to Text
simply:

```objective-c
label.labelMode = kMTMathUILabelModeText;
```

##### Text Alignment
The default alignment of the equations is left. This can be changed to
center or right as follows:

```objective-c
label.textAlignment = kMTTextAlignmentCenter;
```

##### Font size
The default font-size is 20pt. You can change it as follows:

```objective-c
label.fontSize = 30;
```

##### Padding
The `MTMathUILabel` has top, bottom, left and right padding for finer
control of placement of the equation in relation to the view. However,
if you use auto-layout it is preferable to use constraints instead.

If you need to set it you can do as follows:

```objective-c
label.paddingRight = 20;
label.paddingTop = 10;
```

## License

iosMath is available under the MIT license. See the LICENSE file for more info.

