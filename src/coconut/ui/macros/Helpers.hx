package coconut.ui.macros;

#if !macro
  #error
#end
import haxe.macro.Expr;
import tink.hxx.*;
using tink.MacroApi;

class Helpers {
  static public function parse(e:Expr, generator:Generator, fragment:String)
    return switch e.expr {
      case EDisplay(v, k):
        EDisplay(parse(v, generator, fragment), k).at(e.pos);
      default:
        var ctx = generator.createContext();
        return ctx.generateRoot(
          Parser.parseRoot(e, {
            defaultExtension: 'hxx',
            noControlStructures: false,
            defaultSwitchTarget: macro __data__,
            isVoid: ctx.isVoid,
            fragment: fragment,
            treatNested: function (children) return ctx.generateRoot.bind(children).bounce(),
          })
        );
    }
}
