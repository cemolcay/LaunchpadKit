LaunchpadKit
===

Swift API for controlling Novation Launchpad.

Install
---

```
$ pod 'LaunchpadKit'
```

Build
---

```
$ pod install
```

API
---

### LaunchpadManager

* Singleton `shared` object.
* Autoconnects launchpads.
* Informs implementor with `LaunchpadManagarDelegate`

``` Swift
  func launchpadManagerSetupDidChange(_ launchpadManager: LaunchpadManager)
  func launchpadManager(_ launchpadManager: LaunchpadManager, didConnect launchpad: Launchpad)
  func launchpadManager(_ launchpadManager: LaunchpadManager, didDisconnect launchpad: Launchpad)
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didPress button: LaunchpadButton)
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didUnpress button: LaunchpadButton)
```

* Can connect/disconnect launchpads manually

``` Swift
public func connect(launchpad: Launchpad)
public func disconnect(launchpad: Launchpad)
```

* Can set colors of `LaunchpadButton`s

``` Swift
public func setLaunchpadButtonColor(
	_ launchpad: Launchpad,
	x: Int,
	y: Int,
	color: LaunchpadButton.Color,
	brightness: LaunchpadButton.Brightness
)
```

### Launchpad

* The launchpad object with grid of `LaunchpadButton`s.
* Created by `LaunchpadManager` automatically when it detects an available launchpad.
* Can get/set a button with `[row: Int, column: Int]` subscript.

``` Swift
// First button of the second row.
let button = launchpad[1, 0]
// Sets third button of first row.
launchpad[1, 2] = newButton
```

* Can get all buttons in a row.

``` Swift
// get first row
let firstRow = launchpad[row: 0]
```

* Can get all buttons in a column.

``` Swift
// get first column
let firstCol = launchpad[col: 0]
```

* Can get `sceneButtons`.
* Can get `liveButtons`.

### LaunchpadButton

* Created by `Launchpad` object initially on its `grid` array.
* Has `color` and `brightness` properties.

``` Swift
  public enum Brightness: Int {
    case off
    case min
    case mid
    case max
  }

  public enum Color: Int {
    case green
    case red
    case yellow
    case amber
  }
```

* You can read `isPressed` state.
