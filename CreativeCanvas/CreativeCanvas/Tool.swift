//
//  Tool.swift
//  CreativeCanvas
//
//  Created by Harmony Radley on 7/28/20.
//  Copyright © 2020 Harmony Radley. All rights reserved.
//

import UIKit

class Tool{
    static func getContentViewFromPkCanvasView(_ view: UIView) -> some UIView {
        return view.subviews[0]
    }
}
