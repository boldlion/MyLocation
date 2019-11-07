//
//  AlertHelper.swift
//  MyLocation
//
//  Created by Bold Lion on 5.11.19.
//  Copyright © 2019 Bold Lion. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Oops", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
