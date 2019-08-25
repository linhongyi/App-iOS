//
//  SponsorAPI.swift
//  Mopcon
//
//  Created by WU CHIH WEI on 2019/8/23.
//  Copyright © 2019 EthanLin. All rights reserved.
//

import Foundation

enum SponsorAPI: LKRequest {
    
    case sponsor(String?)
    
    var endPoint: String {
        
        switch self {
            
        case .sponsor: return "/api/2019/sponsor"
        
        }
    }
    
    var queryString: [String : String] {
        
        switch self {
            
        case .sponsor(let id):
            
            guard let id = id else { return [:] }
            
            return ["sponsor_id": id]
        }
    }
}
