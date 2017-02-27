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


          var name = path.join('.'),
              data = (macro @:privateAccess { var __x = null; new $cl(__x); __x; }).typeof().sure().reduce();

          switch data {
            case TAnonymous(_):
              var dt = switch data.toComplex() {
                case TAnonymous(fields): 
                  fields.push({ 
                    pos: view.pos,
                    name: 'key',
                    kind: FVar(macro : {}),
                  });
                  for (f in fields)
                    switch f.kind {
                      case FVar(t, e):
                        f.kind = FProp('default', 'never', t, e);
                      default:
                    }
                    TAnonymous(fields);
                default: throw 'assert';
              }
                
              macro {
                var __f = @:privateAccess $ethis.getFactory($v{name}, $p{path}.new);
                var __o:$dt = $a;
                @:privateAccess __f.make(__o);
              }

            default:
              macro @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make($a);
          }
        default:
          view.reject();
      }
}