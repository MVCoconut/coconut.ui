package coconut.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.CoreApi;
using tink.MacroApi;

private class ModeBuilder {

  var fieldDirectives:Array<Named<Member->MetadataEntry->Array<Field>>>;

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
                dataFields = dataFields.concat(v.apply(member, v.meta));
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
        }
  }

  function add(td:TypeDefinition)
    for (f in td.fields)
      c.addMember(f);  

  function constantField(member:Member, meta:MetadataEntry) 
    return [];

  function computedField(member:Member, meta:MetadataEntry) 
    return [];

  function editableField(member:Member, meta:MetadataEntry) {
    return observableField(member, meta);
  }

  function observableField(member:Member, meta:MetadataEntry) 
    return [];
}
#end 

class ModelMacro {
  #if macro 
  static function build() {
    return ClassBuilder.run([ModeBuilder.new]);
  }
  static function buildTransition(e:Expr) {
    return e;
  }
  #end
  macro static public function transition(e) 
    return buildTransition(e);
}