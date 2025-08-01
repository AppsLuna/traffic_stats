import Flutter
import UIKit
import Network

public class TrafficStatsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private static let SPEED_CHANNEL = "traffic_stats/network_speed"
    private var timer: Timer?
    private var previousBytesReceived: Int64 = 0
    private var previousBytesSent: Int64 = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name: SPEED_CHANNEL, binaryMessenger: registrar.messenger())
        let instance = TrafficStatsPlugin()
        channel.setStreamHandler(instance)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startSpeedMonitoring()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopSpeedMonitoring()
        return nil
    }

    private func startSpeedMonitoring() {
        startTimer()
    }

    private func stopSpeedMonitoring() {
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(calculateSpeed), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func calculateSpeed() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil
        var uploadSpeed: Int64 = 0
        var downloadSpeed: Int64 = 0

        if getifaddrs(&ifaddrs) == 0 {
            var pointer = ifaddrs
            while pointer != nil {
                if let ifa_name = pointer?.pointee.ifa_name {
                    let name = String(cString: ifa_name)
                    if name == "en0" || name == "pdp_ip0" { // en0 for Wi-Fi, pdp_ip0 for cellular
                        if let data = pointer?.pointee.ifa_data {
                            let networkData = data.load(as: if_data.self)
                            let receivedBytes = Int64(networkData.ifi_ibytes)
                            let sentBytes = Int64(networkData.ifi_obytes)
                            
                            if self.previousBytesReceived > 0 {
                                let downloadBytes = receivedBytes - self.previousBytesReceived
                                downloadSpeed = (downloadBytes * 8) / 1000 // Convert to kbps
                            }
                            if self.previousBytesSent > 0 {
                                let uploadBytes = sentBytes - self.previousBytesSent
                                uploadSpeed = (uploadBytes * 8) / 1000 // Convert to kbps
                            }
                            
                            self.previousBytesReceived = receivedBytes
                            self.previousBytesSent = sentBytes
                        }
                    }
                }
                pointer = pointer?.pointee.ifa_next
            }
            freeifaddrs(ifaddrs)
        }
        
        DispatchQueue.main.async {
            self.eventSink?(["uploadSpeed": uploadSpeed, "downloadSpeed": downloadSpeed])
        }
    }
}
