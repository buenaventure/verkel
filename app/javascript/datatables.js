require('datatables.net-bs5')
require('datatables.net-fixedcolumns-bs5')
require('datatables.net-fixedheader-bs5')

$.extend(true, $.fn.dataTable.defaults, {
  fixedHeader: true,
  paging: false,
  language: {
    search: "Suche"
  }
});

document.addEventListener("turbo:before-cache", function () {
  $('.dataTable').DataTable().destroy();
});

document.addEventListener("turbo:load", function () {
  $('#ingredients-table').DataTable({
    order: [[0, 'asc'], [1, 'asc']],
  });
  $('#articles-table').DataTable({
    order: [[0, 'asc'], [1, 'asc']],
  });
  $('#participants-table').DataTable();
  $('#orders-table').DataTable();
})
