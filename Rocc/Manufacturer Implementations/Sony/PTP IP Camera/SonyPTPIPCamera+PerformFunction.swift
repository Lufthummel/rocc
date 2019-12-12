//
//  SonyPTPIPCamera+PerformFunction.swift
//  Rocc
//
//  Created by Simon Mitchell on 17/11/2019.
//  Copyright © 2019 Simon Mitchell. All rights reserved.
//

import Foundation
import os.log

extension SonyPTPIPDevice {
    
    func performFunction<T>(_ function: T, payload: T.SendType?, callback: @escaping ((Error?, T.ReturnType?) -> Void)) where T : CameraFunction {
        
        switch function.function {
        case .getEvent:
            let packet = Packet.commandRequestPacket(code: .getAllDevicePropData, arguments: [0], transactionId: ptpIPClient?.getNextTransactionId() ?? 0)
            ptpIPClient?.awaitDataFor(transactionId: packet.transactionId, callback: { (dataResult) in
                
                switch dataResult {
                case .success(let data):
                    guard let numberOfProperties = data.data[qWord: 0] else { return }
                    var offset: UInt = UInt(MemoryLayout<QWord>.size)
                    var properties: [PTPDeviceProperty] = []
                    for _ in 0..<numberOfProperties {
                        guard let property = data.data.getDeviceProperty(at: offset) else { break }
                        properties.append(property)
                        offset += property.length
                    }
                    let event = CameraEvent(sonyDeviceProperties: properties)
                    callback(nil, event as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
            ptpIPClient?.sendCommandRequestPacket(packet, callback: nil)
        case .setShootMode:
            guard let value = payload as? ShootingMode else {
                callback(FunctionError.invalidPayload, nil)
                return
            }
            //TODO: Implement when we have better grasp of available shoot modes
        case .getShootMode:
            ptpIPClient?.getDevicePropDescFor(propCode: .stillCaptureMode, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.shootMode?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .setContinuousShootingMode:
            // This isn't a thing via PTP according to Sony's app (Instead we just have multiple continuous shooting speeds) so we just don't do anything!
            callback(nil, nil)
        case .setISO, .setShutterSpeed, .setAperture, .setExposureCompensation, .setFocusMode, .setExposureMode, .setFlashMode, .setContinuousShootingSpeed:
            guard let value = payload as? SonyPTPPropValueConvertable else {
                callback(FunctionError.invalidPayload, nil)
                return
            }
            ptpIPClient?.sendSetControlDeviceAValue(
                PTP.DeviceProperty.Value(value)
            )
        case .getISO:
            ptpIPClient?.getDevicePropDescFor(propCode: .ISO, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.iso?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getShutterSpeed:
            ptpIPClient?.getDevicePropDescFor(propCode: .shutterSpeed, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.shutterSpeed?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getAperture:
            ptpIPClient?.getDevicePropDescFor(propCode: .fNumber, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.aperture?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getExposureCompensation:
            ptpIPClient?.getDevicePropDescFor(propCode: .exposureBiasCompensation, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.aperture?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getFocusMode:
            ptpIPClient?.getDevicePropDescFor(propCode: .focusMode, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.focusMode?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getExposureMode:
            ptpIPClient?.getDevicePropDescFor(propCode: .exposureProgramMode, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.exposureMode?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .getFlashMode:
            ptpIPClient?.getDevicePropDescFor(propCode: .flashMode, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.flashMode?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .setStillSize:
            guard let stillSize = payload as? StillSize else {
                callback(FunctionError.invalidPayload, nil)
                return
            }
            var stillSizeByte: Byte? = nil
            switch stillSize.size {
            case "L":
                stillSizeByte = 0x01
            case "M":
                stillSizeByte = 0x02
            case "S":
                stillSizeByte = 0x03
            default:
                break
            }
            
            if let _stillSizeByte = stillSizeByte {
                ptpIPClient?.sendSetControlDeviceAValue(
                    PTP.DeviceProperty.Value(
                        code: .imageSizeSony,
                        type: .uint8,
                        value: _stillSizeByte
                    )
                )
            }
            
            guard let aspect = stillSize.aspectRatio else { return }
            
            var aspectRatioByte: Byte? = nil
            switch aspect {
            case "3:2":
                aspectRatioByte = 0x01
            case "16:9":
                aspectRatioByte = 0x02
            case "1:1":
                aspectRatioByte = 0x04
            default:
                break
            }
            
            guard let _aspectRatioByte = aspectRatioByte else { return }
            
            ptpIPClient?.sendSetControlDeviceAValue(
                PTP.DeviceProperty.Value(
                    code: .imageSizeSony,
                    type: .uint8,
                    value: _aspectRatioByte
                )
            )
            
        case .getStillSize:
            
            // Still size requires still size and ratio codes to be fetched!
            ptpIPClient?.getDevicePropDescFor(propCode: .imageSizeSony, callback: { [weak self] (imageSizeResult) in
                
                guard let this = self else {
                    callback(nil, nil)
                    return
                }
                
                switch imageSizeResult {
                case .success(let imageSizeProperty):
                    this.ptpIPClient?.getDevicePropDescFor(propCode: .aspectRatio, callback: { (aspectResult) in
                        switch aspectResult {
                        case .success(let aspectProperty):
                            let event = CameraEvent(sonyDeviceProperties: [imageSizeProperty, aspectProperty])
                            callback(nil, event.stillSizeInfo?.stillSize as? T.ReturnType)
                        case .failure(let error):
                            callback(error, nil)
                        }
                    })
                    
                case .failure(let error):
                    callback(error, nil)
                }
            })
            
        case .setSelfTimerDuration:
            guard let timeInterval = payload as? TimeInterval else {
                callback(FunctionError.invalidPayload, nil)
                return
            }
            let value: SonyStillCaptureMode
            switch timeInterval {
            case 0.0:
                value = .single
            case 2.0:
                value = .timer2
            case 5.0:
                value = .timer5
            case 10.0:
                //TODO: Pick out the one which is available! How!?
                value = .timer10_a
            default:
                value = .single
            }
            ptpIPClient?.sendSetControlDeviceAValue(
                PTP.DeviceProperty.Value(value)
            )
        case .getSelfTimerDuration:
            
            ptpIPClient?.getDevicePropDescFor(propCode: .stillCaptureMode, callback: { (result) in
                switch result {
                case .success(let property):
                    let event = CameraEvent(sonyDeviceProperties: [property])
                    callback(nil, event.selfTimer?.current as? T.ReturnType)
                case .failure(let error):
                    callback(error, nil)
                }
            })
            
        case .setWhiteBalance:
            
            guard let value = payload as? WhiteBalance.Value else {
                callback(FunctionError.invalidPayload, nil)
                return
            }
            ptpIPClient?.sendSetControlDeviceAValue(
                PTP.DeviceProperty.Value(value.mode)
            )
            guard let colorTemp = value.temperature else { return }
            ptpIPClient?.sendSetControlDeviceAValue(
                PTP.DeviceProperty.Value(
                    code: .colorTemp,
                    type: .uint16,
                    value: Word(colorTemp)
                )
            )
            
        case .getWhiteBalance:
            
            // White balance requires white balance and colorTemp codes to be fetched!
            ptpIPClient?.getDevicePropDescFor(propCode: .whiteBalance, callback: { [weak self] (wbResult) in
                
                guard let this = self else {
                    callback(nil, nil)
                    return
                }
                
                switch wbResult {
                case .success(let wbProperty):
                    this.ptpIPClient?.getDevicePropDescFor(propCode: .colorTemp, callback: { (ctResult) in
                        switch ctResult {
                        case .success(let ctProperty):
                            let event = CameraEvent(sonyDeviceProperties: [wbProperty, ctProperty])
                            callback(nil, event.whiteBalance?.whitebalanceValue as? T.ReturnType)
                        case .failure(let error):
                            callback(error, nil)
                        }
                    })
                    
                case .failure(let error):
                    callback(error, nil)
                }
            })
        case .setupCustomWhiteBalanceFromShot:
            //TODO: Implement
            callback(nil, nil)
        case .setProgramShift:
            //TODO: Implement
            callback(nil, nil)
        case .getProgramShift:
            //TODO: Implement
            callback(nil, nil)
        case .takePicture:
            takePicture { (error) in
                callback(error, nil)
            }
        case .startContinuousShooting:
            //TODO: Implement
            callback(nil, nil)
        case .endContinuousShooting:
            //TODO: Implement
            callback(nil, nil)
        case .startVideoRecording:
            //TODO: Implement
            callback(nil, nil)
        case .endVideoRecording:
            //TODO: Implement
            callback(nil, nil)
        case .startAudioRecording:
            //TODO: Implement
            callback(nil, nil)
        case .endAudioRecording:
            //TODO: Implement
            callback(nil, nil)
        case .startIntervalStillRecording:
            //TODO: Implement
            callback(nil, nil)
        case .endIntervalStillRecording:
            //TODO: Implement
            callback(nil, nil)
        case .startBulbCapture:
            //TODO: Implement
            callback(nil, nil)
        case .endBulbCapture:
            //TODO: Implement
            callback(nil, nil)
        case .startLoopRecording:
            //TODO: Implement
            callback(nil, nil)
        case .endLoopRecording:
            //TODO: Implement
            callback(nil, nil)
        case .startLiveView, .startLiveViewWithSize, .endLiveView:
            //TODO: Check whether we need to call any PTP IP methods for this!
            callback(nil, apiDeviceInfo.liveViewURL as? T.ReturnType)
        case .getLiveViewSize:
            //TODO: Implement
            callback(nil, nil)
        case .setSendLiveViewFrameInfo:
            //TODO: Implement
            callback(nil, nil)
        case .getSendLiveViewFrameInfo:
            //TODO: Implement
            callback(nil, nil)
        case .startZooming:
            //TODO: Implement
            callback(nil, nil)
        case .stopZooming:
            //TODO: Implement
            callback(nil, nil)
        case .setZoomSetting:
            //TODO: Implement
            callback(nil, nil)
        case .getZoomSetting:
            //TODO: Implement
            callback(nil, nil)
        case .halfPressShutter, .cancelHalfPressShutter:
            ptpIPClient?.sendSetControlDeviceBValue(
                PTP.DeviceProperty.Value(
                    code: .autoFocus,
                    type: .uint16,
                    value: function.function == .halfPressShutter ? Word(2) : Word(1)
                )
            )
        case .setTouchAFPosition:
            //TODO: Implement
            callback(nil, nil)
        case .getTouchAFPosition:
            //TODO: Implement
            callback(nil, nil)
        case .cancelTouchAFPosition:
            //TODO: Implement
            callback(nil, nil)
        case .startTrackingFocus:
            //TODO: Implement
            callback(nil, nil)
        case .stopTrackingFocus:
            //TODO: Implement
            callback(nil, nil)
        case .setTrackingFocus:
            //TODO: Implement
            callback(nil, nil)
        case .getTrackingFocus:
            //TODO: Implement
            callback(nil, nil)
        case .getContinuousShootingMode:
            //TODO: Implement
            callback(nil, nil)
        case .getContinuousShootingSpeed:
            //TODO: Implement
            callback(nil, nil)
        case .setStillQuality:
            //TODO: Implement
            callback(nil, nil)
        case .getStillQuality:
            //TODO: Implement
            callback(nil, nil)
        case .getPostviewImageSize:
            //TODO: Implement
            callback(nil, nil)
        case .setPostviewImageSize:
            //TODO: Implement
            callback(nil, nil)
        case .setVideoFileFormat:
            //TODO: Implement
            callback(nil, nil)
        case .getVideoFileFormat:
            //TODO: Implement
            callback(nil, nil)
        case .setVideoQuality:
            //TODO: Implement
            callback(nil, nil)
        case .getVideoQuality:
            //TODO: Implement
            callback(nil, nil)
        case .setSteadyMode:
            //TODO: Implement
            callback(nil, nil)
        case .getSteadyMode:
            //TODO: Implement
            callback(nil, nil)
        case .setViewAngle:
            //TODO: Implement
            callback(nil, nil)
        case .getViewAngle:
            //TODO: Implement
            callback(nil, nil)
        case .setScene:
            //TODO: Implement
            callback(nil, nil)
        case .getScene:
            //TODO: Implement
            callback(nil, nil)
        case .setColorSetting:
            //TODO: Implement
            callback(nil, nil)
        case .getColorSetting:
            //TODO: Implement
            callback(nil, nil)
        case .setIntervalTime:
            //TODO: Implement
            callback(nil, nil)
        case .getIntervalTime:
            //TODO: Implement
            callback(nil, nil)
        case .setLoopRecordDuration:
            //TODO: Implement
            callback(nil, nil)
        case .getLoopRecordDuration:
            //TODO: Implement
            callback(nil, nil)
        case .setWindNoiseReduction:
            //TODO: Implement
            callback(nil, nil)
        case .getWindNoiseReduction:
            //TODO: Implement
            callback(nil, nil)
        case .setAudioRecording:
            //TODO: Implement
            callback(nil, nil)
        case .getAudioRecording:
            //TODO: Implement
            callback(nil, nil)
        case .setFlipSetting:
            //TODO: Implement
            callback(nil, nil)
        case .getFlipSetting:
            //TODO: Implement
            callback(nil, nil)
        case .setTVColorSystem:
            //TODO: Implement
            callback(nil, nil)
        case .getTVColorSystem:
            //TODO: Implement
            callback(nil, nil)
        case .listContent:
            //TODO: Implement
            callback(nil, nil)
        case .getContentCount:
            //TODO: Implement
            callback(nil, nil)
        case .listSchemes:
            //TODO: Implement
            callback(nil, nil)
        case .listSources:
            //TODO: Implement
            callback(nil, nil)
        case .deleteContent:
            //TODO: Implement
            callback(nil, nil)
        case .setStreamingContent:
            //TODO: Implement
            callback(nil, nil)
        case .startStreaming:
            //TODO: Implement
            callback(nil, nil)
        case .pauseStreaming:
            //TODO: Implement
            callback(nil, nil)
        case .seekStreamingPosition:
            //TODO: Implement
            callback(nil, nil)
        case .stopStreaming:
            //TODO: Implement
            callback(nil, nil)
        case .getStreamingStatus:
            //TODO: Implement
            callback(nil, nil)
        case .setInfraredRemoteControl:
            //TODO: Implement
            callback(nil, nil)
        case .getInfraredRemoteControl:
            //TODO: Implement
            callback(nil, nil)
        case .setAutoPowerOff:
            //TODO: Implement
            callback(nil, nil)
        case .getAutoPowerOff:
            //TODO: Implement
            callback(nil, nil)
        case .setBeepMode:
            //TODO: Implement
            callback(nil, nil)
        case .getBeepMode:
            //TODO: Implement
            callback(nil, nil)
        case .setCurrentTime:
            //TODO: Implement
            callback(nil, nil)
        case .getStorageInformation:
            //TODO: Implement
            callback(nil, nil)
        case .setCameraFunction:
            callback(CameraError.noSuchMethod("setCameraFunction"), nil)
        case .getCameraFunction:
            callback(CameraError.noSuchMethod("getCameraFunction"), nil)
        case .ping:
            //TODO: Implement
            callback(nil, nil)
        case .startRecordMode:
            callback(CameraError.noSuchMethod("startRecordMode"), nil)
        }
    }
    
    func takePicture(completion: @escaping ((Error?) -> Void)) {
        
        Logger.log(message: "Taking picture...", category: "SonyPTPIPCamera")
        os_log("Taking picture...", log: log, type: .debug)
        
        ptpIPClient?.sendSetControlDeviceBValue(
            PTP.DeviceProperty.Value(
                code: .capture,
                type: .uint8,
                value: Word(2)
            )
        )
        
        performFunction(Focus.Mode.get, payload: nil) { [weak self] (_, focusMode) in
            
            guard let self = self else {
                return
            }
            
            guard focusMode?.isAutoFocus == true else {
                self.cancelShutterPress(completion: completion)
                return
            }
            
            Logger.log(message: "Focus mode is AF variant awaiting focus...", category: "SonyPTPIPCamera")
            os_log("Focus mode is AF variant awaiting focus...", log: self.log, type: .debug)
            
            var newObject: DWord?
                        
            DispatchQueue.global().asyncWhile({ [weak self] (continueClosure) in
                
                guard let self = self else { return }
                
                if let lastEvent = self.lastEventPacket {
                    
                    // If code is property changed, and first variable == "Focus Found"
                    if lastEvent.code == .propertyChanged, lastEvent.variables?.first == 0xD213 {
                        Logger.log(message: "Got property changed event and was \"Focus Found\", continuing with capture process", category: "SonyPTPIPCamera")
                        os_log("Got property changed event and was \"Focus Found\", continuing with capture process", log: self.log, type: .debug)
                        continueClosure(true)
                        return
                    } else if lastEvent.code == .objectAdded {
                        Logger.log(message: "Got property changed event and was \"Object Added\", continuing with capture process", category: "SonyPTPIPCamera")
                        os_log("Got property changed event and was \"Object Added\", continuing with capture process", log: self.log, type: .debug)
                        newObject = lastEvent.variables?.first
                        continueClosure(true)
                        return
                    }
                }
                
                Logger.log(message: "Falling back to manual event check for focus found", category: "SonyPTPIPCamera")
                os_log("Falling back to manual event check for focus found", log: self.log, type: .debug)
                
                // In case we miss the event
                self.performFunction(Event.get, payload: nil) { (error, event) in
                    Logger.log(message: "Got camera event, focussed: \(event?.focusStatus == .focused)", category: "SonyPTPIPCamera")
                    os_log("Got camera event, focussed: %@", log: self.log, type: .debug, event?.focusStatus == .focused ? "true" : "false")
                    continueClosure(event?.focusStatus == .focused)
                }
                
            }, timeout: 1) { [weak self] in
                self?.cancelShutterPress(completion: completion)
            }
        }
    }
    
    private func cancelShutterPress(completion: @escaping ((Error?) -> Void)) {
        
        Logger.log(message: "Cancelling shutter press", category: "SonyPTPIPCamera")
        os_log("Cancelling shutter press", log: self.log, type: .debug)
        
        ptpIPClient?.sendSetControlDeviceBValue(
            PTP.DeviceProperty.Value(
                code: .capture,
                type: .uint8,
                value: Word(1)
            )
        )
        
        completion(nil)
        
        //TODO: Implement getting object ID and saving image to a url for preview!
//        DispatchQueue.global().asyncWhile({ (continue) in
//
//        }, timeout: 35) {
//
//        }
    }
}
