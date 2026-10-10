import AppKit
import AVFoundation
import CoreAudioKit

/// One window per effect slot showing the plugin's own controls, or Apple's
/// generic parameter panel when the plugin has no interface of its own.
@MainActor
final class PluginWindows {
    private var windows: [UUID: NSWindow] = [:]

    func open(_ unit: AVAudioUnit, title: String, slotID: UUID) async {
        if let window = windows[slotID] {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let controller = await unit.auAudioUnit.requestViewController() ?? Self.genericController(for: unit)
        let window = NSWindow(contentViewController: controller)
        window.title = title
        window.isReleasedWhenClosed = false
        // Some plugins report no size until they lay out; give them room.
        let size = controller.view.frame.size
        if size.width < 100 || size.height < 60 {
            window.setContentSize(NSSize(width: 480, height: 320))
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        windows[slotID] = window
    }

    func close(slotID: UUID) {
        windows.removeValue(forKey: slotID)?.close()
    }

    private static func genericController(for unit: AVAudioUnit) -> NSViewController {
        let view = AUGenericView(audioUnit: unit.audioUnit)
        view.showsExpertParameters = true
        let controller = NSViewController()
        controller.view = view
        return controller
    }
}
