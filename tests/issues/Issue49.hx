package issues;

class Issue49 {
  static public function buttons() {
    var data = [{title: "test", click: () -> trace("yo")}];
    return coconut.Ui.hxx('<Buttons buttons={data} />');
  }
}

typedef ButtonInfo = {
  title:String,
  click:Void->Void,
  ? child:Void->RenderResult
}

class Buttons extends View {
  @:skipCheck
  @:attribute var buttons:Array<ButtonInfo>;

  function render() '
    <div>
      <for {b in buttons}>
        <MyButton {...b} />
      </for>
    </div>
  ';

}

class MyButton extends View {
  @:attribute var title:String;
  @:attribute var click:Void->Void;
  @:attribute var child:Void->RenderResult = emptyChild;

  function emptyChild()
    '<span>DEFAULT</span>';

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