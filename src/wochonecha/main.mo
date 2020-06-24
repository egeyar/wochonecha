import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import User "./user";
import Types "./types";
import Array "mo:base/Array";

import Challenge "./challenge";
import ChallengeDB "./challengedb";
import DefaultChallenges "./defaultchallenges";

actor Wochonecha {
  type ChallengeId = Types.ChallengeId;
  type ChallengeMetadata = Types.ChallengeMetadata;
  type ChallengeStatus = Types.ChallengeStatus;
  type UserData = Types.UserData;
  type UserId = Types.UserId;

  flexible var userDb : User.UserDb = User.UserDb();
  flexible var challengeDB: ChallengeDB.ChallengeDB = ChallengeDB.ChallengeDB();

  // The following generates IDs for challenges.
  flexible object challengeCounter = {
    var count = 0;
    public func get_new_id() : Nat { let id = count; count += 1; id };
    public func get_count() : Nat { count };
  };

  // Populate the challenge database with some initial challenges.
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
      case (#suggestion, #suggestion) true;
      case _ false;
    }
  };

  func statusText(s: ChallengeStatus) : Text {
    switch (s) {
      case (#accepted) "accepted";
      case (#completed) "completed";
      case (#expired) "expired";
      case (#inprogress) "inprogress";
      case (#suggestion) "suggestion";
    }
  };

  // Add this challenge metadata to the given user's challenges.
  func addNewChallenge(userdata : UserData, new_cm: ChallengeMetadata) : UserData {
    let updated_userdata : UserData = {
      id = userdata.id;
      name = userdata.name;
      challenges = Array.append<ChallengeMetadata>(userdata.challenges, [new_cm]);
      friends = userdata.friends;
    };

    updated_userdata
  };

  // If the user has a challenge metadata with the given id and status, replace it with the given metadata.
  func replaceExistingChallenge(userdata : UserData, new_cm: ChallengeMetadata, oldStatus: ChallengeStatus) : UserData {
    var cs : [ChallengeMetadata] = [];
    for (cm in userdata.challenges.vals()) {
      if (cm.id == new_cm.id and eqStatus(cm.status, oldStatus)) {
        cs := Array.append<ChallengeMetadata>(cs, [new_cm]);
      } else {
        cs := Array.append<ChallengeMetadata>(cs, [cm]);
      }
    };

    let updated_userdata : UserData = {
      id = userdata.id;
      name = userdata.name;
      challenges = cs;
      friends = userdata.friends;
    };

    updated_userdata;
  };

  func getStatusIfExists (challenge_id: ChallengeId, cm_array: [ChallengeMetadata]) : ?ChallengeStatus {
    func isit(cm: ChallengeMetadata): Bool {
      cm.id == challenge_id
    };
    switch (Array.find<ChallengeMetadata>(isit, cm_array)) {
      case (null) { null };
      case (?cm) { ?cm.status };
    };
  };

  public shared(msg) func createUser(username: Text) : async Text {
    var userData : UserData = userDb.createOrReturn(msg.caller, username);
    "user: id = " # Nat.toText(Nat.fromWord32(Principal.hash(msg.caller))) # ", username = " # userData.name
  };

  public shared(msg) func acceptChallenge(challengeId : ChallengeId) : async Text {
    // Verify the user
    var userData = switch (userDb.findById(msg.caller)) {
      case (null) { return "user not registered" };
      case (?user) user
    };

    // Verify the challenge
    let challenge = switch (challengeDB.get(challengeId)) {
      case (null) { return "A challenge with challenge id " # Nat.toText(challengeId) # " does not exist" };
      case (?ch) ch
    };

    let newMetadata : ChallengeMetadata = {
      id = challengeId;
      status = #accepted;
      completionDeadline = 0;  // TODO
      progress = 0;
    };

    let maybestatus = getStatusIfExists(challengeId, userData.challenges);
    switch maybestatus {
      case (?#accepted) {
        return "The challenge " # Nat.toText(challengeId) # " is already accepted by user " # userData.name
      };

      case (?#inprogress) {
        return "The user " # userData.name # " is already making progress on the challenge " # Nat.toText(challengeId)
      };

      case null {
        userData := addNewChallenge(userData, newMetadata);
        userDb.update(userData);
      };

      case (?#completed) {
        userData := addNewChallenge(userData, newMetadata);
        userDb.update(userData);
      };

      case (?#expired) {
        //TODO: to be decided.
        userData := addNewChallenge(userData, newMetadata);
        userDb.update(userData);
      };

      case (?#suggestion) {
        userData := replaceExistingChallenge(userData, newMetadata, #suggestion);
        userDb.update(userData);
      };
    };

    challengeDB.accepted(challengeId : ChallengeId);
    "accepted challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(userData)
  };

  public shared(msg) func suggestChallenge(username: Text, challengeId: ChallengeId) : async Text {
    // Verify the user
    switch (userDb.findById(msg.caller)) {
      case (null) { return "Please register to be able to suggest challenges to others" };
      case (?user) {}
    };

    // Verify the challenge
    let challenge = switch (challengeDB.get(challengeId)) {
      case (null) { return "A challenge with challenge id " # Nat.toText(challengeId) # " does not exist" };
      case (?ch) ch
    };

    //Verify the recipient
    let users = userDb.findByName(username);
    if (users.len() == 0) {
      return "A user with username " # username # " does not exist";
    };
    let userData = users[0];

    let newMetadata : ChallengeMetadata = {
      id = challengeId;
      status = #suggestion;
      completionDeadline = 0;  // TODO
      progress = 0;
    };

    let maybestatus = getStatusIfExists(challengeId, userData.challenges);
    switch maybestatus {
      case (?#suggestion) {
        return "The challenge " # Nat.toText(challengeId) # " is already suggested to user " # username
      };

      case (?#accepted) {
        return "The challenge " # Nat.toText(challengeId) # " is already accepted by user " # username
      };

      case (?#inprogress) {
        return "The user " # username # " is already making progress on the challenge " # Nat.toText(challengeId)
      };

      case (?#completed) {
        userDb.update(addNewChallenge(userData, newMetadata));
      };

      case (?#expired) {
        //TODO: To be decided...
        userDb.update(addNewChallenge(userData, newMetadata));
      };

      case (null) {
        userDb.update(addNewChallenge(userData, newMetadata));
      };
    };
    "suggested challenge " # Nat.toText(challengeId) # " to user " # username
  };

  public shared(msg) func completeChallenge(challengeId : ChallengeId) : async Text {
    // Verify the user
    var userData = switch (userDb.findById(msg.caller)) {
      case (null) { return "user not registered" };
      case (?user) user
    };

    let newMetadata : ChallengeMetadata = {
      id = challengeId;
      status = #completed;
      completionDeadline = 0;  // TODO
      progress = 100;
    };

    let maybestatus = getStatusIfExists(challengeId, userData.challenges);
    switch maybestatus {
      case (?#suggestion) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so it cannot be completed"
      };

      case (?#expired) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so it cannot be completed"
      };

      case(?#completed) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so it cannot be completed"
      };

      case(null) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so it cannot be completed"
      };

      case (?#accepted) {
        userData := replaceExistingChallenge(userData, newMetadata, #accepted);
        userDb.update(userData);
      };

      case (?#inprogress) {
        userData := replaceExistingChallenge(userData, newMetadata, #inprogress);
        userDb.update(userData);
      };
    };

    challengeDB.completed(challengeId : ChallengeId);
    "completed challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(userData)
  };

  public query func getUser(username : Text) : async Text {
    let users = userDb.findByName(username);
    if (users.len() == 0) {
      return "A user with username " # username # " does not exist";
    };
    let userDataText = userDataAsText(users[0]);
     "querying for user " # username # ":\n" # userDataText
  };

  public shared(msg) func setProgress(challengeId: ChallengeId, newProgress: Nat) : async Text {
    if (newProgress >= 100) {
      return "progress must be less than 100%";
    };

    // Verify the user
    var userData = switch (userDb.findById(msg.caller)) {
      case (null) { return "user not registered" };
      case (?user) user
    };

    let newMetadata : ChallengeMetadata = {
      id = challengeId;
      status = #inprogress;
      completionDeadline = 0;  // TODO
      progress = newProgress;
    };

    let maybestatus = getStatusIfExists(challengeId, userData.challenges);
    switch maybestatus {
      case (?#suggestion) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so cannot change progress"
      };

      case (?#expired) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so cannot change progress"
      };

      case(?#completed) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so cannot change progress"
      };

      case(null) {
        return "The challenge " # Nat.toText(challengeId) # " is not accepted, so cannot change progress"
      };

      case (?#accepted) {
        userData := replaceExistingChallenge(userData, newMetadata, #accepted);
        userDb.update(userData);
      };

      case (?#inprogress) {
        userData := replaceExistingChallenge(userData, newMetadata, #inprogress);
        userDb.update(userData);
      };
    };
    "updated progress for challenge: " # Nat.toText(challengeId) # "\n" # userDataAsText(userData)
  };

  public shared(msg) func createChallenge(title: Text, description: Text) : async Text {
    // Verify the user
    let userData = switch (userDb.findById(msg.caller)) {
      case (null) { return "you need to be a registered user to create challenges" };
      case (?user) user
    };
    let username = userData.name;

    let challenge = Challenge.Challenge(challengeCounter.get_new_id(), title, description, ?msg.caller);
    challengeDB.add(challenge);
    "A new challenge with id " # Nat.toText(challenge.get_id()) # " is created by user " # username
  };

  public func pickMeAChallenge() : async Text {
    switch (challengeDB.get_any()) {
      case (null) { "There are no challenges in the database" };
      case (?challenge) { challengeAsText(challenge) }
    }
  };

  public query func displayChallenge(challengeId: ChallengeId) : async Text {
    switch (challengeDB.get(challengeId)) {
      case (null) { "A challenge with challenge id " # Nat.toText(challengeId) # " does not exist" };
      case (?challenge) { challengeAsText(challenge) }
    }
  };

  func userDataAsText(userData : UserData) : Text {
    let userId : Text = Nat.toText(Nat.fromWord32(Principal.hash(userData.id)));
    var userText : Text = "id: " # userId # ", name: " # userData.name # ", challenges: [";
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
      case null { "DUAL" };
      case (?user_id) {
        switch (userDb.findById(user_id)) {
          case (null) { "DUAL" };
          case (?user) { user.name };
        }
      }
    }
  }
};
