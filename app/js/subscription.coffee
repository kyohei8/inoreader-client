$(->

  $('input[name="type"]').on('change', ->
    type = $('input[name="type"]:checked').val();
    if type is 'e'
      ($ '#edit-subscription-feed').removeAttr('disabled');
      ($ 'input[id^=edit-subscription').removeAttr('disabled', '');

      ($ '#edit-subscription-new').attr('disabled', '');
    else if type is 'u'
      ($ 'input[id^=edit-subscription').attr('disabled', '');
    else
      #subscribe
      ($ '#edit-subscription-feed').attr('disabled', '');
      ($ '#edit-subscription-new').removeAttr('disabled');
      #($ 'input[id^=edit-subscription').attr('disabled', '');
  )

)
