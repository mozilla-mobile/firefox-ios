(function() {
  // The benchmarks that we want to display, in the order they should appear
  // on the plot axis.
  var benchmarks = [
    'New message', 'Populate fields',
    'Populate fields with with',
    'Encode binary', 'Decode binary',
    'Encode JSON', 'Decode JSON',
    'Encode text', 'Decode text',
    'Equality',
  ];

  // The harnessSize keys we want to print in the summary table, in the order
  // they should be displayed.
  var harnessSizeKeys = ['Unstripped', 'Stripped'];

  // Common layout properties for the plot.
  var layout = {
    boxmode: 'group',
    xaxis: {
      showgrid: false,
      showline: false,
      autotick: true,
      ticks: 'outside',
    },
    yaxis: {
      title: 'Runtime (&mu;s)',
      autorange: true,
    },
    margin: {
      l: 60,
      r: 60,
      t: 0,
      b: 60,
    },
    font: {
      family: 'Helvetica',
    },
    hovermode: 'closest',
    legend: {
      font: {
        size: 12,
      },
      yanchor: 'middle',
      xanchor: 'right',
    },
  };

  // Creates and return a series for the given language's results in a session.
  function createSeries(session, series) {
    var x = [];
    var y = [];

    // The x-axis is categorical over the benchmark names. Adding the same
    // benchmark multiple times will collapse all the points on the same
    // vertical, which is what we want.
    for (var i = 0; i < benchmarks.length; i++) {
      var benchmark = benchmarks[i];
      var timings = series.data[benchmark];
      if (timings) {
        for (var j = 0; j < timings.length; j++) {
          x.push(benchmark.replace(" ", "<br>"));
          y.push(timings[j]);
        }
      }
    }

    return {
      name: series.name,
      x: x,
      y: y,
      type: 'box',
      boxpoints: 'all',
      whiskerwidth: 0.5,
      pointpos: 0,
      jitter: 0.3,
      mode: 'marker',
      marker: {
        symbol: 'circle',
        size: 8,
        opacity: 0.6,
      },
      line: {
        width: 1,
      },
    };
  }

  // Computes and returns the median of the given array of values.
  function median(values) {
    values.sort(function(a,b){return a - b});
    var mid = Math.floor(values.length / 2);
    if (values.length % 2) {
      return values[mid];
    } else {
      return (values[mid - 1] + values[mid]) / 2.0;
    }
  }

  // Decorate a cell with the an appropriate background based
  // on the magnitude of the multiplier.
  function decorateMultiplierCell(cell, multiplier) {
    if (multiplier == 1) {
      // Decorate the best case with green
      cell.addClass('bg-success');
    } else if (multiplier < 3) {
      // < 3: Leave this cell white
    } else if (multiplier < 10) {
      // 3 - 10: Mark this cell yellow
      cell.addClass('bg-warning');
    } else {
      // > 10: Mark this cell red
      cell.addClass('bg-danger');
    }
  }

  // Creates and returns the summary table displayed next to the chart for a
  // given session.
  function createSummaryTable(session) {
    var table = $('<table></table>').addClass('table table-condensed numeric');
    var tbody = $('<tbody></tbody>').appendTo(table);

    // Insert the runtime stats.
    var header = $('<tr></tr>').appendTo(table);
    header.append($('<th>Median runtimes</th>'));
    for (var j = 0; j < session.series.length; j++) {
      header.append($('<th colspan="2"></th>').text(session.series[j].name));
    }

    for (var i = 0; i < benchmarks.length; i++) {
      var benchmark = benchmarks[i];
      var tr = $('<tr></tr>')
      table.append(tr);
      tr.append($('<td></td>').text(benchmark));

      // Compute the median time for each language,
      // Track which language was the fastest
      var timings = [];
      var bestLanguage = 0;
      for (var j = 0; j < session.series.length; j++) {
        var languageTimings = session.series[j].data[benchmark];
        if (languageTimings) {
          var med = median(languageTimings);
          timings.push(med);
          if (med < timings[bestLanguage]) {
            bestLanguage = j;
          }
        }
      }

      // Insert the per-language timings into the table
      var bestValue = timings[bestLanguage];
      for (var j = 0; j < session.series.length; j++) {
        var med = timings[j];
        var valueCell = $('<td></td>').appendTo(tr);
        var multiplierCell = $('<td></td>').appendTo(tr);
        if (med) {
          var formattedMedian = med.toFixed(3) + '&nbsp;&micro;s';
          valueCell.html(formattedMedian);
          var multiplier = med / bestValue;
          decorateMultiplierCell(valueCell, multiplier);
          if (j != bestLanguage) {
              multiplierCell.text('(' + multiplier.toFixed(1) + 'x)');
          }
          decorateMultiplierCell(multiplierCell, multiplier);
        }
      }
    }

    // Insert the binary size stats.
    header = $('<tr></tr>').appendTo(table);
    header.append($('<th>Harness size</th>'));
    for (var j = 0; j < session.series.length; j++) {
      header.append($('<th></th>'));
      header.append($('<th></th>'));
    }

    for (var i = 0; i < harnessSizeKeys.length; i++) {
      var harnessSizeKey = harnessSizeKeys[i];
      var tr = $('<tr></tr>')
      table.append(tr);
      tr.append($('<td></td>').text(harnessSizeKey));

      var bestLanguage = 0;
      var sizes = [];
      for (var j = 0; j < session.series.length; j++) {
          var size = session.series[j].data.harnessSize[harnessSizeKey];
          sizes.push(size);
          if (size < sizes[bestLanguage]) {
              bestLanguage = j;
          }
      }

      for (var j = 0; j < session.series.length; j++) {
        var size = sizes[j];
        var multiplier = size / sizes[bestLanguage];
        var formattedSize = size.toLocaleString() + '&nbsp;b';
        var valueCell = $('<td></td>').html(formattedSize).appendTo(tr);
        decorateMultiplierCell(valueCell, multiplier);

        var multiplierCell = $('<td></td>').appendTo(tr);
        if (j != bestLanguage) {
            multiplierCell.text('(' + multiplier.toFixed(1) + 'x)');
        }
        decorateMultiplierCell(multiplierCell, multiplier);
      }
    }

    var tfoot = $('<tfoot></tfoot>').appendTo(table);
    var footerRow = $('<tr></tr>').appendTo(tfoot);
    var colspan = 3 * session.series.length + 1;
    var footerCell =
        $('<td colspan="' + colspan + '"></td>').appendTo(footerRow);
      footerCell.text('Green highlights the best result for each test. ' +
                      'Multipliers indicate how much worse ' +
                      '(slower/larger) a particular result is ' +
                      'compared to the best result.');

    return table;
  }

  $(function() {
    if (!window.sessions) {
      return;
    }

    // Iterate the sessions in reverse order so that the most recent ones
    // appear at the top. We create one chart for each session and tile them
    // down the page.
    for (var i = sessions.length - 1; i >= 0; i--) {
      var session = sessions[i];
      var allSeries = [];

      formattedDate =
          moment(new Date(session.date)).format('MMM Do h:mm:ss a');
      var title = session.type;
      var header = $('<h3></h3>').addClass('row').text(title);

      var subtitle = 'Working tree was at <tt>' + session.branch +
          '</tt>, commit <tt>' + session.commit.substr(0, 6) + '</tt>';
      if (session.uncommitted_changes) {
        subtitle += ' (with uncommited changes)';
      }
      subtitle += ' &ndash; ' + formattedDate;

      header.append($('<small></small>').html(subtitle));
      $('#container').append('<hr>');
      $('#container').append(header);

      var id = 'chart' + i;
      var row = $('<div></div>').addClass('row');
      var chartColumn = $('<div></div>').addClass('col-md-8');
      var tableColumn = $('<div></div>').addClass('col-md-4');

      row.append(chartColumn);
      row.append(tableColumn);
      $('#container').append(row);

      var chart = $('<div></div>').attr('id', id).addClass('chart');
      chartColumn.append(chart);

      for (var j = 0; j < session.series.length; j++) {
        var series = createSeries(session, session.series[j]);
        allSeries.push(series);
      }

      Plotly.newPlot(id, allSeries, layout, {
        displayModeBar: false,
      });

      var table = createSummaryTable(session);
      tableColumn.append(table);
    }

    window.onresize = function() {
      $('.chart').each(function() {
        Plotly.Plots.resize(this);
      });
    };
  });
})();
