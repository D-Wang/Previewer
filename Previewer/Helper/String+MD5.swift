//
//  String+MD5.swift
//  Previewer
//
//  Created by WangWei on 2017/12/19.
//  Copyright © 2017年 WangWei. All rights reserved.
//  https://stackoverflow.com/questions/25248598/importing-commoncrypto-in-a-swift-framework
//

import Foundation
import CCommonCrypto

extension String {
    var md5: String {
        guard let cStr = cString(using: .utf8) else {
            return self
        }
        let bytesLength = CUnsignedInt(lengthOfBytes(using: .utf8))
        let md5DigestLenth = Int(CC_MD5_DIGEST_LENGTH)
        let md5StringPointer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: md5DigestLenth)
        defer {
            md5StringPointer.deallocate()
        }
        CC_MD5(cStr, bytesLength, md5StringPointer)
        var md5String = ""
        for i in 0 ..< md5DigestLenth {
            md5String = md5String.appendingFormat("%02x", md5StringPointer[i])
        }
        return md5String
    }
}
