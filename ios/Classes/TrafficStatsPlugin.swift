import Flutter
import UIKit
import Network

public class TrafficStatsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private static let SPEED_CHANNEL = "traffic_stats/network_speed"
    private var timer: Timer?
    private var previousBytesReceived: Int64 = 0
    private var previousBytesSent: Int64 = 0
    private var isFirstMeasurement: Bool = true

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
        // Reset state when starting
        previousBytesReceived = 0
        previousBytesSent = 0
        isFirstMeasurement = true
        
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
        var totalReceivedBytes: Int64 = 0
        var totalSentBytes: Int64 = 0

        if getifaddrs(&ifaddrs) == 0 {
            var pointer = ifaddrs
            while pointer != nil {
                if let ifa_name = pointer?.pointee.ifa_name {
                    let name = String(cString: ifa_name)
                    
                    // Only process active interfaces
                    if name == "en0" || name == "pdp_ip0" {
                        if let data = pointer?.pointee.ifa_data {
                            let networkData = data.load(as: if_data.self)
                            let receivedBytes = Int64(networkData.ifi_ibytes)
                            let sentBytes = Int64(networkData.ifi_obytes)
                            
                            // Accumulate bytes from all relevant interfaces
                            totalReceivedBytes += receivedBytes
                            totalSentBytes += sentBytes
                            
                            print("TrafficStats: Interface \(name) - Received: \(receivedBytes), Sent: \(sentBytes)")
                        }
                    }
                }
                pointer = pointer?.pointee.ifa_next
            }
            freeifaddrs(ifaddrs)
        }
        
        print("TrafficStats: Total bytes - Received: \(totalReceivedBytes), Sent: \(totalSentBytes)")
        print("TrafficStats: Previous bytes - Received: \(previousBytesReceived), Sent: \(previousBytesSent)")
        
        // Handle first measurement
        if isFirstMeasurement {
            self.previousBytesReceived = totalReceivedBytes
            self.previousBytesSent = totalSentBytes
            isFirstMeasurement = false
            print("TrafficStats: First measurement - setting baseline")
        } else {
            // Calculate download speed
            if totalReceivedBytes >= self.previousBytesReceived {
                let downloadBytes = totalReceivedBytes - self.previousBytesReceived
                downloadSpeed = (downloadBytes * 8) / 1000 // Convert to kbps
                print("TrafficStats: Download calculation - Bytes: \(downloadBytes), Speed: \(downloadSpeed) kbps")
            } else {
                downloadSpeed = 0
                print("TrafficStats: Download counter reset detected")
            }
            
            // Calculate upload speed
            if totalSentBytes >= self.previousBytesSent {
                let uploadBytes = totalSentBytes - self.previousBytesSent
                uploadSpeed = (uploadBytes * 8) / 1000 // Convert to kbps
                print("TrafficStats: Upload calculation - Bytes: \(uploadBytes), Speed: \(uploadSpeed) kbps")
            } else {
                uploadSpeed = 0
                print("TrafficStats: Upload counter reset detected")
            }
            
            // Update previous values
            self.previousBytesReceived = totalReceivedBytes
            self.previousBytesSent = totalSentBytes
        }
        
        // Ensure non-negative values
        downloadSpeed = max(0, downloadSpeed)
        uploadSpeed = max(0, uploadSpeed)
        
        // Cap extremely high values (likely due to measurement errors)
        let maxReasonableSpeed: Int64 = 1000000 // 1 Gbps in kbps
        downloadSpeed = min(downloadSpeed, maxReasonableSpeed)
        uploadSpeed = min(uploadSpeed, maxReasonableSpeed)
        
        print("TrafficStats: Final speeds - Download: \(downloadSpeed) kbps, Upload: \(uploadSpeed) kbps")
        
        DispatchQueue.main.async {
            self.eventSink?(["uploadSpeed": uploadSpeed, "downloadSpeed": downloadSpeed])
        }
    }
}
