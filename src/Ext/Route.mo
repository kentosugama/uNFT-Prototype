import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import TrieSet "mo:base/TrieSet";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Result "mo:base/Result";
import Sub "Sub";

module {

  public let ANY = "any";
  public let NONE = "none";

  public type Baseline = {
    routes : RTEntries;
    services : Services;
    subscribers : Sub.Subscribers;
  };

  public let emptyBaseline = { routes = []; services = []; subscribers = [] };

  public type RoutingError = Result.Result<(), {
    #Unauthorized;
    #BadRoute : Route;
  }>;

  public type Route = {
    from : Text;
    msg : Nat;
  };

  public type Routes = [Route];
  public type Service = ( Text, Text );
  public type Services = [Service];
  public type RTEntries = [(Text, Routes)];
  private type RouteSet = TrieSet.Set<Route>;

  public func equal( x : Route, y : Route ) : Bool {
    let b1 = Text.equal( x.from, y.from );
    let b2 = Nat.equal( x.msg, y.msg );
    Bool.logand(b1, b2);
  };

  public func hash( x : Route ) : Hash.Hash {
    let m : Text = Nat.toText( x.msg );
    let t : Text = Text.concat( x.from, m );
    Text.hash(t);
  };

  public class Rules( x : Routes) {

    var _set = TrieSet.empty<Route>();
    if ( Nat.greater( x.size(), 0 ) ) {
      _set := TrieSet.fromArray( x, hash, equal );
    };
    
    public func put( r : Route ) : () { _set := TrieSet.put<Route>( _set, r, hash(r), equal ) };
    public func delete( r : Route ) : () { _set := TrieSet.delete<Route>( _set, r, hash(r), equal ) };
    public func union( r : RouteSet ) : () { _set := TrieSet.union<Route>( _set, r, equal ) };
    public func match( r : RouteSet ) : Bool { TrieSet.equal<Route>( _set, r, equal ) };
    public func clear() : () { _set := TrieSet.empty<Route>() };
    public func mem( r : Route ) : Bool { TrieSet.mem( _set, r, hash(r), equal ) };
    public func size() : Nat { TrieSet.size( _set ) };
    public func raw() : RouteSet { _set };
    public func toArray() : Routes { TrieSet.toArray( _set ) };

    public func permit( s : Principal, m : Nat ) : Bool {
      let src = Principal.toText(s);
      let r_null : Route = { from = ANY; msg = m };
      let r : Route = { from = src; msg = m };
      Bool.logor( mem(r_null), mem(r) );
    };

  };
    
  public class RoutingTable( x : RTEntries, y : Services ) {
    
    var _map1 = TrieMap.fromEntries<Text, Routes>( x.vals(), Text.equal, Text.hash );
    var _map2 = TrieMap.fromEntries<Text, Text>(y.vals(), Text.equal, Text.hash );

    public func deleteRoutes( p : Text  ) : () { _map1.delete(p) };
    public func replaceRoutes( p : Text, r : Routes ) : () { _map1.put(p, r) };
    public func exportEntries() : RTEntries { Iter.toArray( _map1.entries() ) };
    public func getRoutes( p : Text ) : Routes { Option.get( _map1.get(p), [] ) };

    public func deleteService( s : Text ) : () { _map2.delete(s) };
    public func replaceService( s : Text, ar : Text ) : () { _map2.put(s, ar) };
    public func exportServices() : Services { Iter.toArray(_map2.entries()) };
    public func getActorReference( s : Text ) : Text { Option.get( _map2.get(s), NONE ) };

    public func getServiceId( ar : Text ) : Text {
      let x : List.List<Service> = Iter.toList( _map2.entries() ); 
      let y : ?Service = List.find<Service>( x, func (x : Service ) : Bool { Text.equal(x.1, ar) } );
      switch( y) {
        case( ?z ) {z.0};
        case(_) {NONE};
      };
    };

    public func getServiceNodes() : [Text] { Iter.toArray( _map2.vals() ) };

    public func supported() : [Text] { Iter.toArray( _map2.keys() ) };

    public func isSupported( s: Text ) : Bool { Option.isSome( _map2.get(s) ) };

    public func clear() : () {
      _map1 := TrieMap.TrieMap<Text, Routes>( Text.equal, Text.hash );
      _map2 := TrieMap.TrieMap<Text, Text>( Text.equal, Text.hash );
    };

  };

};