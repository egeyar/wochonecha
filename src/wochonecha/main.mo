import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import User "./user";
import Types "./types";
import Array "mo:base/Array";

import Challenge "./challenge";
import AcceptedChallenge "./acceptedchallenge";
import ChallengeDB "./challengedb";

actor Wochonecha {
  type ChallengeId = Types.ChallengeId;
  type UserData = Types.UserData;

  var userDb : User.UserDb = User.UserDb();
  var challengeDB: ChallengeDB.ChallengeDB = ChallengeDB.ChallengeDB();


  func userDataAsText(userData : UserData) : Text {
    let userId : Text = Nat.toText(Nat.fromWord32(Principal.hash(userData.id)));
    var userText : Text = "id: " # userId # ", name: " # userData.name # ", accepted: [";
    for (challenge in userData.acceptedChallenges.vals()) {
      userText := "" # userText # Nat.toText(challenge) # " ";
    };
    return userText # "]";
  };


  public shared(msg) func createUser(username: Text) : async Text {
    let userData : UserData = userDb.createOrReturn(msg.caller, username);
    "user: id = " # Nat.toText(Nat.fromWord32(Principal.hash(msg.caller))) # ", username = " # userData.name
  };

  public shared(msg) func acceptChallenge(challengeId : ChallengeId) : async Text {
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "user not registered" 
    };
    let userData = Option.unwrap(maybeUserData);
    let updatedUserData : UserData = {
        id = userData.id;
        name = userData.name;
        acceptedChallenges = Array.append<ChallengeId>(userData.acceptedChallenges, [challengeId]);
        completedChallenges = userData.completedChallenges;
        friends = userData.friends;
      };
      userDb.update(updatedUserData);
    "accepted challenge: " # userDataAsText(updatedUserData)
  };

  public query func getUser(username : Text) : async Text {
    let users = userDb.findByName(username);
    let userId  : Text = Nat.toText(Nat.fromWord32(Principal.hash(users[0].id)));
     "querying for user " # username # ": " # userId
  };
};
