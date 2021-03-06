//
//  Apeture.swift
//  Rocc
//
//  Created by Simon Mitchell on 26/04/2018.
//  Copyright © 2018 Simon Mitchell. All rights reserved.
//

import Foundation

/// Functions for interacting with the event API on the camera
public struct Event: CameraFunction {
    
    public var function: _CameraFunction
    
    public typealias SendType = Bool
    
    public typealias ReturnType = CameraEvent
    
    /// Gets the current event
    public static let get = Event(function: .getEvent)
}

/// The focussing status of the camera
///
/// - notFocussing: The camera is not focussed
/// - failed: The focus operation failed
/// - focusing: The camera is focussing
/// - focussed: The camera has finished focussing
public enum FocusStatus {
    
    case notFocussing
    case failed
    case focusing
    case focused
    
    internal var debugString: String {
        switch self {
        case .notFocussing:
            return "Not Focusing"
        case .failed:
            return "Failed"
        case .focusing:
            return "Focusing"
        case .focused:
            return "Focused"
        }
    }
}

/// CameraEvent represents an overview of the camera's current setup.
/// An event can either be a whole snapshot - in-which we expect all the parameters to be set - or an update to certain parameters, for example if the camera's ISO was set on the body; in which case only that parameter would be non-nil.
public struct CameraEvent {
    
    /// A structural representation of all information about the camera's battery
    public struct BatteryInformation {
        
        /// An enum representing the status of a battery
        ///
        /// - active: The battery is in use
        /// - inactive: The battery is not in use
        /// - unknown: The status is unknown
        public enum Status {
            case active
            case inactive
            case unknown
        }
        
        /// An enum representing the charge status of a battery
        ///
        /// - charging: The battery is charging
        /// - nearEnd: The battery is nearing the end of it's charge
        public enum ChargeStatus {
            case charging
            case nearEnd
        }
        
        /// The unique identifier of the battery
        public let identifier: String
        
        /// The current status of the battery
        public let status: Status
        
        /// The current charge status of the battery (If nil, then the battery is simply in a normal state)
        public let chargeStatus: ChargeStatus?
        
        /// A description of the battery
        public let description: String?
        
        /// The charge level of the battery
        public let level: Double
    }
    
    /// A structural representation of information about the live view
    public struct LiveViewInformation {
        
        /// Whether the LiveView on the camera is ready to transfer LiveView images over the API.
        public let status: Bool
        
        /// The orientation of the liveView on the camera.
        public let orientation: String?
    }
    
    /// A structural representation of information about the still size being used by the camera
    public struct StillSizeInformation {
        
        /// Whether the user should check the available values of still size. If true, the client should check the change of available parameters by calling `Camera.isFunctionAvailable(Still.Size.set)`.
        public let shouldCheck: Bool
        
        /// The still size the camera is shooting in.
        public let stillSize: StillSize
    }
    
    /// A structural representation of information about the white balance being used by the camera
    public struct WhiteBalanceInformation {
        
        /// Whether the user should check the available white balances. If true, the client should check the change of available parameters by calling `Camera.isFunctionAvailable(Still.Size.set)`.
        public let shouldCheck: Bool
        
        /// The current white balance value.
        public let whitebalanceValue: WhiteBalance.Value
    }
    
    /// The current status of the camera.
    public let status: CameraStatus?
    
    /// Information about the LiveView on the camera.
    public let liveViewInfo: LiveViewInformation?
    
    /// The current amount the camera is zoomed in, between 0 and 1 (1 being 100% zoom capability of the camera).
    public let zoomPosition: Double?
    
    /// The functions that are currently available to the camera.
    /// This can be used to check availability of APIs instead of the `Camera.isFunctionAvailable` method, although this doesn't return accepted values.
    public let availableFunctions: [_CameraFunction]?
    
    /// URLs for postView images that the camera has taken.
    public let postViewPictureURLs: [[URL]]?
    
    /// Storage information for each of the camera's storage capabilities.
    public let storageInformation: [StorageInformation]?
    
    /// Current and available `Beep Mode` of the camera.
    public let beepMode: (current: String, available: [String])?
    
    /// The current function the camera is setup for using, and the available values to set it to.
    public let function: (current: String, available: [String])?
    
    /// The result of setting the camera function.
    public let functionResult: Bool
    
    /// The video quality the camera is setup to record in, and available values to set it to.
    public let videoQuality: (current: String, available: [String])?
    
    /// Information about the still size the camera is shooting in.
    public let stillSizeInfo: StillSizeInformation?
    
    /// Current and available steady modes of the camera.
    public let steadyMode: (current: String, available: [String])?
    
    /// Current and available view angles of the camera.
    public let viewAngle: (current: Double, available: [Double])?
    
    /// Current and available exposure modes.
    public let exposureMode: (current: String, available: [String])?
    
    /// Current and available post view image size.
    public let postViewImageSize: (current: String, available: [String])?
    
    /// Current and available self timer durations.
    public let selfTimer: (current: TimeInterval, available: [TimeInterval])?
    
    /// Current and available shoot mode.
    public var shootMode: (current: ShootingMode, available: [ShootingMode]?)?
    
    /// Current and available exposure compensation.
    public let exposureCompensation: (current: Double, available: [Double])?
    
    /// Current and available flash modes.
    public let flashMode: (current: String, available: [String])?
    
    /// Current and available apertures.
    public let aperture: (current: String, available: [String])?
    
    /// Current and available focus modes.
    public let focusMode: (current: String, available: [String])?
    
    /// Current and available ISO.
    public let ISO: (current: String, available: [String])?
    
    /// Whether or not the camera is program shifted.
    public let isProgramShifted: Bool?
    
    /// Current and available shutter speeds.
    public let shutterSpeed: (current: ShutterSpeed, available: [ShutterSpeed])?
    
    /// Current white balance and whether need to re-poll for available white balances.
    public let whiteBalance: WhiteBalanceInformation?
    
    /// Current Touch AF Information.
    public let touchAF: TouchAF.Information?
    
    /// The current focus status of the camera.
    public let focusStatus: FocusStatus?
    
    /// The current and available zoom settings.
    public let zoomSetting: (current: String, available: [String])?
    
    /// The current and available still quality.
    public let stillQuality: (current: String, available: [String])?
    
    /// The current and available continuous shooting modes.
    public let continuousShootingMode: (current: ContinuousShootingMode, available: [ContinuousShootingMode])?
    
    /// The current and available continuous shooting speeds.
    public let continuousShootingSpeed: (current: ContinuousShootingSpeed, available: [ContinuousShootingSpeed])?
    
    /// Array of URL of continuous shooting. When more than one URL notifies, the last one is the latest.
    public let continuousShootingURLS: [(postView: URL, thumbnail: URL)]?
    
    /// Current and available flip settings.
    public let flipSetting: (current: String, available: [String])?
    
    /// Current and available scenes.
    public let scene: (current: String, available: [String])?
    
    /// Current and available time intervals.
    public let intervalTime: (current: TimeInterval, available: [TimeInterval])?
    
    /// Current and available color settings.
    public let colorSetting: (current: String, available: [String])?
    
    /// Current and available video file formats.
    public let videoFileFormat: (current: String, available: [String])?
    
    /// Recording time of the video.
    public let videoRecordingTime: TimeInterval?
    
    /// Current and available infrared remote control settings.
    public let infraredRemoteControl: (current: String, available: [String])?
    
    /// Current and available tv color systems.
    public let tvColorSystem: (current: String, available: [String])?
    
    /// The status of tracking focus.
    public let trackingFocusStatus: String?
    
    /// The current and available tracking focusses.
    public let trackingFocus: (current: String, available: [String])?
    
    /// Information about the camera's battery/batteries.
    public let batteryInfo: [BatteryInformation]?
    
    /// The number of shots taken in interval shooting.
    public let numberOfShots: Int?
    
    /// Current and available auto power off intervals.
    public let autoPowerOff: (current: TimeInterval, available: [TimeInterval])?
    
    /// Current and available loop recording times.
    public let loopRecordTime: (current: TimeInterval, available: [TimeInterval])?
    
    /// Current and available audio recording modes for video.
    public let audioRecording: (current: String, available: [String])?
    
    /// Current and available wind noise reduction modes.
    public let windNoiseReduction: (current: String, available: [String])?
    
    /// The url for final bulb shooting
    public let bulbShootingUrl: URL?
    
    /// The time that the bulb shooting has been running for!
    public let bulbCapturingTime: TimeInterval?
}
