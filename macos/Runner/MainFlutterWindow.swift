import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let mediaService = MacOSMediaService()
  private var mediaChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    mediaChannel = FlutterMethodChannel(
      name: "cc.koto.fluent_lyrics/media",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    mediaChannel?.setMethodCallHandler(mediaService.handle)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
