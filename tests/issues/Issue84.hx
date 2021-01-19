package issues;

class Issue84 extends View {
  @:attr function renderChildren(outcome:Outcome<Int, String>) '
    <div>
      <switch ${outcome}>
        <case ${Success(v)}>$v
        <case ${Failure(e)}>$e
      </switch>
    </div>
	';

	function render() return renderChildren(Success(1));
}