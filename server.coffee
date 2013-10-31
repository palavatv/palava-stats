#!/usr/bin/env coffee
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

MongoClient = require('mongodb').MongoClient
app = require('express')()

MongoClient.connect 'mongodb://localhost/plv_stats', (err, db) =>
  if err then throw err

  coll = db.collection 'rtc'

  # stat helper

  add_map_reduce_stat = (name, map, reduce) =>
    path = '/stats/' + name + '.json'

    page_fun = (req, res) =>
      get_int = (key, fallback) =>
        if req.param(key)?
          return parseInt(req.param(key))
        else
          return fallback

      start = get_int('start', 0)
      end = get_int('end', Number.MAX_VALUE)

      scope = {}

      scope.start = start

      if req.param('steps')
        scope.steps = JSON.parse(req.param('steps'))

        if not scope.steps instanceof Array
          res.send({'error': "steps should be a JSON array"})
          return

      scope.scale = get_int('scale', 0)

      scope.min_time = get_int('min_time', 0)
      scope.max_time = get_int('max_time', Number.MAX_VALUE)

      scope.min_peak = get_int('min_peak', 0)
      scope.max_peak = get_int('max_peak', Number.MAX_VALUE)

      scope.adjust_time = (time) =>
        if scale
          return time - time % scale
        else if steps?
          last = start
          for step in steps
            if step <= time
              return step
        else
          return time

      options =
        out:
          inline: 1
        scope: scope
        query:
          c_at:
            $gte: start,
            $lt: end,

      coll.mapReduce map, reduce, options, (err, result) =>
        if err
          res.send({error: err})
          return

        data = {}

        for item in result
          data[item._id] = item.value

        res.send data

    app.get path, page_fun
    app.post path, page_fun

  # stat helpers

  add_objects = (key, values) =>
      result = {}
      for item in values
        for key, value of item
          if result[key]?
            result[key] += value
          else
            result[key] = value
      return result

  # actual stat functions

  add_map_reduce_stat 'count_rooms',
    # map
    () ->
      count = 0
      for peak, amount of @room_peaks
        if peak >= min_peak and peak < max_peak
          count += parseInt(amount)
      emit(adjust_time(@c_at), count)
    # reduce
    (key, values) ->
      return Array.sum(values)

  add_map_reduce_stat 'count_users',
    # map
    () ->
      count = 0
      for time, amount of @connection_time
        if time >= min_time and time < max_time
          count += parseInt(amount)
      emit(adjust_time(@c_at), count)
    # reduce
    (key, values) ->
      return Array.sum(values)

  add_map_reduce_stat 'user_times',
    # map
    () ->
      times = {}
      for key, value of @connection_time
        times[key] = parseInt(value)
      emit(adjust_time(@c_at), times)
    # reduce
    add_objects

  add_map_reduce_stat 'room_peaks',
    # map
    () ->
      peaks = {}
      for key, value of @room_peaks
        peaks[key] = parseInt(value)
      emit(adjust_time(@c_at), peaks)
    # reduce
    add_objects

  console.log "Ready for action"

app.listen(3000)