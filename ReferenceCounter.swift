import Foundation

class WeakBox {
    weak var value: AnyObject?
    var sourceInfo: SourceInfo
    
    init(_ value: AnyObject, sourceInfo: SourceInfo) {
        self.value = value
        self.sourceInfo = sourceInfo
    }
}

struct SourceInfo {
    var file: String
    var function: String
    var line: Int
    
    var description: String {
        let fileName = URL(string: file)?.lastPathComponent ?? file
        return "\(fileName):\(line) \(function)"
    }
}

class ReferenceCounter {
    static let shared = ReferenceCounter()
    
    private var objectMap = [String: [WeakBox]]()
    
    private init() { }
    
    func track(_ object: AnyObject, file: String = #file, function: String = #function, line: Int = #line) {
        let sourceInfo = SourceInfo(file: file, function: function, line: line)
        track(object, sourceInfo: sourceInfo)
    }
    
    func track(_ object: AnyObject, sourceInfo: SourceInfo) {
        let name = getObjectName(object)
        var objects = getLiveObjectsList(name: name)
        objects.append(.init(object, sourceInfo: sourceInfo))
        objectMap[name] = objects
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
            self.report(name: name)
        }
    }
    
    private func report(name: String) {
        let objects = getLiveObjectsList(name: name)
        let count = objects.count
        if count > 1 {
            print("MEMORY LEAK: \(name) count: \(objects.count)")
            for object in objects {
                print("Object \(name) created at: \(object.sourceInfo.description)")
            }
        }
    }
    
    private func getLiveObjectsList(name: String) -> [WeakBox] {
        objectMap[name]?.filter({ $0.value != nil }) ?? []
    }
    
    private func getObjectName(_ object: AnyObject) -> String {
        String(describing: type(of: object))
    }
}
