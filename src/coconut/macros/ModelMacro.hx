package coconut.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.CoreApi;
using tink.MacroApi;

private typedef FieldContext = {
  var name(default, null):String;
  var pos(default, null):Position;
  var type(default, null):ComplexType;
  var expr(default, null):Null<Expr>;
  var meta(default, null):MetadataEntry;
}

enum StateKind {
  Stateless;
  Passed(?dfault:Expr);
  Internal(init:Expr);
}

private typedef Result = {
  var getter(default, null):Expr;
  @:optional var setter(default, null):Expr;
  var state(default, null):StateKind;
}

private class ModeBuilder {

  var fieldDirectives:Array<Named<FieldContext->Result>>;

  var c:ClassBuilder;

  public function new(c) {

    this.c = c;

    if (c.target.isInterface) return;

    fieldDirectives = [
      new Named(':constant',   constantField),
      new Named(':computed',   computedField),
      new Named(':editable',   editableField),
      new Named(':observable', observableField),
    ];

    if (!c.target.meta.has(':tink'))
      c.target.meta.add(':tink', [], c.target.pos);

    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors not allowed in models');

    var dataFields = new Array<Field>();

    var dataType = TAnonymous(dataFields);

    var constr = c.getConstructor((macro function (data:$dataType) {}).getFunction().sure());
    constr.publish();

    for (member in c) 
      if (!member.isStatic)
        switch member.kind {
          case FProp(_, _, _, _): 
          
            member.pos.error('Custom properties not allowed in models');

          case FVar(t, e):

            if (t == null) 
              member.pos.error('Field requires explicit type');
            
            var found = None;

            for (directive in fieldDirectives) 
              found = 
                switch [found, member.extractMeta(directive.name)] {
                  case [None, Success(m)]: Some({ apply: directive.value, meta: m });
                  case [Some({ meta: { name: previous } }), Success({ pos: pos, name: conflicting })]:
                    pos.error('Conflicting directives @:$previous and @:$conflicting');
                  case [v, _]: v;
                }

            switch found {
              case None: 
                member.pos.error('Plain fields not allowed on models');
              case Some(v):
                
                var res = v.apply({
                  name: member.name,
                  type: t,
                  expr: switch e {
                    case null: null;
                    default: macro @:pos(e.pos) ($e : $t);
                  },
                  pos: member.pos,
                  meta: v.meta,
                });

                c.addMember(Member.getter(member.name, res.getter, t));

                var setter = 
                  switch res.setter {
                    case null:
                      'never';
                    case v:
                      c.addMember(Member.setter(member.name, v, t));
                      'set';
                  }

                member.kind = FProp('get', setter, t, null);

                //switch res.state {
                  //case 
                //}
                //dataFields = dataFields.concat();
            }

            switch member.extractMeta(':transition') {
              case Success(m):
                m.pos.error('@:transition not allowed on fields');
              default:
            }

          case FFun(f):

            switch member.extractMeta(':transition') {
              case Success({ params: [] }):
                f.expr = macro @:pos(f.expr.pos) coconut.macros.ModelMacro.transition(${f.expr});
              case Success({ params: v }): 
                v[0].reject("@:transtion does not accept arguments");
              default:
            }

            for (d in fieldDirectives)
              switch member.extractMeta(d.name) {
                case Success({ pos: p, name: n }):
                  p.error('@:$n not allowed on functions');
                default:
              }
                
        }

    //trace(TAnonymous(@:privateAccess c.memberList).toString());
    add(macro class {
      var __cocostate__:Dynamic;
    });
  }

  function add(td:TypeDefinition)
    for (f in td.fields)
      c.addMember(f);  

  function constantField(ctx:FieldContext):Result {
    var name = ctx.name;
    c.getConstructor().init(name, ctx.pos, switch ctx.expr {
      case null: Arg(ctx.type, true);
      case v: Value(v);
    }, { bypass: true });
    
    return {
      getter: macro @:pos(ctx.pos) this.$name,
      state: Stateless,
    }
  }

  function computedField(ctx:FieldContext):Result
    return {
      getter: ctx.expr,
      state: Stateless,
    }

  function editableField(ctx:FieldContext) {
    return observableField(ctx);
  }

  function observableField(ctx:FieldContext):Result {
    var name = ctx.name;
    return {
      getter: macro @:pos(ctx.pos) this.__cocostate__.$name,
      state: Passed(ctx.expr),
    }
  }
}
#end 

class ModelMacro {
  #if macro 
  static function build() {
    return ClassBuilder.run([ModeBuilder.new]);
  }
  static function buildTransition(e:Expr) 
    return e;
  #end
  macro static public function transition(e) 
    return buildTransition(e);
}