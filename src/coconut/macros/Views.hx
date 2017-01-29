package coconut.macros;

import tink.macro.BuildCache;
import haxe.macro.Expr;

class Views {
  static function build() {
    BuildCache.getTypeN('coconut.ui.View', function (ctx:BuildContextN):TypeDefinition {
      ctx.types;
    });
  }
}