package views;

class Example6 extends View {
  @:attribute var children:Children;
  function render() '
    <div>{...children}</div>
  ';
}