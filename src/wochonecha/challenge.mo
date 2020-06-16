import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Types "./types";

module {
  public type ChallengeId = Nat;

  type UserId = Types.UserId;

  public class Challenge (
    id: ChallengeId,
    title: Text,
    description: Text,
    creator: ?UserId) {

    var acception_count: Nat = 0;
    var completion_count: Nat = 0;

    public func get_id() : Nat {
      id
    };

    public func get_title() : Text {
      title
    };

    public func get_description() : Text {
      description
    };

    public func get_creator() : ?UserId {
      creator
    };

    public func get_acception_count() : Nat {
      acception_count
    };

    public func incr_acception_count() {
      acception_count += 1;
    };

    public func get_completion_count() : Nat {
      completion_count
    };

    public func incr_completion_count() {
      completion_count += 1;
    };
  };

  public func isEq(x: ChallengeId, y: ChallengeId): Bool { x == y };
};
