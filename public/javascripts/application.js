$(document).ready(function(){
  $("form.delete").submit(function(event){
    event.preventDefault();
    event.stopPropagation();

    // confirm returns true or false
    var ok = confirm("Are you sure?");  
    if (ok) {
      // this.submit();

      var form = $(this);

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove();  
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
        
      }); 
    }
  });
});