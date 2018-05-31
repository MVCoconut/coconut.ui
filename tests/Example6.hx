class Example6 extends View {
  @:attribute var children:coconut.ui.Children;
  function render() '
    <div>{...children}</div>
  ';
}