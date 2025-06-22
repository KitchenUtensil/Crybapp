import Foundation
import Supabase

// MARK: - Auth User Model
struct AuthUser: Codable {
    let id: UUID
    let email: String
    let userMetadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }
}

// MARK: - User Model
struct CrybUser: Codable, Identifiable {
    let id: UUID
    let email: String?
    let displayName: String?
    let houseId: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case houseId = "house_id"
        case createdAt = "created_at"
    }
}

// MARK: - House Model
struct House: Codable, Identifiable {
    let id: UUID
    let name: String
    let code: String
    let createdAt: Date
    let createdBy: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}

// MARK: - House Request Models
struct CreateHouseRequest: Encodable {
    let name: String
    let code: String
    let createdBy: UUID
    
    enum CodingKeys: String, CodingKey {
        case name
        case code
        case createdBy = "created_by"
    }
}

struct JoinHouseRequest: Encodable {
    let houseId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case houseId = "house_id"
        case userId = "user_id"
    }
}

// MARK: - Chore Model
struct Chore: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let dueDate: Date?
    let isCompleted: Bool
    let assignedUserId: String?
    let houseId: String
    let createdBy: String
    let createdAt: Date
    let recurrence: RecurrenceType?
    let points: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case dueDate = "due_date"
        case isCompleted = "is_completed"
        case assignedUserId = "assigned_user_id"
        case houseId = "house_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case recurrence
        case points
    }
}

// MARK: - Chore Request Models
struct CreateChoreRequest: Encodable {
    let title: String
    let description: String
    let dueDate: String
    let assignedUserId: String
    let houseId: String
    let createdBy: String
    let recurrence: RecurrenceType
    let points: Int
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case dueDate = "due_date"
        case assignedUserId = "assigned_user_id"
        case houseId = "house_id"
        case createdBy = "created_by"
        case recurrence
        case points
        case isCompleted = "is_completed"
    }
}

struct UpdateChoreCompletionRequest: Encodable {
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case isCompleted = "is_completed"
    }
}

struct UpdateChoreAssignmentRequest: Encodable {
    let assignedUserId: String
    
    enum CodingKeys: String, CodingKey {
        case assignedUserId = "assigned_user_id"
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .none: return "No Recurrence"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Expense Model
struct Expense: Codable, Identifiable {
    let id: String
    let title: String
    let amount: Double
    let description: String?
    let paidBy: String
    let houseId: String
    let createdAt: Date
    let category: String?
    let sharedWith: [String]? // Array of user IDs
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case description
        case paidBy = "paid_by"
        case houseId = "house_id"
        case createdAt = "created_at"
        case category
        case sharedWith = "shared_with"
    }
}

// MARK: - Expense Request Models
struct CreateExpenseRequest: Encodable {
    let title: String
    let amount: Double
    let description: String?
    let paidBy: String
    let houseId: String
    let category: String?
    let sharedWith: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case amount
        case description
        case paidBy = "paid_by"
        case houseId = "house_id"
        case category
        case sharedWith = "shared_with"
    }
}

struct UpdateExpenseRequest: Encodable {
    let title: String
    let amount: Double
    let description: String?
    let category: String?
    let sharedWith: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case amount
        case description
        case category
        case sharedWith = "shared_with"
    }
}

// MARK: - Note Model
struct Note: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let houseId: String
    let createdBy: String
    let createdAt: Date
    let isPinned: Bool
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case houseId = "house_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case isPinned = "is_pinned"
        case tags
    }
}

// MARK: - Note Request Models
struct CreateNoteRequest: Encodable {
    let title: String
    let content: String
    let houseId: String
    let createdBy: String
    let isPinned: Bool
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case houseId = "house_id"
        case createdBy = "created_by"
        case isPinned = "is_pinned"
        case tags
    }
}

struct UpdateNoteRequest: Encodable {
    let title: String
    let content: String
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case tags
    }
}

struct UpdateNotePinRequest: Encodable {
    let isPinned: Bool
    
    enum CodingKeys: String, CodingKey {
        case isPinned = "is_pinned"
    }
}

// MARK: - House Rules Model
struct HouseRules: Codable, Identifiable {
    let id: String
    let content: String
    let houseId: String
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case houseId = "house_id"
        case updatedAt = "updated_at"
    }
}

// MARK: - Balance Summary Model
struct BalanceSummary: Codable {
    let youOwe: Double
    let youAreOwed: Double
    let netBalance: Double
    
    enum CodingKeys: String, CodingKey {
        case youOwe = "you_owe"
        case youAreOwed = "you_are_owed"
        case netBalance = "net_balance"
    }
} 