package coconut.ui.macros;

#if macro
import coconut.data.macros.*;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.priority.Queue;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

private typedef PostProcessor = Callback<{
  target: ClassBuilder,
  attributes:Array<Member>,
  states:Array<Member>,
  refs:Array<Member>,
  lifeCycle: Array<Member>,
}>;

class ViewBuilder {

  final config:Config;
  final c:ClassBuilder;

  static function getComparator(t:MetadataEntry) {
    var comparator = macro @:pos(t.pos) null;

    for (p in t.params)
      switch p {
        case macro comparator = $f:
          comparator = f;
        default: p.reject();
      }

    return { comparator: comparator };
  }

  function new(c, config) {
    this.c = c;
    this.config = config;
  }

  static function noArgs(t:MetadataEntry)
    switch t.params {
      case []:
      case v: v[0].reject('no arguments allowed here');
    }

  function doBuild() {

    var defaultPos = (macro null).pos,//perhaps just use currentPos()
        classId = Models.classId(c.target);

    function add(t:TypeDefinition) {
      for (f in t.fields)
        c.addMember(f);
      return t.fields;
    }

    if (!c.target.meta.has(':tink'))
      c.target.meta.add(':tink', [], defaultPos);

    c.target.meta.add(':observable', [], defaultPos);

    if (!c.target.superClass.t.get().meta.has(':coconut.viewbase')) {
      c.target.pos.error('Subclassing views is currently not supported');
    }

    var beforeRender = [],
        tracked = [];

    function scrape<Meta>(name:String, process:MetadataEntry->Meta, ?aliases:Array<String>, ?skipCheck:Bool) {
      switch c.memberByName('${name}s') {
        case Success(group):
          var m = group.getVar(true).sure();

          switch m.type {
            case TAnonymous(fields):
              if (m.expr != null)
                m.expr.reject('initialization not allowed here');

              for (f in fields)
                c.addMember(f).addMeta(':$name');
            default:

              var defaults =
                switch m.expr {
                  case null: new Map();
                  case { expr: EObjectDecl(fields) }: [for (f in fields) f.field => f.expr];
                  case v: v.reject('object literal expected');
                }
              for (f in m.type.toType().sure().getFields().sure())
                c.addMember({
                  pos: f.pos,
                  name: f.name,
                  kind: FVar(f.type.toComplex(), defaults[f.name]),
                  meta: f.meta.get(),
                }).addMeta(':$name').addMeta(':skipCheck');
          }
          c.removeMember(group);
        default:
      }

      var tags = [for (a in [name].concat(switch aliases { case null: []; case v: v; })) ':$a' => true];
      var ret = [];

      for (m in c)
        switch [for (m in m.meta) if (tags[m.name]) m] {
          case []:
          case [t]:
            if (m.kind.match(FProp(_, _, _, _)))
              m.pos.error('$name cannot be property');

            if (!skipCheck && !m.extractMeta(':skipCheck').isSuccess())
              switch m.kind {
                case FVar(t, _):
                  Models.checkLater(m.name, classId);
                default:
              }
            ret.push({
              pos: t.pos,
              member: m,
              meta: process(t),
            });
          case a:
            a[1].pos.error('cannot have ${a[1].name} and ${a[0].name}');
        }

      if (!skipCheck)
        for (f in ret)
          switch f.member.extractMeta(':tracked') {
            case Success({ params: params }):

              var name = f.member.name;

              if (params.length == 0)
                tracked.push(macro this.$name);
              else
                for (p in params)
                  tracked.push(p.substitute({ _ : macro @:pos(p.pos) this.$name }));

            default:
          }

      return ret;
    }

    var initSlots = [],
        attributes:Array<Member> = [];

    function slotName(name)
      return '__coco_$name';

    function addAttribute(a, expr:Expr, type:ComplexType, publicType:ComplexType, optional:Bool, comparator, ?meta) {
      var name = a.name;
      var data = macro @:pos(a.pos) attributes.$name,
          slotName = slotName(a.name);

      initSlots.push(macro @:pos(a.pos) this.$slotName.setData($data));

      if (expr == null)
        expr = macro @:pos(a.pos) null;
      add(macro class {
        private var $slotName(default, never):coconut.ui.tools.Slot<$type, $publicType> =
          new coconut.ui.tools.Slot<$type, $publicType>(this, ${comparator}, $expr);
      });

      switch a.pos.getOutcome(type.toType()).reduce() {
        case TDynamic(null):
          a.pos.error('Attribute `${a.name}` must not be Dynamic');
        case TAbstract(_.get() => { pack: [], name: 'Any' }, _):
          a.pos.error('Attribute `${a.name}` must not be Any');
        default:
      }

      attributes.push({
        name: a.name,
        pos: a.pos,
        kind: FVar(publicType),
        meta:
          (if (optional) [{ name: ':optional', params: [], pos: expr.pos }] else [])
            .concat(switch meta {
              case null: [];
              case v: v;
            })
      });

    }

    for (attr in scrape('attribute', getComparator, ['attr', 'children', 'child'])) {

      var a = attr.member,
          comparator = attr.meta.comparator;

      function add(type:ComplexType, expr:Expr) {
        var optional = a.extractMeta(':optional').isSuccess() || expr != null,
            name = a.name;

        var slotName = slotName(name);

        if (optional && expr == null)
          expr = macro @:pos(a.pos) null;

        addAttribute(a, expr, type, macro : coconut.data.Value<$type>, optional,
          attr.meta.comparator,
          a.metaNamed(':children')
            .concat(a.metaNamed(':child'))
        );

        var isNullable =
          if (optional) switch expr {
            case macro null: true;
            default: false;
          }
          else switch type {
            case macro : Null<$_>: true;
            default: false;
          }
        a.isPublic = true;
        a.kind =
          switch a.pos.getOutcome(type.toType()).reduce() {
            case TFun(args, ret) if (!isNullable):
              var args =
                switch a.kind {
                  case FFun(f):
                    f.args;
                  default:
                    [for (i in 0...args.length) {
                      name: 'a$i',
                      type: args[i].t.toComplex(),
                      opt: args[i].opt
                    }];
                }

              FFun({
                args: args,
                ret: ret.toComplex(),
                expr: {
                  var callArgs = [for (a in args) macro $i{a.name}];
                  var body =
                    if (#if debug optional #else true #end)
                      macro @:pos(a.pos) return this.$slotName.value($a{callArgs});
                    else
                      macro @:pos(a.pos) return switch this.$slotName.value {
                        case null: throw 'mandatory attribute ' + $v{name} + ' of <' + $v{c.target.name} + '/> was set to null';
                        case __fn: __fn($a{callArgs});
                      }
                  body;
                },
              });

            default:
              var getter = 'get_$name';

              c.addMembers(macro class {
                @:noCompletion inline function $getter():$type
                  return this.$slotName.value;
              });
              FProp('get', 'never', type, null);
          }

      }

      switch a.kind {
        case FVar(null, _):
          a.pos.error('type required');//TODO: infer if possible
        case FVar(t, e):
          add(t, e);
        case FFun(f):
          add(
            TFunction(
              [for (a in f.args) if (a.opt) TOptional(a.type) else a.type], //TODO: apparently how optional arguments are dealt with doesn't work properly
              switch f.ret {
                case null: macro : Void;
                case v: v;
              }
            ),//TODO: rewrite this to be Callback when suitable
            if (f.expr == null) null
            else f.asExpr(a.pos)
          );
        default: a.pos.error('attributes cannot be properties');
      }
    }

    for (c in scrape('controlled', noArgs))
      switch c.member.kind {
        case FVar(null, _):
          c.pos.error('type required');//TODO: infer if possible
        case FVar(t, e):
          var optional = switch e {
            case null:
              if (c.member.metaNamed(':optional').length > 0) {
                e = macro @:pos(e.pos) new tink.state.State<$t>(cast null);
                true;
              }
              else false;
            default:
              e = macro @:pos(e.pos) new tink.state.State<$t>($e);
              true;
          }

          addAttribute(c.member, e, t, macro : coconut.data.Variable<$t>, optional, macro @:pos(c.pos) null);

          c.member.kind = FProp('get', 'set', t);

          var name = c.member.name;

          var getter = 'get_$name',
              setter = 'set_$name',
              slotName = slotName(name);

          add(macro class {
            inline function $getter():$t
              return this.$slotName.value;
            function $setter(param:$t):$t {
              switch @:privateAccess this.$slotName.data {//TODO: this is quite hideous
                case null: //should probably never happen
                case v: v.set(param);
              }
              return param;
            }
          });
        case _.match(FFun(_)) => isFunc:
          c.pos.error('controlled attributes cannot be ${if (isFunc) 'functions' else 'properties'}');
      }

    var rendererPos = null;
    var renderer = switch c.memberByName('render') {
      case Success(m):
        rendererPos = m.pos;
        m.addMeta(':noCompletion', (macro null).pos);
        m.getFunction().sure();
      default:
        c.target.pos.error('missing field render');
    }

    if (renderer.args.length > 0)
      rendererPos.error('argument should not be specified');

    {
      var renders = config.renders;
      switch renderer.ret {
        case null: renderer.ret = macro : $renders;
        case ct: (macro @:pos(rendererPos) ((null:$ct):$renders)).typeof().sure();
      }
    }

    var refs = [];

    for (ref in scrape('ref', noArgs, true)) {
      var f = ref.member;
      refs.push(f);
      var type = f.getVar(true).sure().type;

      f.kind = FProp('default', 'never', type);

      var setter = '_coco_set_${f.name}',
          refHolder = f.name;

      var set = (function () {
        var e = Context.storeTypedExpr(Context.typeExpr(macro this.$refHolder));
        return macro $e = param;
      }).bounce(f.pos);

      f.addMeta(':refSetter', [macro $i{setter}]);
      c.addMembers(macro class {
        @:noCompletion function $setter(param:$type) $set;
      });
    }

    renderer.expr = beforeRender.concat([switch renderer.expr {
      case e = { expr: EConst(CString(s)), pos: p }: macro @:pos(p) return hxx($e);
      case e: e;
    }]).toBlock(renderer.expr.pos);

    var states = [];

    for (state in scrape('state', getComparator)) {
      var s = state.member;
      states.push(s);
      var v = s.getVar(true).sure();

      if (v.expr == null)
        s.pos.error('@:state requires initial value');

      var t = v.type;
      var internal = '__coco_${s.name}',
          get = 'get_${s.name}',
          set = 'set_${s.name}';

      c.addMembers(macro class {
        @:noCompletion private var $internal:tink.state.State<$t> = @:pos(v.expr.pos) new tink.state.State<$t>(${v.expr}, ${state.meta.comparator});
        inline function $get():$t return $i{internal}.value;
        inline function $set(param:$t) {
          $i{internal}.set(param);
          return param;
        }
      });

      s.kind = FProp('get', 'set', t, null);
    }

    var lifeCycle = [];

    {
      if (c.hasConstructor())
        c.getConstructor().toHaxe().pos.error('custom constructor not allowed');

      var notFound:Array<Member> = [];

      function processHook(name:String, ?ret:Lazy<ComplexType>, with:Member->Function->Void)
        return
          switch c.memberByName(name) {
            case Success(m):
              var f = m.getFunction().sure();
              lifeCycle.push(m);
              m.overrides = false;
              if (m.metaNamed(':noCompletion').length == 0)
                m.addMeta(':noCompletion');

              if (ret != null)
                switch f.ret {
                  case null:
                    f.ret = ret;
                  case t:
                    (macro @:pos(m.pos) ((null:$t):$ret)).typeof().sure();
                }

              with(m, f);

              macro @:pos(m.pos) $i{m.name};
            default:
              notFound.push({
                name: name,
                pos: defaultPos,
                kind: FProp('default', 'never', macro : Dynamic),
                meta: [{ name: ':optional', params: [], pos: defaultPos }]
              });
              macro null;
          }

      var shouldUpdate = processHook('shouldViewUpdate', macro : Bool, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      var beforeRender = [],
          afterRender = [];

      var snapshot = null;

      var getSnapshotBeforeUpdate = processHook('getSnapshotBeforeUpdate', null, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');

        snapshot = switch f.ret {
          case null: m.pos.makeBlankType();
          case v: v;
        }

        beforeRender.push(macro @:pos(m.pos) snapshot = getSnapshotBeforeUpdate());
      });

      processHook('viewDidRender', macro : Void, function (m, f) {

        switch f.args {
          case []: f.args.push({ name: 'firstTime', type: macro : Bool });
          case [arg]: if (arg.type == null) arg.type = macro : Bool;
          default: m.pos.error('${m.name} should have one argument');
        }

        afterRender.push(macro @:pos(m.pos) viewDidRender(firstTime));
      });

      processHook('viewDidUpdate', macro : Void, function (m, f) {

        if (snapshot != null)
          switch f.args {
            case []: f.args.push({ name: 'snapshot', type: snapshot });
            case [arg]: if (arg.type == null) arg.type = snapshot;
            default: m.pos.error('${m.name} should have one argument');
          }
        else if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');

        var args = [for (a in f.args) macro @:pos(m.pos) $i{a.name}];

        afterRender.push(macro @:pos(m.pos) if (!firstTime) viewDidUpdate($a{args}));
      });

      processHook('viewDidMount', macro : Void, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');

        afterRender.push(macro @:pos(m.pos) if (firstTime) viewDidMount());
      });

      var viewWillUnmount = processHook('viewWillUnmount', macro : Void, function (m, f) {
        if (f.args.length > 0)
          m.pos.error('${m.name} cannot take arguments');
      });

      var getDerivedStateFromAttributes =
        processHook(
          'getDerivedStateFromAttributes',
          function () return TAnonymous([
            for (s in states) {

              var t = s.getVar().sure().type;

              {
                name: s.name,
                pos: s.pos,
                kind: FProp('default', 'never', macro : $t),
                meta: [{ name: ':optional', params: [], pos: s.pos}],
              }

            }
          ]),
          function (m, f) {

            if (!m.isStatic)
              m.pos.error('${m.name} should be static');

            var argFields = [];
            var argType = TAnonymous(argFields);

            for (m in attributes.concat(states))
              argFields.push({
                name: m.name,
                pos: m.pos,
                kind: switch c.memberByName(m.name).sure().kind {
                  case FFun(f): FFun({
                    expr: null,
                    ret: f.ret,
                    args: f.args,
                    params: f.params
                  });
                  case FProp(_, _, t) | FVar(t): FVar(t);
                }
              });

            var arg = EObjectDecl([for (f in argFields) { field: f.name, expr: macro @:pos(m.pos) $p{['this', f.name]} }]).at(m.pos);

            switch f.args {
              case []: f.args.push({ name: 'previous', type: argType });
              case [arg]:
                if (arg.type != null)
                  m.pos.error('Argument ${arg.name} should not have its type specified');
                else
                  arg.type = argType;
              default: m.pos.error('${m.name} must have one argument');
            }

            var applyChanges = [for (s in states) {
              var name = s.name;
              macro @:pos(s.pos) if (changed.$name) this.$name = nu.$name;
            }];

            tracked.unshift(
              macro @:pos(m.pos) tink.state.Observable.untracked(function () {
                var nu = getDerivedStateFromAttributes($arg),
                    changed = tink.Anon.existentFields(nu);

                $b{applyChanges}
              })
            );

          });

      var notFound = TAnonymous(notFound);

      for (m in c)
        if (m.name.charAt(3) != '_' && m.kind.match(FFun(_)) && m.metaNamed(':noCompletion').length == 0)
          switch notFound.getFieldSuggestions(m.name) {
            case '':
            case v: m.pos.warning('Potential typo$v');
          }

      var attributes = TAnonymous(attributes),
          init = '__initAttributes',
          track =
            if (tracked.length > 0)
              macro function track() $b{tracked};
            else macro null;

      c.getConstructor((macro @:pos(c.target.pos) function (__coco_data_:$attributes) {
        this.$init(__coco_data_);

        var snapshot:$snapshot = null;

        super(
          render,
          $shouldUpdate,
          $track,
          ${
            if (snapshot == null) macro null
            else macro function () snapshot = getSnapshotBeforeUpdate()
          },
          ${switch afterRender {
            case []: macro null;
            default: macro function (firstTime:Bool) $b{afterRender};
          }}
        );

        switch ($viewWillUnmount) {
          case null:
          case v: beforeUnmounting(v);
        }

      }).getFunction().sure()).isPublic = true;

      var self = Context.getLocalType().toComplexType();
      var params = switch self {
        case TPath(t): t.params;
        default: throw 'assert';
      }
      c.addMembers(macro class {
        #if debug
        @:keep function toString() {
          return $v{c.target.name}+'#'+this.viewId;
        }
        #end

        @:noCompletion function $init(attributes:$attributes)
          $b{initSlots};

      });
    }

    for (f in c)
      switch [f.kind, f.extractMeta(':computed')] {
        case [FVar(t, e), Success(m)]:

          if (m.params.length > 0)
            m.params[0].reject('@:computed does not support parameters');

          if (e == null)
            m.pos.error('@:computed field requires expression');

          if (t == null)
            m.pos.error('@:computed field requires type');

          var internal = '__coco_${f.name}',
              get = 'get_${f.name}';

          c.addMembers(macro class {
            @:noCompletion private var $internal:tink.state.Observable<$t> =
              @:pos(e.pos) tink.state.Observable.auto(function ():$t return $e);
            inline function $get() return $i{internal}.value;
          });

          if (f.metaNamed(':skipCheck').length == 0)
            Models.checkLater(f.name, classId);

          f.kind = FProp('get', 'never', t);
        default:
      }

    config.afterBuild.invoke({
      target: c,
      attributes: attributes,
      states: states,
      refs: refs,
      lifeCycle: lifeCycle,
    });
  }

  @:persistent static final configs:Map<String, Config> = new Map();

  static function build(configId:String)
    return ClassBuilder.run([
      c -> new ViewBuilder(c, switch configs[configId] {
        case null: Context.fatalError('please restart the compiler server', Context.currentPos());
        case v: v;
      }).doBuild()
    ]);

  static public function init(renders:ComplexType, afterBuild:PostProcessor) {

    var cls = Context.getLocalClass().get();

    var id = '${cls.module}.${cls.name}';

    configs.set(id, { renders: renders, afterBuild: afterBuild });

    cls.meta.add(':observable', [], (macro null).pos);
    cls.meta.add(':coconut.viewbase', [], (macro null).pos);
    cls.meta.add(':autoBuild', [macro coconut.ui.macros.ViewBuilder.build($v{id})], (macro null).pos);

    return Context.getBuildFields().concat(base(renders).fields);
  }

  static function base(renders) return macro class {
    public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

    @:noCompletion var _coco_revision = new tink.state.State(0);

    public function new(
        render:Void->$renders,
        shouldUpdate:Void->Bool,
        track:Void->Void,
        beforeRerender:Void->Void,
        rendered:Bool->Void
      ) {

      var mounted = if (rendered != null) rendered.bind(true) else null,
          updated = if (rendered != null) rendered.bind(false) else null;

      var firstTime = true,
          last = null,
          hasBeforeRerender = beforeRerender != null,
          hasUpdated = updated != null,
          lastRev = _coco_revision.value;

      super(
        tink.state.Observable.auto(
          function renderView() {
            var curRev = _coco_revision.value;
            if (track != null) track();

            if (firstTime) firstTime = false;
            else {
              if (curRev == lastRev && shouldUpdate != null && !shouldUpdate())
                return last;
              var hasCallbacks = __bc.length > 0;
              if (hasBeforeRerender || hasCallbacks)
                tink.state.Observable.untracked(function () {
                  if (hasBeforeRerender) beforeRerender();
                  if (hasCallbacks) for (c in __bc.splice(0, __bc.length)) c.invoke(false);
                });
            }
            lastRev = curRev;
            return last = render();
          }
        ),
        mounted,
        function () {
          var hasCallbacks = __au.length > 0;
          if (hasUpdated || hasCallbacks)
            tink.state.Observable.untracked(function () {
              if (hasUpdated) updated();
              if (hasCallbacks) for (c in __au.splice(0, __au.length)) c.invoke(Noise);
            });
        },
        function () {
          last = null;
          firstTime = true;
          __beforeUnmount();
        }
      );
    }

    @:noCompletion var __bu:Array<tink.core.Callback.CallbackLink> = [];
    @:noCompletion function __beforeUnmount() {
      for (c in __bu.splice(0, __bu.length)) c.dissolve();
      for (c in __bc.splice(0, __bu.length)) c.invoke(true);
    }

    @:extern inline function untilUnmounted(c:tink.core.Callback.CallbackLink):Void __bu.push(c);
    @:extern inline function beforeUnmounting(c:tink.core.Callback.CallbackLink):Void __bu.push(c);

    @:noCompletion var __bc:Array<tink.core.Callback<Bool>> = [];

    @:extern inline function untilNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);
    @:extern inline function beforeNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);

    @:noCompletion var __au:Array<tink.core.Callback<tink.core.Noise>> = [];

    @:extern inline function afterUpdating(callback:Void->Void) __au.push(callback);

    function forceUpdate(?callback) {
      _coco_revision.set(_coco_revision.value + 1);
      if (callback != null) afterUpdating(callback);
    }
  }
}

private typedef Config = {
  final renders: ComplexType;
  final afterBuild:PostProcessor;
}
#end
