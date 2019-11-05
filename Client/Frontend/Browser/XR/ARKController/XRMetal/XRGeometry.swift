
import Foundation
import MetalKit
import ModelIO

public class GeometryElement {
    public let indexBuffer: MTLBuffer
    public let primitiveType: MTLPrimitiveType
    public let indexBufferOffset: Int
    public let indexCount: Int
    public let indexType: MTLIndexType
    
    public var material = Material()
    
    public init(indexBuffer: MTLBuffer, offset: Int = 0, primitiveType: MTLPrimitiveType, indexCount: Int, indexType: MTLIndexType) {
        self.indexBuffer = indexBuffer
        self.indexBufferOffset = offset
        self.primitiveType = primitiveType
        self.indexCount = indexCount
        self.indexType = indexType
    }
}

open class Geometry {
    
    public var name: String?
    public let buffers: [MTLBuffer]
    public let elements: [GeometryElement]
    public let vertexDescriptor: MTLVertexDescriptor
    
    public init(buffers: [MTLBuffer], elements: [GeometryElement], vertexDescriptor: MTLVertexDescriptor) {
        self.buffers = buffers
        self.elements = elements
        self.vertexDescriptor = vertexDescriptor
    }
    
    public convenience init?(url: URL, bufferAllocator: BufferAllocator) {
        let vertexDescriptor = MDLVertexDescriptor()
        let attribute0 = vertexDescriptor.attributes[0] as! MDLVertexAttribute
        attribute0.bufferIndex = 0
        attribute0.name = MDLVertexAttributePosition
        attribute0.format = .float3
        attribute0.offset = 0

        let attribute1 = vertexDescriptor.attributes[1] as! MDLVertexAttribute
        attribute1.bufferIndex = 0
        attribute1.name = MDLVertexAttributeNormal
        attribute1.format = .float3
        attribute1.offset = MemoryLayout<Float>.stride * 3

        let attribute2 = vertexDescriptor.attributes[2] as! MDLVertexAttribute
        attribute2.bufferIndex = 0
        attribute2.name = MDLVertexAttributeTextureCoordinate
        attribute2.format = .float2
        attribute2.offset = MemoryLayout<Float>.stride * 6

        (vertexDescriptor.layouts[0] as! MDLVertexBufferLayout).stride = MemoryLayout<Float>.stride * 8
        
        let mdlBufferAllocator = MTKMeshBufferAllocator(device: bufferAllocator.device)

        let asset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: mdlBufferAllocator)

        asset.loadTextures()

        guard let (sourceMeshes, meshes) = try? MTKMesh.newMeshes(asset: asset, device: bufferAllocator.device) else {
            return nil
        }
        
        guard let firstMesh = meshes.first, let firstSourceMesh = sourceMeshes.first else { return nil }

        var buffers = [MTLBuffer]()
        for meshBuffer in firstMesh.vertexBuffers {
            assert(meshBuffer.offset == 0) // Not supported
            buffers.append(meshBuffer.buffer)
        }
        
        var elements = [GeometryElement]()
        for (sourceSubmesh, submesh) in zip(firstSourceMesh.submeshes as! [MDLSubmesh], firstMesh.submeshes) {
            let element = GeometryElement(indexBuffer: submesh.indexBuffer.buffer,
                                          offset: submesh.indexBuffer.offset,
                                          primitiveType: .triangle,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType)
            elements.append(element)
            
            if let submeshMaterial = sourceSubmesh.material {
                element.material.diffuse.contents = submeshMaterial.property(with: .baseColor)?.stringValue
            }
        }
        

        self.init(buffers: buffers, elements: elements, vertexDescriptor: Geometry.defaultVertexDescriptor)
    }
    
    static var defaultVertexDescriptor: MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        let bufferIndex = 0
        descriptor.attributes[Material.AttributeIndex.position].bufferIndex = bufferIndex
        descriptor.attributes[Material.AttributeIndex.position].format = .float3
        descriptor.attributes[Material.AttributeIndex.position].offset = 0
        
        descriptor.attributes[Material.AttributeIndex.normal].bufferIndex = bufferIndex
        descriptor.attributes[Material.AttributeIndex.normal].format = .float3
        descriptor.attributes[Material.AttributeIndex.normal].offset = MemoryLayout<Float>.stride * 3
        
        descriptor.attributes[Material.AttributeIndex.texCoords].bufferIndex = bufferIndex
        descriptor.attributes[Material.AttributeIndex.texCoords].format = .float2
        descriptor.attributes[Material.AttributeIndex.texCoords].offset = MemoryLayout<Float>.stride * 6
        
        descriptor.layouts[bufferIndex].stepFunction = .perVertex
        descriptor.layouts[bufferIndex].stepRate = 1
        descriptor.layouts[bufferIndex].stride = MemoryLayout<Float>.stride * 8
        return descriptor
    }
}
