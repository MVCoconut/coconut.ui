package views;

class Wrapper extends View {

  @:state var key:Int = 0;
  @:attribute var depth:Int;

	function render() '
    <if {depth == 0}>
      <div key=${key} onclick=${key++}>Key: $key</div>
    <else>
      <Wrapper depth={depth - 1} />
    </if>
  ';
}