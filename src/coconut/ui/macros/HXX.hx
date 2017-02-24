package coconut.ui.macros;

#if macro 
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;
using StringTools;

typedef Options = {
  var child(default, null):ComplexType;
  @:optional var customAttributes(default, null):String;
  @:optional var flatten(default, null):Expr->Expr;
}
#end

class HXX {
  #if macro
  static public var options:Options;
  static public function parse(e:Expr) {
    if (options == null)
      e.reject('Either the renderer did not configure HXX properly, or no renderer is used');
    return 
      tink.hxx.Parser.parse(
        e, 
        {
          child: options.child,
          customAttributes: options.customAttributes,
          flatten: if (Reflect.hasField(options, 'flatten')) options.flatten else null,
          merger: macro coconut.ui.macros.HXX.merge,
        }, 
        { defaultExtension: 'hxx', noControlStructures: false, defaultSwitchTarget: macro __data__ }
      );
  }
  #end

  macro static public function observable(e:Expr) {
    var blank = e.pos.makeBlankType();
    return 
      try 
        Context.storeTypedExpr(Context.typeExpr(macro @:pos(e.pos) ($e : tink.state.Observable.ObservableObject<$blank>)))
      catch (_:Dynamic) 
        macro @:pos(e.pos) tink.state.Observable.auto(function () return $e);
  }

  macro static public function merge(primary:Expr, rest:Array<Expr>)
    return tink.hxx.Merge.mergeObjects(primary, rest, {
      fixField: function (e) return e,
      genField: function (ctx) {
        if (ctx.expected.reduce().toString().startsWith('tink.state.Observable<')) {
          var df = ctx.getDefault();
          return
            switch df {
              case macro ($e : $t):
                macro @:pos(df.pos) (coconut.ui.macros.HXX.observable($e) : $t);
              default:
                df;
            }
        }
        return ctx.getDefault();
      },
      decomposeSingle: function (src, expected, decompose) {
        return
          switch expected.reduce() {
            case TAnonymous(_.get().fields => fields):              
              return 
                if ((macro ($src : coconut.data.Model)).typeof().isSuccess()) {
                  var parts = [macro __model__, macro { key: __model__ }];
                  macro {
                    var __model__ = $src;
                    ${decompose.bind(parts).bounce()};
                  }
                }
                else decompose([src]);
            default: src;
          }
      },
    });

  macro static public function hxx(e:Expr)
    return parse(e);
}