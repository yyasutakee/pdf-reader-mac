public enum PDFAssistantAvailability: Equatable {
    case available
    case unavailable(title: String, description: String)
}
