type Metadata = {
  logo : ?Text;
  name : ?Text;
  created_at : Nat64;
  upgraded_at : Nat64;
  custodians : Principal;
  symbol : ?Text;
};

type Stats = {
  cycles : Nat;
  total_transactions : Nat;
  total_unique_holders : Nat;
  total_supply : Nat;
};

type GenericValue = {
  #Nat64Content : Nat64;
  #Nat32Content : Nat32;
  #BoolContent : Bool;
  #Nat8Content : Nat8;
  #Int64Content : Int64;
  #IntContent : Int;
  #NatContent : Nat;
  #Nat16Content : Nat16;
  #Int32Content : Int32;
  #Int8Content : Int8;
  #FloatContent : Float64;
  #Int16Content : Int16;
  #BlobContent : Blob;
  #NestedContent : Vec;
  #Principal : Principal;
  #TextContent : Text;
};

type TokenMetadata = {
  transferred_at : ?Nat64;
  transferred_by : ?Principal;
  owner : ?Principal;
  operator : ?Principal;
  properties : [(Text, GenericValue)];
  is_burned : Bool;
  token_identifier : Nat;
  burned_at : ?Nat64;
  burned_by : ?Principal;
  approved_at : ?Nat64;
  approved_by : ?Principal;
  minted_at : Nat64;
  minted_by : Principal;
};

type NftError = {
  #SelfTransfer;
  #TokenNotFound;
  #TxNotFound;
  #SelfApprove;
  #OperatorNotFound;
  #UnauthorizedOwner;
  #UnauthorizedOperator;
  #ExistedNFT;
  #OwnerNotFound;
  #Other : Text;
};

type SupportedInterface = {
  #Burn;
  #Mint;
  #Approval;
  #TransactionHistory
};