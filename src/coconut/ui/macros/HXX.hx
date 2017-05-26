package coconut.ui.macros;

#if macro 
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;
using StringTools;

typedef Options = {
  var child(default, null):ComplexType;
  @:optional var customAttributes(default, null):String;
  @:optional var flatten(default, null):Expr->Expr;
  @:optional var interceptClass(default, null):{ path: TypePath, pos:Position, arg:Expr }->Option<Expr>;
}
#end

class HXX {
  #if macro
  static public var options:Options;
  static public function parse(e:Expr) {

    if (options == null)
      e.reject('Either the renderer did not configure HXX properly, or no renderer is used');

    var ret = 
      tink.hxx.Parser.parse(
        e, 
        {
          child: options.child,
          customAttributes: options.customAttributes,
          flatten: if (Reflect.field(options, 'flatten') != null) options.flatten else null,
          merger: macro coconut.ui.macros.HXX.merge,
        }, 
        { defaultExtension: 'hxx', noControlStructures: false, defaultSwitchTarget: macro __data__ }
      );

    var interceptClass = 
      if (Reflect.field(options, 'interceptClass') != null) //Testing against null directly yields `Can't create closure : value is not a function`
        options.interceptClass
      else
        function (_) return None;

    function rec(e:Expr) return switch e = e.map(rec) {
      case macro new $view($o):
        switch interceptClass({ pos: e.pos, path: view, arg: o }) {
          case None: macro @:pos(e.pos) coconut.ui.tools.ViewCache.create($e);
          case Some(v): v;
        }
      case macro super($o):
        macro @:pos(e.pos) super(coconut.ui.macros.HXX.liftIfNeedBe($o));      
      case macro tink.hxx.Merge.complexAttribute($_):
        macro {
          var __coco_cache = coconut.ui.tools.ViewCache.current;
          $e;
        }      
      default: e;
    }
    return rec(ret);//TODO: this should really happen through HXX in a single pass
  }

  #end
  macro static public function liftIfNeedBe(e:Expr):Expr 
    return
      switch Context.getExpectedType() {
        case TAbstract(_.get() => { pack: ['tink', 'state'], name: 'Observable' }, [_.toComplex() => t]):
          macro @:pos(e.pos) tink.state.Observable.auto(function ():$t return $e);
        default: e;
      }

  macro static public function observable(e:Expr) {
    var blank = e.pos.makeBlankType();
    
    function checkConst(t:TypedExpr) {
      switch t.expr {
        case TCall({ expr: TField(_, f) }, _):
          switch f {
            case FEnum(_, _):
              
            default:
              throw false;  
          } 
        case TCall(_, _): 
          throw false;
        case TField(_, FEnum(_, _)):
        case TField(_, FInstance(_, _, f) | FStatic(_, f) | FAnon(f)):
          switch f.get().kind {
            case FMethod(_):
            case FVar(_, AccNever | AccInline):
            case v:
              throw false;
          }
        case TField(_, _):
          throw false;
        default:
          
      }
      t.iter(checkConst);
    }
    var t = Context.typeExpr(e);
    return
      try {
        checkConst(t);
        Context.storeTypedExpr(t);
      }
      catch (error:Bool) 
        try 
          Context.storeTypedExpr(Context.typeExpr(macro @:pos(e.pos) ($e : tink.state.Observable.ObservableObject<$blank>)))
        catch (_:Dynamic) 
          macro @:pos(e.pos) tink.state.Observable.auto(function () return $e);
  }


  macro static public function merge(primary:Expr, rest:Array<Expr>)
    return tink.hxx.Merge.mergeObjects(primary, rest, {
      genField: function (ctx) {
        return
          if (ctx.expected.reduce().toString().startsWith('tink.state.Observable<')) {
            var ct = ctx.expected.toComplex();
            var e = ctx.original;
            macro @:pos(e.pos) (coconut.ui.macros.HXX.observable($e) : $ct);
          }
          else ctx.getDefault();
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
