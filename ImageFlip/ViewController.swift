import UIKit
import MetalKit
import PHAssetPicker
import SnapKit
import MetalView
import Alloy
import Photos
import MetalPerformanceShaders

class ViewController: UIViewController {

    private var metalView: MetalView!
    private var context: MTLContext!
    private var textureFlip: TextureFlip!
    private var textureCopy: TextureCopy!
    private var chooseImageButton: UIButton!
    private var flipTextureButton: UIButton!
    private var shareImageButton: UIButton!
    private var assetPickerController: PHAssetPickerController!
    private var imageManager: PHImageManager!
    private var imageRequestOptions: PHImageRequestOptions!
    private var texture: MTLTexture!

    init() {
        super.init(nibName: nil,
                   bundle: nil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.redraw()
    }

    // MARK: - Setup

    private func setup() {
        do {
            self.context = try .init()
            self.metalView = try .init(context: self.context)
            self.textureFlip = try .init(library: self.context
                                                      .library(for: TextureFlip.self))
            self.textureCopy = try .init(context: self.context)
            self.chooseImageButton = .init(type: .roundedRect)
            self.flipTextureButton = .init(type: .roundedRect)
            self.flipTextureButton.accessibilityIdentifier = "FlipTextureButton"
            self.shareImageButton = .init(type: .roundedRect)
            self.assetPickerController = .init()
            self.assetPickerController
                .configuration
                .selection
                .max = 1
            self.imageManager = .init()
            self.imageRequestOptions = .init()
            self.imageRequestOptions
                .isNetworkAccessAllowed = true
            self.imageRequestOptions
                .deliveryMode = .highQualityFormat
            self.imageRequestOptions
                .resizeMode = .exact
            self.imageRequestOptions
                .version = .current

            self.draw(image: Asset.image.image)

            self.setupUI()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func setupUI() {
        self.view
            .backgroundColor = .systemBackground

        // MetalView

        self.view
            .addSubview(self.metalView)
        self.metalView
            .layer
            .cornerRadius = 10
        self.metalView
            .layer
            .masksToBounds = true
        self.metalView
            .snp
            .makeConstraints { constraintMaker in
                constraintMaker.top
                               .equalToSuperview()
                               .inset(40)
                constraintMaker.bottom
                               .equalToSuperview()
                               .inset(120)
                constraintMaker.trailing
                               .leading
                               .equalToSuperview()
        }

        // chooseImageButton

        self.view
            .addSubview(self.chooseImageButton)
        self.chooseImageButton
            .setImage(Asset.gallery.image,
                      for: .normal)
        self.chooseImageButton
            .tintColor = .label
        self.chooseImageButton
            .addTarget(self,
                       action: #selector(self.chooseImage),
                       for: .touchUpInside)

        self.chooseImageButton
            .snp
            .makeConstraints { constraintMaker in
                constraintMaker.width
                               .equalTo(54)
                constraintMaker.height
                               .equalTo(40)
                constraintMaker.bottom
                               .equalToSuperview()
                               .inset(60)
                constraintMaker.leading
                               .equalToSuperview()
                               .inset(20)
        }

        // flipTextureButton

        self.view
            .addSubview(self.flipTextureButton)
        self.flipTextureButton
            .setImage(Asset.flip.image,
                      for: .normal)
        self.flipTextureButton
            .tintColor = .label
        self.flipTextureButton
            .addTarget(self,
                       action: #selector(self.flipTexture),
                       for: .touchUpInside)

        self.flipTextureButton
            .snp
            .makeConstraints { constraintMaker in
                constraintMaker.width
                               .height
                               .equalTo(40)
                constraintMaker.bottom
                               .equalToSuperview()
                               .inset(60)
                constraintMaker.centerX
                               .equalToSuperview()
        }

        // shareImageButton

        self.view
            .addSubview(self.shareImageButton)
        self.shareImageButton
            .setImage(Asset.share.image,
                      for: .normal)
        self.shareImageButton
            .tintColor = .label
        self.shareImageButton
            .addTarget(self,
                       action: #selector(self.shareImage),
                       for: .touchUpInside)

        self.shareImageButton
            .snp
            .makeConstraints { constraintMaker in
                constraintMaker.width
                               .equalTo(30)
                constraintMaker.height
                               .equalTo(40)
                constraintMaker.bottom
                               .equalToSuperview()
                               .inset(60)
                constraintMaker.trailing
                               .greaterThanOrEqualToSuperview()
                               .inset(20)
        }

    }

    // MARK: - Redraw

    private func draw(image: UIImage?) {
        guard let image = image,
              let cgImage = image.cgImage,
              let texture = try? self.context
                                     .texture(from: cgImage,
                                              srgb: false,
                                              usage: [.shaderWrite, .shaderRead])
        else { return }

        self.texture = texture

        #if targetEnvironment(macCatalyst)
        try? self.context.scheduleAndWait { commandBuffer in
            commandBuffer.blit { blitEncoder in
                blitEncoder.synchronize(resource: self.texture)
            }
        }
        #endif

        self.redraw()
    }

    private func redraw() {
        self.metalView.setNeedsAdaptToTextureInput()
        DispatchQueue.main.async {
            try? self.context.schedule { commandBuffer in
                self.metalView.draw(texture: self.texture,
                                    in: commandBuffer)
            }
        }
    }

    // MARK: - Button Actions

    @objc
    func chooseImage() {
        presentPHAssetPicker(self.assetPickerController,
                             select: { _ in },
                             deselect: { _ in },
                             cancel: { _ in },
                             finish: { assets in
            guard let asset = assets.first
            else { return }

            self.imageManager
                .requestImage(for: asset,
                              targetSize: PHImageManagerMaximumSize,
                              contentMode: .default,
                              options: self.imageRequestOptions) { image, info in
                                self.draw(image: image)
            }
        })
    }

    @objc
    func flipTexture() {
        guard let temporaryTexture = try? self.texture.matchingTexture()
        else { return }
        self.metalView.setNeedsAdaptToTextureInput()
        DispatchQueue.main.async {
            try? self.context.scheduleAndWait { commandBuffer in
                self.textureFlip(source: self.texture,
                                 destination: temporaryTexture,
                                 in: commandBuffer)
                self.textureCopy(sourceTexture: temporaryTexture,
                                 destinationTexture: self.texture,
                                 in: commandBuffer)
                self.metalView.draw(texture: self.texture,
                                    in: commandBuffer)
            }
        }
    }

    @objc
    func shareImage() {
        guard let image = try? self.texture
                                   .image()
        else { return }

        let activityViewController = UIActivityViewController(activityItems: [image],
                                                              applicationActivities: nil)
        present(activityViewController,
                animated: true)
    }


}

