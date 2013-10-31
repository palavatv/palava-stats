$ () =>
  $.getJSON 'stats/count_users.json', { scale: 60*60*24, min_time: 1 }, (data) =>
    array = []

    for time, count of data
      array.push([time * 1000, count])

    array.sort()

    console.log array

    $.plot $("#placeholder"), [{data: array, lines: { show: true}}], {xaxis: { tickLength: 5, mode: "time" }}
