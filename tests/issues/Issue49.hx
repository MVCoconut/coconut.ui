package issues;

class Issue49 extends View {
  @:attribute var title:String;
  @:attribute var click:Void->Void;
  @:attribute var child:Void->RenderResult = emptyChild;

  function emptyChild() '<span>DEFAULT</span>';

  function render() '
    <a href="#"
      class="button button-outline"
      onclick={click}
    >
      {title}
      {child()}
    </a>
  ';
}