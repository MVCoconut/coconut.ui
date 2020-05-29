package coconut.ui;

class Isolated extends View {
  @:attribute var children:Children;
  function render() '<>${...children}</>';
}
