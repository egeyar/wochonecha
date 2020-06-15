import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import User "./user";
import Challenge "./challenge";
import AcceptedChallenge "./acceptedchallenge";
import ChallengeDB "./challengedb";

actor Wochonecha {
  var userDb : User.UserDb = User.UserDb();
  var challengeDB: ChallengeDB.ChallengeDB = ChallengeDB.ChallengeDB();

  public shared(msg) func createUser(username: Text) : async Text {
    userDb.createUser(msg.caller, username);
    "created user " # username # " with id " # Nat.toText(Nat.fromWord32(Principal.hash(msg.caller)))
  };

  public query func getUser(username : Text) : async Text {
     "querying for user " # username 
  };
};
