import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FitMitJoditWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state, name: context.attributes.workoutName)
                .activityBackgroundTint(Theme.color(for: context.state.kind))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.kind.label, systemImage: context.state.kind.symbolName)
                        .font(.caption.bold())
                        .foregroundStyle(Theme.color(for: context.state.kind))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(state: context.state)
                        .font(.title2.bold().monospacedDigit())
                        .frame(maxWidth: 90)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 2) {
                        Text(context.state.blockName).font(.headline).lineLimit(1)
                        if let next = context.state.nextName {
                            Text("Danach: \(next)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.kind.symbolName)
                    .foregroundStyle(Theme.color(for: context.state.kind))
            } compactTrailing: {
                CountdownText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                CountdownText(state: context.state)
                    .monospacedDigit()
                    .font(.caption2)
            }
        }
    }
}

struct CountdownText: View {
    let state: WorkoutActivityAttributes.ContentState
    var body: some View {
        if state.isPaused {
            Text(DurationFormat.clock(state.pausedRemaining))
        } else {
            Text(timerInterval: state.blockStart...state.blockEnd, countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState
    let name: String
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.kind.label.uppercased()).font(.caption.bold()).opacity(0.85)
                Text(state.blockName).font(.title2.bold()).lineLimit(1)
                HStack(spacing: 8) {
                    if let r = state.roundText { Text(r) }
                    if let next = state.nextName { Text("Danach: \(next)").lineLimit(1) }
                }
                .font(.caption).opacity(0.85)
            }
            Spacer()
            CountdownText(state: state)
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .frame(maxWidth: 140, alignment: .trailing)
        }
        .foregroundStyle(.white)
        .padding()
    }
}
