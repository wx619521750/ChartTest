import Metal
import QuartzCore
import UIKit

// Low-level Metal resources used by LineChartDrawer's curve drawing path.

private struct MetalChartUniforms {
    var dataBounds: SIMD4<Float>
    var viewport: SIMD4<Float>
    var plot: SIMD4<Float>
    var renderScale: SIMD4<Float>
    var baseColor: SIMD4<Float>
    var params: SIMD4<UInt32>
}

final class MetalLineChartRenderer {
    private weak var chartView: LineChartView?
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var pointBuffer: MTLBuffer?
    private var pointCapacity = 0
    private var rangeBuffer: MTLBuffer?
    private var colorBuffer: MTLBuffer?
    private var rangeCapacity = 0
    private var gapBuffer: MTLBuffer?
    private var gapCapacity = 0
    private var multisampleTexture: MTLTexture?
    let sampleCount: Int

    init?(device: MTLDevice, chartView: LineChartView) {
        guard let commandQueue = device.makeCommandQueue() else { return nil }
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct Uniforms {
            float4 dataBounds;
            float4 viewport;
            float4 plot;
            float4 renderScale;
            float4 baseColor;
            uint4 params;
        };

        struct VertexOut {
            float4 position [[position]];
            float dataY;
            float valid;
        };

        float2 screenPoint(float2 data, constant Uniforms& uniforms) {
            float xProgress = (data.x - uniforms.dataBounds.x)
                / max(uniforms.dataBounds.y - uniforms.dataBounds.x, 0.000001);
            float yProgress = (data.y - uniforms.dataBounds.z)
                / max(uniforms.dataBounds.w - uniforms.dataBounds.z, 0.000001);
            return float2(
                uniforms.viewport.z + xProgress * uniforms.plot.x,
                uniforms.viewport.w + (1.0 - yProgress) * uniforms.plot.y
            );
        }

        float2 cubicPoint(float2 start, float2 control1, float2 control2, float2 end, float t) {
            float oneMinusT = 1.0 - t;
            return oneMinusT * oneMinusT * oneMinusT * start
                + 3.0 * oneMinusT * oneMinusT * t * control1
                + 3.0 * oneMinusT * t * t * control2
                + t * t * t * end;
        }

        vertex VertexOut chartVertex(
            uint vertexID [[vertex_id]],
            uint instanceID [[instance_id]],
            constant float4* points [[buffer(0)]],
            constant Uniforms& uniforms [[buffer(1)]]) {
            VertexOut output;
            uint subdivisions = max(uniforms.params.x, 1u);
            uint segmentIndex = instanceID / subdivisions;
            uint subdivisionIndex = instanceID % subdivisions;
            float4 first = points[segmentIndex];
            float4 second = points[segmentIndex + 1];
            if (first.z < 0.5 || second.z < 0.5) {
                output.position = float4(2.0, 2.0, 0.0, 1.0);
                output.dataY = 0.0;
                output.valid = 0.0;
                return output;
            }

            float t0 = float(subdivisionIndex) / float(subdivisions);
            float t1 = float(subdivisionIndex + 1) / float(subdivisions);
            float2 data0 = first.xy;
            float2 data1 = second.xy;
            float2 start = screenPoint(data0, uniforms);
            float2 end = screenPoint(data1, uniforms);
            float2 point0;
            float2 point1;
            float dataY0;
            float dataY1;
            if (uniforms.params.y == 1u) {
                float2 control1 = float2((start.x + end.x) * 0.5, start.y);
                float2 control2 = float2((start.x + end.x) * 0.5, end.y);
                point0 = cubicPoint(start, control1, control2, end, t0);
                point1 = cubicPoint(start, control1, control2, end, t1);
                dataY0 = cubicPoint(data0, float2((data0.x + data1.x) * 0.5, data0.y),
                    float2((data0.x + data1.x) * 0.5, data1.y), data1, t0).y;
                dataY1 = cubicPoint(data0, float2((data0.x + data1.x) * 0.5, data0.y),
                    float2((data0.x + data1.x) * 0.5, data1.y), data1, t1).y;
            } else {
                point0 = mix(start, end, t0);
                point1 = mix(start, end, t1);
                dataY0 = mix(data0.y, data1.y, t0);
                dataY1 = mix(data0.y, data1.y, t1);
            }

            float2 delta = point1 - point0;
            if (length(delta) < 0.0001) {
                output.position = float4(2.0, 2.0, 0.0, 1.0);
                output.dataY = dataY0;
                output.valid = 0.0;
                return output;
            }
            float2 direction = normalize(delta);
            float halfWidth = uniforms.plot.z * 0.5;
            point0 -= direction * halfWidth;
            point1 += direction * halfWidth;
            float2 normal = float2(-direction.y, direction.x) * halfWidth;
            float2 corners[4] = { point0 + normal, point0 - normal, point1 + normal, point1 - normal };
            uint cornerIndices[6] = { 0, 1, 2, 2, 1, 3 };
            uint cornerIndex = cornerIndices[vertexID];
            float2 position = corners[cornerIndex];
            float2 ndc = float2(
                position.x / uniforms.viewport.x * 2.0 - 1.0,
                1.0 - position.y / uniforms.viewport.y * 2.0
            );
            output.position = float4(ndc, 0.0, 1.0);
            output.dataY = cornerIndex < 2 ? dataY0 : dataY1;
            output.valid = 1.0;
            return output;
        }

        fragment float4 chartFragment(
            VertexOut input [[stage_in]],
            constant Uniforms& uniforms [[buffer(0)]],
            constant float4* ranges [[buffer(1)]],
            constant float4* colors [[buffer(2)]],
            constant float4* gaps [[buffer(3)]]) {
            if (input.valid < 0.5) { discard_fragment(); }
            float screenX = input.position.x / max(uniforms.renderScale.x, 0.000001);
            float xProgress = (screenX - uniforms.viewport.z)
                / max(uniforms.plot.x, 0.000001);
            float dataX = uniforms.dataBounds.x
                + xProgress * (uniforms.dataBounds.y - uniforms.dataBounds.x);
            for (uint index = 0; index < uniforms.params.w; ++index) {
                if (dataX > gaps[index].x && dataX < gaps[index].y) {
                    discard_fragment();
                }
            }
            float screenY = input.position.y / max(uniforms.renderScale.y, 0.000001);
            float yProgress = 1.0 - (screenY - uniforms.viewport.w)
                / max(uniforms.plot.y, 0.000001);
            float fragmentDataY = uniforms.dataBounds.z
                + yProgress * (uniforms.dataBounds.w - uniforms.dataBounds.z);
            for (uint index = 0; index < uniforms.params.z; ++index) {
                if (fragmentDataY <= ranges[index].x && fragmentDataY >= ranges[index].y) {
                    return colors[index];
                }
            }
            return uniforms.baseColor;
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            guard let vertex = library.makeFunction(name: "chartVertex"),
                  let fragment = library.makeFunction(name: "chartFragment") else { return nil }
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            let supportsMSAA = device.supportsTextureSampleCount(4)
            sampleCount = supportsMSAA ? 4 : 1
            descriptor.rasterSampleCount = sampleCount
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        self.chartView = chartView
    }

    func draw(in layer: CAMetalLayer) {
        guard let chartView,
              chartView.usesMetalRendering,
              layer.bounds.width > 0,
              layer.bounds.height > 0,
              let drawable = layer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let pass = renderPassDescriptor(drawable: drawable)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }

        let model = chartView.chartModel
        let points = model.lineModel.pointsShouldDraw
        guard points.count > 1 else {
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        let xOrigin = model.minX
        let packedPoints = points.map {
            SIMD4<Float>(Float($0.x - xOrigin), Float($0.y), $0.dataType == .data ? 1 : 0, 0)
        }
        ensurePointBuffer(device: device, count: packedPoints.count)
        packedPoints.withUnsafeBytes { bytes in
            if let baseAddress = bytes.baseAddress {
                pointBuffer?.contents().copyMemory(from: baseAddress, byteCount: bytes.count)
            }
        }

        let ranges = model.verticalColorRnages
        ensureRangeBuffers(device: device, count: max(ranges.count, 1))
        var packedRanges = ranges.map { SIMD4<Float>(Float($0.top), Float($0.bottom), 0, 0) }
        var packedColors = ranges.map { rgba($0.color) }
        if packedRanges.isEmpty {
            packedRanges = [SIMD4<Float>(0, 0, 0, 0)]
            packedColors = [SIMD4<Float>(0, 0, 0, 0)]
        }
        packedRanges.withUnsafeBytes { bytes in
            rangeBuffer?.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        }
        packedColors.withUnsafeBytes { bytes in
            colorBuffer?.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        }

        let gaps = model.lineModel.emptyAreas
        ensureGapBuffer(device: device, count: max(gaps.count, 1))
        var packedGaps = gaps.map {
            SIMD4<Float>(Float($0.left - xOrigin), Float($0.right - xOrigin), 0, 0)
        }
        if packedGaps.isEmpty {
            packedGaps = [SIMD4<Float>(0, 0, 0, 0)]
        }
        packedGaps.withUnsafeBytes { bytes in
            gapBuffer?.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        }

        let lineStyle = model.lineModel.datalineStyle
        let lineWidth: CGFloat
        let baseColor: UIColor
        let isBezier: Bool
        switch lineStyle {
        case .straight(let width, let color):
            lineWidth = width; baseColor = color; isBezier = false
        case .bezier(let width, let color):
            lineWidth = width; baseColor = color; isBezier = true
        }
        let inset = model.chartContentInsert
        let subdivisions: UInt32 = isBezier
            ? subdivisionCount(points: points, model: model, size: layer.bounds.size)
            : 1
        let drawableScaleX = layer.drawableSize.width / layer.bounds.width
        let drawableScaleY = layer.drawableSize.height / layer.bounds.height
        var uniforms = MetalChartUniforms(
            dataBounds: SIMD4<Float>(
                0,
                Float(model.maxX - xOrigin),
                Float(model.minY),
                Float(model.maxY)
            ),
            viewport: SIMD4<Float>(Float(layer.bounds.width), Float(layer.bounds.height), Float(inset.left), Float(inset.top)),
            plot: SIMD4<Float>(
                Float(layer.bounds.width - inset.left - inset.right),
                Float(layer.bounds.height - inset.top - inset.bottom),
                Float(lineWidth),
                0
            ),
            renderScale: SIMD4<Float>(Float(drawableScaleX), Float(drawableScaleY), 0, 0),
            baseColor: rgba(baseColor),
            params: SIMD4<UInt32>(subdivisions, isBezier ? 1 : 0, UInt32(ranges.count), UInt32(gaps.count))
        )

        encoder.setScissorRect(MTLScissorRect(
            x: max(0, Int(inset.left * drawableScaleX)),
            y: max(0, Int(inset.top * drawableScaleY)),
            width: max(1, Int((layer.bounds.width - inset.left - inset.right) * drawableScaleX)),
            height: max(1, Int((layer.bounds.height - inset.top - inset.bottom) * drawableScaleY))
        ))
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(pointBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalChartUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalChartUniforms>.stride, index: 0)
        encoder.setFragmentBuffer(rangeBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(colorBuffer, offset: 0, index: 2)
        encoder.setFragmentBuffer(gapBuffer, offset: 0, index: 3)
        encoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: 6,
            instanceCount: (points.count - 1) * Int(subdivisions)
        )
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func renderPassDescriptor(drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        let attachment = descriptor.colorAttachments[0]!
        attachment.clearColor = MTLClearColorMake(0, 0, 0, 0)
        attachment.loadAction = .clear
        if sampleCount > 1 {
            let texture = ensureMultisampleTexture(size: drawable.texture.width, height: drawable.texture.height)
            attachment.texture = texture
            attachment.resolveTexture = drawable.texture
            attachment.storeAction = .multisampleResolve
        } else {
            attachment.texture = drawable.texture
            attachment.storeAction = .store
        }
        return descriptor
    }

    private func ensureMultisampleTexture(size: Int, height: Int) -> MTLTexture? {
        if multisampleTexture?.width == size, multisampleTexture?.height == height {
            return multisampleTexture
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: size,
            height: height,
            mipmapped: false
        )
        descriptor.textureType = .type2DMultisample
        descriptor.sampleCount = sampleCount
        descriptor.storageMode = .private
        descriptor.usage = .renderTarget
        multisampleTexture = device.makeTexture(descriptor: descriptor)
        return multisampleTexture
    }

    private func subdivisionCount(
        points: [ChartPointModel],
        model: ChartModel,
        size: CGSize
    ) -> UInt32 {
        let xRange = model.maxX - model.minX
        let yRange = model.maxY - model.minY
        guard xRange > 0, yRange > 0 else { return 16 }
        let plotWidth = size.width - model.chartContentInsert.left - model.chartContentInsert.right
        let plotHeight = size.height - model.chartContentInsert.top - model.chartContentInsert.bottom
        var maximumDistance: CGFloat = 0
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            guard previous.dataType == .data, current.dataType == .data else { continue }
            let dx = CGFloat((current.x - previous.x) / xRange) * plotWidth
            let dy = CGFloat((current.y - previous.y) / yRange) * plotHeight
            maximumDistance = max(maximumDistance, hypot(dx, dy))
        }
        return UInt32(min(64, max(16, Int(ceil(maximumDistance / 3)))))
    }

    private func ensurePointBuffer(device: MTLDevice, count: Int) {
        guard count > pointCapacity else { return }
        pointCapacity = max(count, pointCapacity * 2, 256)
        pointBuffer = device.makeBuffer(
            length: pointCapacity * MemoryLayout<SIMD4<Float>>.stride,
            options: .storageModeShared
        )
    }

    private func ensureRangeBuffers(device: MTLDevice, count: Int) {
        guard count > rangeCapacity else { return }
        rangeCapacity = max(count, rangeCapacity * 2, 4)
        let length = rangeCapacity * MemoryLayout<SIMD4<Float>>.stride
        rangeBuffer = device.makeBuffer(length: length, options: .storageModeShared)
        colorBuffer = device.makeBuffer(length: length, options: .storageModeShared)
    }

    private func ensureGapBuffer(device: MTLDevice, count: Int) {
        guard count > gapCapacity else { return }
        gapCapacity = max(count, gapCapacity * 2, 4)
        gapBuffer = device.makeBuffer(
            length: gapCapacity * MemoryLayout<SIMD4<Float>>.stride,
            options: .storageModeShared
        )
    }

    private func rgba(_ color: UIColor) -> SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha))
    }
}
