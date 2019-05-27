//
//  ViewController.swift
//  Example
//
//  Created by cem.olcay on 27/05/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import Cocoa
import LaunchpadKit

class ViewController: NSViewController, LaunchpadManagerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    LaunchpadManager.shared.delegate = self
  }

  // MARK: LaunchpadManagerDelegate

  func launchpadManagerSetupDidChange(_ launchpadManager: LaunchpadManager) {
    print("setup did change")
  }

  func launchpadManager(_ launchpadManager: LaunchpadManager, didConnect launchpad: Launchpad) {
    print("did connect \(launchpad)")
  }

  func launchpadManager(_ launchpadManager: LaunchpadManager, didDisconnect launchpad: Launchpad) {
    print("did disconnect \(launchpad)")
  }

  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didPress button: LaunchpadButton) {
    print("did press button row: \(button.row) col: \(button.col) isLiveButton: \(button.isLiveButton) isSceneButton: \(button.isSceneButton)")
    launchpadManager.setLaunchpadButtonColor(launchpad, x: button.col, y: button.row, color: .green, brightness: .min)
  }

  func launchpadManager(_ launchpadManager: LaunchpadManager, launchpad: Launchpad, didUnpress button: LaunchpadButton) {
    print("did unpress button row: \(button.row) col: \(button.col) isLiveButton: \(button.isLiveButton) isSceneButton: \(button.isSceneButton)")
    launchpadManager.setLaunchpadButtonColor(launchpad, x: button.col, y: button.row, color: .green, brightness: .off)
  }
}
