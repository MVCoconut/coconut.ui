package views;

class MyView extends View {
  function render() '
    <switch ${int()}>
      <case ${0}>
        <div>Zero</div>
      <case ${1}>
        <div>One</div>
      <case ${_}>
        <div>Default</div>
    </switch>
  ';

  function int() return 1;
}