document.addEventListener("turbo:load", function () {
  console.log('test')
  const hash = window.location.hash;
  hash && $('ul.nav a[href="' + hash + '"]').tab('show');

  $('.nav-tabs a').click(function (e) {
    $(this).tab('show');
    window.location.hash = this.hash;
  });
})
