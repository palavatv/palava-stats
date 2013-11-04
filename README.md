# palava stats

## About

This tool displays the statistics generated by palava-machine. We try to
collect as few information as possible. The statistics are available through a
web interface.

## Usage

Install with the following commands

	# initialize support (submodules, build, ...)
	./setup.sh

	# install dependencies
	npm install

To run the server simply use the start script

	./start.js

After this just open the webinterface in your favorite browser. The port which
is used is displayed as soon as the app is ready.

The application is configured through environment variables. Here is an example
on how to configure the port on which the app listens

	export BIND_PORT=8080

The following variables are available

* `BIND_PORT`: port on which the webinterface listens (default: 3000)
* `BIND_HOST`: host on which the webinterface binds (default: 0.0.0.0)
* `MONGO_HOST`: address of the mongodb server (default: localhost)
* `MONGO_DB`: database in which the data is stored (default: plv\_stats)

## Collected Data

**Important**: This section describes the date collected by palava-machine. Your
web server might collect much more data which is most probably not anonymized!
Please configure your server log in a way which respects users privacy.

The following data is collected by palava-machine:

* How many users spent how many minutes in a room in one hour
* How many rooms had which maximum size in one hour

Each data point represents sums over one hour.

Room names, user names, IP addresses etc. are not saved and there is no
connection between the user stats and the room stats. Users entering multiple
rooms times will be counted each time.

A sample of the collected data might look like this

	connection_time": { "0": 1, "5": 2, "7": 1 },
	"room_peaks": { "1": 1, "3": 1 }

That means there was one user staying 0 minutes (under 1 minute), two users
staying 5 minutes and one user staying 7 minutes. They used two rooms, one with
a size of 1 user and one with a size of 3 users.

Room stats and user stats will not always add up that easily. Users might
leave the room and later be replaced by another user, which will not increase
the maximum size reached in this room.

## TODOs

* make the interface useable
* add design
* ability to zoom into graphs
* add more graphs
	* punch cards
	* ..

