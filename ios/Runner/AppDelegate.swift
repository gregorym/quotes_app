import UIKit
import Flutter
import StoreKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FlutterMethodChannel(
      name: "com.mars6.noexcuse/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard
        call.method == "share",
        let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        let filePath = arguments["filePath"] as? String,
        FileManager.default.fileExists(atPath: filePath)
      else {
        result(FlutterError(
          code: "invalid_share",
          message: "The quote image is unavailable.",
          details: nil
        ))
        return
      }

      guard let presenter = Self.topViewController() else {
        result(FlutterError(
          code: "share_unavailable",
          message: "The share sheet could not be opened.",
          details: nil
        ))
        return
      }

      let shareController = UIActivityViewController(
        activityItems: [text, URL(fileURLWithPath: filePath)],
        applicationActivities: nil
      )
      if let popover = shareController.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX,
          y: presenter.view.bounds.midY,
          width: 1,
          height: 1
        )
      }
      presenter.present(shareController, animated: true) { result(nil) }
    }

    FlutterMethodChannel(
      name: "com.mars6.noexcuse/settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard
        call.method == "openSystemSettings",
        let url = URL(string: UIApplication.openSettingsURLString)
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url, options: [:]) { result($0) }
    }

    FlutterMethodChannel(
      name: "com.mars6.noexcuse/links",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard
        call.method == "openURL",
        let value = call.arguments as? String,
        let url = URL(string: value),
        url.scheme == "https"
      else {
        result(FlutterError(
          code: "invalid_url",
          message: "Only secure links can be opened.",
          details: nil
        ))
        return
      }
      UIApplication.shared.open(url, options: [:]) { result($0) }
    }

    FlutterMethodChannel(
      name: "com.mars6.noexcuse/storekit",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "currentEntitlements" else {
        result(FlutterMethodNotImplemented)
        return
      }

      Task {
        var productIDs: [String] = []
        for await entitlement in Transaction.currentEntitlements {
          guard case .verified(let transaction) = entitlement else { continue }
          productIDs.append(transaction.productID)
        }
        await MainActor.run { result(productIDs) }
      }
    }
  }

  private static func topViewController(
    from root: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tabs = root as? UITabBarController {
      return topViewController(from: tabs.selectedViewController)
    }
    return root
  }
}
