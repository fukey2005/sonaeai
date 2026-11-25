import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let photoChannel = FlutterMethodChannel(
      name: "jp.ac.tid.neoJichikai/room_photo",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    photoChannel.setMethodCallHandler { call, result in
      guard call.method == "suggestChecks" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let photo = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid_photo", message: nil, details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let checks = Self.photoCheckSuggestions(photo.data)
        DispatchQueue.main.async { result(checks) }
      }
    }
  }

  private static func photoCheckSuggestions(_ data: Data) -> [Int] {
    let request = VNClassifyImageRequest()
    do {
      try VNImageRequestHandler(data: data).perform([request])
      let objects = Set((request.results ?? []).filter { $0.confidence >= 0.25 }.map(\.identifier))
      // In RoomArea order. These labels suggest what to inspect in person.
      let areas: [Set<String>] = [
        ["bookshelf", "cabinet", "furniture"],
        ["door", "cardboard_box", "carton"],
        ["bookshelf", "cabinet", "closet"],
      ]
      return areas.indices.filter { !objects.isDisjoint(with: areas[$0]) }
    } catch {
      return []
    }
  }
}
