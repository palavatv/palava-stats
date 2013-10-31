###############################################################################
#
#  palava stats - Statistics monitor for palava
#  Copyright (C) 2013  Stephan Thamm
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

$ () =>
  timed_array = (object) =>
    array = []

    for time, count of object
      array.push([time * 1000, count])

    return array

  dateFormatter = (v) => new Date(v).toLocaleDateString()

  modes =
    "User Count":
      url: "/stats/count_users.json"
      unit: "users/day"
      convert: timed_array
      mode: 'time'
      toolFormat: dateFormatter
      options:
        min_time:
          name: "Minimum Minutes"
          value: 1
          active: true
        max_time:
          name: "Maximum Minutes"
          value: 10
          active: false
        scale:
          value: 60*60*24
          static: true
        scale_shift:
          value: 60*60
          static: true

    "Room Count":
      url: "/stats/count_rooms.json"
      unit: "rooms/day"
      convert: timed_array
      mode: 'time'
      toolFormat: dateFormatter
      options:
        min_peak:
          name: "Minimum Participants"
          value: 2
          active: true
        max_peak:
          name: "Maximum Participants"
          value: 5
          active: false
        scale:
          value: 60*60*24
          static: true
        scale_shift:
          value: 60*60
          static: true

    "User Time Spent":
      url: "/stats/user_times.json"
      unit: "user(s)"
      bars: true
      convert: (raw) =>
        if not raw[0]?
          return []

        ranges = {}

        for time, amount of raw[0]
          if time == '0'
            key = -1
          else
            key = Math.floor(Math.log(time)/Math.LN2)

          if ranges[key]?
            ranges[key] += amount
          else
            ranges[key] = amount

        console.log ranges

        array = []

        for range, amount of ranges
          array.push([range, amount])

        console.log(array)

        return array
      tickFormat: (v) =>
        if v == -1
          return 0
        else
          Math.pow(2, v)
      toolFormat: (v) =>
        if v == -1
          return "0 minutes"
        else if v == 0
          return "1 minute"
        else
          from = Math.pow(2, v)
          to = Math.pow(2, v + 1) - 1
          return from + " to " + to + " minutes"
      options:
        steps:
          value: "[0]"
          static: true
        min_time:
          name: "Minimum Minutes"
          value: 1
          active: true
        start:
          name: "Start of timespan (timestamp)"
          value: new Date().getTime() / 1000 - 60*60*24*7
          active: false
        end:
          name: "End of timespan (timestamp)"
          value: new Date().getTime() / 1000
          active: false

    "Room Peaks":
      url: "/stats/room_peaks.json"
      unit: "room(s)"
      bars: true
      convert: (raw) =>
        if not raw[0]?
          return []

        array = []

        for peak, amount of raw[0]
          array.push([peak, amount])

        return array
      toolFormat: (v) => v + " peak user(s)"
      options:
        steps:
          value: "[0]"
          static: true
        min_peak:
          name: "Minimum Peak"
          value: 2
          active: true
        start:
          name: "Start of timespan (timestamp)"
          value: new Date().getTime() / 1000 - 60*60*24*7
          active: false
        end:
          name: "End of timespan (timestamp)"
          value: new Date().getTime() / 1000
          active: false

  heading = (text) => $('#heading').text(text)

  $.each modes, (name, data) =>
    div = $('<div class="mode">')

    caption = $('<h2>')
    caption.text(name)
    div.append(caption)

    content = $('<div class="content">')
    div.append(content)

    form = $('<form>')
    content.append(form)

    $.each data.options, (option, data) =>
      if data.static
        return

      item = $('<div class="item">')

      label = $('<span class="label">')
      label.text(data.name)
      item.append(label)

      active = $('<input type="checkbox">')
      active.prop 'checked', data.active
      item.append(active)

      input = $('<input type="text">')
      input.val(data.value)
      input.attr('name', option)
      item.append(input)

      form.append(item)

      active.change () =>
        input.prop 'disabled', !active.prop('checked')
      active.change()

    submit = $('<input type="submit" value="Show Graph">')
    form.append(submit)

    form.submit () =>
      try
        submit.prop 'disabled', true

        params = {}

        for option, spec of data.options
          if spec.static
            params[option] = spec.value
          else
            input = form.find('input[name=' + option + ']')

            if not input.prop 'disabled'
              console.log 'adding ' + option
              params[option] = input.val()

        $.getJSON data.url, params, (raw_data) =>
          submit.prop 'disabled', false
          heading name

          array = data.convert raw_data

          options =
            xaxis:
              tickLength: 5
              mode: data.mode
              tickFormatter: data.tickFormat
            grid:
              hoverable: true

          data_source =
            data: array

          if data.bars
            data_source.bars = { show: true }
          else
            data_source.lines = { show: true }

          $.plot $("#placeholder"), [data_source], options

          last_tooltip = undefined

          $("#placeholder").bind "plothover", (event, pos, item) =>
            if item?
              if last_tooltip != item.dataIndex
                $('#tooltip').remove()

                last_tooltip = item.dataIndex

                tooltip = $('<div id="tooltip">')
                tooltip.css 'left', item.pageX + 5
                tooltip.css 'top', item.pageY - 5

                toolFormat = data.toolFormat ? (v) => v
                label_text = toolFormat item.datapoint[0]

                label = $('<div id="date">')
                label.text  label_text + ":"
                tooltip.append label

                value = $('<div id="value">')
                value.text item.datapoint[1] + " " + data.unit
                tooltip.append value

                $('html').append tooltip
            else
              $('#tooltip').remove()
              last_tooltip = undefined
      catch e
        console.log e
        console.log e.stack

      return false

    $('#ui').append(div)

  $('.mode:first form').submit()

