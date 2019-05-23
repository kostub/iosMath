//
//  FirstViewController.swift
//  iosMathSwiftExample
//
//  Created by denn nevera on 22/05/2019.
//  Copyright © 2019 Aithea. All rights reserved.
//

import UIKit
import iosMath
import RxCocoa
import RxSwift

class LiveViewController: UIViewController {

    var disposeBag = DisposeBag()

    @IBOutlet weak var latexInput: UITextField!
    
    @IBOutlet weak var latexLabel: Label!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        latexLabel.textAlignment = .center
        latexLabel.contentInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 20);
        latexLabel.displayErrorInline = false;
        
        latexInput.rx
            .text
            .orEmpty
            .subscribe(onNext: { text in
                
                self.latexLabel.latex = text
                
            })
            .disposed(by: disposeBag)
        
    }


}

