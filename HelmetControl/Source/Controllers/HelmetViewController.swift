//
//  HelmetViewController.swift
//  ShakuroApp
//
//  Created by Vlad Onipchenko on 8/10/20.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import UIKit
import SpriteKit
import Shakuro_CommonTypes

public class HelmetViewController: UIViewController {

    public static func loadFromNib() -> HelmetViewController {
        return HelmetBundleHelper.instantiateViewController(targetClass: HelmetViewController.self, nibName: "HelmetViewController")
    }

    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var helmetContainerView: UIView!
    @IBOutlet private var helmetView: SKView!

    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var buyButton: UIButton!
    @IBOutlet private var priceLabel: PriceLabel!

    private let scene = HelmetScene()

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        buyButton.isHidden = true
        helmetView.clipsToBounds = false
        helmetContainerView.clipsToBounds = false
        helmetView.showsFPS = false
        helmetView.showsNodeCount = false
        helmetView.ignoresSiblingOrder = true
        helmetView.presentScene(scene)
        helmetView.allowsTransparency = true
        helmetView.scene?.backgroundColor = UIColor.clear
        gradientView.setupGradient { (layer) in
            layer.colors = [
                UIColor(red: 0.188, green: 0.18, blue: 0.282, alpha: 1).cgColor,
                UIColor(red: 0.055, green: 0.122, blue: 0.192, alpha: 1).cgColor
            ]
            layer.locations = [0, 1]
            layer.startPoint = CGPoint(x: 0.5, y: 0.25)
            layer.endPoint = CGPoint(x: 0.5, y: 0.75)
        }
        let infoText = NSLocalizedString("Riding in winter? You need a dual pane face shield. The EVO-AT970 is the dual-sport helmet that lets you decide: face shield or goggles.", comment: "")
        let infoParagraphStyle = NSMutableParagraphStyle()
        infoParagraphStyle.lineHeightMultiple = 1.46
        infoParagraphStyle.alignment = .center
        infoLabel.attributedText = NSAttributedString(string: infoText,
                                                      attributes: [.font: Stylesheet.FontFace.sfProMedium.fontWithSize(14),
                                                                   .paragraphStyle: infoParagraphStyle])
        infoLabel.textColor = UIColor(hex: "#BBBFD2")?.withAlphaComponent(0.4)
        buyButton.backgroundColor = HelmetBundleHelper.color(named: "HelmetColor")
        buyButton.clipsToBounds = true
        buyButton.layer.cornerRadius = 28
        buyButton.setTitle(NSLocalizedString("BUY NOW", comment: ""), for: .normal)

        priceLabel.font = Stylesheet.FontFace.dinCondensedBold.fontWithSize(48)
        priceLabel.setText("$289.95", animated: false)
        priceLabel.backgroundColor = .clear

        scene.didSelectBlackHelmet = { [weak self] in
            self?.priceLabel.setText("$289.95", animated: true)
        }

        scene.didSelectPinkHelmet = { [weak self] in
            self?.priceLabel.setText("$295.40", animated: true)
        }

    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (helmetView.scene as? HelmetScene)?.didAppear()
    }

    @IBAction private func buyButtonPressed(_ sender: UIButton) {

    }

}
