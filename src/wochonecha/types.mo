import Principal "mo:base/Principal";

module {
  public type UserId = Principal;
  public type ChallengeId = Nat;

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
    acceptedCount: Nat;
    completedCount: Nat;
  };

  public type UserData = {
    id: UserId;
    name: Text;
    acceptedChallenges: [ChallengeId];
    completedChallenges: [ChallengeId];
    friends: [UserId];
  };
}