import $ from 'jquery'
import DataTable from 'datatables.net-bs5'
import 'datatables.net-fixedcolumns-bs5'
import 'datatables.net-fixedheader-bs5'

// DataTables 3 dropped its jQuery dependency, so it has to be handed the
// jQuery instance webpack provides for the $().DataTable() calls below to work.
DataTable.use($)

$.extend(true, DataTable.defaults, {
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
  $('#group-spendings-table').DataTable({
    order: [],
  });
})
