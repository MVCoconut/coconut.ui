package coconut.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class ViewBuilder { 
  static function process(c:ClassBuilder) {
    switch c.target.superClass.params {
      case [data, TInst(_.get() => { kind: KExpr(v) }, [] )]:
        
        var ct = data.toComplex({ direct: true });
        
        var fields = (macro class {
          override function render(__data__:$ct) {
            
            ${EVars([
              for (f in data.getFields().orUse([])) if (f.isPublic) {
                var name = f.name;
                {
                  name: name,
                  type: null,
                  expr: macro __data__.$name,
                }
              }
            ]).at(v.pos)}
            return @:pos(v.pos) hxx($v);
          }
          
          @:keep function toString()
            return $v{c.target.name}+' '+this.key;
        }).fields;        
        
        for (f in fields)
          c.addMember(f);
          
      default:
        throw 'invalid usage';
    }
  }
  static function build() {
    return ClassBuilder.run([process]);
  }
  
}