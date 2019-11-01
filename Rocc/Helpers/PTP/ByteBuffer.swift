//
//  ByteBuffer.swift
//  CCKit
//
//  Created by Simon Mitchell on 30/01/2019.
//  Copyright © 2019 Simon Mitchell. All rights reserved.
//

import Foundation

typealias Byte = UInt8
typealias Word = UInt16
typealias DWord = UInt32

extension Data {
    /// Converts a `Data` object to it's `UInt8` byte array equivalent
    var toBytes: [Byte] {
        let byteCount = count / MemoryLayout<UInt8>.size
        // create an array of Uint8
        var byteArray = [UInt8](repeating: 0, count: byteCount)
        // copy bytes into array
        copyBytes(to: &byteArray, count: byteCount)
        return byteArray
    }
}

/// ByteBuffer is a simple struct for manipulating and accessing bytes in a little-endian manner.
struct ByteBuffer {
    
    /// The raw array of bytes the buffer represents
    var bytes: [Byte?] = []
    
    //MARK: - Writing -
    
    private mutating func setLittleEndian(offset: UInt, value: UInt, nBytes: UInt) {
        for i in 0..<nBytes {
            // >> 8 * i shifts a whole byte to the right adding 0s to replace missing bits
            // (say i = 1) 01010101 11101110 01010101 01010101 -> 00000000 01010101 11101110 01010101
            // & Byte(0xff) does a logical AND between the shifted bits and 00000000 00000000 00000000 11111111
            // so 00000000 01010101 11101110 01010101 & 0xff -> 00000000 00000000 00000000 01010101
            bytes[safe: offset + i] = Byte((value >> (8 * i)) & UInt(0xff))
        }
    }
    
    private func getLittleEndian(offset: UInt, nBytes: UInt) -> Int? {
        
        var value: Int = 0
        for i in 0..<nBytes {
            guard let byte = bytes[safe: offset + i] else { continue }
            value = value + Int(byte) << (8 * i)
        }
        return value
    }
    
    mutating func append(data: Data) {
        bytes.append(contentsOf: data.toBytes)
    }
    
    mutating func append(dWord value: DWord) {
        setLittleEndian(offset: UInt(bytes.count), value: UInt(value), nBytes: 4)
    }
    
    mutating func append(word value: Word) {
        setLittleEndian(offset: UInt(bytes.count), value: UInt(value), nBytes: 2)
    }
    
    mutating func append(byte value: Byte) {
        bytes.append(value)
    }
    
    mutating func append(wChar character: Character) {
        // As described in "PIMA 15740:2000", characters are encoded in PTP as
        // ISO10646 2-byte characters.
        guard let utf16 = character.unicodeScalars.first?.utf16.first else { return }
        append(word: utf16)
    }
    
    mutating func append(wString string: String) {
        
        let lengthWithNull = string.count + 1;
        append(byte: UInt8(lengthWithNull));
        string.forEach { (character) in
            append(wChar: character)
        }
        append(word: 0);
    }
    
    private mutating func set(dWord value: DWord, at offset: UInt) {
        setLittleEndian(offset: offset, value: UInt(value), nBytes: 4)
    }
    
    private mutating func set(word value: Word, at offset: UInt) {
        setLittleEndian(offset: offset, value: UInt(value), nBytes: 2)
    }
    
    //MARK: - Reading -
    
    var toString: String {
        var s = ""
        var separator = ""
        bytes.forEach { (x) in
            guard let byte = x else { return }
            let hex = String(byte, radix: 16, uppercase: false)
            s = s + separator + (hex.count == 1 ? "0" : "") + hex
            separator = " "
        }
        return s
    }
    
    var length: Int {
        return bytes.count
    }
}

extension ByteBuffer {
    
    subscript (index: UInt) -> Byte? {
        get {
            return bytes[safe: index]
        }
        set {
            bytes[safe: index] = newValue
        }
    }
    
    subscript (word index: UInt) -> Word? {
        get {
            guard let littleEndian = getLittleEndian(offset: index, nBytes: 2) else {
                return nil
            }
            return Word(littleEndian)
        }
        set {
            guard let newValue = newValue else { return }
            set(word: newValue, at: index)
        }
    }
    
    subscript (dWord index: UInt) -> DWord? {
        get {
            guard let littleEndian = getLittleEndian(offset: index, nBytes: 4) else {
                return nil
            }
            return DWord(littleEndian)
        }
        set {
            guard let newValue = newValue else { return }
            set(dWord: newValue, at: index)
        }
    }
}

extension Array where Element == UInt8? {
    
    subscript (safe index: UInt) -> Element {
        get {
            return Int(index) < count ? self[Int(index)] : nil
        }
        set {
            while Int(index) >= count {
                append(nil)
            }
            self[Int(index)] = newValue
        }
    }
}

extension Array where Element: UnsignedInteger {
    
    subscript (safe index: UInt) -> Element? {
        get {
            return Int(index) < count ? self[Int(index)] : nil
        }
        set {
            guard let newValue = newValue else { return }
            while Int(index) >= count {
                append(0)
            }
            self[Int(index)] = newValue
        }
    }
}

