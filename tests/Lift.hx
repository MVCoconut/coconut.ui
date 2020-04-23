package ;

#if coconut.vdom
class VDomViews {
  static public function lift(view:coconut.vdom.View):coconut.vdom.RenderResult {
    return view;
  }
}
#end

#if react
class ReactViews {
  static public function lift(view:coconut.react.View):coconut.react.RenderResult {
    return view.reactify();
  }
}
#end