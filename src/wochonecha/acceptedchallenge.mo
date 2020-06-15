import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Types "./types";
import Challenge "./challenge";

module {
  type UserId = Types.UserId;
  type ChallengeId = Challenge.ChallengeId;

  public class AcceptedChallenge ( id: ChallengeId ) {

    public func get_id() : Nat {
      id
    };
  };
};
