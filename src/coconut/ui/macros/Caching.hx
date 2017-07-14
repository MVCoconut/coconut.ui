package coconut.ui.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;

class Caching {

  static public function getCache() {
    var scope =
      if ((macro this).typeof().isSuccess()) macro this;
      else Context.getLocalType().getID().resolve();
    return 
      macro coconut.ui.tools.ViewCache.get($scope);  
  }

  static public function createView(ethis:Expr, cl:TypePath, a:Expr) {
    var path = cl.pack.copy();
    path.push(cl.name);
    
    switch cl.sub {
      case null: '';
      case v: path.push(v);
    }

    var name = path.join('.'),
        data = (macro @:privateAccess { var __x = null; new $cl(__x); __x; }).typeof().sure().reduce();
    return  
      switch data {
        case TAbstract(_.get() => { pack: ['tink', 'state'], name: 'Observable' }, [_.reduce().toComplex() => t]):
          
          var fields = switch t {
            case TAnonymous(fields): fields;
            default: 
              switch a {
                case macro coconut.ui.macros.HXX.merge(${ { expr: EObjectDecl([]) } }, $v):
                  return macro @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make(coconut.ui.macros.HXX.liftIfNeedBe($a));
                default: 
                  a.log().reject();
              }
          }

          var func = macro false;
          var key = null;

          switch a {
            case macro coconut.ui.macros.HXX.merge($a{args}):
              switch args[0].expr {
                case EObjectDecl(fields):
                  
                  var nu = [];
                  
                  for (f in fields)
                    switch f.field {
                      case 'key': key = switch f.expr {
                        case macro @reusingFunctions $key: 
                          func = macro true;
                          key;
                        case macro @reusingFunctions($v) $key: 
                          func = macro $v;
                          key;
                        case v: v;
                      }
                      default: nu.push(f);
                    }
                  
                  args[0].expr = EObjectDecl(nu);//TODO: modifying expressions in place is usually not a good idea

                default:
              }
            default:
          }
          
          if (key == null) 
            macro @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make(coconut.ui.macros.HXX.liftIfNeedBe($a));
          else
            macro {
              var __f =  @:privateAccess $ethis.getFactory($v{name}, $p{path}.new);
              var __s = __f.forKey($key, function () {
                var s = new tink.state.State<Void->$t>(null);
                var o = coconut.ui.tools.Compare.stabilize(tink.state.Observable.auto(function () return s.value()), coconut.ui.tools.Compare.shallow.bind($func));
                return new tink.core.Pair(s, o);
              });
              @:privateAccess tink.state.Observable.stack.push(__s.a);//TODO: this is horrible
              __s.a.set(function ():$t return $a);
              @:privateAccess tink.state.Observable.stack.pop();
              __f.make(__s.b);
            }
        default:
          macro @:privateAccess $ethis.getFactory($v{name}, $p{path}.new).make($a);
      }
  }
}