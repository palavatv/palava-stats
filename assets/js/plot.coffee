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
  modes =
    "User Count":
      url: "/stats/count_users.json"
      unit: "users/day"
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
            input = $('input[name=' + option + ']')

            if not input.prop 'disabled'
              params[option] = input.val()

        $.getJSON data.url, params, (raw_data) =>
          submit.prop 'disabled', false
          heading name

          array = []

          for time, count of raw_data
            array.push([time * 1000, count])

          options =
            xaxis:
              tickLength: 5
              mode: "time"
            grid:
              hoverable: true

          $.plot $("#placeholder"), [{data: array, lines: { show: true}}], options

          last_tooltip = undefined

          $("#placeholder").bind "plothover", (event, pos, item) =>
            if item?
              if last_tooltip != item.dataIndex
                $('#tooltip').remove()

                last_tooltip = item.dataIndex

                tooltip = $('<div id="tooltip">')
                tooltip.css 'left', item.pageX + 5
                tooltip.css 'top', item.pageY + 5

                date = new Date item.datapoint[0]

                label = $('<div id="date">')
                label.text date.toLocaleDateString() + ":"
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

