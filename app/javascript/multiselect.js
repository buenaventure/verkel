require('select2')

document.addEventListener("turbo:load", function () {
  $('.select2').select2({
    theme: 'bootstrap-5',
  });
})
