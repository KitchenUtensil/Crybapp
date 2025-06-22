import Foundation
import Supabase

struct SupabaseConfig {
    static let shared = SupabaseClient(
        supabaseURL: URL(string: "https://krrsltregsxmbspauqnd.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycnNsdHJlZ3N4bWJzcGF1cW5kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0OTE0NTcsImV4cCI6MjA2MjA2NzQ1N30.-pgwV2srfasomvwoX-Sxj8iox6Io-eW7xiY4X6BBAlw"
    )
} 
