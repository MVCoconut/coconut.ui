package coconut.ui.macros;

import haxe.macro.Expr;
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

          var name = path.join('.');

          macro {
            @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make($a);
          }

        default:
          view.reject();
      }
}