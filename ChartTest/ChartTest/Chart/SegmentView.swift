//
//  SegmentView.swift
//
//
//  Created by 王星鑫 on 2022/10/6.
//  Copyright © 2019 王星鑫. All rights reserved.
//

import UIKit
import SnapKit
public protocol SegmentViewDelegate: NSObjectProtocol {
    func segmentView(_ segmentView: SegmentView, selectedIndex: Int)
}

public class SegmentView: UIView {
    public weak var delegate: SegmentViewDelegate?
    public var titleEdge: CGFloat=30
    public var titleSpace: CGFloat=15
    public var defaultColor = UIColor.black
    public var selectedColor = UIColor.red
    public var defaultFont = UIFont.systemFont(ofSize: 14)
    public var selectedFont = UIFont.boldSystemFont(ofSize: 16)
    public var titles: [String]=["title1", "title2"]
    public var trailiingView:UIView?
    public var seletedBtn: UIButton?
    public var scrollable: Bool=true
    public var defaultBgColor = UIColor.clear
    public var selectBgColor = UIColor.clear
    public var titleInnerEdge:CGFloat = 0
    public var isCornered = false
    public var initSelectIndex:Int = 0


    public lazy var scrollView: UIScrollView = {
        let scrollview=UIScrollView.init()
        scrollview.backgroundColor = .white
        scrollview.showsHorizontalScrollIndicator=false
        return scrollview
    }()

    public lazy var line: UIView = {
        let line=UIView(frame: .zero)
        line.frame.size = .init(width: 20, height: 4)
        line.layer.cornerRadius = 2
        line.backgroundColor=self.selectedColor
        return line
    }()

    public init(frame: CGRect, titles: [String]) {
        super.init(frame: frame)
        self.titles=titles
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")

    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        self.initUI()
    }

    func initUI() {
        self.scrollView.frame=self.bounds
        self.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.scrollView.addSubview(self.line)

        var titlesLenght: CGFloat=0.0
        var title_x: CGFloat=CGFloat(self.titleEdge)

        if self.scrollable {
            for (index, value) in self.titles.enumerated() {
                var size = value.boundingRect(with: CGSize.init(width: 300, height: 20), options: NSStringDrawingOptions.usesFontLeading, attributes: [NSAttributedString.Key.font: self.selectedFont], context: nil)
                size.size.width += (2*self.titleInnerEdge)
                titlesLenght += size.width

                let titleBtn=UIButton.init(type: .custom)
                titleBtn.layer.cornerRadius = self.isCornered ? self.frame.height*0.5:0
                titleBtn.clipsToBounds = true
                self.scrollView.addSubview(titleBtn)
                titleBtn.tag=index+100
                titleBtn.titleLabel?.font=self.defaultFont
                titleBtn.setTitle(value, for: .normal)
                titleBtn.setTitleColor(self.defaultColor, for: .normal)
                titleBtn.setTitleColor(self.selectedColor, for: .selected)
            
                titleBtn.addTarget(self, action: #selector(titleBtnClick(btn:)), for: UIControl.Event.touchUpInside)
                titleBtn.frame=CGRect.init(x: title_x, y: 0, width: size.width, height: self.frame.size.height)
                title_x=title_x+size.width+CGFloat(self.titleSpace)
            }
            if let trailingView = self.trailiingView{
                trailingView.frame=CGRect.init(x: title_x, y: 0, width: trailingView.intrinsicContentSize.width, height: self.frame.size.height)
                self.scrollView.addSubview(trailingView)
                title_x = title_x+trailingView.intrinsicContentSize.width+CGFloat(self.titleSpace)
            }
            self.scrollView.contentSize=CGSize(width: title_x-self.titleSpace+self.titleEdge>self.scrollView.frame.size.width ? title_x-self.titleSpace+self.titleEdge:self.scrollView.frame.size.width, height: 0)
        } else {
            for value in self.titles {
                var size = value.boundingRect(with: CGSize.init(width: 300, height: 20), options: NSStringDrawingOptions.usesFontLeading, attributes: [NSAttributedString.Key.font: self.selectedFont], context: nil)
                titlesLenght += size.width
            }

            self.titleSpace=(self.scrollView.frame.size.width-2*self.titleEdge-titlesLenght)/CGFloat(self.titles.count-1)

            for (index, value) in self.titles.enumerated() {
                var size = value.boundingRect(with: CGSize.init(width: 300, height: 20), options: NSStringDrawingOptions.usesFontLeading, attributes: [NSAttributedString.Key.font: self.selectedFont], context: nil)
                size.size.width += (2*self.titleInnerEdge)

                titlesLenght += size.width

                let titleBtn=UIButton.init(type: .custom)
                titleBtn.layer.cornerRadius = self.isCornered ? self.frame.height*0.5:0
                titleBtn.clipsToBounds = true
                self.scrollView.addSubview(titleBtn)
                titleBtn.tag=index+100
                titleBtn.titleLabel?.font=self.defaultFont
                titleBtn.setTitle(value, for: .normal)
                titleBtn.setTitleColor(self.defaultColor, for: .normal)
                titleBtn.setTitleColor(self.selectedColor, for: .selected)
    
                titleBtn.addTarget(self, action: #selector(titleBtnClick(btn:)), for: UIControl.Event.touchUpInside)
                titleBtn.frame=CGRect.init(x: title_x, y: 0, width: (self.titles.count == 1) ?self.frame.width:size.width, height: self.frame.size.height)
                title_x=title_x+size.width+CGFloat(self.titleSpace)
            }
            self.scrollView.contentSize=CGSize(width: title_x-self.titleSpace+self.titleEdge>self.scrollView.frame.size.width ? title_x-self.titleSpace+self.titleEdge:self.scrollView.frame.size.width, height: 0)
        }

        self.selectIndex(index: self.initSelectIndex, withDelegate: false)
    }

    @objc func titleBtnClick(btn: UIButton) {
        self.selectIndex(index: btn.tag-100, withDelegate: true)
    }

    public func selectIndex(index: Int, withDelegate: Bool) {
        self.seletedBtn?.isSelected=false
        self.seletedBtn?.titleLabel?.font = self.defaultFont
        if !(self.scrollView.viewWithTag(index+100)?.isKind(of: UIButton.self) ?? false) {
            return
        }
        guard let btn=self.scrollView.viewWithTag(index+100) as? UIButton else{
            return
        }
        btn.isSelected=true
        self.seletedBtn=btn
        self.seletedBtn?.titleLabel?.font = self.selectedFont
        UIView.animate(withDuration: 0.3, animations: {
            self.line.frame.origin = .init(x:btn.frame.origin.x + (btn.frame.size.width-self.line.frame.width)*0.5 , y: self.frame.size.height-self.line.frame.height)
//            self.line.frame=CGRect(x: btn.frame.origin.x, y: self.frame.size.height-2, width: btn.frame.size.width, height: 2)
        }) { (_) in
            UIView .animate(withDuration: 0.3, animations: {
                var x=btn.frame.origin.x+btn.frame.size.width/2-self.frame.size.width/2
                if x<0 {
                    x=0
                }
                if x>(self.scrollView.contentSize.width-self.bounds.size.width) {
                    x=(self.scrollView.contentSize.width-self.bounds.size.width)
                }
                self.scrollView.contentOffset=CGPoint(x: x, y: 0)
            })
        }
        if withDelegate {
            self.delegate?.segmentView(self, selectedIndex: index)
        }

    }

    public  func setBackgroundColor(color: UIColor) {
        self.backgroundColor = color
        self.scrollView.backgroundColor = color
    }

    func reloadData() {
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        self.initUI()
    }
}
