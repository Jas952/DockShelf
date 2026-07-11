import Foundation

final class LoginItemService: ObservableObject {
    @Published private(set) var isEnabled: Bool = false

    private let label: String

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    init(label: String = Bundle.main.bundleIdentifier ?? "local.codex.DockShelf") {
        self.label = label
        refresh()
    }

    func refresh() {
        isEnabled = FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try installLaunchAgent()
        } else {
            try removeLaunchAgent()
        }
        refresh()
    }

    private func installLaunchAgent() throws {
        guard let executable = Bundle.main.executableURL else {
            throw CocoaError(.fileNoSuchFile)
        }

        let directory = launchAgentURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>\(executable.path)</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
        """

        try plist.write(to: launchAgentURL, atomically: true, encoding: .utf8)
    }

    private func removeLaunchAgent() throws {
        if FileManager.default.fileExists(atPath: launchAgentURL.path) {
            try FileManager.default.removeItem(at: launchAgentURL)
        }
    }
}
