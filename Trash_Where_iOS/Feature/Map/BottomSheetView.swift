//
//  TrashDetailViewController.swift
//  Trash_Where_iOS
//
//  Created by 이치훈 on 2023/07/20.
//

import SnapKit
import UIKit

final class BottomSheetView: PassThroughView {
  
  // MARK: Constants
  enum Mode {
    case tip
    case full
  }
  
  private enum Const {
    static let duration = 0.5
    static let cornerRadius = 12.0
    static let barViewTopSpacing = 5.0
    static let barViewSize = CGSize(width: UIScreen.main.bounds.width * 0.2, height: 5.0)
    static let bottomSheetRatio: (Mode) -> Double = { mode in
      switch mode {
      case .tip:
        return 0.83 // 위에서 부터의 값 (밑으로 갈수록 값이 커짐)
      case .full:
        return 0.5
      }
    }
    static let bottomSheetYPosition: (Mode) -> Double = { mode in
      Self.bottomSheetRatio(mode) * UIScreen.main.bounds.height
    }
  }
  
  // MARK: - Properties
  var mode: Mode = .tip {
    didSet {
      switch self.mode {
      case .tip:
        cancelPinButton.isHidden = true
        break
      case .full:
        cancelPinButton.isHidden = false
        break
      }
      self.updateConstraint(offset: Const.bottomSheetYPosition(self.mode))
    }
  }
  var bottomSheetColor: UIColor? {
    didSet { self.bottomSheetView.backgroundColor = self.bottomSheetColor }
  }
  var barViewColor: UIColor? {
    didSet { self.barView.backgroundColor = self.barViewColor }
  }
  
  // MARK: - UI
  
  let bottomSheetView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGroupedBackground
    return view
  }()
  private let barView: UIView = {
    let view = UIView()
    view.backgroundColor = .lightGray
    view.isUserInteractionEnabled = false
    view.layer.cornerRadius = 2.5
    return view
  }()
  let handlerView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
  let testLabel: UILabel = {
    let label = UILabel()
    label.text = "BottomSheetView"
    return label
  }()
  let cancelPinButton: UIButton = {
    let button = UIButton()
    let cancelImageView = UIImageView(image: UIImage(systemName: "xmark"))
    button.backgroundColor = .white
    button.layer.cornerRadius = 15
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowOpacity = 0.5
    button.layer.shadowRadius = 3
    button.isHidden = true
    button.addSubview(cancelImageView)
    cancelImageView.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }
    cancelImageView.tintColor = .black
    return button
  }()
  
  // MARK: - Initializer
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.backgroundColor = .clear
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
    self.handlerView.addGestureRecognizer(panGesture)
    
    self.bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    self.bottomSheetView.layer.cornerRadius = Const.cornerRadius
    self.bottomSheetView.clipsToBounds = true
    
    addTarget()
    configureSubviews()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init() has not been implemented")
  }
  
  func addTarget() {
    cancelPinButton.addTarget(self, action: #selector(cancelPin), for: .touchUpInside)
  }
  
  // MARK: - Action
  
  @objc private func didPan(_ recognizer: UIPanGestureRecognizer) {
    let translationY = recognizer.translation(in: self).y
    let minY = self.bottomSheetView.frame.minY
    let offset = translationY + minY
    
    if Const.bottomSheetYPosition(.full)...Const.bottomSheetYPosition(.tip) ~= offset {
      self.updateConstraint(offset: offset)
      recognizer.setTranslation(.zero, in: self)
    }
    UIView.animate(
      withDuration: 0,
      delay: 0,
      options: .curveEaseOut,
      animations: self.layoutIfNeeded,
      completion: nil
    )
    
    guard recognizer.state == .ended else { return }
    UIView.animate(
      withDuration: Const.duration,
      delay: 0,
      options: .allowUserInteraction,
      animations: {
        // velocity를 이용하여 위로 스와이프인지, 아래로 스와이프인지 확인
        self.mode = recognizer.velocity(in: self).y >= 0 ? Mode.tip : .full
      },
      completion: nil
    )
  }
  
  @objc func cancelPin() {
    print("select dismiss")
    self.pushDownBottomSheet()
    cancelPinButton.isHidden = true
  }
  
  public func popUpBottomSheet() { // bottomSheetView 올림
    UIView.animate(
      withDuration: Const.duration,
      delay: 0,
      options: .allowUserInteraction,
      animations: {
        // velocity를 이용하여 위로 스와이프인지, 아래로 스와이프인지 확인
        self.mode = .full
      },
      completion: nil
    )
  }
  
  public func pushDownBottomSheet() { //bottomSheetView 내림
    UIView.animate(
      withDuration: Const.duration,
      delay: 0,
      options: .allowUserInteraction,
      animations: {
        // velocity를 이용하여 위로 스와이프인지, 아래로 스와이프인지 확인
        self.mode = .tip
      },
      completion: nil
    )
  }
  
}

//MARK: - LayoutSupport

extension BottomSheetView: LayoutSupport {

  func configureSubviews() {
    addSubviews()
    setupSubviewsConstraints()
  }

  func addSubviews() {
    self.addSubview(self.bottomSheetView)
    self.bottomSheetView.addSubview(handlerView)
    self.handlerView.addSubview(self.barView)
    self.bottomSheetView.addSubview(testLabel)
    self.handlerView.addSubview(cancelPinButton)
  }

}

extension BottomSheetView: SetupSubviewsConstraints {

  private func updateConstraint(offset: Double) {
    self.bottomSheetView.snp.updateConstraints {
      $0.left.right.bottom.equalToSuperview()
      $0.top.equalToSuperview().inset(offset)
    }
  }
  
  func setupSubviewsConstraints() {
    self.bottomSheetView.snp.makeConstraints {
      $0.left.right.bottom.equalToSuperview()
      $0.top.equalTo(Const.bottomSheetYPosition(.tip))
    }
    
    self.barView.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().inset(Const.barViewTopSpacing)
      $0.size.equalTo(Const.barViewSize)
    }
    
    self.handlerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(bottomSheetView)
      $0.height.equalTo(40)
    }
    
    self.testLabel.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }
    
    self.cancelPinButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(5)
      $0.height.width.equalTo(30)
    }
  }

}
