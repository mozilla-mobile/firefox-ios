
import Foundation
import Metal

open class BufferAllocator {
    public let device: MTLDevice
    
    private let allocationQueue = DispatchQueue(label: "com.metalbyexample.alloc-queue")
    
    private var pool: [MTLBuffer]

    public init(device: MTLDevice) {
        self.device = device
        pool = []
    }
    
    public func makeBuffer(length: Int) -> MTLBuffer {
        return device.makeBuffer(length: length, options: [.storageModeShared])!
    }

    public func dequeueReusableBuffer(length: Int) -> MTLBuffer {
        var removedIndex: Int? = nil
        var buffer: MTLBuffer? = nil
        
        return allocationQueue.sync {
            for i in 0 ..< pool.count {
                if pool[i].length >= length {
                    buffer = pool[i]
                    removedIndex = i
                }
            }
            
            if let index = removedIndex, let buffer = buffer {
                pool.remove(at: index)
                return buffer
            }
            
            return makeBuffer(length: length)
        }
    }
    
    public func enqueueReusableBuffer(_ buffer: MTLBuffer) {
        allocationQueue.sync {
            pool.append(buffer)
        }
    }
}
