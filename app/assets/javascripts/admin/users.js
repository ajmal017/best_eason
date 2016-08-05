  function setCompanyUser(user_id){
    $.post("/admin/users/" + user_id + "/set_company_user", {}, function(data){
      window.location.reload();
    })
  }

  function cancelCompanyUser(user_id){
    $.post("/admin/users/" + user_id + "/cancel_company_user", {}, function(data){
      window.location.reload();
    })
  }