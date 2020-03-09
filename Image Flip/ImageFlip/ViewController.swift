import UIKit
import MetalKit
import PHAssetPicker
import SnapKit
import MetalView
import Alloy
import Photos

class ViewController: UIViewController {

    private var metalView: MetalView!
    private var context: MTLContext!
    private var chooseImageButton: UIButton!
    private var assetPickerController: PHAssetPickerController!
    private var imageManager: PHImageManager!
    private var imageRequestOptions: PHImageRequestOptions!

    init() {
        super.init(nibName: nil,
                   bundle: nil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        do {
            self.context = try .init()
            self.metalView = try .init(context: self.context)
            self.chooseImageButton = .init(type: .roundedRect)
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
            .addSubview(self.metalView)
        self.metalView
            .layer
            .cornerRadius = 6
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


        self.view
            .backgroundColor = .systemBackground
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
                               .height
                               .equalTo(50)
                constraintMaker.bottom
                               .equalToSuperview()
                               .inset(60)
                constraintMaker.leading
                               .equalToSuperview()
                               .inset(20)
        }

    }

    private func draw(image: UIImage?) {
        guard let image = image,
              let cgImage = image.cgImage,
              let texture = try? self.context.texture(from: cgImage)
        else { return }
        self.metalView.setNeedsAdaptToTextureInput()
        DispatchQueue.main.async {
            try? self.context
                     .schedule { commandBuffer in
                self.metalView
                    .draw(texture: texture,
                          in: commandBuffer)
            }
        }
    }

    @objc
    func chooseImage() {
        presentPHAssetPicker(self.assetPickerController,
                             select: { (asset) in

        }, deselect: { (asset) in

        }, cancel: { (assets) in

        }, finish: { (assets) in
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


}

