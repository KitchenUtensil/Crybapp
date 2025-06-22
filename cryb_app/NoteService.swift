import Foundation
import Supabase
import Combine

@MainActor
class NoteService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var notes: [Note] = []
    @Published var pinnedNotes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchNotes(houseId: String) async {
        isLoading = true
        
        do {
            let response: [Note] = try await supabase
                .from("notes")
                .select()
                .eq("house_id", value: houseId)
                .order("is_pinned", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            notes = response
            pinnedNotes = response.filter { $0.isPinned }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createNote(title: String, content: String, tags: [String]?, houseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            let request = CreateNoteRequest(
                title: title,
                content: content,
                houseId: houseId,
                createdBy: userId,
                isPinned: false,
                tags: tags ?? []
            )
            
            let response: [Note] = try await supabase
                .from("notes")
                .insert(request)
                .execute()
                .value
            
            if let note = response.first {
                notes.insert(note, at: 0)
                updatePinnedNotes()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateNote(_ note: Note, title: String, content: String, tags: [String]?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateNoteRequest(
                title: title,
                content: content,
                tags: tags ?? []
            )
            
            let response: [Note] = try await supabase
                .from("notes")
                .update(request)
                .eq("id", value: note.id)
                .execute()
                .value
            
            if let updatedNote = response.first {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index] = updatedNote
                }
                updatePinnedNotes()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func togglePinNote(_ note: Note) async {
        guard let _ = Int(note.id) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateNotePinRequest(isPinned: !note.isPinned)
            
            let response: [Note] = try await supabase
                .from("notes")
                .update(request)
                .eq("id", value: note.id)
                .execute()
                .value
            
            if let updatedNote = response.first {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index] = updatedNote
                }
                updatePinnedNotes()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteNote(_ note: Note) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("notes")
                .delete()
                .eq("id", value: note.id)
                .execute()
            
            notes.removeAll { $0.id == note.id }
            updatePinnedNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func updatePinnedNotes() {
        pinnedNotes = notes.filter { $0.isPinned }
    }
    
    func searchNotes(query: String) -> [Note] {
        if query.isEmpty {
            return notes
        }
        
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            (note.tags?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
        }
    }
    
    func getNotesByTag(_ tag: String) -> [Note] {
        return notes.filter { note in
            note.tags?.contains(tag) ?? false
        }
    }
    
    func getAllTags() -> [String] {
        let allTags = notes.compactMap { $0.tags }.flatMap { $0 }
        return Array(Set(allTags)).sorted()
    }
} 