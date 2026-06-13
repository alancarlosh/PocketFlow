import Foundation

struct PocketFlowSnapshot: Codable, Equatable, Sendable {
    var clients: [Client]
    var transactions: [Transaction]
    var syncQueue: [SyncQueueItem] = []
    var lastSyncDate: Date? = nil

    init(
        clients: [Client],
        transactions: [Transaction],
        syncQueue: [SyncQueueItem] = [],
        lastSyncDate: Date? = nil
    ) {
        self.clients = clients
        self.transactions = transactions
        self.syncQueue = syncQueue
        self.lastSyncDate = lastSyncDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        clients = try container.decode([Client].self, forKey: .clients)
        transactions = try container.decode([Transaction].self, forKey: .transactions)
        syncQueue = try container.decodeIfPresent([SyncQueueItem].self, forKey: .syncQueue) ?? []
        lastSyncDate = try container.decodeIfPresent(Date.self, forKey: .lastSyncDate)
    }
}

protocol PocketFlowDataStoring {
    func loadSnapshot() throws -> PocketFlowSnapshot?
    func saveSnapshot(_ snapshot: PocketFlowSnapshot) throws
}

final class LocalJSONPocketFlowDataStore: PocketFlowDataStoring {
    private let fileURL: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadSnapshot() throws -> PocketFlowSnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(PocketFlowSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: PocketFlowSnapshot) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportURL
            .appendingPathComponent("PocketFlow", isDirectory: true)
            .appendingPathComponent("pocketflow-data.json")
    }
}
