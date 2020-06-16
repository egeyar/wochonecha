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

  object challengeCounter = {
    var count = 0;
    public func get_new_id() : Nat { let id = count; count += 1; id };
    public func get_count() : Nat { count };
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
    "accepted challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(updatedUserData)
  };

  public shared(msg) func completeChallenge(challengeId : ChallengeId) : async Text {
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "user not registered" 
    };

    let userData = Option.unwrap(maybeUserData);
    var remainingChallenges : [ChallengeId] = [];
    var foundAccepted = false;
    for (cId in userData.acceptedChallenges.vals()) {
      if (challengeId == cId) {
        foundAccepted := true;
      } else {
        remainingChallenges := Array.append<ChallengeId>(remainingChallenges, [cId]);
      }
    };
    if (not foundAccepted) {
      return "challenge " # Nat.toText(challengeId) # " was not accepted yet, so it cannot be completed"
    };
    let updatedUserData : UserData = {
        id = userData.id;
        name = userData.name;
        acceptedChallenges = remainingChallenges;
        completedChallenges = Array.append<ChallengeId>(userData.completedChallenges, [challengeId]);
        friends = userData.friends;
      };
      userDb.update(updatedUserData);
    "completed challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(updatedUserData)
  };

  public query func getUser(username : Text) : async Text {
    let users = userDb.findByName(username);
    let userDataText = userDataAsText(users[0]);
     "querying for user " # username # ":\n" # userDataText
  };

  public shared(msg) func createChallenge(title: Text, description: Text) : async Text {
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "you need to be a registered user to create challenges"
    };
    let username = Option.unwrap(maybeUserData).name;
    let challenge = Challenge.Challenge(challengeCounter.get_new_id(), title, description, msg.caller);
    challengeDB.add(challenge);
    "A new challenge with id " # Nat.toText(challenge.get_id()) # " is created by user " # username
  };

  public query func displayChallenge(challenge_id: ChallengeId) : async Text {
    let maybechallenge : ?Challenge.Challenge = challengeDB.get(challenge_id);
    if (Option.isNull(maybechallenge)) {
      return "A challenge with challenge id " # Nat.toText(challenge_id) # " does not exist";
    };
    let challenge = Option.unwrap(maybechallenge);
    challengeAsText(challenge)
  };

  func userDataAsText(userData : UserData) : Text {
    let userId : Text = Nat.toText(Nat.fromWord32(Principal.hash(userData.id)));
    var userText : Text = "id: " # userId # ", name: " # userData.name # ", accepted: [";
    for (challengeId in userData.acceptedChallenges.vals()) {
      userText := userText # " " # Nat.toText(challengeId);
    };
    userText := userText # " ], completed: [";
    for (challengeId in userData.completedChallenges.vals()) {
      userText := userText # " " # Nat.toText(challengeId);
    };
    return userText # " ]";
  };

  func challengeAsText(challenge: Challenge.Challenge) : Text {
    let id = Nat.toText(challenge.get_id());
    let username = Option.unwrap(userDb.findById(challenge.get_creator())).name;
    let acception_count = Nat.toText(challenge.get_acception_count());
    let completion_count = Nat.toText(challenge.get_completion_count());
    "Challenge " # id # ":\nTitle: " # challenge.get_title() # "\nDescripton: " # challenge.get_description()
      # "\nCreated by " # username # "\nAccepted " # acception_count # " times\nCompleted " # completion_count # " times"
  };

  func challengeIdArrayAsText(challenge_ids: [Challenge.ChallengeId]) : Text {
    var text : Text = "";
    for (challenge_id in challenge_ids.vals()) {
      let challenge = Option.unwrap(challengeDB.get(challenge_id));
      text := text # challengeAsText(challenge) # "\n";
    };
    text
  };

};
