package ;

class RunTests {

  static function main() {
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}

class Example extends coconut.ui.View<{ foo: Int }> {
  function render() '
    <div>{foo}</div>
  ';
}