package coconut.ui.macros;

#if macro
import tink.hxx.StringAt;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import tink.hxx.Node;
import tink.anon.Macro.Part;


using tink.MacroApi;
using tink.CoreApi;

class Generator extends tink.hxx.Generator {
  
  override function complexAttribute(n:Node) 
    return unboxValues(super.complexAttribute(n));

  static function unboxValues(f:Option<Type>->Expr):Option<Type>->Expr 
    return function (expected:Option<Type>) return 
      switch expected {
        case Some(t):
          f(switch unboxValue(t) {
            case None: Some(t);
            case v: v;
          });
        default: 
          f(expected);
      }

  static function unboxValue(t:Type)
    return switch t {
      case TAbstract(_.get() => { module: 'coconut.data.Value' }, [t]): Some(t);
      case TAbstract(_.get() => { pack: [], name: 'Null' }, [t]): unboxValue(t);
      case TType(_.get() => { pack: [], name: 'Null' }, [t]): unboxValue(t);
      default: None; 
    }

  override function makeChildren(c:Children, t:Type, root:Bool)
    return super.makeChildren(c, switch unboxValue(t) {
      case Some(v): v;
      case None: t;
    }, root);

  override function makeAttribute(name:StringAt, value:Expr):Part {
    
    var ret = super.makeAttribute(name, value);
    var f = unboxValues(ret.getValue);
    
    if (Context.defined('display') && value.has(function (e) return e.expr.match(EDisplay(_, _)))) {
      var raw = f;
      f = function (t) {
        var ret = raw(t);
        return macro @:pos(ret.pos) ($ret:Dynamic);
      }
    }

    @:privateAccess ret.getValue = f;
    return ret;
  } 
}
#end