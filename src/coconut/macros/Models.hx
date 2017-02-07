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

private enum Init {
  Skip;
  Value(e:Expr);
  Arg;
  OptArg(defaultsTo:Expr);
}

private typedef Result = {
  var getter(default, null):Expr;
  @:optional var setter(default, null):Expr;
  @:optional var stateful(default, null):Bool;
  var init(default, null):Init;
}

private class ModelBuilder {

  var fieldDirectives:Array<Named<FieldContext->Result>>;

  var c:ClassBuilder;

  public function new(c) {

    this.c = c;

    if (c.target.isInterface) return;
    
    var OPTIONAL = [{ name: ':optional', params: [], pos: c.target.pos }];

    fieldDirectives = [
      new Named(':constant'  , constantField),
      new Named(':computed'  , computedField),
      new Named(':editable'  , observableField.bind(_, true)),
      new Named(':observable', observableField.bind(_, false)),
    ];

    
    if (!c.target.meta.has(':tink'))
      c.target.meta.add(':tink', [], c.target.pos);
    
    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors not allowed in models');

    var argFields = [],
        transitionFields = [];

    var argType = TAnonymous(argFields),
        transitionType = TAnonymous(transitionFields);

    var cFunc = (macro function (?initial:$argType) {
    }).getFunction().sure();

    var constr = c.getConstructor(cFunc);
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
                var name = member.name;
                var res = v.apply({
                  name: name,
                  type: t,
                  expr: e,
                  pos: member.pos,
                  meta: v.meta,
                });

                c.addMember(Member.getter(name, res.getter, t));

                var setter = 
                  switch res.setter {
                    case null:
                      'never';
                    case v:
                      c.addMember(Member.setter(name, v, t));
                      'set';
                  }

                member.kind = FProp('get', setter, t, null);
                member.publish();

                function addArg(?meta)
                  argFields.push({
                    name: name,
                    pos: member.pos,
                    meta: meta,
                    kind: FProp('default', 'null', t),
                  });

                function getValue() 
                  return switch res.init {
                    case Value(e): macro @:pos(e.pos) ($e : $t);
                    case Arg: 
                      cFunc.args[0].opt = false;
                      addArg();
                      macro initial.$name;

                    case OptArg(e):
                      
                      addArg(OPTIONAL);
                      macro switch initial.$name {
                        case null: @:pos(e.pos) ($e : $t);
                        case v: v;
                      }

                    case Skip: 
                      null;
                  }

                if (res.stateful) {
                  if (setter == 'never')
                    transitionFields.push({
                      name: name,
                      pos: member.pos,
                      kind: FProp('default', 'never', t),
                      meta: OPTIONAL,
                    });

                  switch getValue() {
                    case null:
                      throw "assert";
                    case e: 
                      c.addMember({
                        access: [APrivate],
                        name: stateOf(name),
                        pos: member.pos,
                        kind: FVar(macro : tink.state.State<$t>),
                      });
                      constr.init(stateOf(name), e.pos, Value(e));
                  }
                }
                else switch getValue() {
                  case null:
                  case v:
                    constr.init(name, member.pos, Value(v), { bypass: true });
                }                  
            }

            switch member.extractMeta(':transition') {
              case Success(m):
                m.pos.error('@:transition not allowed on fields');
              default:
            }

          case FFun(f):

            switch member.extractMeta(':transition') {
              case Success({ params: params }):
                
                member.publish();

                var ret = null;
                for (v in params)
                  switch v {
                    case macro return $e: 
                      if (ret == null)
                        ret = e;
                      else
                        v.reject('Only one return clause allowed');
                    default:
                      v.reject();
                  }

                if (ret == null) 
                  ret = macro null;

                function next(e:Expr) return switch e {
                  case macro @applyChanges $v: macro @:pos(e.pos) ($v : $transitionType);
                  default: e.map(next);
                }

                f.expr = macro @:pos(f.expr.pos) coconut.macros.Models.transition(
                  function ():tink.core.Promise<$transitionType> ${next(f.expr)}, $ret
                );

              default:
            }

            for (d in fieldDirectives)
              switch member.extractMeta(d.name) {
                case Success({ pos: p, name: n }):
                  p.error('@:$n not allowed on functions');
                default:
              }
                
        }

    if (cFunc.args[0].opt)
      constr.addStatement(macro initial = {}, true);

    var updates = [];
    
    for (f in transitionFields) {
      var name = f.name;
      updates.push(macro if (delta.$name != null) $i{stateOf(name)}.set(delta.$name));
    }

    add(macro class {
      @:noCompletion function __cocoupdate(delta:$transitionType) $b{updates};
    });
  }
  static public function stateOf(name:String)
    return '__coco_$name';

  function add(td:TypeDefinition)
    for (f in td.fields)
      c.addMember(f);  

  function constantField(ctx:FieldContext):Result {
    var name = ctx.name;
    
    return {
      getter: macro @:pos(ctx.pos) this.$name,
      init: switch ctx.expr {
        case null: Arg;
        case macro @byDefault $v: OptArg(v);
        case v: Value(v);
      },
    }
  }

  function computedField(ctx:FieldContext):Result
    return {
      getter: ctx.expr,
      init: Skip,
    }

  function observableField(ctx:FieldContext, setter:Bool):Result {
    var name = ctx.name,
        state = '__coco_$name';
    return {
      getter: macro @:pos(ctx.pos) this.$state.value,
      setter: if (setter) macro @:pos(ctx.pos) this.$state.set(param) else null,
      stateful: true,
      init: switch ctx.expr {
        case null: Arg;
        case macro @byDefault $v: OptArg(v);
        case v: Value(v);
      },
    }
  }
}
#end 

class Models {
  #if macro 
  static public function build() 
    return ClassBuilder.run([function (c) new ModelBuilder(c)]);

  static public function isAssignment(op:Binop)
    return switch op {
      case OpAssign | OpAssignOp(_): true;
      default: false; 
    }

  static public function buildTransition(e:Expr, ret:Expr) { 
    
    var ret = switch ret {
      case null | macro null: macro ret;
      case v: macro ret.next(function (_) return $v);
    }

    return macro @:pos(e.pos) {
      var ret = $e();
      ret.handle(function (o) switch o {
        case Success(v): __cocoupdate(v);
        case _:
      });
      return $ret;
    }

  }
  #end
  macro static public function transition(e, ?ret) 
    return buildTransition(e, ret);
}
