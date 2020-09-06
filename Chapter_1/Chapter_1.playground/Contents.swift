//MetalKit is a framework to make using Metal simpler
import PlaygroundSupport
import MetalKit

//Tu tworzę urządzenia (GPU) wykorzystywane do wyświetlania
//Powinno być tworzone jedno urządzenie na start aplikacji i wielokrotnie używane
guard let device = MTLCreateSystemDefaultDevice() else {
  fatalError("GPU is not supported")
}


//Frame to klatka na, której będe "rysował"
let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
//View to widok na którym ta klatka będzie wyświetlana
//TMKView to subklasa NSView z MacOS lub UIView z iOS
let view = MTKView(frame: frame, device: device)
//clearColor to kolor do "czyszczenia" lub w tym przypadku BackGround color czyli kolor, na którym będzie wszystko wświetlane
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)

//Allocator zarządza pamięcią
let allocator = MTKMeshBufferAllocator(device: device)
//MDLMesh tworzy dpowiedni obiekt
let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                      segments: [90, 90],
                      inwardNormals: false,
                      geometryType: .triangles,
                      allocator: allocator)

let mesh = try MTKMesh(mesh: mdlMesh, device: device)

//Kolejka zadań, też powinna być jedna na cykl życia aplikacji
guard let commandQueue = device.makeCommandQueue() else {
  fatalError("Could not create a command queue")
}

//Verteks odpowiada za manipulacje punktami
//Fragmen za kolor
let shader = """
#include <metal_stdlib>
using namespace metal;
struct VertexIn {
  float4 position [[ attribute(0) ]];
};
vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
  return vertex_in.position;
}
fragment float4 fragment_main() {
  return float4(0.1, 0.1, 0.1, 1);
}
"""

let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")

//
let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction

pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)

//
let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

//
guard let commandBuffer = commandQueue.makeCommandBuffer(),
    let renderPassDescriptor = view.currentRenderPassDescriptor,
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {  fatalError() }

renderEncoder.setRenderPipelineState(pipelineState)

renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)

guard let submesh = mesh.submeshes.first else {
  fatalError()
}

renderEncoder.drawIndexedPrimitives(type: .triangle,
                                    indexCount: submesh.indexCount,
                                    indexType: submesh.indexType,
                                    indexBuffer: submesh.indexBuffer.buffer,
                                    indexBufferOffset: 0)

renderEncoder.endEncoding()
guard let drawable = view.currentDrawable else {
  fatalError()
}
commandBuffer.present(drawable)
commandBuffer.commit()




PlaygroundPage.current.liveView = view
