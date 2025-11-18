import CoreData
import Foundation

/// Manages Core Data persistence layer
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Add sample data for previews
        let context = controller.container.viewContext

        // Sample census
        let census = CensusEntity(context: context)
        census.id = UUID().uuidString
        census.name = "Sample Census"
        census.censusDescription = "A sample census for preview"
        census.active = true
        census.totalMembers = 150

        do {
            try context.save()
        } catch {
            fatalError("Preview context save failed: \(error)")
        }

        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "zkCensus")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }

    func delete(_ object: NSManagedObject) {
        let context = container.viewContext
        context.delete(object)
        save()
    }

    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type))

        do {
            let objects = try context.fetch(fetchRequest)
            objects.forEach { context.delete($0) }
            save()
        } catch {
            print("Delete all error: \(error)")
        }
    }

    func clearAllData() {
        let entities = container.managedObjectModel.entities

        entities.forEach { entity in
            if let name = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try container.viewContext.execute(deleteRequest)
                } catch {
                    print("Failed to delete \(name): \(error)")
                }
            }
        }

        save()
    }
}
