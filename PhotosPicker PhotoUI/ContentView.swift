import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    
    @State private var errorMessage: String?
    
    @State private var selectedImageData: Data?
    @State var caption: String = ""

    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
    
    // Fetch from database
    @Query(sort: \Feed.createdDate, order: .forward) var feeds: [Feed]
    
    var body: some View {
        VStack {
            Form {
                photoPickerSection
                imagesSection
                
                // Preview saved images
                Section {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(feeds, id: \.self) { item in
                            VStack {
                                if let imageData = item.image, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10.0))
                                }
                                
                                Text(item.caption)
                                
                                // Show tags
                                ForEach(item.tags ?? [], id: \.self) { tag in
                                    HStack {
                                        Text("#\(tag.label)")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem {
                Button(action: {
                   // save to swiftdata
                    
                    save()
                    
                }, label: {
                    Text("Save")
                })
            }
        })
    }
    
    private var photoPickerSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhotos,
                         maxSelectionCount: 1,
                         matching: .images) {
                Label("Select a photo", systemImage: "photo")
            }
            .onChange(of: selectedPhotos) { _ in
                loadSelectedPhotos()
            }
        }
    }
    
    
    private var imagesSection: some View {
        Section {
            ForEach(images, id: \.self) { image in
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10.0))
                        .padding(.vertical, 10)
                    
                    TextField("Type caption...", text: $caption)
                }
            }
        }
    }
    
    private func loadSelectedPhotos() {
        images.removeAll()
        errorMessage = nil
        
        Task {
            await withTaskGroup(of: (UIImage?, Error?).self) { taskGroup in
                for photoItem in selectedPhotos {
                    taskGroup.addTask {
                        do {
                            if let imageData = try await photoItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: imageData) {
                                
                                self.selectedImageData = imageData
                                
                                return (image, nil)
                            }
                            return (nil, nil)
                        } catch {
                            return (nil, error)
                        }
                    }
                }
                
                for await result in taskGroup {
                    if let error = result.1 {
                        errorMessage = "Failed to load one or more images."
                        break
                    } else if let image = result.0 {
                        images.append(image)
                    }
                }
            }
        }
    }
    
    func save() {
        
        // UIImage -> Data
        let feed = Feed(image: selectedImageData, caption: removeHashtags(from: caption))
        
        var tags: [Tag] = []
        
        let hashtags = extractHashtags(from: caption)
        hashtags.forEach { tag in
            tags.append(Tag(label: tag))
        }
        feed.tags = tags
        
        modelContext.insert(feed)
        
        print("Saved!")
    }
    
    func extractHashtags(from text: String) -> [String] {
        // Regular expression pattern to match hashtags
        let pattern = "#(\\w+)"
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        // Range of the entire string
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // Find matches
        let matches = regex.matches(in: text, options: [], range: range)
        
        // Extract hashtags from matches
        let hashtags = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[range])
        }
        
        return hashtags
    }
    
    func removeHashtags(from text: String) -> String {
        // Regular expression pattern to match hashtags
        let pattern = "#\\w+"
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        // Range of the entire string
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // Replace matches with an empty string
        let modifiedText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        
        // Trim any whitespace or newlines from the resulting string
        let trimmedText = modifiedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedText
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
