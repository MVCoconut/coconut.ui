package coconut.data;

@:autoBuild(coconut.macros.ModelMacro.build())
interface Model {}

// #if macro
// import haxe.macro.Context;
// using tink.MacroApi;
// #end
// import haxe.macro.Expr;
// import tink.state.Observable;
// import tink.state.State;

// using tink.CoreApi;

// @:autoBuild(coconut.macros.ModelMacro.build())
// class Model<T> { 
  
//   public inline function toObservable():Observable<T>
//     return this.__state__;
    
//   public var data(get, never):T;
//     inline function get_data()
//       return this.__state__.value;
  
//   /**
//    * Access this field directly and you will suffer eternal pain and misery!
//    */
//   @:noCompletion var __state__:State<T>;
  
//   public function new(data:T) {
//     this.__state__ = new State(data);
//   }
  
//   function set(data:T)
//     this.__state__.set(data);
    
//   macro function modify(ethis:Expr, fieldUpdates:Array<Expr>):Expr {
    
//     var fields = [for (f in (macro $ethis.data).typeof().sure().getFields().sure())
//       f.name => {
//         var name = f.name;
//         macro __old__.$name;
//       }
//     ];
    
//     function resolve(name:Expr) {
//       var ret = name.getIdent().sure();
//       if (!fields.exists(ret))
//         name.reject('unknown field $ret');
//       return ret;
//     }
    
//     function change(name:Expr, value:Expr) {
//       var n = name.getIdent();
//     }
    
//     for (f in fieldUpdates)
//       switch f {
//         case macro $name = $value:
//           fields[resolve(name)] = value;
//         case { expr: EBinop(OpAssignOp(op), name, value) }:
//           throw 'not implemented';
//         default:
//           throw 'not allowed';
//       }
    
//     var nu = {
//       pos: Context.currentPos(),
//       expr: EObjectDecl([for (f in fields.keys()) { field: f, expr: fields[f] }]),
//     }
    
//     return macro {
//       var __old__ = this.__state__.value;
//       this.set($nu);
//     }
//   }
// }