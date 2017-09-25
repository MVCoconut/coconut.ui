package coconut.ui.macros;

#if macro
import tink.hxx.StringAt;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using tink.MacroApi;
using tink.CoreApi;

class Generator extends tink.hxx.Generator {

  override function instantiate(name:StringAt, isClass:Bool, key:Option<Expr>, attr:Expr, children:Option<Expr>)
    return switch key {
      case None: 
        super.instantiate(name, isClass, key, attr, children);
      case Some(key):
        if (children != None)
          name.pos.error('Key handling for views with children not yet implemented');

        macro @:pos(name.pos) @:privateAccess coconut.ui.tools.ViewCache.propView(
          $key, 
          $v{Context.getType(name.value).getID()},
          $attr,
          $i{name.value}.new
        );
    }

  override function plain(name:StringAt, isClass:Bool, arg:Expr, pos:Position)
    return 
      if (isClass) 
        macro @:pos(name.pos) @:privateAccess coconut.ui.tools.ViewCache.modelView(
          $v{Context.getType(name.value).getID()},
          $arg,
          $i{name.value}.new          
        )
      else super.plain(name, isClass, arg, pos);
  
}
#end