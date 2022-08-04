import Principal "mo:base/Principal";
import Msg "Messages";
import Svc "../Ext/Services";
import ExtRouting "../Ext/Route";
import Sub "../Ext/Sub";
// =============================================================================================== //
// MESSAGE ROUTING TEMPLATE (MR-T)                                                                 //
// ----------------------------------------------------------------------------------------------- //
//  Description : This module provides a standard template for defining ExtRouting rules.          //
// =============================================================================================== //
module {
  // ============================================================================================= //
  //  TYPE DEFINTIONS                                                                              //
  // ============================================================================================= //
  type StableNodeRules = ExtRoute.StableNodeRules;
  type SubArray = Sub.SubArray;
  public type Baseline = ExtRouting.Baseline;
  // ============================================================================================= //
  // ACTOR REFERENCES - ALL TRUSTED ACTORS SHOULD BE DEFINED HERE                                  //
  // --------------------------------------------------------------------------------------------- //  
  //                                                                                               //
  // --------------------------------------------------------------------------------------------- //
  // PRIVILEGED ACCOUNTS                                                                           //
  // --------------------------------------------------------------------------------------------- //
  //  Description : These account will likely be controlled by a governacne system or responsible  //
  //                engineer or similar authority.                                                 //
  // --------------------------------------------------------------------------------------------- //
  private let ANY       : Text = ExtRouting.ANY;  
  private let ADMIN     : Text = "6pbsk-5kqts-mrulc-qb3gr-gyh7c-n55ms-p773q-457bq-j4zbl-c3a5f-bae";
  // --------------------------------------------------------------------------------------------- //
  // SYSTEM SERVICES                                                                               //
  // --------------------------------------------------------------------------------------------- //
  //  Description : The core services provided by the system. These services will address each     //
  //                other directly using actor references.                                         //
  // --------------------------------------------------------------------------------------------- // 
  private let ROUTING   : Text = "rrkah-fqaaa-aaaaa-aaaaq-cai";
  private let REGISTRY  : Text = "tbd";
  private let ASSETS    : Text = "tbd";
  private let EVENTS    : Text = "tbd";
  // --------------------------------------------------------------------------------------------- //
  // GATEWAY SERVICES                                                                              //
  // --------------------------------------------------------------------------------------------- //
  //  Description : Gateway canisters proivde an entry point for apps that expect a standardized   //
  //                interface. These canisters can be upgraded; therefore, Core services should    //
  //                not address them directly.                                                     //
  // --------------------------------------------------------------------------------------------- //
  private let EXTV2     : Text = "tbd";
  private let DIP721    : Text = "tbd";
  // ============================================================================================= //
  // BASELINE DEFINITIONS                                                                          //
  // --------------------------------------------------------------------------------------------- //  
  public let _BASELINE_ : Baseline = {

    services = [
      ( Svc.routing, ROUTING ),
      ( Svc.registry, REGISTRY ),
      ( Svc.assets, ASSETS ),
      ( Svc.events, EVENTS ),
      ( Svc.extv2, EXTV2 ),
      ( Svc.dip721, DIP721 ),
    ];

    routes = [

      ( ROUTING, [
        { from = ADMIN; msg = Msg.Routing.subscribe; },
        { from = ADMIN; msg = Msg.Routing.unsubscribe; },
        { from = ANY; msg = Msg.Routing.download; },
        { from = ANY; msg = Msg.Routing.get_rules; },
        { from = ANY; msg = Msg.Routing.get_actors; },
        { from = ADMIN; msg = Msg.Routing.get_nodes; },
        { from = ANY; msg = Msg.Routing.get_subs; },
        { from = ADMIN; msg = Msg.Routing.upload; },
        { from = ADMIN; msg = Msg.Routing.add_route; },
        { from = ADMIN; msg = Msg.Routing.add_node; },
        { from = ADMIN; msg = Msg.Routing.del_route; },
        { from = ADMIN; msg = Msg.Routing.del_node; },
      ]),
      
    ];

    subscribers = [];

  };
};  
