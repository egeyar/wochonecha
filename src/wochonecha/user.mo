import Principal "mo:base/Principal";

module {
  public type UserId = Principal;

  public type User = {
    id: UserId;
    name: Text;
    accepted_challenges: [AcceptedChallenge];
    completed_challenges: [AcceptedChallenge];
    friends: [UserId];
  };
};
