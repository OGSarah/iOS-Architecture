import RealityKit
import SwiftUI

/// The full immersive space: one of the three excavation sites, built
/// entirely from procedural RealityKit primitives, with the board rendered
/// in situ where it was actually found.
///
/// The view is a dumb renderer of ``ExcavationViewModel`` and the placement
/// data inside each ``Excavation``. It knows nothing about matches and
/// nothing about what scene comes next.
struct ExcavationImmersiveView: View {

    /// The coordinator, read for the active excavation ViewModel.
    let coordinator: AppCoordinator

    var body: some View {
        if let viewModel = coordinator.activeExcavationViewModel {
            ExcavationContentView(viewModel: viewModel)
                .id(ObjectIdentifier(viewModel))
        }
    }
}

/// The RealityKit scene for one visit: sky, ground, props, the in situ
/// board, and the floating site panel.
private struct ExcavationContentView: View {

    let viewModel: ExcavationViewModel

    var body: some View {
        RealityView { content, attachments in
            let root = Entity()
            root.name = "siteRoot"
            content.add(root)
            SiteBuilder.build(site: viewModel.currentSite, boardPoints: viewModel.boardPoints, in: root)
            if let panel = attachments.entity(for: "panel") {
                panel.position = SIMD3(0.85, 1.25, -1.15)
                panel.look(at: SIMD3(0, 1.4, 0), from: panel.position, relativeTo: nil)
                content.add(panel)
            }
        } update: { content, _ in
            guard let root = content.entities.first(where: { $0.name == "siteRoot" }) else { return }
            let siteID = viewModel.currentSite.id
            if root.children.first?.name != siteID {
                root.children.removeAll()
                SiteBuilder.build(site: viewModel.currentSite, boardPoints: viewModel.boardPoints, in: root)
            }
        } attachments: {
            Attachment(id: "panel") {
                ExcavationPanel(viewModel: viewModel)
            }
        }
    }
}

/// The floating panel naming the site, telling its story, and offering the
/// site switcher and the way back.
private struct ExcavationPanel: View {

    let viewModel: ExcavationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.currentSite.name)
                .font(.title.bold())
                .foregroundStyle(Color(.sandLight))
            Text(viewModel.currentSite.era)
                .font(.headline)
                .foregroundStyle(Color(.sandMid))
            Text(viewModel.currentSite.blurb)
                .font(.callout)
                .frame(maxWidth: 380, alignment: .leading)

            HStack(spacing: 10) {
                ForEach(viewModel.sites) { site in
                    Button(site.name) {
                        viewModel.selectSite(id: site.id)
                    }
                    .buttonStyle(.bordered)
                    .tint(site.id == viewModel.currentSite.id ? Color(.sandLight) : nil)
                    .accessibilityIdentifier(AXID.Excavation.siteButton(site.id))
                }
            }

            Button {
                viewModel.returnTapped()
            } label: {
                Label("Return to the table", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.stoneDeep))
            .accessibilityIdentifier(AXID.Excavation.returnButton)
        }
        .padding(24)
        .glassBackgroundEffect()
        .accessibilityIdentifier(AXID.Excavation.panel)
    }
}

/// Builds a site's entity tree from its placement data.
@MainActor
private enum SiteBuilder {

    /// Assembles sky, ground, light, props, and the in situ board under a
    /// container named after the site, so the update closure can tell which
    /// site is currently built.
    static func build(site: Excavation, boardPoints: [PlayerColor?], in root: Entity) {
        let container = Entity()
        container.name = site.id
        root.addChild(container)

        container.addChild(makeSky(site: site))
        container.addChild(makeGround(site: site))
        container.addChild(makeSunlight(site: site))
        for prop in site.props {
            container.addChild(makeProp(prop))
        }
        container.addChild(makeBoard(site: site, boardPoints: boardPoints))
    }

    /// A large inverted sphere with a vertical gradient from the site's sky
    /// colors.
    private static func makeSky(site: Excavation) -> Entity {
        var material = UnlitMaterial()
        if let texture = makeGradientTexture(top: site.skyTop, bottom: site.skyHorizon) {
            material.color = .init(texture: .init(texture))
        } else {
            material.color = .init(tint: uiColor(site.skyHorizon))
        }
        let sky = ModelEntity(mesh: .generateSphere(radius: 60), materials: [material])
        sky.scale = SIMD3(-1, 1, 1)
        return sky
    }

    private static func makeGround(site: Excavation) -> Entity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: uiColor(site.groundColor))
        material.roughness = 1.0
        material.metallic = 0.0
        let ground = ModelEntity(
            mesh: .generateCylinder(height: 0.04, radius: site.groundRadius),
            materials: [material]
        )
        ground.position.y = -0.02
        return ground
    }

    /// A single angled directional light standing in for the site's sun or
    /// lamplight.
    private static func makeSunlight(site: Excavation) -> Entity {
        let light = Entity()
        light.components.set(DirectionalLightComponent(color: .white, intensity: site.lightIntensity))
        light.look(at: SIMD3(0.4, 0, -0.6), from: SIMD3(-2, 5, 2), relativeTo: nil)
        return light
    }

    private static func makeProp(_ prop: Excavation.Prop) -> Entity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: uiColor(prop.color))
        material.roughness = .init(floatLiteral: prop.roughness)
        material.metallic = 0.0
        let mesh: MeshResource
        switch prop.shape {
        case .box(let size):
            mesh = .generateBox(width: size.x, height: size.y, depth: size.z)
        case .cylinder(let radius, let height):
            mesh = .generateCylinder(height: height, radius: radius)
        }
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = prop.position
        entity.orientation = simd_quatf(angle: prop.yRotation, axis: SIMD3(0, 1, 0))
        return entity
    }

    /// The board carved where it was found, reusing the tabletop's board and
    /// stone builders so both renderers agree on the geometry.
    private static func makeBoard(site: Excavation, boardPoints: [PlayerColor?]) -> Entity {
        let board = StoneMillTable.makeBoardEntity(
            size: 0.5,
            thickness: 0.03,
            slabColor: uiColor(site.boardColor),
            grooveColor: UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1)
        )
        for point in Board.allPoints {
            guard let owner = boardPoints[point] else { continue }
            let stone = PieceEquipment.makeStoneEntity(color: owner)
            let position = Board.layoutPosition(of: point)
            stone.position = SIMD3(position.x, 0.002, position.y)
            board.addChild(stone)
        }
        board.position = site.boardPosition
        board.orientation = simd_quatf(angle: site.boardYRotation, axis: SIMD3(0, 1, 0))
        board.scale = SIMD3(repeating: site.boardScale)
        return board
    }

    private static func uiColor(_ color: Excavation.ColorValue) -> UIColor {
        UIColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: 1
        )
    }

    /// A small vertical gradient texture for the sky dome.
    private static func makeGradientTexture(top: Excavation.ColorValue, bottom: Excavation.ColorValue) -> TextureResource? {
        let height = 256
        let width = 8
        var pixels = [UInt8]()
        pixels.reserveCapacity(width * height * 4)
        for row in 0..<height {
            let t = Float(row) / Float(height - 1)
            let r = UInt8(((1 - t) * top.red + t * bottom.red) * 255)
            let g = UInt8(((1 - t) * top.green + t * bottom.green) * 255)
            let b = UInt8(((1 - t) * top.blue + t * bottom.blue) * 255)
            for _ in 0..<width {
                pixels.append(contentsOf: [r, g, b, 255])
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return nil
        }
        return try? TextureResource(
            image: image,
            options: TextureResource.CreateOptions(semantic: .color)
        )
    }
}
