package coconut.ui.macros;

#if !macro
  #error
#end
import haxe.macro.Expr;
import haxe.macro.*;
import tink.hxx.*;
using tink.MacroApi;
using tink.CoreApi;

class HXX {

  static public var defaults(default, never) = new tink.priority.Queue<Lazy<Array<Named<Expr.Position->Tag>>>>();

  static public var generator = new Generator(function ()
    return [for (group in defaults) for (tag in group.get()) tag]
  );
  static public function parse(e:Expr)
    return switch e.expr {
      case EDisplay(v, k):
        EDisplay(parse(v), k).at(e.pos);
      default:
        var ctx = generator.createContext();
        return ctx.generateRoot(
          Parser.parseRoot(e, {
            defaultExtension: 'hxx',
            noControlStructures: false,
            defaultSwitchTarget: macro __data__,
            isVoid: ctx.isVoid,
            fragment: Context.definedValue('hxx_fragment'),
            treatNested: function (children) return ctx.generateRoot.bind(children).bounce(),
          })
        );
    }
}
