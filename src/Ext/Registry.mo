import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import List "mo:base/List";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";


module ExtRegistry = {
  public type TokenBuffer = Buffer.Buffer<ExtCore.TokenIndex>;
  public type TokenList = List.List<ExtCore.TokenIndex>;
  public type UserRecord = {
    id : Principal;
    sub : ExtCore.SubAccount;
  };
  public type LockRequest = {
    token : ExtCore.TokenIndex;
    buyer : ExtCore.AccountIdentifier;
  };
  public type ListRequest = {
    token : ExtCore.TokenIndex;
    seller : ExtCore.AccountIdentifier;
  };
  public type RegistryError = Result.Result<(), {
    #InvalidToken;
    #Unauthorized;
    #Listed;
    #NotListed;
    #Locked;
    #NotLocked;
    #SecurityLock;
    #MintLimit
    #FatalFault : Nat;
    #Other : Text;
  }>;
  public type TokenState = {
    canister : ?Principal;
    buyer : ?ExtCore.AccountIdentifier;
  };
  public type TransferEvent = {
    token : Nat;
    sender : ExtCore.AccountIdentifier;
    receiver : ExtCore.AccountIdentifier;
  };
  public type TransferOrder = {
    token : ExtCore.TokenIndex;
    sender : ExtCore.AccountIdentifier;
    receiver : UserRecord;
  };
  public type SaleOrder = {
    token : ExtCore.TokenIndex;
    buyer : UserRecord;
    price : Nat64;
  };
  public module UserRecord = {
    public func toAID( x : UserRecord ) : ExtCore.AccountIdentifier {
      AID.fromPrincipal( x.id, ?x.sub );
    };
  };
};