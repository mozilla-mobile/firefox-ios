
import Foundation
import Metal
import simd

public class Plane : Geometry {
    
    private struct Vertex {
        var position: packed_float3
        var normal: packed_float3
        var texCoords: packed_float2
    }

    init(vertices: [float3], texCoords: [float2], indices:[Int16], bufferAllocator: BufferAllocator) {
        let vertexBuffer = bufferAllocator.makeBuffer(length: MemoryLayout<Vertex>.stride * vertices.count)
        let indexBuffer = bufferAllocator.makeBuffer(length: MemoryLayout<UInt16>.stride * indices.count)

        let verticesPtr = vertexBuffer.contents().assumingMemoryBound(to: Vertex.self)
        let indicesPtr = indexBuffer.contents().assumingMemoryBound(to: UInt16.self)
        
        assert(indices.count > 2)
        
        let v0 = vertices[Int(indices[0])]
        let v1 = vertices[Int(indices[1])]
        let v2 = vertices[Int(indices[2])]
        let v10 = v1 - v0
        let v20 = v2 - v0
        let normal = normalize(simd_cross(v10, v20))
        
        for i in 0..<vertices.count {
            verticesPtr[i].position = packed_float3(vertices[i])
            verticesPtr[i].normal = packed_float3(normal)
            verticesPtr[i].texCoords = texCoords[i]
        }
        
        for i in 0..<indices.count {
            indicesPtr[i] = UInt16(indices[i])
        }

        let indexSource = GeometryElement(indexBuffer: indexBuffer, primitiveType: .triangle,
                                          indexCount: indices.count, indexType: .uint16)
        
        let descriptor = Geometry.defaultVertexDescriptor

        super.init(buffers: [vertexBuffer], elements: [indexSource], vertexDescriptor: descriptor)
    }
    
    init(width: Float, depth: Float, segments: Int, bufferAllocator: BufferAllocator) {
        let vertexCount = (segments + 1) * (segments + 1)
        let indexCount = (2 * segments + 3) * segments
        
        let vertexBuffer = bufferAllocator.makeBuffer(length: MemoryLayout<Vertex>.stride * vertexCount)
        let indexBuffer = bufferAllocator.makeBuffer(length: MemoryLayout<UInt32>.stride * indexCount)
        
        let vertices = vertexBuffer.contents().assumingMemoryBound(to: Vertex.self)
        let indices = indexBuffer.contents().assumingMemoryBound(to: UInt32.self)
        
        var i = 0
        let y = Float(0)
        var z = -depth / 2
        var t = Float(0)
        let deltaX = width / Float(segments)
        let deltaZ = depth / Float(segments)
        let deltaS = 1 / Float(segments)
        let deltaT = 1 / Float(segments)
        for _ in 0...segments {
            var x = -width / 2
            var s = Float(0)
            for _ in 0...segments {
                vertices[i].position = packed_float3(x, y, z)
                vertices[i].normal = packed_float3(0, 1, 0)
                vertices[i].texCoords = packed_float2(s, t)
                x += deltaX
                s += deltaS
                i += 1
            }
            t += deltaT
            z += deltaZ
        }

        i = 0
        
        let restart = UInt32.max
        for r in 0..<segments {
            indices[i] = UInt32((r + 1) * (segments + 1)); i += 1
            indices[i] = UInt32(r * (segments + 1)); i += 1
            for c in 0..<segments {
                indices[i] = UInt32((r + 1) * (segments + 1) + (c + 1)); i += 1
                indices[i] = UInt32(r * (segments + 1) + (c + 1)); i += 1
            }
            indices[i] = restart; i += 1
        }

        let indexSource = GeometryElement(indexBuffer: indexBuffer, primitiveType: .triangleStrip,
                                          indexCount: indexCount, indexType: .uint32)
        
        let descriptor = Plane.defaultVertexDescriptor

        super.init(buffers: [vertexBuffer], elements: [indexSource], vertexDescriptor: descriptor)
    }
}
