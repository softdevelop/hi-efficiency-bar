//
//  ViewDetailVC.swift
//  Hi-Efficiency Bar
//
//  Created by Colin Ngo on 3/21/18.
//  Copyright © 2018 QTS Coder. All rights reserved.
//

import UIKit
import Alamofire
class ViewDetailVC: HelpController,ASFSharedViewTransitionDataSource {
    @IBOutlet weak var tblDetail: UITableView!
     @IBOutlet weak var imgDetail: UIImageView!
    @IBOutlet weak var btnAddMyCard: SSSpinnerButton!
    @IBOutlet weak var lblQuanlity: UILabel!
    var number = 1
    @IBOutlet var subNaviRight: UIView!
    @IBOutlet weak var btnFav: UIButton!
    @IBOutlet weak var constraintBottomFav: NSLayoutConstraint!
    var isFav = false
    @IBOutlet weak var iconCustomize: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    var drinkObj = DrinkObj.init(dict: NSDictionary.init())
    var arringredients = NSMutableArray.init()
    var arrGarnish = NSMutableArray.init()
    @IBOutlet weak var heightTable: NSLayoutConstraint!
    @IBOutlet weak var tblGarnish: UITableView!
    @IBOutlet weak var heightTblGarnish: NSLayoutConstraint!
    @IBOutlet weak var subIce: UIView!
    @IBOutlet weak var subTitleIce: UIView!
    @IBOutlet weak var heightIce: NSLayoutConstraint!
    @IBOutlet weak var heightTitleIce: NSLayoutConstraint!
    
    @IBOutlet weak var imgNone: UIImageView!
    @IBOutlet weak var lblNone: UILabel!
    @IBOutlet weak var imgSome: UIImageView!
    @IBOutlet weak var lblSome: UILabel!
    @IBOutlet weak var imgNormal: UIImageView!
    @IBOutlet weak var lblNormal: UILabel!
    var valueIce = 0
    @IBOutlet weak var bgCover: UIImageView!
    @IBOutlet weak var icCup: UIImageView!
    var idProduct = 0
    @IBOutlet weak var scrollPage: UIScrollView!
     var closeBar = CloseBar.init(frame: .zero)
    var cartSuccess = AddCartSuccess.init(frame: .zero)
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(ViewDetailVC.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        // refreshControl.tintColor = UIColor.red
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing please wait...", attributes: attributes)
        return refreshControl
    }()
    var timer: Timer?
    var indexSecond = 0.0
    var isSuccess = false
    var numberItem = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
         self.tblDetail.register(UINib(nibName: "CurrentOrderCellNotTimeLine", bundle: nil), forCellReuseIdentifier: "CurrentOrderCell")
        btnAddMyCard.spinnerColor = .white
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        let btnRight = UIBarButtonItem.init(customView: subNaviRight)
        self.navigationItem.rightBarButtonItem = btnRight
        if idProduct == 0
        {
            self.initViewDetail()
        }
        else{
            self.getDrinkByID()
        }
         self.scrollPage.addSubview(self.refreshControl)
        addCartSuccess()
      
    }
    
    func addCartSuccess()
    {
         cartSuccess = Bundle.main.loadNibNamed("AddCartSuccess", owner: self, options: nil)?[0] as! AddCartSuccess
        cartSuccess.frame = CGRect(x:0, y:self.view.frame.size.height - 70 - (self.tabBarController?.tabBar.frame.size.height)!, width: self.view.frame.size.width, height: 70)
        cartSuccess.constraintRightImage.constant = (UIScreen.main.bounds.size.width/5) + 5
         cartSuccess.imgDetail.image = imgDetail.image
        cartSuccess.imgDetail.backgroundColor = UIColor.white
      
    }
    
    func showPopUpCloseBar(_ isAdd: Bool)
    {
        self.closeBar.removeFromSuperview()
        closeBar = Bundle.main.loadNibNamed("CloseBar", owner: self, options: nil)?[0] as! CloseBar
        closeBar.registerCell()
        closeBar.frame = UIScreen.main.bounds
        closeBar.tapRefresh = { [] in
            if isAdd
            {
                self.closeBar.removeFromSuperview()
            }
            else{
              self.getDrinkByID()
            }
            
        }
        APP_DELEGATE.window?.addSubview(closeBar)
    }
    @objc func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        //DO
        if idProduct == 0
        {
            if drinkObj.id != nil
            {
                self.idProduct = drinkObj.id!
                self.getDrinkByID()
            }
            
        }
        else{
            self.getDrinkByID()
        }
    }
    
    
    func getDrinkByID()
    {
        ManagerWS.shared.getDrinkBYID(drinkID: self.idProduct) { (success, obj) in
            self.refreshControl.endRefreshing()
            if !success!
            {
                self.showPopUpCloseBar(false)
            }
            else{
                if obj != nil
                {
                    self.closeBar.removeFromSuperview()
                    self.drinkObj = obj!
                    print(self.drinkObj.ingredients!)
                    self.initViewDetail()
                }
            }
           
        }
    }
    
    @objc func timeSecond()
    {
        indexSecond = indexSecond + 0.1
        if indexSecond == MAX_SECOND
        {
            
            if isSuccess
            {
                 //
                print("SUCCESS")
                timer?.invalidate()
                timer = nil
                if success!
                {
                    
                    btnAddMyCard.stopAnimate(complete: {
                        self.btnAddMyCard.alpha = 0.1
                        UIView.animate(withDuration: 0.5, animations: {
                            self.btnAddMyCard.alpha = 1.0
                            self.removeLoadingView()
                            self.btnAddMyCard.setBackgroundImage(#imageLiteral(resourceName: "btn"), for: .normal)
                            self.btnAddMyCard.setTitle("", for: .normal)
                            self.btnAddMyCard.setImage(#imageLiteral(resourceName: "tick"), for: .normal)
                        }, completion: { (success) in
                            self.view.addSubview(self.cartSuccess)
                            self.cartSuccess.imgDetail.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                            self.cartSuccess.imgPin.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                            self.cartSuccess.spaceBottom.constant = 0
                            APP_DELEGATE.callWSgetBadge()
                            UIView.animate(withDuration: 1.0,
                                           delay: 0,
                                           usingSpringWithDamping: CGFloat(0.3),
                                           initialSpringVelocity: CGFloat(0.35),
                                           options: UIViewAnimationOptions.allowUserInteraction,
                                           animations: {
                                            self.cartSuccess.imgDetail.transform = CGAffineTransform.identity
                                            self.cartSuccess.imgPin.transform = CGAffineTransform.identity
                            },
                                           completion: { Void in()
                                            self.cartSuccess.removeFromSuperview()
                                            self.btnAddMyCard.setBackgroundImage(#imageLiteral(resourceName: "btn"), for: .normal)
                                            self.btnAddMyCard.setTitle("ADD TO MY TAB", for: .normal)
                                            self.btnAddMyCard.setImage(UIImage.init(), for: .normal)
                            }
                            )
                        })
                        
                    })
                    
                }
                else{
                    
                    btnAddMyCard.stopAnimate(complete: {
                        self.removeLoadingView()
                        self.btnAddMyCard.setBackgroundImage(#imageLiteral(resourceName: "btn"), for: .normal)
                        self.btnAddMyCard.setTitle("ADD TO MY TAB", for: .normal)
                        self.btnAddMyCard.setImage(UIImage.init(), for: .normal)
                        if self.code == SERVER_CODE.CODE_403
                        {
                            self.showPopUpCloseBar(true)
                        }
                        else{
                            self.showAlertMessage(message: self.error!)
                        }   
                    })
                    
                  
                    
                }
                
            }
            else{
                indexSecond =  0.1
            }
        }
    }
    
    func initViewDetail()
    {
        arrGarnish.removeAllObjects()
        arringredients = drinkObj.ingredients?.mutableCopy() as! NSMutableArray
        for recod in drinkObj.garnishes!
        {
            let dict = recod as! NSDictionary
            let obj = garnish.init(dict: dict)
           
            arrGarnish.add(obj)
            
        }
        if drinkObj.image != nil
        {
            imgDetail.sd_setImage(with: URL.init(string: drinkObj.image!), completed: { (image, error, type, url) in
                if error == nil
                {
                    //self.setSizeFitImageToImage(image!)
                }
            })
        }
        if drinkObj.image_background != nil
        {
            bgCover.sd_setImage(with: URL.init(string: drinkObj.image_background!), completed: { (image, error, type, url) in
                //CommonHellper.addBlurView(self.bgCover)
            })
        }
        else{
            CommonHellper.addBlurView(self.bgCover)
        }
        lblName.text = drinkObj.name
        if drinkObj.is_favorite! {
            self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav2"), for: .normal)
        }
        else{
            self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav1"), for: .normal)
        }
        heightTable.constant = CGFloat(arringredients.count * 55)
        heightTblGarnish.constant = CGFloat(arrGarnish.count * 44)
        if drinkObj.is_have_ice!
        {
            subIce.isHidden = false
            subTitleIce.isHidden = false
            heightTitleIce.constant = 35
            heightIce.constant = 100
        }
        else{
            subIce.isHidden = true
            subTitleIce.isHidden = true
            heightTitleIce.constant = 0
            heightIce.constant = 0
        }
        valueIce = 0
        self.setColorTextNormalOrSelect(lable: lblNone, isSelect: true)
        self.setColorTextNormalOrSelect(lable: lblSome, isSelect: false)
        self.setColorTextNormalOrSelect(lable: lblNormal, isSelect: false)
        setImageSeletd(imageView: imgNone, uimage: #imageLiteral(resourceName: "ice_none2"))
        setImageSeletd(imageView: imgSome, uimage: #imageLiteral(resourceName: "ice_some1"))
        setImageSeletd(imageView: imgNormal, uimage: #imageLiteral(resourceName: "ice_normal1"))
        if drinkObj.categoryObj?.name == "1"
        {
            icCup.image = #imageLiteral(resourceName: "ic_cup")
        }
        else if drinkObj.categoryObj?.name == "2"
        {
            icCup.image = #imageLiteral(resourceName: "ic_cup2")
        }
        else{
            icCup.image = #imageLiteral(resourceName: "ic_cup3")
        }
        self.tblDetail.reloadData()
        self.tblGarnish.reloadData()
        if drinkObj.status == CONST_STATUS_ENABLED
        {
            btnAddMyCard.isEnabled = true
        }
        else{
             btnAddMyCard.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func doFav(_ sender: Any) {
        if !drinkObj.is_favorite!
        {
            drinkObj.is_favorite = true
            UIView.animate(withDuration: 0.5,
                           animations: {
                            self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav2"), for: .normal)
                            self.constraintBottomFav.constant = -52
                            self.btnFav.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
                           completion: { _ in
                            UIView.animate(withDuration: 0.25) {
                                self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav2"), for: .normal)
                                self.constraintBottomFav.constant = -37
                                self.btnFav.transform = CGAffineTransform.identity
                            }
            })
        }
        else{
           drinkObj.is_favorite = false
            UIView.animate(withDuration: 0.5,
                           animations: {
                            self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav1"), for: .normal)
                            self.constraintBottomFav.constant = -52
                            self.btnFav.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
                           completion: { _ in
                            UIView.animate(withDuration: 0.25) {
                                self.btnFav.setImage(#imageLiteral(resourceName: "ic_fav1"), for: .normal)
                                self.constraintBottomFav.constant = -37
                                self.btnFav.transform = CGAffineTransform.identity
                            }
            })
        }
        
        ManagerWS.shared.favUnFavDrink(drinkID: drinkObj.id!) { (success) in
            
        }
       
    }
    @IBAction func doCustomize(_ sender: Any) {
        self.iconCustomize.swing {
            let vc = UIStoryboard.init(name: "Tabbar", bundle: nil).instantiateViewController(withIdentifier: "CustomDetailVC") as! CustomDetailVC
            vc.drinkObj = self.drinkObj
            self.navigationController?.pushViewController(vc, animated: true)
        }
       
      
    }
    
    @IBAction func doBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func doTang(_ sender: Any) {
        number = number + 1
        lblQuanlity.text = "\(number)"
        CommonHellper.animateButton(view: lblQuanlity)
    }
    
    @IBAction func doGiam(_ sender: Any) {
        if number == 1
        {
            
        }
        else{
            number = number - 1
            lblQuanlity.text = "\(number)"
            CommonHellper.animateButton(view: lblQuanlity)
        }
    }
    var success: Bool?
    var error: String?
    var code: Int?
    
    @IBAction func doAddMyTab(_ sender: SSSpinnerButton) {
        self.addLoadingView()
        sender.setBackgroundImage(#imageLiteral(resourceName: "color_tim"), for: .normal)
        sender.startAnimate(spinnerType: .circleStrokeSpin, spinnercolor: .white, complete: nil)
        indexSecond = 0.1
        self.isSuccess = false
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timeSecond), userInfo: nil, repeats: true)
        ManagerWS.shared.addMyTab(para: self.paramAddMyTab(), complete: { (success, error, code) in
            if error != nil
            {
                self.btnAddMyCard.stopAnimate(complete: {
                    self.removeLoadingView()
                    self.btnAddMyCard.setBackgroundImage(#imageLiteral(resourceName: "btn"), for: .normal)
                    self.btnAddMyCard.setTitle("ADD TO MY TAB", for: .normal)
                    self.btnAddMyCard.setImage(UIImage.init(), for: .normal)
                    if self.code == SERVER_CODE.CODE_403
                    {
                    }
                    else{
                        print(error)
                        self.showAlertMessage(message: error!)
                    }
                    
                })
            }
            else{
                
                self.isSuccess = true
                self.success = success
                self.error = error
                self.code = code
            }
            

        })
        
    }
  
    func checkValueGarnish()->Bool
    {
        var isCheck = false
        for recod in arrGarnish {
            let obj = recod as! garnish
            if obj.isSwitch!
            {
                isCheck = true
                break
            }
        }
        return isCheck
    }
    
    
    func arrayparaGarnish()-> String
    {
        var strIngredient = ""
        for recod in arrGarnish {
            let obj = recod as! garnish
            if obj.isSwitch!
            {
                strIngredient = "\(strIngredient)\(obj.id!),"
            }
        }
        if !strIngredient.isEmpty
        {
            strIngredient = strIngredient.substring(from: 0, to: strIngredient.count - 1)
        }
        strIngredient  =  "[\(strIngredient)]"
        return strIngredient
    }
    
    func paramAddMyTab()->Parameters
    {
        if self.checkValueGarnish() {
            let para = ["ice": valueIce, "quantity": lblQuanlity.text!, "drink": drinkObj.id!,"garnishes": self.arrayparaGarnish()] as [String : Any]
            return para
        }
        else{
            let para = ["ice": valueIce, "quantity": lblQuanlity.text!, "drink": drinkObj.id!] as [String : Any]
            return para
        }
    }
    
   
    func sharedView() -> UIView! {
        return self.imgDetail
    }
    
    func setColorTextNormalOrSelect(lable: UILabel, isSelect: Bool)
    {
        if isSelect {
            lable.textColor = COLOR_SELECTED
        }
        else
        {
            lable.textColor = COLOR_NORMAL
        }
    }
    func setImageSeletd(imageView: UIImageView, uimage: UIImage)
    {
        imageView.image = uimage
    }
    @IBAction func doNone(_ sender: Any) {
        self.setColorTextNormalOrSelect(lable: lblNone, isSelect: true)
        self.setColorTextNormalOrSelect(lable: lblSome, isSelect: false)
        self.setColorTextNormalOrSelect(lable: lblNormal, isSelect: false)
        setImageSeletd(imageView: imgNone, uimage: #imageLiteral(resourceName: "ice_none2"))
        setImageSeletd(imageView: imgSome, uimage: #imageLiteral(resourceName: "ice_some1"))
        setImageSeletd(imageView: imgNormal, uimage: #imageLiteral(resourceName: "ice_normal1"))
        CommonHellper.animateView(view: imgNone)
        valueIce = 0
    }
    @IBAction func doSome(_ sender: Any) {
        self.setColorTextNormalOrSelect(lable: lblNone, isSelect: false)
        self.setColorTextNormalOrSelect(lable: lblSome, isSelect: true)
        self.setColorTextNormalOrSelect(lable: lblNormal, isSelect: false)
        setImageSeletd(imageView: imgNone, uimage: #imageLiteral(resourceName: "ice_none1"))
        setImageSeletd(imageView: imgSome, uimage: #imageLiteral(resourceName: "ice_some2"))
        setImageSeletd(imageView: imgNormal, uimage: #imageLiteral(resourceName: "ice_normal1"))
        CommonHellper.animateView(view: imgSome)
        valueIce = 10
    }
    @IBAction func doNormal(_ sender: Any) {
        self.setColorTextNormalOrSelect(lable: lblNone, isSelect: false)
        self.setColorTextNormalOrSelect(lable: lblSome, isSelect: false)
        self.setColorTextNormalOrSelect(lable: lblNormal, isSelect: true)
        
        setImageSeletd(imageView: imgNone, uimage: #imageLiteral(resourceName: "ice_none1"))
        setImageSeletd(imageView: imgSome, uimage: #imageLiteral(resourceName: "ice_some1"))
        setImageSeletd(imageView: imgNormal, uimage: #imageLiteral(resourceName: "ice_normal2"))
        CommonHellper.animateView(view: imgNormal)
        valueIce = 20
    }
}
extension ViewDetailVC: UITableViewDelegate, UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tblGarnish
        {
            return arrGarnish.count
        }
        return arringredients.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == tblGarnish
        {
            return 44
        }
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tblGarnish
        {
            let cell = self.tblGarnish.dequeueReusableCell(withIdentifier: "GarnishCell") as! GarnishCell
            self.configCellGarnish(cell, garnishObj: arrGarnish[indexPath.row] as! garnish)
            return cell
        }
        let cell = self.tblDetail.dequeueReusableCell(withIdentifier: "CurrentOrderCell") as! CurrentOrderCell
        cell.subContent.backgroundColor = CommonHellper.ramColorViewDetail()
        cell.backgroundColor = UIColor.clear
        self.configCell(cell, dict: arringredients[indexPath.row] as! NSDictionary)
        return cell
    }
    
    func configCell(_ cell: CurrentOrderCell, dict: NSDictionary)
    {
        if let unit = dict.object(forKey: "unit_view") as? String
        {
            if let ratio = dict.object(forKey: "ratio") as? Double
            {
                 cell.lblPart.text = "\(ratio) \(unit)"
            }
           
        }
        
        if let val = dict.object(forKey: "ingredient") as? NSDictionary
        {
            if let name = val.object(forKey: "name") as? String
            {
                 cell.lblName.text = name
            }
        }
        else{
             cell.lblName.text = ""
        }
       
    }
    
    func configCellGarnish(_ cell: GarnishCell, garnishObj: garnish)
    {
         cell.lblName.text = garnishObj.name
        cell.btnSwitch.isOn = garnishObj.isSwitch!
        
    }
}

