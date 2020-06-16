import Principal "mo:base/Principal";

module {
  public type UserId = Principal;
  public type ChallengeId = Nat;

  public type ChallengeStatus = {
      #accepted; #completed; #expired
  };

  public type ChallengeMetadata = {
      id: ChallengeId;
      status: ChallengeStatus;
      completionDeadline: Nat;  // timestamp (unix-style?)
      progress: Nat;  // percent completed (0-100)
  };

  public type UserData = {
    id: UserId;
    name: Text;
    challenges: [ChallengeMetadata];
    friends: [UserId];
  };
}