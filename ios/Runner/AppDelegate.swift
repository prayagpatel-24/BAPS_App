import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let widgetPluginName = "VachanamrutWidgetBridge"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    VachanamrutWidgetBridge.registerIfAvailable(
      with: engineBridge.pluginRegistry.registrar(forPlugin: Self.widgetPluginName)
    )
  }
}

private final class VachanamrutWidgetBridge: NSObject, FlutterPlugin {
  private static let widgetChannelName = "vachanamrut_app/widget"
  private static let widgetKind = "VachanamrutDailyWidget"
  private static let appGroupIdentifier = "group.com.example.vachanamrutApp"

  static func registerIfAvailable(with registrar: FlutterPluginRegistrar?) {
    guard let registrar else {
      return
    }
    register(with: registrar)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: widgetChannelName,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(VachanamrutWidgetBridge(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPinWidget":
      result(false)
    case "refreshWidgets":
      reloadWidgets()
      result(nil)
    case "syncState":
      guard let payload = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_payload",
            message: "Expected widget state payload.",
            details: nil
          )
        )
        return
      }
      persistWidgetState(payload)
      reloadWidgets()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func persistWidgetState(_ payload: [String: Any]) {
    let defaults = UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
    let language = stringValue(payload["language"], fallback: "gujarati")
    let previousLanguage = defaults.string(forKey: "language")
    defaults.set(stringValue(payload["appMode"], fallback: "vachanamrut"), forKey: "appMode")
    defaults.set(stringValue(payload["widgetContentMode"], fallback: "vachanamrut"), forKey: "widgetContentMode")
    defaults.set(intValue(payload["quoteIntervalMinutes"], fallback: 60), forKey: "quoteIntervalMinutes")
    defaults.set(intValue(payload["mukhpathIntervalMinutes"], fallback: 60), forKey: "mukhpathIntervalMinutes")
    defaults.set(language, forKey: "language")
    defaults.set(stringArray(payload["completedMukhpathIds"]), forKey: "completedMukhpathIds")
    if let previousLanguage = previousLanguage, previousLanguage != language {
      defaults.set(false, forKey: "showMeaning")
    }

    if let quotesJson = jsonString(from: payload["quotes"]) {
      defaults.set(quotesJson, forKey: "quotesJson")
    }
    if let mukhpathJson = jsonString(from: payload["mukhpathItems"]) {
      defaults.set(mukhpathJson, forKey: "mukhpathJson")
    }

    defaults.synchronize()
  }

  private func reloadWidgets() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
    }
  }

  private func stringValue(_ value: Any?, fallback: String) -> String {
    return value as? String ?? fallback
  }

  private func intValue(_ value: Any?, fallback: Int) -> Int {
    if let value = value as? Int {
      return value
    }
    if let value = value as? NSNumber {
      return value.intValue
    }
    return fallback
  }

  private func stringArray(_ value: Any?) -> [String] {
    return (value as? [Any])?.compactMap { $0 as? String } ?? []
  }

  private func jsonString(from value: Any?) -> String? {
    guard let items = value as? [Any] else {
      return nil
    }

    let normalizedItems = items.compactMap { item -> [String: String]? in
      guard let item = item as? [String: Any] else {
        return nil
      }
      return item.reduce(into: [String: String]()) { result, element in
        result[element.key] = element.value as? String ?? ""
      }
    }

    guard JSONSerialization.isValidJSONObject(normalizedItems),
          let data = try? JSONSerialization.data(withJSONObject: normalizedItems),
          let json = String(data: data, encoding: .utf8) else {
      return nil
    }
    return json
  }
}
