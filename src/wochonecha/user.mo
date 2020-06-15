import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Types "./types";

module {
  type UserId = Types.UserId;
  type ChallengeId = Types.ChallengeId;
  type UserData = Types.UserData;
  type Challenge = Types.Challenge;

  public class UserDb() {
    func isEq(x: UserId, y: UserId): Bool { x == y };

    let hashMap = HashMap.HashMap<UserId, UserData>(1, isEq, Principal.hash);

    public func createUser(userId: UserId, username: Text) {
      ignore hashMap.set(userId, makeUserData(userId, username));
    };

    public func findByName(username: Text): [UserData] {
      var users: [UserData] = [];
      for ((id, userData) in hashMap.iter()) {
        if (userData.name == username) {
          users := Array.append<UserData>(users, [userData]);
        };
      };
      users
    };

    // Helpers.
    func makeUserData(userId: UserId, username: Text): UserData {
      {
        id = userId;
        name = username;
        acceptedChallenges = [];
        completedChallenges = [];
        friends = [];
      }
    };

  }
}

