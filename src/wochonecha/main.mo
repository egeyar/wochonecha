import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

import User "./user";

actor UserApi {
  var userDb : User.UserDb = User.UserDb();

  public shared(msg) func createUser(username: Text) : async Text {
    userDb.createUser(msg.caller, username);
    "created user " # username # " with id " # Nat.toText(Nat.fromWord32(Principal.hash(msg.caller)))
  };

  public query func getUser(username : Text) : async Text {
     "querying for user " # username 
  };
};

