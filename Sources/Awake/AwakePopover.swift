import AppKit
import SwiftUI
import AwakeCore

struct AwakePopover: View {
    @ObservedObject var model: SleepModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            keepAwakeRow
            durationRow
            displayRow
            loginRow
            statusRow
            if model.systemSleepLocked && !model.keepAwake {
                VStack(alignment: .leading, spacing: 6) {
                    Text(" Sleep is locked by an old pmset setting. Awake is off, but the Apple menu stays gray until this is cleared.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Unlock Apple Sleep…") {
                        model.unlockSystemSleep()
                    }
                    .controlSize(.small)
                }
            }
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            about
        }
        .padding(18)
        .frame(width: 280)
        .background(.regularMaterial)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.keepAwake)
        .task { await model.load() }
    }

    private var statusLabel: String {
        if model.keepAwake { return "Sleep disabled" }
        if model.systemSleepLocked { return "Apple Sleep still locked" }
        return "Sleep allowed"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1"
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("AWAKE")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.secondary)
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit Awake")
            .accessibilityLabel("Quit Awake")
            .keyboardShortcut("q")
        }
    }

    private var keepAwakeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: model.keepAwake ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(model.keepAwake ? Color.green : Color.secondary)
                .frame(width: 36, height: 36)
                .background(
                    model.keepAwake ? Color.green.opacity(0.12) : Color.primary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 11)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Disable sleep")
                    .font(.system(size: 14, weight: .semibold))
                Text(model.keepAwake ? "Sleep disabled" : "Sleep allowed")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Toggle("Disable sleep", isOn: Binding(
                get: { model.keepAwake },
                set: { value in Task { await model.setKeepAwake(value) } }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.green)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityHint("Prevents this Mac from sleeping while Awake is on. Sleep is allowed again when you turn this off or quit.")
        }
    }

    private var durationRow: some View {
        HStack {
            Text("Duration")
                .font(.system(size: 12))
            Spacer()
            Picker("Duration", selection: Binding(
                get: { model.duration },
                set: { value in Task { await model.setDuration(value) } }
            )) {
                ForEach(AwakeDuration.allCases, id: \.self) { duration in
                    Text(duration.title).tag(duration)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .disabled(model.isBusy)
            .accessibilityHint("How long to keep the Mac awake.")
        }
    }

    private var displayRow: some View {
        Toggle(
            "Keep display on",
            isOn: Binding(
                get: { model.preventDisplaySleep },
                set: { value in Task { await model.setPreventDisplaySleep(value) } }
            )
        )
        .font(.system(size: 12))
        .toggleStyle(.checkbox)
        .controlSize(.small)
        .disabled(model.isBusy)
        .accessibilityHint("When off, the display may sleep while the Mac stays awake.")
    }

    private var loginRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                )
            )
            .font(.system(size: 12))
            .toggleStyle(.checkbox)
            .controlSize(.small)
            Text("Works after moving Awake to Applications.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(model.keepAwake ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 4, height: 4)
            Text(statusLabel)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            if model.isBusy {
                ProgressView().controlSize(.mini).accessibilityLabel("Updating")
            }
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 3) {
            Divider()
            Text("Mario Codarin · v\(appVersion)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("Blocks idle sleep. Lid close and  → Sleep still work.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link("github.com/MarioCodarin/Awake", destination: URL(string: "https://github.com/MarioCodarin/Awake")!)
                .font(.system(size: 10))
        }
        .padding(.top, 2)
    }
}
