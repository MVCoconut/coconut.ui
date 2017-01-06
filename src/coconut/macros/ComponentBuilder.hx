package coconut.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class ComponentBuilder { 
  static function process(c:ClassBuilder) {
    switch c.target.superClass.params {
      case [data, TInst(_.get() => { kind: KExpr(v) }, [] )]:
        
        var ct = data.toComplex();
        
        var fields = (macro class {
          override function render(attributes:$ct) {
            
            ${EVars([
              for (f in data.getFields().sure()) {
                var name = f.name;
                {
                  name: name,
                  type: null,
                  expr: macro attributes.$name,
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