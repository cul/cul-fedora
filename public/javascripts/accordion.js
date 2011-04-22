$(document).ready(function() {
  $('#facets h3').next("ul, div").each(
    function(){
      var f_content = $(this);
      $(f_content).prev('h3').addClass('toggle');
      // find all f_content's that don't have any span descendants with a class of "selected"
      if($('span.selected', f_content).length == 0){
        // hide it
        f_content.hide();
        $(f_content).prev('h3').addClass('collapsed');
      } else {
        $(f_content).prev('h3').addClass('expanded');
      }
      // attach the toggle behavior to the h3 tag
      $(f_content.parent().children('.toggle')).click(
        function(){
          // toggle the content
          if ($(this).hasClass('expanded')) {
            $(this).removeClass('expanded');
            $(this).addClass('collapsed'); 
          } else {
            $(this).removeClass('collapsed');
            $(this).addClass('expanded'); 
          }
          $(this).next('ul, div').slideToggle();
        });
    });
});
