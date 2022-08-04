import Metadata "DIP721/Metadata";
import Stats "DIP721/Stats";
import GenericValue "DIP721/GenericValue";
import TokenMetadata "DIP721/TokenMetadata";
import NftError "DIP721/NftError";
import SupportedInterface "DIP721/SupportedInterface";
import Cycles "mo:base/ExperimentalCycles";
import Result "mo:base/Result";

actor class DIP721() : this {

  public type Result = Result.Result;

  private stable var _logo : ?Text = null;
  private stable var _name : ?Text = null;
  private stable var _created_at : Nat64 = 0;
  private stable var _upgraded_at : Nat64 = 0;
  private stable var _custodians : [Principal] = [];
  private stable var _symbol : ?Text = null;
  private stable var _unique_holders : Nat = 0;
  private stable var _total_supply : Nat = 0;

  // Basic Interface - Query Methods
  //
  public query func logo() : async ?Text { _logo; };
  public query func name() : async ?Text { _name; };
  public query func symbol() : async ?Text { _symbol; };
  public query func custodians() : async Principal () { _custodians; };
  public query func cycles() : async Nat { Cycles.balance(); };
  public query func totalUniqueHolders() : async Nat { _unique_holders; };
  public query func stats() : async Stats {
    stats : Stats = {
      cycles : Cycles.balance();
      total_transactions : _total_transactions;
      total_unique_holders : _unique_holders;
      total_supply : _total_supply;
    };
    stats;
  };
  public query func metadata() : async Metadata {
    let metadata : Metadata = {
      logo = _logo;
      name = _name;
      created_at = _created_at;
      upgraded_at = _upgraded_at;
      custodians = _custodians;
      symbol = _symbol;
    };
    metadata;
  };
  public query func tokenMetadata(token_identifier : Nat) : async Result<TokenMetadata, NftError> {
    // TODO
  };  
  public query func balanceOf(user : Principal) : async Result<Nat, NftError> {
    // TODO
  };
  public query func ownerOf(token_identifier : Nat) : async Result<?Principal, NftError> {
    // TODO
  };
  public query func ownerTokenIdentifiers(user : Principal) : async Result<[Nat], NftError> {
    // TODO
  };
  public query func ownerTokenMetadata(user : Principal) : async Result<[TokenMetadata], NftError> {
    // TODO
  };
  public query func operatorOf(token_identifier : Nat) : async Result<?Principal, NftError> {
    // TODO
  };
  public query func operatorTokenIdentifiers(user : Principal) : async Result<[Nat], NftError> {
    // TODO
  };
  public query func operatorTokenMetadata(user : Principal) : async Result<[TokenMetadata], NftError> {
    // TODO
  };
  public query func SupportedInterfaces() : async [SupportedInterface] {
    // TODO
  };
  public query func totalSupply() : async Nat {
    _total_supply;
  };
  
  // Basic Interface - Update Methods
  //
  // These are dummy interfaces; included only to satisfy interface spec
  //
  public shared(msg) func setLogo( logo : Text) : async () { return; };
  public shared(msg) func setName(name : Text) : async () { return; };
  public shared(msg) func setSymbol(symbol : Text) : async () { return; };
  public shared(msg) func setCustodian(custodians : [Principal]) : async () { return; };
};
