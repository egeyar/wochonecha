import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import User "./user";
import Types "./types";
import Array "mo:base/Array";

import Challenge "./challenge";
import AcceptedChallenge "./acceptedchallenge";
import ChallengeDB "./challengedb";
import DefaultChallenges "./defaultchallenges";

actor Wochonecha {
  type ChallengeId = Types.ChallengeId;
  type ChallengeMetadata = Types.ChallengeMetadata;
  type ChallengeStatus = Types.ChallengeStatus;
  type UserData = Types.UserData;
  type UserId = Types.UserId;

  var userDb : User.UserDb = User.UserDb();
  var challengeDB: ChallengeDB.ChallengeDB = ChallengeDB.ChallengeDB();

  object challengeCounter = {
    var count = 0;
    public func get_new_id() : Nat { let id = count; count += 1; id };
    public func get_count() : Nat { count };
  };

  for (tuple in DefaultChallenges.challenges.vals())
    {
      challengeDB.add(
        Challenge.Challenge(challengeCounter.get_new_id(), tuple.0, tuple.1, null));
    };

  func eqStatus(s1: ChallengeStatus, s2 : ChallengeStatus) : Bool {
    switch (s1, s2) {
      case (#accepted, #accepted) true;
      case (#completed, #completed) true;
      case (#expired, #expired) true;
      case (#inprogress, #inprogress) true;
      case _ false;
    }
  };

  func statusText(s: ChallengeStatus) : Text {
    switch (s) {
      case (#accepted) "accepted";
      case (#completed) "completed";
      case (#expired) "expired";
      case (#inprogress) "inprogress";
    }
  };

  func isAcceptedOrInProgress(cId: ChallengeId, cMetadata: [ChallengeMetadata]): Bool {
    func isOn(cm: ChallengeMetadata): Bool {
      cm.id == cId and ( eqStatus(cm.status, #accepted) or eqStatus(cm.status, #inprogress))
    };
    switch (Array.find<ChallengeMetadata>(isOn, cMetadata)) {
      case (null) { false };
      case (_) { true };
    };
  };

  public shared(msg) func createUser(username: Text) : async Text {
    let userData : UserData = userDb.createOrReturn(msg.caller, username);
    "user: id = " # Nat.toText(Nat.fromWord32(Principal.hash(msg.caller))) # ", username = " # userData.name
  };

  public shared(msg) func acceptChallenge(challengeId : ChallengeId) : async Text {
    // Verify the user
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "user not registered" 
    };
    let userData = Option.unwrap(maybeUserData);

    // Verify the challenge
    let maybechallenge : ?Challenge.Challenge = challengeDB.get(challengeId);
    if (Option.isNull(maybechallenge)) {
      return "A challenge with challenge id " # Nat.toText(challengeId) # " does not exist";
    };
    let challenge = Option.unwrap(maybechallenge);

    // Verify that the user has not already accepted the challenge
    if (isAcceptedOrInProgress(challengeId, userData.challenges)) {
      return "The challenge " # Nat.toText(challengeId) # " is already accepted by user " # userData.name
    };

    let newChallenge : ChallengeMetadata = {
      id = challengeId;
      status = #accepted;
      completionDeadline = 0;  // TODO
      progress = 0;
    };
    let updatedUserData : UserData = {
      id = userData.id;
      name = userData.name;
      challenges = Array.append<ChallengeMetadata>(userData.challenges, [newChallenge]);
      friends = userData.friends;
    };
    userDb.update(updatedUserData);
    challengeDB.accepted(challengeId : ChallengeId);
    "accepted challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(updatedUserData)
  };

  public shared(msg) func completeChallenge(challengeId : ChallengeId) : async Text {
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "user not registered" 
    };

    let userData = Option.unwrap(maybeUserData);
    if (not isAcceptedOrInProgress(challengeId, userData.challenges)) {
      return "challenge " # Nat.toText(challengeId) # " is not accepted, so it cannot be completed"
    };
    var cs : [ChallengeMetadata] = [];
    for (cm in userData.challenges.vals()) {
      if (cm.id == challengeId and ( eqStatus(cm.status, #accepted) or eqStatus(cm.status, #inprogress))) {
        let completed : ChallengeMetadata = {
          id = cm.id;
          status = #completed;
          completionDeadline = 0;  // TODO
          progress = 100;
        };
        cs := Array.append<ChallengeMetadata>(cs, [completed]);
      } else {
        cs := Array.append<ChallengeMetadata>(cs, [cm]);
      }
    };
    let updatedUserData : UserData = {
        id = userData.id;
        name = userData.name;
        challenges = cs;
        friends = userData.friends;
      };
    userDb.update(updatedUserData);
    challengeDB.completed(challengeId : ChallengeId);
    "completed challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(updatedUserData)
  };

  public query func getUser(username : Text) : async Text {
    let users = userDb.findByName(username);
    let userDataText = userDataAsText(users[0]);
     "querying for user " # username # ":\n" # userDataText
  };

  public shared(msg) func setProgress(challengeId: ChallengeId, newProgress: Nat) : async Text {
    if (newProgress >= 100) {
      return "progress must be less than 100%";
    };
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "user not registered" 
    };

    let userData = Option.unwrap(maybeUserData);
    if (not isAcceptedOrInProgress(challengeId, userData.challenges)) {
      return "challenge " # Nat.toText(challengeId) # " is not accepted, so cannot change progress"
    };
    var cs : [ChallengeMetadata] = [];
    for (cm in userData.challenges.vals()) {
      if (cm.id == challengeId
          and ( eqStatus(cm.status, #accepted) or eqStatus(cm.status, #inprogress))) {
        let completed : ChallengeMetadata = {
          id = cm.id;
          status = #inprogress;
          completionDeadline = 0;  // TODO
          progress = newProgress;
        };
        cs := Array.append<ChallengeMetadata>(cs, [completed]);
      } else {
        cs := Array.append<ChallengeMetadata>(cs, [cm]);
      }
    };
    let updatedUserData : UserData = {
        id = userData.id;
        name = userData.name;
        challenges = cs;
        friends = userData.friends;
      };
    userDb.update(updatedUserData);
    "updated progress for challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(updatedUserData)
  };

  public shared(msg) func createChallenge(title: Text, description: Text) : async Text {
    let maybeUserData : ?UserData = userDb.findById(msg.caller);
    if (Option.isNull(maybeUserData)) {
      return "you need to be a registered user to create challenges"
    };
    let username = Option.unwrap(maybeUserData).name;
    let challenge = Challenge.Challenge(challengeCounter.get_new_id(), title, description, ?msg.caller);
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
    for (cm in userData.challenges.vals()) {
      userText := userText # " " # Nat.toText(cm.id) # ":" # statusText(cm.status) # ":" # Nat.toText(cm.progress) # "%"
    };
    return userText # " ]";
  };

  func challengeAsText(challenge: Challenge.Challenge) : Text {
    let id = Nat.toText(challenge.get_id());
    let creator = getUsernameFromOption(challenge.get_creator());
    let acception_count = Nat.toText(challenge.get_acception_count());
    let completion_count = Nat.toText(challenge.get_completion_count());
    "Challenge " # id # ":\nTitle: " # challenge.get_title() # "\nDescripton: " # challenge.get_description()
      # "\nCreated by " # creator # "\nAccepted " # acception_count # " times\nCompleted " # completion_count # " times"
  };

  func challengeIdArrayAsText(challenge_ids: [Challenge.ChallengeId]) : Text {
    var text : Text = "";
    for (challenge_id in challenge_ids.vals()) {
      let challenge = Option.unwrap(challengeDB.get(challenge_id));
      text := text # challengeAsText(challenge) # "\n";
    };
    text
  };

  func getUsernameFromOption(maybe_user_id : ? UserId) : Text {
    switch (maybe_user_id) {
      case null return "Wochonecha";
      case (?user_id) return (Option.unwrap(userDb.findById(user_id)).name);
    };
  }
    

};
