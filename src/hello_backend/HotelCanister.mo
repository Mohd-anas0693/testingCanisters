import CA "mo:candb/CanisterActions";
import CanDB "mo:candb/CanDB";
import Entity "mo:candb/Entity";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Prim "mo:prim";
import List "mo:base/List";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Nat16 "mo:base/Nat16";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";

shared ({ caller = owner }) actor class Comment({
  // the primary key of this canister
  partitionKey : Text;
  // the scaling options that determine when to auto-scale out this canister storage partition
  scalingOptions : CanDB.ScalingOptions;
  // (optional) allows the developer to specify additional owners (i.e. for allowing admin or backfill access to specific endpoints)
  owners : ?[Principal];
}) {
  /// @required (may wrap, but must be present in some form in the canister)
  stable let db = CanDB.init({
    pk = partitionKey;
    scalingOptions = scalingOptions;
    btreeOrder = null;
  });

  stable var lastCallCyclesLeft : Nat = 0;

  stable var trackCyclesConsumption = List.nil<Text>();

  stable var numberOfupdateCalls = 0;

  stable var userUuidList : List.List<Text> = List.nil<Text>();

  type Result = Result.Result<(), (Error.ErrorCode, Text)>;
  /// @recommended (not required) public API
  public query func getPK() : async Text { db.pk };

  /// @required public API (Do not delete or change)
  public query func skExists(sk : Text) : async Bool {
    CanDB.skExists(db, sk);
  };
  /// @required public API (Do not delete or change)
  public shared ({ caller = caller }) func transferCycles() : async () {
    if (caller == owner) {
      return await CA.transferCycles(caller);
    };
  };

  // returns a greeting to the user if exists
  // public query func greetUser(userId : Text) : async ?Text {
  //   let user = switch (CanDB.get(db, { sk = userId })) {
  //     case null { null };
  //     case (?userEntity) { unwrapUser(userEntity) };
  //   };
  func getUuid() : async Text {
    let g = Source.Source();
    UUID.toText(await g.new());
  };

  //   switch (user) {
  //     case null { null };
  //     case (?u) {
  //       ?("Hello " # u.userPhone # " from " # db.pk);
  //     };
  //   };
  // };

  public query func getArrayUuid() : async [Text] {
    List.toArray(userUuidList);
  };

  public func getCycles() : async Nat {
    Debug.print(debug_show (ExperimentalCycles.balance()));
    lastCallCyclesLeft := ExperimentalCycles.balance();
    lastCallCyclesLeft;
  };

  public query func cycleAnalysis() : async [Text] {
    List.toArray(trackCyclesConsumption);
  };

  //to checkMemory size

  public func checkMemorySize() : async Nat {
    let memorySize = Prim.rts_memory_size();
    return memorySize;
  };

  //there is a putblog function to insert the data of blog in which user id is used
  func putBlog(hotelName : Text, hoteldes : Text, hotelLocation : Text, hotelType : Text, userId : Text) : async () {
    let blogId : Text = await getUuid();

    userUuidList := List.push(blogId, userUuidList);

    if (blogId == "" or hotelName == "" or hoteldes == "" or userId == "") {
      return;
    };

    await* CanDB.put(
      db,
      {
        sk = blogId;
        attributes = [
          ("hotelName", #text(hotelName)),
          ("hoteldes", #text(hoteldes)),
          ("hotelLocation", #text(hotelLocation)),
          ("hotelType", #text(hotelType)),
          ("userId", #text(userId)),
        ];
      },
    );
  };
  
public func loopClass(hotelName : Text, hoteldes : Text, hotelLocation : Text, hotelType : Text, userId : Text):async (){
  for(i in Iter.range(0, 366 - 1)) {
     await putBlog(hotelName, hoteldes, hotelLocation, hotelType, userId);
      let currentCycles:Nat= ExperimentalCycles.balance();
      let cyclesLeft = lastCallCyclesLeft -currentCycles;
      trackCyclesConsumption := List.push("call No: " #Nat.toText(numberOfupdateCalls) # "Cycles Consumed" #Nat.toText(cyclesLeft), trackCyclesConsumption);
      lastCallCyclesLeft:=currentCycles;
      numberOfupdateCalls :=numberOfupdateCalls +1 ;
  };
};
 
  // Create a new user. In this basic case, we're using the user's name as the sort key
  // This works for our hello world app, but as names are easily duplicated, one might want
  // to attach an unique identifier to the sk to separate users with the same name
  // public func putUser(userId : Text, name : Text, userPhone : Text) : async () {
  //   if (userId == "" or name == "" or userPhone == "") { return };

  //   // inserts the entity into CanDB
  //   await* CanDB.put(
  //     db,
  //     {
  //       sk = userId;
  //       attributes = [
  //         ("name", #text(name)),
  //         ("userPhone", #text(userPhone)),
  //       ];
  //     },
  //   );
  // };

  // type User = {
  //   name : Text;
  //   userPhone : Text;
  // };

  // // attempts to cast an Entity (retrieved from CanDB) into a User type
  // func unwrapUser(entity : Entity.Entity) : ?User {
  //   let { sk; attributes } = entity;
  //   let nameValue = Entity.getAttributeMapValueForKey(attributes, "name");
  //   let userPhoneValue = Entity.getAttributeMapValueForKey(attributes, "userPhone");

  //   switch (nameValue, userPhoneValue) {
  //     case (
  //       ?(#text(name)),
  //       ?(#text(userPhone)),
  //     ) { ?{ name; userPhone } };
  //     case _ {
  //       null;
  //     };
  //   };
  // };

  type Blog = {
    hotelName : Text;
    hoteldes : Text;
    userId : Text;
    hotelLocation : Text;
    hotelType : Text;
  };

  //get function to retrun the  blog data
  public query func getBlog(blogId : Text) : async ?Text {
    let blog = switch (CanDB.get(db, { sk = blogId })) {
      case null { null };
      case (?userEntity) {
        unwrapblog(userEntity);
      };
    };
    switch (blog) {
      case null { null };
      case (?u) {
        ?("Hello" # u.hotelName # "Anss");
      };
    };
  };
  type ScanBlog = {
    blogs : [Blog];
    nextKey : ?Text;
  };
  public query func scanBlogs(skLowerBound : Text, skUpperBound : Text, limit : Nat, ascending : ?Bool) : async ScanBlog {
    //cap the amount of entries one can return from database to reduce load and incentive use pagiation
    let cappedLimit = if (limit > 10) { 10 } else { limit };
    let { entities; nextKey } = CanDB.scan(
      db,
      {
        skLowerBound = skLowerBound;
        skUpperBound = skUpperBound;
        limit = cappedLimit;
        ascending = ascending;
      },
    );
    {
      blogs = arrayUnwarpBlog(entities);
      nextKey = nextKey;
    };
  };
  //unwarp function for the blogs
  func unwrapblog(entity : Entity.Entity) : ?Blog {
    let { sk; attributes } = entity;
    let hotelNameValue = Entity.getAttributeMapValueForKey(attributes, "hotelName");
    let hoteldesValue = Entity.getAttributeMapValueForKey(attributes, "hoteldes");
    let userIdValue = Entity.getAttributeMapValueForKey(attributes, "userId");
    let hotelLocationValue = Entity.getAttributeMapValueForKey(attributes, "hotelLocation");
    let hotelTypeValue = Entity.getAttributeMapValueForKey(attributes, "hotelType");
    switch (hotelNameValue, hoteldesValue, userIdValue, hotelLocationValue, hotelTypeValue) {
      case (
        ?(#text(hotelName)),
        ?(#text(hoteldes)),
        ?(#text(userId)),
        ?(#text(hotelType)),
        ?(#text(hotelLocation)),
      ) {
        ?{
          hotelName = hotelName;
          hoteldes = hoteldes;
          userId = userId;
          hotelType = hotelType;
          hotelLocation = hotelLocation;
        };
      };
      case _ {
        null;
      };
    };
  };
  func arrayUnwarpBlog(entities : [Entity.Entity]) : [Blog] {
    Array.mapFilter<Entity.Entity, Blog>(
      entities,
      func(e) {
        let { sk; attributes } = e;
        let hotelNameValue = Entity.getAttributeMapValueForKey(attributes, "hotelName");
        let hoteldesValue = Entity.getAttributeMapValueForKey(attributes, "hoteldes");
        let userIdValue = Entity.getAttributeMapValueForKey(attributes, "userId");
        let hotelLocationValue = Entity.getAttributeMapValueForKey(attributes, "hotelLocation");
        let hotelTypeValue = Entity.getAttributeMapValueForKey(attributes, "hotelType");
        switch (hotelNameValue, hoteldesValue, userIdValue, hotelLocationValue, hotelTypeValue) {
          case (
            ?(#text(hotelName)),
            ?(#text(hoteldes)),
            ?(#text(userId)),
            ?(#text(hotelType)),
            ?(#text(hotelLocation)),
          ) {
            ?{
              hotelName = hotelName;
              hoteldes = hoteldes;
              userId = userId;
              hotelType = hotelType;
              hotelLocation = hotelLocation;
            };
          };
          case _ {
            null;
          };
        };
      },
    );
  };
};
