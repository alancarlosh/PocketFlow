import Foundation

struct Client: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var company: String
    var status: ClientStatus
    var salesforceAccountId: String?

    init(
        id: UUID = UUID(),
        name: String,
        company: String,
        status: ClientStatus = .active,
        salesforceAccountId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.company = company
        self.status = status
        self.salesforceAccountId = salesforceAccountId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        company = try container.decode(String.self, forKey: .company)
        status = try container.decodeIfPresent(ClientStatus.self, forKey: .status) ?? .active
        salesforceAccountId = try container.decodeIfPresent(String.self, forKey: .salesforceAccountId)
    }
}

enum ClientStatus: String, CaseIterable, Codable, Sendable {
    case lead = "Lead"
    case prospect = "Prospecto"
    case active = "Activo"
    case paused = "En pausa"
    case closed = "Cerrado"
}
