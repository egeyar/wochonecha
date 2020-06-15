import Principal "mo:base/Principal";

module {
  public type UserId = Principal;
  public type ChallengeId = Principal;

  public type Challenge = {
    id: ChallengeId;
    title: Text;
    text: Text;
    stats: ChallengeStats;
  };

  public type AcceptedChallenge = {
    challenge: Challenge;
    // receivedVia: ReceivedVia;
  };

  public type ChallengeStats = {
    creator: UserId;
    accepted: Nat;
    completed: Nat;
  };

  public type UserData = {
    id: UserId;
    name: Text;
    acceptedChallenges: [AcceptedChallenge];
    completedChallenges: [AcceptedChallenge];
    friends: [UserId];
  };
}