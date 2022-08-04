import Bool "mo:base/Bool";
import ExtRouting "Route";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";


module {  
  
  public type Routes = ExtRouting.Routes;
  public type Subscribers = [ Subscriber ];
  public type SubSet = Trie.Trie<Subscriber, ()>;
  public type Subscriber = {
    sub : Text;
    callback : shared (Routes) -> async ();
  };

  public func equal( s1 : Subscriber, s2 : Subscriber ) : Bool { Text.equal( s1.sub, s2.sub ) };
  public func hash( s : Subscriber ) : Hash.Hash { Text.hash( s.sub ) };

  public class Subscriptions( x : Subscribers) {

    var _set : SubSet = TrieSet.fromArray<Subscriber>( x, hash, equal );

    public func put( s : Subscriber ) : () { _set := TrieSet.put<Subscriber>( _set, s, hash(s), equal ) };
    public func delete( s : Subscriber ) : () { _set := TrieSet.delete<Subscriber>( _set, s, hash(s), equal ) };
    public func union( s : SubSet ) : () { _set := TrieSet.union<Subscriber>( _set, s, equal ) };
    public func match( s : SubSet ) : Bool { TrieSet.equal<Subscriber>( _set, s, equal ) };
    public func clear() : () { _set := TrieSet.empty<Subscriber>() };
    public func isSubscribed( s : Subscriber ) : Bool { TrieSet.mem<Subscriber>( _set, s, hash(s), equal ) };
    public func subscribers() : Subscribers { Iter.fromArray( _set.toArray() ) };
    public func size() : Nat { TrieSet.size<Subscriber>( _set ) };
    public func export() : Subscribers { TrieSet.toArray<Subscriber>( _set ) };
    public func raw() : SubSet { _set };

  };

};