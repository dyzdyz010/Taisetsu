import Foundation
import TaisetsuCore
import WidgetKit

struct TaisetsuWatchWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchSnapshot
    var relevance: TimelineEntryRelevance?
}
