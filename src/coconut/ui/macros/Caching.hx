package coconut.ui.macros;

import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;

class Caching {

  static public function createView(ethis:Expr, view:Expr) 
    return 
      switch view.expr {
        case ENew(cl, [a]):
          var path = cl.pack.copy();
          path.push(cl.name);
          
          switch cl.sub {
            case null: '';
            case v: path.push(v);
          }


          var name = path.join('.'),
              data = (macro @:privateAccess { var __x = null; new $cl(__x); __x; }).typeof().sure().reduce();

          switch data {
            case TAbstract(_.get() => { pack: ['tink', 'state'], name: 'Observable' }, [_.toComplex() => t]):
              throw t.toString();
            default:
              macro @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make($a);
          }
        default:
          view.reject();
      }
}