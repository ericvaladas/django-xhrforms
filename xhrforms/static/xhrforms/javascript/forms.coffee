
## Form Helpers

# XhrForm
#
# This file will perform the legwork for submitting and displaying errors on
# any form with a data-xhr attribute. The value of data-xhr will determine the
# behavior. Current options: "submit", "blur"
#
# It assumes the form is rendered using the bootstrap-friendly as_basic
# method for the core.forms.BasicForm mixin.
#
# The view on the other side of the action url should
# core.views.generic.BasicFormView.

$ ->
  for form in $('form[data-xhr]') then do ->
    $form = $(form)
    type = $form.data 'xhr'
    method = $form.attr 'method'
    url = $form.attr 'action'

    if type == 'submit'
      $form.on 'submit', (e)->
        e.preventDefault()
        xhr = $.ajax type: method, url: url, data: $form.serialize(), dataType: 'text'
        xhr.always ->
          if xhr.status == 200
            $form.trigger 'success', xhr

            if $form.data 'xhr-success-url'
              document.location = $form.data 'xhr-success-url'

            else if $form.data('xhr-success') == 'refresh'
              document.location = document.location.href

            else if $form.data('xhr-success') == 'alert'
              $form.find('.alert-saved').hide()
              $form.find('[type=submit]').after "
                  <div class='alert alert-success alert-saved'>Saved</div>"
              setTimeout (-> $('.alert-saved').fadeOut()), 7000

            else if $form.data('xhr-success') == 'modal' and $form.data 'xhr-modal'
              $($form.data('xhr-modal')).modal()

          else if xhr.status == 500
            return

          else
            displayFormErrors $form, JSON.parse(xhr.responseText), true

    else if type == 'blur'
      $form.on 'blur', '[name]', (e)->
        e.preventDefault()
        $field = $(this)

        data =
          'inline_submit': 'true'
          'fields': {}
        data.fields[$field.attr('name')] = $field.attr('value')
        data = JSON.stringify data

        xhr = $.ajax
          type: method,
          url: url,
          data: data,
          dataType: 'text',
          headers: {'X-CSRFToken': $form.find('[name=csrfmiddlewaretoken]').val()}
        xhr.always ->
          if xhr.status == 200
            $control = $field.closest('.form-group')
            $control.addClass 'has-success'
            $control.find('.help-block:not(.has-error)').show()
            $control.find('.help-block.has-error').remove()
          else
            $field.closest('.form-group').removeClass 'has-success'
            displayFormErrors $form, JSON.parse(xhr.responseText).errors, false

displayFormErrors = ($form, errors, remove)->
  $form.find('.alert-error').remove()
  if errors.hasOwnProperty '__all__'
    $form.find('.form-group').first().before "<div class='alert alert-error'>#{errors.__all__}</div>"

  for field in $form.find('[name]')
    $control = $(field).closest('.form-group')
    $control.removeClass 'has-error'
    $control.find('.help-block:not(.has-error)').show()
    $control.find('.help-block.has-error').remove()

  for field in $form.find('[name]')
    $field = $(field)
    name = $field.attr 'name'
    $control = $field.closest('.form-group')

    if errors.hasOwnProperty name
      $control.removeClass 'has-success'
      $control.addClass 'has-error'
      $field.removeClass 'has-success'
      $field.addClass 'has-error'
      $control.find('.help-block:not(.has-error)').hide()
      $control.children('div').append "<span class='help-block has-error'>#{errors[name]}</span>"

  $form.find('[type=submit],input.submit').prop 'disabled', false
