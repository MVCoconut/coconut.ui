package coconut.ui.macros;

#if macro 
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.hxx.Generator.GeneratorOptions;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;
using StringTools;
#end

class HXX {
  #if macro
  static public var options:GeneratorOptions;
  static public function parse(e:Expr) {

    if (options == null)
      e.reject('Either the renderer did not configure HXX properly, or no renderer is used');
    
    var options:GeneratorOptions = {
      child: options.child,
      customAttributes: options.customAttributes,
      flatten: if (Reflect.field(options, 'flatten') != null) options.flatten else null,
      instantiate: if (Reflect.field(options, 'instantiate') != null) function (o) return options.instantiate(o) else null, //In some regards Haxe is just so broken I want to cry
      merger: switch options.merger {
        case null: macro coconut.ui.macros.HXX.merge;
        case v: v;
      },
    };

    return 
      Generator.generate(
        options,
        tink.hxx.Parser.parseRoot(e, { defaultExtension: 'hxx', noControlStructures: false, defaultSwitchTarget: macro __data__ })
      );//.log();

    var ret = 
      tink.hxx.Parser.parse(
        e, 
        options, 
        { defaultExtension: 'hxx', noControlStructures: false, defaultSwitchTarget: macro __data__ }
      );

    function rec(e:Expr) return switch e = e.map(rec) {
      case macro new $view($o):
        macro @:pos(e.pos) coconut.ui.tools.ViewCache.create($e);
      case macro super($o):
        macro @:pos(e.pos) super(coconut.ui.macros.HXX.liftIfNeedBe($o));      
      case macro tink.hxx.Merge.complexAttribute($_):
        macro {
          var __coco_cache = coconut.ui.tools.ViewCache.get();
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

  macro static public function hxx(e:Expr) 
    return parse(e);
}
