package issues;

import tink.CoreApi;

class Issue79 extends View {
  @:loaded var foo:String = Promise.resolve('foo');
  function render() '
    <switch ${foo}>
      <case ${Loading}>Loading
      <case ${Done(v)}>$v
      <case ${Failed(e)}>${e.toString()}
    </switch>
  ';
}