import Metal
import QuartzCore

/// Hosts only the Metal-rendered data curve.
final class MetalLineChartLayer: CAMetalLayer {
    private weak var drawer: LineChartDrawer?

    init(drawer: LineChartDrawer) {
        self.drawer = drawer
        super.init()
        isOpaque = false
        pixelFormat = .bgra8Unorm
        framebufferOnly = true
        needsDisplayOnBoundsChange = true

        guard let metalDevice = drawer.metalDevice else {
            isHidden = true
            return
        }
        device = metalDevice
    }

    override init(layer: Any) {
        if let source = layer as? MetalLineChartLayer {
            drawer = source.drawer
        }
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func display() {
        drawer?.drawMetalCurve(in: self)
    }
}
