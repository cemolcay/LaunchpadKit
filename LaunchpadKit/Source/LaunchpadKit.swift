//
//  LaunchpadManager.swift
//  LaunchpadKit
//
//  Created by cem.olcay on 27/05/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import Foundation
import AudioKit

/// Represents a button on Launchpad.
public class LaunchpadButton {
  /// Brightness level of a button.
  public enum Brightness: Int {
    /// No brightness.
    case off
    /// Minimum brightness.
    case min
    /// Medium brightness.
    case mid
    /// Maximum brightness.
    case max
  }

  /// Color of the button.
  public enum Color: Int {
    /// Green color.
    case green
    /// Red color.
    case red
    /// Yellow color.
    case yellow
    /// Amber color.
    case amber
  }

  /// Row index of the button on the grid.
  public let col: Int
  /// Column index of the button on the grid.
  public let row: Int
  /// MIDI note value of the button on the grid.
  public let midiNote: UInt8
  /// Current color of the button.
  public internal(set) var color: Color
  /// Current brightness of the button.
  public internal(set) var brightness: Brightness
  /// Current pressing state of the button.
  public internal(set) var isPressed: Bool

  /// Returns true if the button is located on top row.
  public var isLiveButton: Bool {
    return row == 8
  }

  /// Returns true if the buttons is located on last column.
  public var isSceneButton: Bool {
    return col == 8
  }

  /// Returns the MIDI code for the current color/brightness configuration.
  public var colorCode: UInt8 {
    var red = brightness.rawValue * (color == .red || color == .amber ? 1 : 0)
    var green = brightness.rawValue * (color == .red || color == .amber ? 1 : 0)

    if color == .yellow && brightness != .off {
      red = 2
      green = 3
    }

    return
      UInt8(0b10000 * green) +
      UInt8(0b00001 * red)
  }

  /// Returns the MIDI status code for the color message sending.
  public var colorStatusCode: UInt8 {
    return isLiveButton ? 176 : 144
  }

  /// Initilizes the button with
  ///
  /// - Parameters:
  ///   - row: Row index, y-position of the button.
  ///   - col: Column index, x-position of the button.
  ///   - color: Color of the button.
  ///   - brightness: Brightness of the button.
  public init(row: Int, col: Int, midiNote: UInt8, color: Color = .green, brightness: Brightness = .off) {
    self.row = row
    self.col = col
    self.midiNote = midiNote
    self.color = color
    self.brightness = brightness
    self.isPressed = false
  }
}

/// Represents a connected Launchpad.
public class Launchpad {
  /// Contains all the buttons on launchpad.
  public var grid: [LaunchpadButton]
  /// MIDI-input name of the launchpad.
  public internal(set) var name: String
  /// MIDI port of the launchpad.
  public internal(set) var port: MIDIUniqueID
  /// Current connection state of the launchpad.
  public internal(set) var isConnected: Bool

  /// Initilizes a Launchpad with it's MIDI configuration.
  ///
  /// - Parameters:
  ///   - name: MIDI-input name of the Launchpad.
  ///   - port: MIDI port of the Launchpad.
  public init(name: String, port: MIDIUniqueID) {
    self.grid = []
    self.name = name
    self.port = port
    self.isConnected = false

    for x in 0..<9 {
      for y in 0..<9 {
        let midiNote = UInt8(y == 0 ? 104 + x : (16 * x) + y - 1)
        let button = LaunchpadButton(row: y, col: x, midiNote: midiNote)
        grid.append(button)
      }
    }
  }

  /// Gets or sets a `LaunchpadButton` on the grid by its x-y position.
  ///
  /// - Parameters:
  ///   - x: Column of the button on the grid.
  ///   - y: Row of the button on the grid.
  public subscript(_ x: Int, _ y: Int) -> LaunchpadButton? {
    get {
      return grid.first(where: { $0.col == x && $0.row == y })
    } set {
      guard let index = grid.firstIndex(where: { $0.col == x && $0.row == y }),
        let button = newValue
        else { return }
      grid[index] = button
    }
  }

  /// Gets or sets a `LaunchpadButton` on the grid by it's MIDI note number.
  ///
  /// - Parameter number: MIDI note number of the button on the grid.
  public subscript(midiNote number: UInt8) -> LaunchpadButton? {
    get {
      return grid.first(where: { $0.midiNote == number })
    } set {
      guard let index = grid.firstIndex(where: { $0.midiNote == number }),
        let button = newValue
        else { return }
      grid[index] = button
    }
  }

  /// Returns all buttons on a column.
  ///
  /// - Parameter index: Index of the column.
  public subscript(col index: Int) -> [LaunchpadButton] {
    return grid.filter({ $0.col == index })
  }

  /// Returns all buttons on a row.
  ///
  /// - Parameter index: Index of the row.
  public subscript(row index: Int) -> [LaunchpadButton] {
    return grid.filter({ $0.row == index })
  }

  /// Returns scene buttons on the grid.
  public var sceneButtons: [LaunchpadButton] {
    return grid.filter({ $0.isSceneButton })
  }

  /// Returns live buttons on the grid.
  public var liveButtons: [LaunchpadButton] {
    return grid.filter({ $0.isLiveButton })
  }
}

/// Informs implementor about Launchpad actions.
public protocol LaunchpadManagerDelegate: class {
  /// Informs about Launchpad device changes.
  ///
  /// - Parameter launchpadManager: Manager object.
  func launchpadManagerSetupDidChange(_ launchpadManager: LaunchpadManager)

  /// Informs that a Launchpad is connected.
  ///
  /// - Parameters:
  ///   - launchpadManager: Manager object.
  ///   - launchpad: Connected Launchpad.
  func launchpadManager(_ launchpadManager: LaunchpadManager, didConnect launchpad: Launchpad)

  /// Informs that a Launchpad is disconnected.
  ///
  /// - Parameters:
  ///   - launchpadManager: Manager object.
  ///   - launchpad: Disconnected Launchpad.
  func launchpadManager(_ launchpadManager: LaunchpadManager, didDisconnect launchpad: Launchpad)

  /// Informs that a button has pressed on a Launchpad.
  ///
  /// - Parameters:
  ///   - launchpadManager: Manager object.
  ///   - launchpad: Launchpad object.
  ///   - button: Pressed button.
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didPress button: LaunchpadButton)

  /// Informs that a button is unpressed on a Launchpad.
  ///
  /// - Parameters:
  ///   - launchpadManager: Manager object.
  ///   - launchpad: Launchpad object.
  ///   - button: Unpressed button.
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didUnpress button: LaunchpadButton)
}

/// Singleton manager object.
public class LaunchpadManager: AKMIDIListener {
  /// Shared singleton object.
  public static let shared = LaunchpadManager()
  /// MIDI manager.
  private let midi = AKMIDI()
  /// Currently available Launchpad devices.
  public private(set) var launchpads: [Launchpad] = []
  /// If enables, auto connects the plugged Launchpads. Defaults true.
  public var autoconnectEnabled = true
  /// Delegate that informs about changes.
  public weak var delegate: LaunchpadManagerDelegate?

  /// Initilizes the manager.
  private init() {
    midi.addListener(self)
    initializeLaunchpads()
  }

  // MARK: Launchpad Setup

  /// Initializes the Launchpads/
  public func initializeLaunchpads() {
    let detectedLaunchpads = midi.inputUIDs
      .filter({ midi.inputName(for: $0)?.contains("Launchpad") == true })
      .map({ Launchpad(name: midi.inputName(for: $0) ?? "Launchpad", port: $0) })

    // Connect
    let connectingLaunchpads = detectedLaunchpads.filter({ detected in launchpads.contains(where: { $0.port == detected.port }) == false })
    connectingLaunchpads.forEach({
      launchpads.append($0)
      if autoconnectEnabled {
        connect(launchpad: $0)
      }
    })

    // Disconnect
    let disconnectingLaunchpads = launchpads.filter({ lp in detectedLaunchpads.contains(where: { $0.port == lp.port }) == false })
    for lp in disconnectingLaunchpads {
      disconnect(launchpad: lp)
      guard let index = launchpads.firstIndex(where: { $0.port == lp.port }) else { continue }
      launchpads.remove(at: index)
    }

    delegate?.launchpadManagerSetupDidChange(self)
  }

  /// Connects a Launchpad.
  ///
  /// - Parameter launchpad: Connecting Launchpad.
  public func connect(launchpad: Launchpad) {
    midi.openInput(uid: launchpad.port)
    midi.openOutput(uid: launchpad.port)
    launchpad.isConnected = true
    delegate?.launchpadManager(self, didConnect: launchpad)
  }

  /// Disconnects from a Launchpad.
  ///
  /// - Parameter launchpad: Disconnecting Launchpad.
  public func disconnect(launchpad: Launchpad) {
    midi.closeInput(uid: launchpad.port)
    midi.closeOutput(uid: launchpad.port)
    launchpad.isConnected = false
    delegate?.launchpadManager(self, didDisconnect: launchpad)
  }

  // MARK: Launchpad Color Setting

  /// Sets a launchpad's button color.
  ///
  /// - Parameters:
  ///   - launchpad: Launchpad object.
  ///   - col: Column of the button on the grid.
  ///   - row: Row of the button on the grid.
  ///   - color: Color of the button.
  ///   - brightness: Brightness of the button.
  public func setLaunchpadButtonColor(_ launchpad: Launchpad,
                                      col: Int,
                                      row: Int,
                                      color: LaunchpadButton.Color,
                                      brightness: LaunchpadButton.Brightness) {
    guard let button = launchpad[col, row] else { return }
    button.color = color
    button.brightness = brightness

    let midiEvent = [button.colorStatusCode, button.midiNote, button.colorCode]
    midi.sendMessage(midiEvent)
  }

  // MARK: AKMIDIListener

  public func receivedMIDISetupChange() {
    initializeLaunchpads()
  }

  public func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID) {
    guard let launchpad = launchpads.first(where: { $0.port == portID }),
      let button = launchpad[midiNote: noteNumber]
      else { return }
    if velocity > 0 {
      button.isPressed = true
      delegate?.launchpadManager(self, launchpad: launchpad, didPress: button)
    } else {
      button.isPressed = false
      delegate?.launchpadManager(self, launchpad: launchpad, didUnpress: button)
    }
  }

  public func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID) {
    guard let launchpad = launchpads.first(where: { $0.port == portID }),
      let button = launchpad[midiNote: noteNumber]
      else { return }
    button.isPressed = false
    delegate?.launchpadManager(self, launchpad: launchpad, didUnpress: button)
  }

  public func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID) {
    guard let launchpad = launchpads.first(where: { $0.port == portID }),
      let button = launchpad[midiNote: controller]
      else { return }
    if value > 0 {
      button.isPressed = true
      delegate?.launchpadManager(self, launchpad: launchpad, didPress: button)
    } else {
      button.isPressed = false
      delegate?.launchpadManager(self, launchpad: launchpad, didUnpress: button)
    }
  }
}
