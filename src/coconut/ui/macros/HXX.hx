package coconut.ui.macros;

#if !macro
  #error
#end
import haxe.macro.Expr;
import tink.hxx.*;
using tink.MacroApi;

class HXX {
  static public var generator = new Generator();
  static public function parse(e:Expr) {
    var ctx = generator.createContext();
    return ctx.generateRoot(
      Parser.parseRoot(e, { 
        defaultExtension: 'hxx', 
        noControlStructures: false, 
        defaultSwitchTarget: macro __data__,
        isVoid: ctx.isVoid
      })
    );
  }
}
