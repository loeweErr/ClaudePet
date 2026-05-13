import AppKit
import Carbon.HIToolbox

/// Registers a small set of global Carbon hot keys. Each binding has a
/// stable signature/id so that re-registering after a toggle works
/// without leaking event handler refs.
final class HotKeyManager {

    enum Action: UInt32, CaseIterable {
        case summon = 1   // ⌃⌥P → move cat to mouse cursor
        case toggle = 2   // ⌃⌥H → hide / show window
        case feed   = 3   // ⌃⌥F → feed
    }

    /// Called on the main thread when a registered hot key fires.
    var onAction: ((Action) -> Void)?

    private static let signature: OSType = {
        // 'CPet' as four-char code, used as a namespace for our hot keys.
        let chars: [UInt8] = [0x43, 0x50, 0x65, 0x74]
        return OSType(chars[0]) << 24 | OSType(chars[1]) << 16
             | OSType(chars[2]) << 8  | OSType(chars[3])
    }()

    private var refs: [EventHotKeyRef?] = []
    private var handler: EventHandlerRef?
    private(set) var isEnabled = false

    /// Bring the bindings online. Safe to call repeatedly — duplicates
    /// are torn down first.
    func enable() {
        disable()
        installHandler()
        register(.summon, keyCode: UInt32(kVK_ANSI_P), modifiers: cmdCtrlOpt())
        register(.toggle, keyCode: UInt32(kVK_ANSI_H), modifiers: ctrlOpt())
        register(.feed,   keyCode: UInt32(kVK_ANSI_F), modifiers: ctrlOpt())
        isEnabled = true
    }

    func disable() {
        for ref in refs {
            if let r = ref { UnregisterEventHotKey(r) }
        }
        refs.removeAll()
        if let h = handler {
            RemoveEventHandler(h)
            handler = nil
        }
        isEnabled = false
    }

    private func ctrlOpt() -> UInt32 {
        UInt32(controlKey | optionKey)
    }

    /// summon adds Cmd to reduce conflicts with system shortcuts that
    /// often use ⌃⌥P alone.
    private func cmdCtrlOpt() -> UInt32 {
        UInt32(cmdKey | controlKey | optionKey)
    }

    private func register(_ action: Action, keyCode: UInt32, modifiers: UInt32) {
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: HotKeyManager.signature, id: action.rawValue)
        let status = RegisterEventHotKey(keyCode, modifiers, id,
                                         GetApplicationEventTarget(), 0, &ref)
        if status != noErr {
            FileHandle.standardError.write(Data(
                "[hotkey] register failed for action \(action) (status=\(status))\n".utf8
            ))
        }
        refs.append(ref)
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind:  OSType(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, ud -> OSStatus in
            guard let eventRef = eventRef, let ud = ud else { return noErr }
            var hkID = EventHotKeyID()
            let s = GetEventParameter(eventRef,
                                      EventParamName(kEventParamDirectObject),
                                      EventParamType(typeEventHotKeyID),
                                      nil,
                                      MemoryLayout<EventHotKeyID>.size,
                                      nil, &hkID)
            guard s == noErr,
                  hkID.signature == HotKeyManager.signature,
                  let action = Action(rawValue: hkID.id) else {
                return noErr
            }
            let mgr = Unmanaged<HotKeyManager>.fromOpaque(ud).takeUnretainedValue()
            DispatchQueue.main.async { mgr.onAction?(action) }
            return noErr
        }, 1, &spec, userData, &handler)
    }

    deinit { disable() }
}
