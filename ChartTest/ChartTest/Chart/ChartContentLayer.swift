import QuartzCore

/// Draws every chart element except the Metal data curve.
final class ChartContentLayer: CALayer {
    private weak var drawer: LineChartDrawer?

    init(drawer: LineChartDrawer) {
        self.drawer = drawer
        super.init()
        isOpaque = false
        needsDisplayOnBoundsChange = true
    }

    override init(layer: Any) {
        if let source = layer as? ChartContentLayer {
            drawer = source.drawer
        }
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in context: CGContext) {
        drawer?.drawChartContent(in: self, context: context)
    }
}
