//
//  LaunchpadManager.swift
//  LaunchpadKit
//
//  Created by cem.olcay on 27/05/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import Foundation
import AudioKit
import MIDIEventKit

public class LaunchpadButton {
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

  public let x: Int
  public let y: Int
  public let midiNote: UInt8
  public internal(set) var color: Color
  public internal(set) var brightness: Brightness
  public internal(set) var isPressed: Bool

  public var isLiveButton: Bool {
    return y == 0
  }

  public var isSceneButton: Bool {
    return x == 8
  }

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

  public var colorStatusCode: UInt8 {
    return isLiveButton ? 176 : 144
  }

  public init(x: Int, y: Int, color: Color = .green, brightness: Brightness = .off) {
    self.x = x
    self.y = y
    self.color = color
    self.brightness = brightness
    self.isPressed = false
    self.midiNote = y == 8 ? UInt8(104 + x) : UInt8((y * 16) + x)
  }
}

public class Launchpad {
  public var grid: [LaunchpadButton]
  public internal(set) var name: String
  public internal(set) var port: MIDIUniqueID
  public internal(set) var isConnected: Bool

  public init(name: String, port: MIDIUniqueID) {
    grid = [Int](0..<8).map({ x in [Int](0..<8).map({ y in LaunchpadButton(x: x, y: y) }) }).flatMap({ $0 })
    self.name = name
    self.port = port
    isConnected = false
  }

  public subscript(_ x: Int, _ y: Int) -> LaunchpadButton? {
    get {
      return grid.first(where: { $0.x == x && $0.y == y })
    } set {
      guard let index = grid.firstIndex(where: { $0.x == x && $0.y == y }),
        let button = newValue
        else { return }
      grid[index] = button
    }
  }

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

  public subscript(row index: Int) -> [LaunchpadButton] {
    return grid.filter({ $0.x == index })
  }

  public subscript(col index: Int) -> [LaunchpadButton] {
    return grid.filter({ $0.y == index })
  }

  public var sceneButtons: [LaunchpadButton] {
    return grid.filter({ $0.isSceneButton })
  }

  public var liveButtons: [LaunchpadButton] {
    return grid.filter({ $0.isLiveButton })
  }
}

public protocol LaunchpadManagerDelegate: class {
  func launchpadManagerSetupDidChange(_ launchpadManager: LaunchpadManager)
  func launchpadManager(_ launchpadManager: LaunchpadManager, didConnect launchpad: Launchpad)
  func launchpadManager(_ launchpadManager: LaunchpadManager, didDisconnect launchpad: Launchpad)
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didPress button: LaunchpadButton)
  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didUnpress button: LaunchpadButton)
}

public class LaunchpadManager: AKMIDIListener {
  public static let shared = LaunchpadManager()
  private let midi = AKMIDI()
  public private(set) var launchpads: [Launchpad] = []
  public var autoconnectEnabled = true
  public weak var delegate: LaunchpadManagerDelegate?

  private init() {
    midi.addListener(self)
  }

  // MARK: Launchpad Color Setting

  public func setLaunchpadButtonColor(_ launchpad: Launchpad,
                                      x: Int,
                                      y: Int,
                                      color: LaunchpadButton.Color,
                                      brightness: LaunchpadButton.Brightness) {
    guard let button = launchpad[x, y] else { return }
    button.color = color
    button.brightness = brightness

    let midiEvent = [button.colorStatusCode, button.midiNote, button.colorCode]
    midi.sendMessage(midiEvent)
  }

  // MARK: Launchpad Connection

  public func connect(launchpad: Launchpad) {
    midi.openInput(uid: launchpad.port)
    midi.openOutput(uid: launchpad.port)
    launchpad.isConnected = true
    delegate?.launchpadManager(self, didConnect: launchpad)
  }

  public func disconnect(launchpad: Launchpad) {
    midi.closeInput(uid: launchpad.port)
    midi.closeOutput(uid: launchpad.port)
    launchpad.isConnected = false
    delegate?.launchpadManager(self, didDisconnect: launchpad)
  }

  // MARK: AKMIDIListener

  public func receivedMIDISetupChange() {
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
}
