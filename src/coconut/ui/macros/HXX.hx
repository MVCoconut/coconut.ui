package coconut.ui.macros;

#if !macro
  #error
#end
import haxe.macro.Expr;

class HXX {
  static public var generator = new Generator();
  static public function parse(e:Expr) 
    return generator.root(
      tink.hxx.Parser.parseRoot(e, { defaultExtension: 'hxx', noControlStructures: false, defaultSwitchTarget: macro __data__ })
    );
}
