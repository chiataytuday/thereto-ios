import Foundation

struct User: Codable {
    var nickname: String
    var social: SocialType
    var profileURL: String?
    var receivedCount = 0
    var sentCount = 0
    var id: String
    var newFriendRequest: Bool = false
    var createdAt: String
    
    init(nickname: String,social: String, id: String, profileURL: String?) {
        self.nickname = nickname
        self.social = SocialType(rawValue: social)!
        self.profileURL = profileURL
        self.id = id
        self.createdAt = DateUtil.date2String(date: Date.init())
    }
    
    init(friend: Friend) {
        self.nickname = friend.nickname
        self.social = friend.social
        self.profileURL = friend.profileURL
        self.receivedCount = friend.receivedCount
        self.sentCount = friend.sentCount
        self.id = friend.id
        self.createdAt = friend.createdAt!
    }
    
    init(map: [String: Any]) {
        self.nickname = map["nickname"] as! String
        self.social = SocialType(rawValue: map["social"] as! String)!
        self.profileURL = map["profileURL"] as? String
        self.receivedCount = map["receivedCount"] as! Int
        self.sentCount = map["sentCount"] as! Int
        self.id = map["id"] as! String
        self.newFriendRequest = map["newFriendRequest"] as! Bool
        self.createdAt = map["createdAt"] as! String
    }
    
    func toDict() -> [String: Any] {
        return ["id": id,
                "nickname": nickname,
                "social": social.rawValue,
                "profileURL": profileURL!,
                "receivedCount": receivedCount,
                "sentCount": sentCount,
                "newFriendRequest": newFriendRequest,
                "createdAt": createdAt]
    }
    
    func getSocial() -> String {
        return social.rawValue
    }
}
