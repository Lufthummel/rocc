//
//  FocusMode+SonyPTPPropValueConvertable.swift.swift
//  Rocc
//
//  Created by Simon Mitchell on 10/11/2019.
//  Copyright © 2019 Simon Mitchell. All rights reserved.
//

import Foundation

extension FocusStatus: SonyPTPPropValueConvertable {
    
    var sonyPTPValue: PTPDevicePropertyDataType {
        switch self {
        case .focused:
            return Word(2)
        case .focusing, .notFocussing, .failed:
            return Word(1)
        }
    }
    
    var type: PTP.DeviceProperty.DataType {
        return .uint8
    }
    
    var code: PTP.DeviceProperty.Code {
        return .focusFound
    }
    
    init?(sonyValue: PTPDevicePropertyDataType) {
        guard let intValue = sonyValue.toInt else { return nil }
        switch intValue {
        case 1:
            self = .notFocussing
        case 2, 3:
            self = .focused
        default:
            return nil
        }
    }
}
