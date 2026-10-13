import SwiftUI

/// Has VoiceOver say `message`. High priority, so a screen change doesn't cut it off.
func announce(_ message: String) {
    var announcement = AttributedString(message)
    announcement.accessibilitySpeechAnnouncementPriority = .high
    AccessibilityNotification.Announcement(announcement).post()
}
