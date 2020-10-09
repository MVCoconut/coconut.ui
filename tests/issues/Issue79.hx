package issues;

import tink.CoreApi;

class Issue79 extends View {
  @:loaded var foo:String = Promise.resolve('foo');
  function render() '<div />';
}