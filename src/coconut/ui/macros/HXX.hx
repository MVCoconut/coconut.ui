package coconut.ui.macros;

#if !macro
  #error
#end
import haxe.macro.Expr;
using tink.MacroApi;

class HXX {
  static public var generator = new Generator();
  static public function parse(e:Expr) {
    var ctx = generator.createContext();
    return ctx.generateRoot(
      tink.hxx.Parser.parseRoot(e, { 
        defaultExtension: 'hxx', 
        noControlStructures: false, 
        defaultSwitchTarget: macro __data__,
        isVoid: ctx.isVoid
      })
    );
  }
}
