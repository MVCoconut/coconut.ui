package ;

import js.Browser.*;

class RunTests {

  static function main() {
    travix.Logger.exit(
      try {
        document.body.appendChild(new Example({ foo: 4 }).toElement());
        if (document.querySelector('body>div>h1').innerHTML != '4')
          throw 'test failed';
        0;
      }
      catch (e:Dynamic) {
        travix.Logger.println(Std.string(e));
        500;
      }
    ); 
  }
  
}

class Example extends coconut.ui.View<{ foo: Int }> {
  function render() '
    <div>
      <h1>{foo}</h1>
    </div>
  ';
}