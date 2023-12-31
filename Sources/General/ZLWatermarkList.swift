//
//  ZLWatermarkList.swift
//  ZLPhotoBrowserDTCustom
//
//  Created by Tao Deng on 2023/5/23.
//

import UIKit


public enum ZLWatermarkType :String {
    case noWatermark = "无水印"
    case personalWatermark = "个人水印"
    case tiledWatermark = "平铺水印"
}

public class ZLWatermark{
    
    public static let shared : ZLWatermark = {
        let instance = ZLWatermark()
        return instance
    }()
    
    public var watermarkType :ZLWatermarkType = .personalWatermark
    
    private let watermakeList: ZLWatermarkList = ZLWatermarkList(frame: UIScreen.main.bounds)
    
    fileprivate var selectedTypeCompletion :(() -> Void)?
    
    fileprivate weak var superView :UICollectionView?
    
    weak var watermakebutton :Watermakebutton?
    
    fileprivate let logoImage = getImage("zlp_colg_logo")
    
    public var userName :String = ""
    
    public func hide(){
        ZLWatermark.shared.superView?.isScrollEnabled = true
        self.watermakeList.removeFromSuperview()
        self.watermakebutton?.hide()
        self.superView = nil
    }
    
    public func show( inView :UICollectionView ,navigationBarHeight :CGFloat, completion : @escaping () -> Void) {
        guard self.superView != inView else {return}
        self.superView = inView
        self.superView?.isScrollEnabled = false
        
        self.selectedTypeCompletion = completion
        let topSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        watermakeList.table.frame = CGRect(origin: CGPoint(x:fabs(inView.frame.minX), y: -watermakeList.table.bounds.height), size: watermakeList.table.bounds.size)
        watermakeList.frame = inView.bounds
        inView.addSubview(watermakeList)
        

        UIView.animate(withDuration: 0.25, animations: {
            self.watermakeList.table.frame = CGRect(origin: CGPoint(x:self.watermakeList.table.frame.minX, y: (topSafeAreaInset + navigationBarHeight)), size: self.watermakeList.table.bounds.size)
        },completion: { (_) in
            let i = ["个人水印","平铺水印","无水印"].firstIndex(of: ZLWatermark.shared.watermarkType.rawValue) ?? 2
            self.watermakeList.table.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
        })
    }
    
    
    public func watermark(_ image: UIImage,_ type :ZLWatermarkType) -> UIImage {
        
        if type == .noWatermark {
            return image
        }
        
        if image.size.width < 200 || image.size.height < 100 {
            return image
        }

        let font = 30 / 750  * image.size.width
    
        if type == .personalWatermark {
            
            UIGraphicsBeginImageContext(image.size)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let attributedText = createWatermarkAttributedString(font)
            if let logo = logoImage?.scaleImage(toHeight: font){
                if #available(iOS 13.0, *) {
                    let attachment = NSTextAttachment(image: logo)
                    attributedText.insert(NSAttributedString(attachment: attachment), at: 0)
                } else {
                    let attachment = NSTextAttachment()
                    attachment.image = logo;
                    attributedText.insert(NSAttributedString(attachment: attachment), at: 0)
                    
                    // Fallback on earlier versions
                }
                
            }
            let textSize = attributedText.size()
            let point = CGPoint(x: image.size.width - textSize.width - 10 , y: image.size.height - textSize.height - 10)
            let rect = CGRect(x: point.x, y: point.y, width: textSize.width, height: textSize.height)
            attributedText.draw(in: rect.integral)
            
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return result ?? image
            
        }else if type == .tiledWatermark {
            
            let attributedText = createWatermarkAttributedString(font)
            let textSize = attributedText.size()
            let stepX: CGFloat = textSize.width * 2
            let stepY: CGFloat = textSize.height * 2
//            let tiledSize = CGSize(width: textSize.width * 2, height: textSize.height * 3)
            
            let imageRect = CGRect(origin: .zero, size: image.size)

            let rendererForWatermark = UIGraphicsImageRenderer(size: image.size)

            let watermarkImage = rendererForWatermark.image { ctx in

                ctx.cgContext.translateBy(x: image.size.width / 2, y: image.size.height / 2)
                ctx.cgContext.rotate(by: -(CGFloat.pi / 4))
                ctx.cgContext.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)

                let w = (sqrt(pow(image.size.width, 2)+pow(image.size.height, 2)))
                var y: CGFloat = -w
                var doOffset = false
                
                while y < 2*w {
                    defer {
                        y += stepY
                        doOffset.toggle()
                    }
                    var x: CGFloat = -2*w
                    if doOffset {
                        x -= stepX/2
                    }
                    while x < w {
                        defer { x += stepX }
                        let p = CGPoint(x: x, y: y)
                        attributedText.draw(at: p)
                    }
                }
                
            }
            
            let rendererForImage = UIGraphicsImageRenderer(size: image.size)
            
            let finalImage = rendererForImage.image { ctx in
                image.draw(in: imageRect)
                watermarkImage.draw(at: CGPoint.zero, blendMode: .softLight, alpha: 0.7)
            }

            return finalImage
            
        }

        return image

    }
    
    
    func createWatermarkAttributedString(_ font :CGFloat) -> NSMutableAttributedString{
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        shadow.shadowOffset = CGSize(width: 1, height:1)
        shadow.shadowBlurRadius = 4
        let attributedStringKeys : [NSAttributedString.Key : Any] = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: font),
                                                                     NSAttributedString.Key.foregroundColor:UIColor(red: 1, green: 1, blue: 1, alpha: 1),
                                                                     NSAttributedString.Key.shadow:shadow,
                                                                     NSAttributedString.Key.baselineOffset: UIFont.systemFont(ofSize: font).lineHeight - font]
        
        let text = watermarkType == .personalWatermark ? self.userName : "@Colg玩家社区"
        
        let attributedText = NSMutableAttributedString(string: text,attributes: attributedStringKeys)
        return attributedText
    }
    
}


class ZLWatermarkList :UIControl,UIGestureRecognizerDelegate{
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    let table = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 168))
    private func setupView() {
        self.backgroundColor = .clear
        self.addTarget(self, action: #selector(watermakeListBackgroundAction), for: .touchUpInside)
        table.register(ZLWatermarkListCell.self, forCellReuseIdentifier: "ZLWatermarkListCell")
        table.backgroundColor = UIColor(red: 44/255, green: 45/255, blue: 44/255, alpha: 1)
        table.tableFooterView = UIView()
        table.isScrollEnabled = false
        table.rowHeight = 56
        table.separatorColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        table.separatorInset = .zero
        table.dataSource = self
        table.delegate = self
        self.addSubview(table)
        
    }
    
    @objc
    func watermakeListBackgroundAction(){
        removeWatermakeList()
    }
    
    func removeWatermakeList(){
        UIView.animate(withDuration: 0.25, animations: {
            self.table.frame = CGRectOffset(self.table.bounds, 0, -self.table.bounds.height)
        },completion: { (_) in
            ZLWatermark.shared.hide()
        })
    }
    

}

extension ZLWatermarkList :UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let watermarkTypes :[ZLWatermarkType] = [.personalWatermark,.tiledWatermark,.noWatermark]
        ZLWatermark.shared.watermarkType = watermarkTypes[indexPath.row] ?? .noWatermark
        ZLWatermark.shared.selectedTypeCompletion?()
        removeWatermakeList()
    }
}

extension ZLWatermarkList :UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZLWatermarkListCell", for: indexPath)
        (cell as? ZLWatermarkListCell)?.titleLabel.text = ["个人水印","平铺水印","无水印"][indexPath.row] ?? ""
        return cell
    }
}

class ZLWatermarkListCell :UITableViewCell{
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    let titleLabel = UILabel(frame: CGRect(x: 28, y: 18, width: 100, height: 20))
    let selectImage = UIImageView(frame: CGRect(x: UIScreen.main.bounds.width - 50, y: 14, width: 30, height: 30))
    private func setupView() {
        self.selectionStyle = .none
        self.backgroundColor = UIColor(red: 44/255, green: 45/255, blue: 44/255, alpha: 1)
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor(red: 44/255, green: 45/255, blue: 44/255, alpha: 1)
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        self.addSubview(titleLabel)
        
        selectImage.image = getImage("zl_albumSelect")
        selectImage.isHidden = true
        self.addSubview(selectImage)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectImage.isHidden = !isSelected
    }

}


extension UIImage {
    public func scaleImage(toHeight height: CGFloat) -> UIImage? {
        let scale = height / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}

class Watermakebutton :UIControl{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    let titleLabel = UILabel()
    var arrow :UIImageView!
    
    var selectWatermakeBlock: ( () -> Void )?
    
    private func setupView() {
        self.backgroundColor = UIColor(red: 91/255, green: 91/255, blue: 91/255, alpha: 1.0)
        self.layer.cornerRadius = ZLEmbedAlbumListNavView.titleViewH / 2
        self.layer.masksToBounds = true
        self.addTarget(self, action: #selector(watermakeClick), for: .touchUpInside)
        

        self.titleLabel.textColor = UIColor.white
        self.titleLabel.font = ZLLayout.bottomToolTitleFont
        self.titleLabel.textAlignment = .left
        self.titleLabel.text = ZLWatermark.shared.watermarkType.rawValue
        self.addSubview(self.titleLabel)
        
        self.arrow = UIImageView(image: getImage("zl_downArrow"))
        self.arrow.clipsToBounds = true
        self.arrow.contentMode = .scaleAspectFill
        self.addSubview(self.arrow)
        
    }
    
    func show(){
        if self.arrow.transform == .identity {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
    }
    
    func hide(){
        if self.arrow.transform != .identity {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = .identity
            }
        }
    }
    
    @objc func watermakeClick() {
        if ZLWatermark.shared.superView == nil {
            show()
        }
        self.selectWatermakeBlock?()
    
    }
}
