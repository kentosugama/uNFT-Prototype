import AID "motoko/util/AccountIdentifier";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import ExtCore "motoko/ext/Core";
import ExtRouting "Extensions/Routing";
import ExtRegistry "Extensions/Registry";
import ExtNonFungible "motoko/ext/NonFungible";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import List "mo:base/List";

actor class Registry() = this {

  type Extension = ExtCore.Extension;
  type User = ExtCore.User;
  type TokenIndex = ExtCore.TokenIndex;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type Metadata = Text;
  type UserRecord = ExtRegistry.UserRecord;
  type TokenState = ExtRegistry.TokenState;
  type ListRequest = ExtRegistry.ListRequest;
  type RegistryError = ExtRegistry.RegistryError;
  type LockRequest = ExtRegistry.LockRequest;
  type TransferOrder = ExtRegistry.TransferOrder;
  type SaleOrder = ExtRegistry.SaleOrder;
  type TokenList = ExtRegistry.TokenList;
  type TokenBuffer = ExtRegistry.TokenBuffer;
  type MintRequest = ExtRegistry.MintRequest;

  private let EXTENSIONS : [Extension] = ["@ext/nonfungible", "@ext/registry"];

  //
  // Stable Memory
  //
  //private stable var _assets_stable : 
  private stable var _user_record_stable : [ ( AccountIdentifier, UserRecord ) ] = [];
  private stable var _metadata_stable : [ ( TokenIndex, Metadata ) ] = [];
  private stable var _token_state_stable : [ ( TokenIndex, TokenState ) ] = [];
  private stable var _owners_stable : [ ( AccountIdentifier, [ TokenIndex ] ) ] = [];
  private stable var _operators_stable : [ ( AccountIdentifier, [ TokenIndex ] ) ] = [];
  private stable var _locked_stable : [ TokenIndex ] = [];
  private stable var _listed_stable : [ TokenIndex ] = [];
  private stable var _token_operators_stable : [ ( TokenIndex, [ AccountIdentifier ] ) ] = [];
  private stable var _token_registry_stable : [ ( TokenIndex, AccountIdentifier) ] = [];
  private stable var _security_lock : Bool = false;
  private stable var _nextTokenId : TokenIndex  = 0;
  private stable var _maxTokenID : TokenIndex = 999;


  //
  // Runtime Memory
  //
  //private var _assets : TrieMap.TrieMap<TokenIndex, Asset> = TrieMap.fromEntries(_assets_stable.vals(), TokenIndex.equal, TokenIndex.hash);
  private var _user_record : TrieMap.TrieMap<AccountIdentifier, UserRecord> = TrieMap.fromEntries(_user_record_stable.vals(), AID.equal, AID.hash);
  private var _metadata : TrieMap.TrieMap<TokenIndex, Metadata> = TrieMap.fromEntries(_metadata_stable.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _token_state : TrieMap.TrieMap<TokenIndex, TokenState> = TrieMap.fromEntries(_token_state_stable.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _owners : TrieMap.TrieMap<AccountIdentifier, [TokenIndex]> = TrieMap.fromEntries(_owners_stable.vals(), AID.equal, AID.hash);
  private var _operators : TrieMap.TrieMap<AccountIdentifier, [TokenIndex]> = TrieMap.fromEntries(_operators_stable.vals(), AID.equal, AID.hash);
  private var _token_operators : TrieMap.TrieMap<TokenIndex, [AccountIdentifier]> = TrieMap.fromEntries(_token_operators_stable.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _token_registry : TrieMap.TrieMap<TokenIndex, AccountIdentifier> = TrieMap.fromEntries(_token_registry_stable.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _locked : TokenBuffer = Buffer.Buffer<TokenIndex>(0);
  private var _listed : TokenBuffer = Buffer.Buffer<TokenIndex>(0);

  //
  // System Functions
  //
  system func preupgrade() {
    _token_registry_stable := Iter.toArray( _token_registry.entries() );
    _token_state_stable := Iter.toArray( _token_state.entries() );
    _user_record_stable := Iter.toArray( _user_record.entries() );
    //_assets_stable := Iter.toArray( _assets.entries() );
    _metadata_stable := Iter.toArray( _metadata.entries() );
    _operators_stable := Iter.toArray( _operators.entries() );
    _token_operators_stable := Iter.toArray( _token_operators.entries());
    _owners_stable := Iter.toArray( _owners.entries() );
    _locked_stable := _locked.toArray();
    _listed_stable := _listed.toArray();

  };
  system func postupgrade() {
    for ( entry in _locked_stable.vals() ) {
      _locked.add( entry );
    };
    for( entry in _listed_stable.vals() ) {
      _listed.add( entry );
    };
    _token_registry_stable := [];
    _token_state_stable := [];
    _user_record_stable := [];
    _token_operators_stable := [];
    //_assets_stable := [];
    _metadata_stable := [];
    _operators_stable := [];
    _owners_stable := [];
    _locked_stable := [];
    _listed_stable := [];
  };

  // --------------- //
  // Query Interface //
  // --------------- //
  //
  // 
  public query func getSecurityLock() : async Bool { _security_lock };
  public query func getHolders() : async [AccountIdentifier] { Iter.toArray( _owners.keys() ) };
  public query func getListed() : async [TokenIndex] { _listed.toArray() };
  public query func getLocked() : async [TokenIndex] { _locked.toArray() };
  public query func getTokenOperators( token : TokenIndex ) : async ?[AccountIdentifier] {
    switch( _token_operators.get( token ) ) {
      case( ?token_operators ) { ?token_operators };
      case(_) { null };
    };
  };

  // --------------------------------- //
  // Public Interface - Update Methods //
  // --------------------------------- //
  //
  // disableTransfers() : params() -> ()
  //
  public shared(msg) func disableTransfers() : async () { _security_lock := true };
  //
  // enableTransfers() : params() -> ()
  //
  public shared(msg) func enableTransfers() : async () { _security_lock := false };
  //
  // mint() : params( MintRequest ) -> RegistryError
  //
  public shared(msg) func mint( user : MintRequest ) : RegistryError {
    if ( _nextTokenId == 1000 ) { return #err( #MintLimit ) };
    // TODO : add logic for making a callback to the asset management canister
    _transferTokenToUser( _nextTokenId, user );
    _nextTokenId += 1;
  };
  //
  // list() : params( ListRequest ) -> RegistryError
  //
  public shared(msg) func list( request : ListRequest ) : async RegistryError {
    if ( _isTokenRegistered( request.token ) == false ) { return #err( #InvalidToken ) };
    if ( _isTokenListed( request.token ) ) { return #err( #Listed ) };
    if ( _isTokenLocked( request.token ) ) { return #err( #FatalFault( 5 ) ) };
    if ( _isOwner( request.token, request.seller ) ) {
      _listed.add( request.token );
      return #ok();
    } else {
      return #err( #Unauthorized );
      }; 
  };
  //
  // lock() : params( LockRequest ) -> RegistryError
  //
  public shared(msg) func lock( request : LockRequest ) : async RegistryError {
    if ( _isTokenListed( request.token ) == false ) { return #err( #NotListed ) };
    if ( _isTokenLocked( request.token ) ) { return #err( #Locked ) };
    if ( _isTokenRegistered( request.token ) ) {
      _locked.add( request.token );
      _token_state.put( request.token, {
        canister = ?msg.caller;
        buyer =  ?request.buyer;
      });
      return #ok();
    } else {
      return #err( #InvalidToken )
    };
  };
  //
  // transfer() : params( TransferOrder ) -> RegistryError
  //
  public shared(msg) func transfer( order : TransferOrder ) : async RegistryError {
    if ( _security_lock ) { return #err( #SecurityLock ) };
    if ( _isTokenRegistered( order.token ) == false ) { return #err( #InvalidToken ) };
    if ( _isTokenLocked( order.token ) == false ) { return #err( #Locked ) };
    if ( _isOwner( order.token, order.sender) or _isOperator( order.token, order.sender ) ) {
      _removeOperatorsToken( order.token );
      _removeOwnerToken( order.token, order.sender );
      _removeListing( order.token );
      _removeLocked( order.token );
      _transferTokenToUser( order.token, order.receiver );
      return #ok();
    } else { return #err( #Unauthorized ) }; 
  };
  //
  // sale() : params( SaleOrder ) -> RegistryError
  //
  public shared(msg) func sale( order : SaleOrder ) : async RegistryError {
    let buyer : AccountIdentifier = ExtRegistry.UserRecord.toAID( order.buyer );
    if ( _security_lock ) { return #err( #SecurityLock ) };
    if ( _isTokenListed( order.token ) == false ) { return #err( #NotListed ) };
    if ( _isTokenLocked( order.token )  == false ) { return #err( #NotLocked ) };
    if ( _hasSaleAuthority( order.token, msg.caller ) == false ) { return #err( #Unauthorized ) };
    if ( _hasPurchaseAuthority( order.token, buyer ) ) {
      switch( _getOwnerAID( order.token ) ) {
        case( ?owner ) {
          _removeOperatorsToken( order.token );
          _removeOwnerToken( order.token, owner );
          _removeListing( order.token );
          _removeLocked( order.token );
          _transferTokenToUser( order.token, order.buyer );
          return #ok()
        };
        case(_) { return #err( #FatalFault( 6 ) ) };
      };
    } else {
      return #err( #Unauthorized );
    };
  };
  
  // --------------- //
  // Private Methods //
  // --------------- //
  //
  // _transferTokenToUser() : params( TokenIndex, Principal, SubAccount ) -> ()
  //
  func _transferTokenToUser( token : TokenIndex, owner: UserRecord ) : () {
    let owner_account : AccountIdentifier = ExtRegistry.UserRecord.toAID( owner );
    _addOwner( token, owner_account);
    _token_registry.put( token, owner_account );
    _user_record.put( owner_account, owner );
    _token_state.put( token, {
      canister = null;
      buyer = null;
    } );
  };
  //
  // _addOwner() : params( TokenIndex, AccountIdentifier ) -> ()
  //
  func _addOwner( token : TokenIndex, owner : AccountIdentifier ) : () {
    let temp_buffer : TokenBuffer = Buffer.Buffer<TokenIndex>(0);
    switch( _owners.get( owner ) ) {
      case( ?owner_tokens ) {
        for ( t in owner_tokens.vals() ) {
          temp_buffer.add( t );
        };
      };
      case(_) {};
    };
    temp_buffer.add( token );
    _owners.put( owner, temp_buffer.toArray() );
  };
  func _removeOperatorsToken( token : TokenIndex ) : () {
    switch( _token_operators.get( token ) ) {
      case( ?token_operators ) {
        if ( Nat.greater( Iter.size( token_operators.vals() ), 0 ) ) {
          for ( user in token_operators.vals() ) {
            switch( _operators.get( user ) ) {
              case( ?op_tokens ) { _operators.put( user, Array.filter( op_tokens, func(x : TokenIndex) : Bool { x != token } ) );
              };
              case(_) {};
            };
          };
        };
      };
      case(_) {};
    };
  };
  func _removeOwnerToken( token : TokenIndex, owner : AccountIdentifier ) : () {
    switch( _owners.get( owner ) ) {
      case( ?o_tokens ) { _owners.put( owner, Array.filter( o_tokens, func(x : TokenIndex) : Bool { x != token } ) ) };
      case(_) {};
    };
  };
  func _removeListing( token : TokenIndex ) : () {
    let filtered = Iter.filter( _listed.vals(), func(x : TokenIndex) : Bool { x != token } );
    _listed.clear();
    for ( entry in filtered ) {
      _listed.add( entry );
    };
  };
  func _removeLocked( token : TokenIndex ) : () {
    let filtered = Iter.filter( _locked.vals(), func(x : TokenIndex) : Bool { x != token } );
    _locked.clear();
    for ( entry in filtered ) {
      _locked.add( entry );
    };
  };
  func _isOperator( token : TokenIndex, user : AccountIdentifier ) : Bool {
    switch( _token_operators.get( token ) ) {
      case( ?operators ) {
        let test = Iter.size( Array.filter( operators, func( x : AccountIdentifier ) : Bool { x == user } ).vals() );
        if ( Nat.greater( test, 0 ) ) {
          return true;
        } else {
          return false;
        };
      };
      case(_) { return false };
    };
  };
  func _isOwner( token : TokenIndex, user : AccountIdentifier ) : Bool {
    switch( _token_registry.get( token ) ) {
      case( ?owner ) {
        if ( AID.equal( owner, user ) ) {
          return true; 
        } else { return false };
      };
      case(_) { return false };
    };
  };
  func _isTokenRegistered( token : TokenIndex ) : Bool {
    let existing_tokens : List.List<TokenIndex> = Iter.toList( _token_state.keys() );
    _isTokenInList( existing_tokens, token );
  };
  func _isTokenLocked( token : TokenIndex ) : Bool {
    let locked_tokens = _bufferToList( _locked );
    _isTokenInList( locked_tokens, token );
  };
  func _isTokenListed( token : TokenIndex ) : Bool {
    let listed_tokens = _bufferToList( _listed );
    _isTokenInList( listed_tokens, token );
  };
  func _hasSaleAuthority( token : TokenIndex, canister : Principal ) : Bool {
    switch( _token_state.get( token ) ) {
      case( ?token_state ) {
        switch( token_state.canister ) {
          case( ?locking_principal ) {
            if ( Principal.equal( locking_principal, canister ) ) {
              return true;
            } else {
              return false;
            };
          };
          case(_) { return false };
        };
      };
      case(_) { return false };
    };
  };
  func _hasPurchaseAuthority( token : TokenIndex, buyer : AccountIdentifier ) : Bool {
    switch( _token_state.get( token ) ) {
      case( ?token_state ) {
        switch( token_state.buyer ) {
          case( ?auth_buyer ) {
            if ( AID.equal( buyer, auth_buyer ) ) {
              return true;
            } else { return false };
          };
          case(_) { return false };
        };
      };
      case(_) { return false };
    };
  };
  func _getOwnerAID( token : TokenIndex ) : ?AccountIdentifier {
    switch ( _token_registry.get( token ) ) {
      case( ?owner ) { ?owner };
      case(_) { null };
    };
  };
  func _checkPermissions( map : TrieMap.TrieMap<TokenIndex, [AccountIdentifier]>, token : TokenIndex, user : AccountIdentifier ) : Bool {
    switch( map.get( token ) ) {
      case( ?privileged_users ) {
        let test = Iter.size( Array.filter( privileged_users, func( x : AccountIdentifier ) : Bool { x == user } ).vals() );
        if ( Nat.greater( test, 0 ) ) {
          return true;
        } else {
          return false;
        };
      };
      case(_) { return false };
    };
  };
  func _bufferToList( buf : TokenBuffer ) : TokenList {
    let list : List.List<TokenIndex> = Iter.toList( buf.vals() );
    return list;
  };
  func _isTokenInList( list : TokenList, token : TokenIndex ) : Bool {
    switch( List.find( list, func( x : TokenIndex ) : Bool { x == token } ) ) {
      case( ?t ) { return true };
      case(_) { return false };
    };
  };

};