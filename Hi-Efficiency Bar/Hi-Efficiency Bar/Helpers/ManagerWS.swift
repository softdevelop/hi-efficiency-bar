//
//  ManagerWS.swift
//  ATAX
//
//  Created by QTS Coder on 8/16/17.
//  Copyright © 2017 QTS Coder. All rights reserved.
//

import UIKit
import Alamofire

struct ManagerWS {
    static let shared = ManagerWS()
    private let auth_headerLogin: HTTPHeaders    = ["Content-Type": "application/x-www-form-urlencoded"]
    private var manager: Alamofire.SessionManager
    private init() {
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "hiefficiencybar.com": .disableEvaluation
        ]
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        manager = Alamofire.SessionManager(
            configuration: URLSessionConfiguration.default,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }
    
    func register(_ para: Parameters, _ image: UIImage, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void) {
        let name = Date().millisecondsSince1970
        let imgData = UIImageJPEGRepresentation(image, 1.0)!
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imgData, withName: "avatar",fileName: "\(name).jpg", mimeType: "image/jpg")
            for (key, value) in para {
                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
        },
         to:"\(URL_SERVER)api/user/signup/")
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    switch(response.result) {
                    case .success(_):
                        if let code = response.response?.statusCode
                        {
                            print(response)
                            print("CODE   \(code)")
                            if let val = response.value as? NSDictionary
                            {
                                if code == SERVER_CODE.CODE_201
                                {
                                    if let id = val["id"] as? Int
                                    {
//                                        UserDefaults.standard.set(id, forKey: kID)
//                                        if let token = val["token"] as? String
//                                        {
//                                            UserDefaults.standard.set(token, forKey: kToken)
//                                        }
//                                        UserDefaults.standard.synchronize()
                                        complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                                    }
                                }
                                else if code == SERVER_CODE.CODE_400
                                {
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "User with this email address already exists."))
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"))
                                }
                            }
                            
                        }
                        break
                    case .failure(let error):
                        complete(false, ErrorManager.processError(error: error))
                    }
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
       
    }
   
    
    func loginUser(_ para: Parameters, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?, _ token: String?,_ id: Int?,_ birthday: String?) ->Void)
    {
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/")!, method: .post, parameters: para,  encoding: URLEncoding(destination: .methodDependent), headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                if let id = val["id"] as? Int
                                {
                                    if let token = val["token"] as? String
                                    {
                                        if let birthday = val["birthday"] as? String
                                        {
                                            complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"), token, id, birthday)
                                        }
                                        else{
                                            if let detail = val.object(forKey: "detail") as? String
                                            {
                                                 complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail), nil, nil, nil)
                                            }
                                            else{
                                                 complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Wrong birthday."), nil, nil, nil)
                                            }
                                        }
                                    }
                                }
                            }
                            else if code == SERVER_CODE.CODE_400
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail), nil, nil, nil)
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Wrong birthday."), nil, nil, nil)
                                }
                            }
                            else{
                                complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"),nil,nil, nil)
                            }
                        }
                        
                    }
                    break
                case .failure(let error):
                    complete(false, ErrorManager.processError(error: error), nil, nil, nil)
                }
            }
    }
    
    
    func getMainBar(complete:@escaping (_ success: Bool?, _ arrs: [MainBarObj]?, _ code: Int) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/category/?main=true")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [MainBarObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(MainBarObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas, code)
                            }
                        }
                        else{
                            complete(false, arrDatas, code)
                        }
                    }
                 break
                    
                case .failure(_):
                     complete(false, arrDatas, SERVER_CODE.CODE_403)
                    break
                }
            }
    }
    
    func getListDrink(offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        print(code)
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else if code == SERVER_CODE.CODE_403
                                {
                                    if let detail = val.object(forKey: "detail") as? String
                                    {
                                        APP_DELEGATE.mainBarVC?.showAlertCloseBar(detail)
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                     complete(true, arrDatas)
                                }
                            }
                            else{
                                if code == SERVER_CODE.CODE_403
                                {
                                    if let detail = val.object(forKey: "detail") as? String
                                    {
                                        APP_DELEGATE.mainBarVC?.showAlertCloseBar(detail)
                                    }
                                    complete(true, arrDatas)
                                }
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(true, arrDatas)
                    break
                }
        }
    }
    
    func getSearchDrink(txtSearch: String, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let search = txtSearch.replacingOccurrences(of: " ", with: "%20")
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?offset=\(offset)&limit=\(kLimitPage)&search=\(search)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                     complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(true, arrDatas)
                    break
                }
        }
    }
    
    func getSearchIngredient(txtSearch: String, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [Ingredient]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        var search = txtSearch.replacingOccurrences(of: "#", with: "").lowercased()
        search = search.replacingOccurrences(of: " ", with: "%20")
        print(search)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/ingredient/?offset=\(offset)&limit=\(kLimitPage)&search=\(search)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [Ingredient]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(Ingredient.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                     complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                     complete(true, arrDatas)
                case .failure(_):
                    break
                }
        }
    }
    
    
    func getListDrinkByCategory(categoryID: Int, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?category=\(categoryID)&offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                     complete(true, arrDatas)
                                }
                            }
                            else{
                                 complete(true, arrDatas)
                            }
                        }
                        else{
                             complete(true, arrDatas)
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(true, arrDatas)
                    break
                }
        }
    }
    
    
    func favUnFavDrink(drinkID: Int,complete:@escaping (_ success: Bool?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/favorite/\(drinkID)/")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                   complete(true)
                                    
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    break
                }
        }
    }
    
    func forgotPassword(para: Parameters,complete:@escaping (_ success: Bool?) ->Void)
    {
       
        manager.request(URL.init(string: "\(URL_SERVER)api/user/forget/password/")!, method: .post, parameters: para,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            print(val)
                            if code == SERVER_CODE.CODE_200
                            {
                                complete(true)
                                
                            }
                            else{
                                complete(false)
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false)
                    break
                }
        }
    }
    
    func getProfile(complete:@escaping (_ success: Bool?, _ inforUser: NSDictionary) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/")!, method: .post, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                complete(true, val)
                                
                            }
                            else{
                                complete(false, NSDictionary.init())
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false, NSDictionary.init())
                    break
                }
        }
    }
    
    func addMyTab(para: Parameters, complete:@escaping (_ success: Bool?,_ error: String?, _ codeError: Int?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(para)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        print(auth_headerLogin)
        manager.request(URL.init(string: "\(URL_SERVER)api/user/add/tab/")!, method: .post, parameters: para,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        print("CODE --\(code)")
                        if code == SERVER_CODE.CODE_201 || code == SERVER_CODE.CODE_200
                        {
                            complete(true, nil, code)
                            
                        }
                        else{
                            if let val = response.value as? NSDictionary
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                    complete(false, detail, code)
                                }
                                else{
                                    complete(false, "Server not order", code)
                                }
                            }
                            else{
                                complete(false,"Server not order", code)
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(false, "Server error", SERVER_CODE.CODE_200)
                    break
                }
        }
    }
    
    func getListAllGlass(complete:@escaping (_ success: Bool?, _ arrs: [GlassObj]?, _ code: Int) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/glass/")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [GlassObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(GlassObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas, code)
                            }
                            else{
                                 complete(false, arrDatas, code)
                            }
                            
                        }
                        else{
                            complete(false, arrDatas, code)
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(false, arrDatas, SERVER_CODE.CODE_403)
                    break
                }
        }
    }
    
    
    func addDrinkStep1(para: Parameters, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?,_ drinkID: Int?, _ code: Int) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(para)
        
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/")!, method: .post, parameters: para,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        print("CODE --\(code)")
                        if code == SERVER_CODE.CODE_201
                        {
                            if let val = response.value as? NSDictionary
                            {
                                if let id = val["id"] as? Int
                                {
                                    complete(true, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"), id, code)
                                }
                                else{
                                    if let detail = val.object(forKey: "name") as? String
                                    {
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail), 0, code)
                                    }
                                    else{
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: response.description), 0, code)
                                    }
                                }
                            }
                            else{
                                complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: response.description), 0, code)
                            }
                            
                            
                        }
                        else{
                             complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:"Drink with this name already exists"), 0, code)
                        }
                    }
                    break
                    
                case .failure(_):
                    //complete(true, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                     complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: response.description), 0, SERVER_CODE.CODE_403)
                    break
                }
        }
    }
    func loginFacebook(para: Parameters, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?,_ token: String?,_ id: Int?,_ birthday: String?) ->Void)
    {
    
        print(para)
        manager.request(URL.init(string: "\(URL_SERVER)api/user/signup/")!, method: .post, parameters: para,  encoding: URLEncoding.default, headers: nil)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        print(response)
                        print("CODE   \(code)")
                        if let val = response.value as? NSDictionary
                        {
                            if code == SERVER_CODE.CODE_201
                            {
                                if let id = val["id"] as? Int
                                {
                                    if let token = val["token"] as? String
                                    {
                                        complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"), token, id,  val["birthday"] as? String)

                                    }
                                }
                                else{
                                      complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "ID is invalid."), nil, nil,nil)
                                }
                            }
                            else if code == SERVER_CODE.CODE_400
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail), nil, nil, nil)
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Wrong birthday."), nil, nil, nil)
                                }
                            }
                            else{
                                complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"), nil, nil,nil)
                            }
                        }
                        
                    }
                    
                case .failure(_):
                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "User with this email address already exists."),nil, nil,nil)
                    break
                }
        }
    }
    
    // SEARHC CATEGORY
    func getSearchDrinkByCategory(txtSearch: String, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [GenreObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        var search = txtSearch.replacingOccurrences(of: "#", with: "").lowercased()
         search = search.replacingOccurrences(of: " ", with: "%20")
        //search = "mood"
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/category/?offset=\(offset)&limit=\(kLimitPage)&search=\(search)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [GenreObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(GenreObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas)
                            }
                            else{
                                 complete(true, arrDatas)
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(true, arrDatas)
                    break
                }
        }
    }
    
    
    // SEARCH ingredient
    
    func getListDrinkByingredient(ingredientID: Int, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print("\(URL_SERVER)api/drink/?ingredient=\(ingredientID)&offset=\(offset)&limit=\(kLimitPage)")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?ingredient=\(ingredientID)&offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            else{
                                complete(true, arrDatas)
                            }
                        }
                        else{
                            complete(true, arrDatas)
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    // GET LIST FAV
    func getListFavDrinks(offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?myfavorite=true&offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    func getSearchGenere(complete:@escaping (_ success: Bool?, _ arrs: [GenreObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/category/?ancestor=true")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [GenreObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(GenreObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas)
                            }
                            else{
                                complete(true, arrDatas)
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    // GET SUB CATEGORY BY PARENT ID
    func getSubCategoryByParentID(parentID: Int, complete:@escaping (_ success: Bool?, _ arrs: [GenreObj]?) ->Void)
    {
        
       
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/category/?parent=\(parentID)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                
                CommonHellper.hideBusy()
                var arrDatas = [GenreObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(GenreObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas)
                            }
                            else{
                                complete(true, arrDatas)
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    // GET LIST MY TAB
    func getListMyTab(complete:@escaping (_ success: Bool?, _ arrs: [MyTabObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/tab/")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [MyTabObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(MyTabObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    func deleteMyTab(tabID: Int,complete:@escaping (_ success: Bool?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print("\(URL_SERVER)api/user/me/tab/\(tabID)")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/tab/\(tabID)/")!, method: .delete, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if code == SERVER_CODE.CODE_200
                        {
                            complete(true)
                        }
                        else{
                            complete(false)
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false)
                    break
                }
        }
    }
    
    func updateMyTab(tabID: Int, quantity: Int,complete:@escaping (_ success: Bool?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
       
        let param = ["quantity":quantity]
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
         print(auth_headerLogin)
        print("\(URL_SERVER)api/user/me/tab/\(tabID)/")
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/tab/\(tabID)/")!, method: .patch, parameters: param,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if code == SERVER_CODE.CODE_200
                        {
                            complete(true)
                        }
                        else{
                            complete(false)
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false)
                    break
                }
        }
    }
    
    
    func addMyCardImage(token: String, image: UIImage,complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void)
    {
        print(image)
         print(token)
        let name = Date().millisecondsSince1970
        let imgData = UIImageJPEGRepresentation(image, 0.5)!
        guard let tokenLogin = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let param = ["stripe_token":token]
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(tokenLogin)"]
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imgData, withName: "photo",fileName: "\(name).jpg", mimeType: "image/jpg")
            for (key, value) in param {
                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
        }, usingThreshold: UInt64.init(), to: "\(URL_SERVER)api/user/order/", method: .post, headers: auth_headerLogin) { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    switch(response.result) {
                    case .success(_):
                        if let code = response.response?.statusCode
                        {
                            
                            if code == SERVER_CODE.CODE_200 || code == SERVER_CODE.CODE_201
                            {
                                complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                            }
                            else{
                                if let val = response.value as? NSDictionary
                                {
                                    if let detail = val.object(forKey: "detail") as? String
                                    {
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: detail))
                                    }
                                    else{
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                                    }
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                                }
                            }
                        }
                        break
                    case .failure(let error):
                        complete(false, ErrorManager.processError(error: error))
                    }
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
    func addMyTabCard(token: String,complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void)
    {
        guard let tokenLogin = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let param = ["stripe_token":token]
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(tokenLogin)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/order/")!, method: .post, parameters: param,  encoding: URLEncoding.methodDependent, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        
                        if code == SERVER_CODE.CODE_200 || code == SERVER_CODE.CODE_201
                        {
                            complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                        }
                        else{
                            if let val = response.value as? NSDictionary
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                     complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: detail))
                                }
                                else{
                                     complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                                }
                            }
                            else{
                                 complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                     complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                    break
                }
        }
    }    
    func fetchListSearchIngredient(id: Int, offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [IngredientSearchObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/ingredient/?ingredient_by=\(id)&offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [IngredientSearchObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(IngredientSearchObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    func fetchIngredientType(complete:@escaping (_ success: Bool?, _ arrs: [MainBarObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/ingredient/type/")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [MainBarObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(MainBarObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas)
                            }
                            else{
                                complete(true, arrDatas)
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
   
    
    func fetchIngredientbyTypeID(_ id: Int, complete:@escaping (_ success: Bool?, _ arrs: [MainBarObj]?,_ code: Int?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print("\(URL_SERVER)api/ingredient/brand/type/?type=\(id)&ingredients=true")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/ingredient/brand/type/?type=\(id)&ingredients=true")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [MainBarObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let arrs = response.value as? NSArray
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                                for item in arrs
                                {
                                    let dictItem = item as! NSDictionary
                                    arrDatas.append(MainBarObj.init(dict: dictItem))
                                }
                                complete(true, arrDatas, code)
                            }
                            else{
                                complete(true, arrDatas, code)
                            }
                        }
                        else{
                             complete(true, arrDatas, code)
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas, SERVER_CODE.CODE_400)
                    break
                }
        }
    }
    
    func createDrinkByUser(_ id: String, complete:@escaping (_ success: Bool?, _ arrs: [DrinkObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print("id ------------\(id)")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/?ingredient_by=\(id)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [DrinkObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let dict = response.value as? NSDictionary
                        {
                            if let arrs = dict["results"] as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(DrinkObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            else{
                                complete(true, arrDatas)
                            }
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    func SearchIngredient(value: String, complete:@escaping (_ success: Bool?, _ arrs: [IngredientSearchObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let search = value.replacingOccurrences(of: " ", with: "%20")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/ingredient/?search=\(search)&limit=20")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [IngredientSearchObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(IngredientSearchObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    // GET LIST USER ODER
    func fetchListUserOrder(offset: Int,complete:@escaping (_ success: Bool?, _ arrs: [OrderUserObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        print("\(URL_SERVER)api/user/order/?offset=\(offset)&limit=\(kLimitPage)")
        manager.request(URL.init(string: "\(URL_SERVER)api/user/order/?offset=\(offset)&limit=\(kLimitPage)")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [OrderUserObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(OrderUserObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    // REODER Anh gọi api POST
    
    func reorder(order_id: Int,complete:@escaping (_ success: Bool?, _ error: String?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let param = ["order_id":order_id]
        print(param)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/order/")!, method: .post, parameters: param,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                if let code = response.response?.statusCode
                {
                    if code == SERVER_CODE.CODE_200
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let block_count = val.object(forKey: "block_count") as? Int
                            {
                                if block_count > 0
                                {
                                    if let  block_drinks = val.object(forKey: "block_drinks") as? NSArray
                                    {
                                        if block_drinks.count > 0
                                        {
                                            var strValue = ""
                                            for item in block_drinks
                                            {
                                                strValue = "\(strValue)\(item as! String), "
                                            }
                                            let err = "\(block_count) item not available at this time: \(strValue.substring(from: 0, to: strValue.count - 2))"
                                            complete(false, err)
                                        }
                                    }
                                    else{
                                        complete(false,"Reorder error")
                                    }
                                }
                                else{
                                    complete(true, nil)
                                }
                            }
                            else{
                                complete(true, nil)
                            }
                        }
                        else{
                            complete(true, nil)
                        }
                        
                    }
                    else{
                        complete(false,"Reorder error")
                    }
                }
        }
    }
    
    func reorderTab(order_id: Int,complete:@escaping (_ success: Bool?, _ error: String?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let param = ["tab_id":order_id]
        print(param)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        print("Token \(token)")
        print("\(URL_SERVER)api/user/order/")
        manager.request(URL.init(string: "\(URL_SERVER)api/user/order/")!, method: .post, parameters: param,  encoding: URLEncoding.default, headers: auth_headerLogin)
            
            .responseJSON { response in
                print(response)
                if let code = response.response?.statusCode
                {
                    if code == SERVER_CODE.CODE_200
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let block_count = val.object(forKey: "block_count") as? Int
                            {
                                if block_count > 0
                                {
                                    if let  block_drinks = val.object(forKey: "block_drinks") as? NSArray
                                    {
                                        if block_drinks.count > 0
                                        {
                                            var strValue = ""
                                            for item in block_drinks
                                            {
                                                strValue = "\(strValue)\(item as! String), "
                                            }
                                            let err = "\(block_count) item not available at this time: \(strValue.substring(from: 0, to: strValue.count - 2))"
                                              complete(false, err)
                                        }
                                    }
                                    else{
                                         complete(false,"Reorder error")
                                    }
                                }
                                else{
                                     complete(true, nil)
                                }
                            }
                            else{
                                 complete(true, nil)
                            }
                        }
                        else{
                             complete(true, nil)
                        }
                       
                    }
                    else{
                        complete(false,"Reorder error")
                    }
                }
        }
    }
    
    func fetchListCurrentOrder(complete:@escaping (_ success: Bool?, _ arrs: [OrderUserObj]?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/order/?current=true")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                var arrDatas = [OrderUserObj]()
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if let arrs = val.object(forKey: "results") as? NSArray
                            {
                                if code == SERVER_CODE.CODE_200
                                {
                                    for item in arrs
                                    {
                                        let dictItem = item as! NSDictionary
                                        arrDatas.append(OrderUserObj.init(dict: dictItem))
                                    }
                                    complete(true, arrDatas)
                                }
                                else{
                                    complete(true, arrDatas)
                                }
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, arrDatas)
                    break
                }
        }
    }
    
    func activeCodeForgot(param: Parameters,complete:@escaping (_ success: Bool?, _ error: String) ->Void)
    {
       
        print("\(URL_SERVER)api/user/forget/password/")
        manager.request(URL.init(string: "\(URL_SERVER)api/user/forget/password/")!, method: .post, parameters: param,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if code == SERVER_CODE.CODE_200
                        {
                            complete(true, "")
                        }
                        else{
                            complete(false, "\(response.result.value as! NSDictionary)")
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false, "\(response.result.value as! NSDictionary)")
                    break
                }
        }
    }
    func getSettingApp(_ complete:@escaping (_ success: Bool?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/settings/")!, method: .get, parameters: nil,  encoding: URLEncoding(destination: .methodDependent), headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let arrs = response.value as? NSArray
                    {
                        if arrs.count > 0
                        {
                            if let val = arrs[0] as? NSDictionary
                            {
                                APP_DELEGATE.settingObj = SettingObj.init(dict: val)
                                if let bar_status  = val["bar_status"] as? Bool
                                {
                                    if bar_status
                                    {
                                        complete(true)
                                    }
                                    else{
                                        complete(false)
                                    }
                                }
                                else{
                                    complete(false)
                                }
                            }
                            else{
                                complete(false)
                            }
                        }
                        else{
                           complete(false)
                        }
                    }
                    else{
                        complete(false)
                    }
                    
                    break
                case .failure(_):
                    complete(false)
                    break
                }
        }
    }
    
    
    // GET DRINK BY ID
    func getDrinkBYID(drinkID: Int,complete:@escaping (_ success: Bool?, _ drinkObj: DrinkObj?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print("\(URL_SERVER)api/drink/\(drinkID)/")
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/drink/\(drinkID)/")!, method: .get, parameters: nil,  encoding: URLEncoding.default, headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            print(code)
                            if code == SERVER_CODE.CODE_200
                            {
                                 complete(true, DrinkObj.init(dict: val))
                            }
                            else if code == SERVER_CODE.CODE_403
                            {
                                 complete(false, DrinkObj.init(dict: NSDictionary.init()))
                            }
                            else{
                                complete(true, DrinkObj.init(dict: NSDictionary.init()))
                            }
                        }
                        else{
                            complete(true, DrinkObj.init(dict: NSDictionary.init()))
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(true, DrinkObj.init(dict: NSDictionary.init()))
                    break
                }
        }
    }
    
    func changeAvatar(user_id: Int, image: UIImage,complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void)
    {
        let name = Date().millisecondsSince1970
        let imgData = UIImageJPEGRepresentation(image, 1.0)!
        guard let tokenLogin = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let param = Parameters()
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(tokenLogin)"]
        print(auth_headerLogin)
        print("\(URL_SERVER)api/user/\(user_id)")
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imgData, withName: "avatar",fileName: "\(name).jpg", mimeType: "image/jpg")
            for (key, value) in param {
                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            }
        }, usingThreshold: UInt64.init(), to: "\(URL_SERVER)api/user/\(user_id)/", method: .patch, headers: auth_headerLogin) { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    switch(response.result) {
                    case .success(_):
                        if let code = response.response?.statusCode
                        {
                            
                            if code == SERVER_CODE.CODE_200 || code == SERVER_CODE.CODE_201
                            {
                                complete(true,ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Success"))
                            }
                            else{
                                if let val = response.value as? NSDictionary
                                {
                                    if let detail = val.object(forKey: "detail") as? String
                                    {
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: detail))
                                    }
                                    else{
                                        complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                                    }
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(response.result.value as? NSDictionary)"))
                                }
                            }
                        }
                        break
                    case .failure(let error):
                        complete(false, ErrorManager.processError(error: error))
                    }
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
    
    
    
    func editProfile(_ para: Parameters, _ userID: Int, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void)
    {
        guard let tokenLogin = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(tokenLogin)"]
        print(auth_headerLogin)
        manager.request(URL.init(string: "\(URL_SERVER)api/user/\(userID)/")!, method: .patch, parameters: para,  encoding: URLEncoding(destination: .methodDependent), headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if code == SERVER_CODE.CODE_200
                            {
                               complete(true, nil)
                            }
                            else if code == SERVER_CODE.CODE_400
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail))
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "Wrong birthday."))
                                }
                            }
                            else{
                                complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"))
                            }
                        }
                        
                    }
                    break
                case .failure(let error):
                    complete(false, ErrorManager.processError(error: error))
                }
        }
    }
    
    
    func changePassword(_ para: Parameters, complete:@escaping (_ success: Bool?, _ errer: ErrorModel?) ->Void)
    {
        guard let tokenLogin = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(tokenLogin)"]
        print(auth_headerLogin)
        manager.request(URL.init(string: "\(URL_SERVER)api/user/change/password/")!, method: .post, parameters: para,  encoding: URLEncoding(destination: .methodDependent), headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            if code == 200
                            {
                                complete(true, nil)
                            }
                            else if code == SERVER_CODE.CODE_400
                            {
                                if let detail = val.object(forKey: "detail") as? String
                                {
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg:detail))
                                }
                                else{
                                    complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"))
                                }
                            }
                            else{
                                complete(false, ErrorManager.processError(error: nil, errorCode: nil, errorMsg: "\(val)"))
                            }
                        }
                        
                    }
                    break
                case .failure(let error):
                    complete(false, ErrorManager.processError(error: error))
                }
        }
    }
    
    func updateBirthday(_ token: String, _ userID: String,_ birthday: String, complete:@escaping (_ success: Bool?) ->Void)
    {
        let auth_header: HTTPHeaders = ["Authorization": "Token \(token)"]
        let para = ["birthday": birthday]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/\(userID)/")!, method: .patch, parameters: para,  encoding: URLEncoding.default, headers: auth_header)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let code = response.response?.statusCode
                    {
                        if let val = response.value as? NSDictionary
                        {
                            print(val)
                            if code == SERVER_CODE.CODE_200
                            {
                                complete(true)
                                
                            }
                            else{
                                complete(false)
                            }
                            
                        }
                    }
                    break
                    
                case .failure(_):
                    complete(false)
                    break
                }
        }
    }
    
    func getBadgeCustom(_ complete:@escaping (_ success: Int?) ->Void)
    {
        guard let token = UserDefaults.standard.value(forKey: kToken) as? String else {
            return
        }
        print(token)
        let auth_headerLogin: HTTPHeaders = ["Authorization": "Token \(token)"]
        manager.request(URL.init(string: "\(URL_SERVER)api/user/me/tab/?sum_quantity=true")!, method: .get, parameters: nil,  encoding: URLEncoding(destination: .methodDependent), headers: auth_headerLogin)
            .responseJSON { response in
                print(response)
                switch(response.result) {
                case .success(_):
                    if let result = response.value as? NSDictionary
                    {
                        if let badge = result.object(forKey: "badge") as? Int
                        {
                             complete(badge)
                        }
                        else{
                            complete(0)
                        }
                    }
                    else{
                        complete(0)
                    }
                   break
                    
                case .failure(_):
                    complete(0)
                    break
                }
        }
    }
    
}
