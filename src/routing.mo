import ExtRoute "Ext/Route";
import ExtServices "Ext/Services";
import ExtSub "Ext/Sub";
import Messages "Env/Messages";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

shared ({ caller = _installer }) actor class Routing() = this {
  
// =============================================================== //
// Type Definitions                                                // 
// =============================================================== //
  type NONE = ExtRoute.NONE;
  type Baseline = ExtRoute.Baseline;
  type Routes = ExtRoute.Routes;
  type Services = ExtRoute.Services;
  type RoutingError = ExtRoute.RoutingError;
  type Subscriber = ExtSub.Subscriber;
  type Subscribers = ExtSub.Subscribers;
  type Subscriptions = ExtSub.Subscriptions;

  type Msg = Messages.Routing;

// =============================================================== //
// One-Time Programmable                                           // 
// =============================================================== //
  private stable var _INIT_ : Bool = false;
  private stable let _SERVICE_ID_ : Text = NONE;
  private stable var _CANISTER_ID_ : Text = NONE;
  private stable var _REGISTRY_ : Text = NONE;
  private stable var _EVENTS_ : Text = NONE;
  private stable var _ASSETS_ : Text = NONE;

// =============================================================== //
// Stable Memory                                                   //
// =============================================================== //
  private stable var _stable_baseline : Baseline = ExtRoute.emptyBaseline;

// =============================================================== //
// Heap Memory                                                     //
// =============================================================== //                                                            
  private var _routing_table = ExtRoute.RoutingTable( _stable_baseline.routes, _stable_baseline.services );
  private var _rules = ExtRoute.Rules( _routing_table.getRoutes( _CANISTER_ID_ ) );
  private var _subscriptions = ExtSub.Subscriptions( _stable_baseline.subscribers );

// =============================================================== //
// Public Interface - Update Methods                               //
// =============================================================== //

  // Canister Initialization
  public shared ({caller}) func init( bl : Baseline ) : async () {

    // Canister can only be initialized once; by the canister installer
    assert Bool.logand( Principal.equal(caller, _installer), Bool.lognot(_INIT_));
    _CANISTER_ID_ := Principal.toText( Principal.fromActor(this) );

    // The routing table must contain actor references for the core services
    _routing_table_stable := ExtRoute.RoutingTable( bl.routes, bl.services );
    assert _routing_table.isSupported( ExtServices.routing );
    assert _routing_table.isSupported( ExtServices.assets );
    assert _routing_table.isSupported( ExtServices.registry );
    assert _routing_table.isSupported( ExtServices.events );

    // The 'routing' service reference must match this canister's ID
    assert Text.equal( _routing_table.getActorReference( ExtServices.routing ), _CANISTER_ID_ );

    // Set OTP values, load local rule set, and commit stable baseline
    _SERVICE_ID_ := ExtServices.routing;
    _REGISTRY_ := _routing_table.getActorReference( ExtServices.registry );
    _ASSETS_ := _routing_table.getActorReference( ExtServices.assets );
    _EVENTS_ := _routing_table.getActorReference( ExtServices.events );
    _rules := ExtRoute.Rules( _routing_table.getRoutes( _CANISTER_ID_ ) );
    _committed_baseline := bl;
    _INIT_ := true;
  };

  // Reset canister to known-good state                                           
  public shared ({caller}) func reset() : async () {
    assert _rules.permit( caller, Msg.reset );
    _routing_table := ExtRoute.RoutingTable( _committed_baseline.routes, _committed_baseline.services );
    _rules := ExtRoute.Rules( _routing_table.getActorReference( _CANISTER_ID_ ) );
  };   

  // Commit active baseline to stable memory
  public shared ({caller}) func commit() : async Baseline {
    assert _rules.permit( caller, Msg.commit );
    _commitBaseline();
  };

  // Called by client services that want to receive routing updates
  public shared ({caller}) func subscribe( s : Subscriber ) : async Routes {
    assert _rules.permit( caller, Msg.subscribe );
    if ( Principal.equal( caller, Principal.fromText(s.sub) ) ) {
      let temp = _routing_table.getRoutes( Principal.toText(caller) );
      _subscriptions.put(s);
      temp;
    } else {[]};
  };

  // Called by client services that no longer require routing updates
  public shared ({caller}) func unsubscribe( s : Subscriber ) : async () {
    assert  _rules.permit( caller, Msg.unsubscribe );
    if ( Principal.equal( caller, s.sub ) ) { _subscriptions.delete(s) };
  };

  // Periodically called by the local service manager
  public shared ({caller}) func ping() : async Text { 
    assert _rules.permit( caller, Msg.ping );
    _CANISTER_ID_;
  };

  // Provide routes to calling service (from active baseline)
  public shared ({caller}) func refresh() : async Routes {
    assert _rules.permit( caller, Msg.refresh );
    _routing_table.getRoutes( Principal.toText(caller) );
  };

// =============================================================== //
// Public Interface - Query Methods                                //
// =============================================================== //

  // Exports the active baseline
  public shared query ({caller}) func download() : async Baseline {
    assert _rules.permit( caller, Msg.download );
    _active_baseline();
  };

  // Exports an array of routes for a given actor (from active baseline)
  public shared query ({caller}) func rules( c : Text ) : async Routes {
    assert _rules.permit( caller, Msg.rules );
    _routing_table.getRoutes( c );
  };

  // Exports an array of supported services (from active baseline)
  public shared query ({caller}) func services() : async Services {
    assert _rules.permit( caller, Msg.actors );
    _routing_table.supported();
  };

  // Exports an array of trusted actors (from active baseline)
  public shared query ({caller}) func nodes() : async [Text] {
    assert _rules.permit( caller, Msg.nodes );
    _trusted_nodes.vals();
  };

  // Exports an array of current subscribers
  public shared query ({caller}) func subscribers() : async Subscribers {
    assert _rules.permit( caller, Msg.subscribers );
    _subscriptions.export();
  };

  // --------------------------------------------------------------- //
  // Private Methods                                                 //
  // --------------------------------------------------------------- //

  func _publishBaseline() : () {
    for ( sub in _subscriptions.subscribers() ) {
      let t_routes : Routes = _routing_table.getRoutes( sub.sub );
      await sub.callback( t_routes ); // TODO catch errors and respond accordingly
    };
  };

  func _activeBaseline() : Baseline {
    return {
      services = _routing_table.exportServices();
      routes = _routing_table.exportRoutes();
      subscribers = _subscriptions.export();
    };
  };
  
  func _commitBaseline() : Baseline {
    _stable_baseline := _activeBaseline();
    return _stable_baseline;
  };

};
