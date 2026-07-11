import Carbon
import Foundation

final class HotKeyManager {
    private static weak var current: HotKeyManager?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    deinit {
        unregister()
    }

    func registerOptionSpace(action: @escaping () -> Void) {
        self.action = action
        unregister()
        HotKeyManager.current = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, _ in
                HotKeyManager.current?.action()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: fourCharCode("DSHF"), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    string.utf8.reduce(0) { result, byte in
        (result << 8) + FourCharCode(byte)
    }
}
