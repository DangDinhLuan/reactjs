$ ->
  # Update campaigns start_on
  $(".js-update-campaigns-start-on").on "click", (event) ->
    event.preventDefault()
    ids = $(".js-checkbox-single:checked").map((_, elem) -> $(elem).val()).get()
    $.ajax
      dataType: "json"
      type: "PATCH"
      data: {ids: ids}
      url: "/admin/batch/campaigns/publish"

      success: (data) ->
        $(".js-checkbox-single:checked").each ->
          current_tr = $(@).closest("tr")
          current_tr.find(".js-campaign-status").html("<i class='fa fa-circle green'></i>")
          period_kind = current_tr.find(".period-kind").data("period-kind")

          if(period_kind == "temporary")
            current_tr.find(".js-start-on-date").html(data.date)
            current_end_on = current_tr.find(".js-end-on-date")
            if(new Date(current_end_on.html()).getTime() <= new Date(data.date).getTime())
              current_end_on.html("")

      error: (response) ->
        show_error_message response.responseJSON.message

  # Update campaigns end_on
  $(".js-update-campaigns-end-on").on "click", (event) ->
    event.preventDefault()
    ids = $(".js-checkbox-single:checked").map((_, elem) -> $(elem).val()).get()
    $.ajax
      dataType: "json"
      type: "PATCH"
      data: {ids: ids}
      url: "/admin/batch/campaigns/unpublish"

      success: (data) ->
        $(".js-checkbox-single:checked").each ->
          current_tr = $(@).closest("tr")
          current_tr.find(".js-campaign-status").html("<i class='fa fa-circle red'></i>")
          period_kind = current_tr.find(".period-kind").data("period-kind")

          if(period_kind == "temporary")
            current_tr.find(".js-end-on-date").html(data.date)
            current_start_on = current_tr.find(".js-start-on-date")
            if(new Date(current_start_on.html()).getTime() > new Date(data.date).getTime())
              current_start_on.html("")

      error: (response) ->
        show_error_message response.responseJSON.message

  show_error_message = (message) ->
    $("#js-error-mess div, .alert.fade.in").remove()
    $("#js-error-mess").append(
      "<div class='alert alert-danger fade in'><button class='close'data-dismiss='alert'>×</button>#{message}</div>"
    )
