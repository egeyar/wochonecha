import Principal "mo:base/Principal";

module {
  public type ChallengeId = Principal;

  public type Challenge = {
    id: ChallengeId;
    title: Text;
    text: Text;
    stats: ChallengeStats;
  };

  public type AcceptedChallenge = {
    challenge: Challenge;
    receivedVia: ReceivedVia:
  };

  public type ReceivedVia = variant {
    friend : UserId;
    created;
    pool;
  };

  public type ChallengeStats = {
    creator: UserId;
    accepted: Nat;
    completed: Nat;
  };
};
