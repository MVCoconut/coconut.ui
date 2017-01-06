package coconut.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class ComponentBuilder { 
  static function process(c:ClassBuilder) {
    switch c.target.superClass.params {
      case [data, TInst(_.get() => { kind: KExpr(v) }, [] )]:
        
        var ct = data.toComplex();
        
        c.addMember(Member.method('render', false, {
          args: [{ name: 'attributes', type: ct }],
          ret: null,
          expr: macro @:pos(v.pos) {
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
            return hxx($v);
          }
        }));
        
        //c.getConstructor().init(
        //for (f in fields) {
          //c.getConstructor().addArg(f.name, f.type.toComplex());
        //}
        //trace(TAnonymous([c.getConstructor().toHaxe()]).toString());
      default:
        throw 'invalid usage';
    }
  }
  static function build() {
    return ClassBuilder.run([process]);
  }
  
}