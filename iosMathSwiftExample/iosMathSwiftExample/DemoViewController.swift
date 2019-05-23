//
//  SecondViewController.swift
//  iosMathSwiftExample
//
//  Created by denn nevera on 22/05/2019.
//  Copyright © 2019 Aithea. All rights reserved.
//

import UIKit
import iosMath

class Label: MTMathUILabel {}

class DemoViewController: UIViewController {
    
    @IBOutlet weak var firstDemoLabel: Label!
    
    @IBOutlet weak var firstDemoRawLabel: UILabel!
    
    let firstLatexString = "\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstDemoLabel.latex = firstLatexString
        firstDemoRawLabel.text = firstLatexString
    }


}

