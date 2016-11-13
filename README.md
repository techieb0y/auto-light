# Turning a light on at sundown, the hard way

For several years, I worked in a cubicle in a mostly-windowless room in an office that was staffed 24x7; the overhead lights were on pretty much all the time, and the passage of the seasons outside had little impact. Then in mid-2015 I relocated to an office with its own large south-facing window. The transition away from Daylight Saving time made the effect of that one-hour shift suddenly more apparant, and I decided I wanted a light to come on shortly before it got dark outside, and to turn off automatically when I left for the day (regardless of how late I was working).

I had a few requirements:

 * It couldn't require rewiring or other alterations of existing fixtures
 * I wanted something reasonably self-contained; a separate hub was undesirable
 * Wired network ports weren't available
 * Internet access would have to play nice with the guest WiFi

A "smart" LED lightbulb in a plain desk lamp looked like it was be best approach here; bulbs from [LIFX](http://www.lifx.com/), looked like the best option, so I ordered one. As an added bonus, this allows for the possibility of color-temp adjustments (as in [F.lux](https://justgetflux.com/)).

Ordinarily I'd prefer a no-cloud solution, but getting any kind of direct external access to the bulb or special DHCP configuration wasn't going to happen on my office network. [LIFX's API](https://api.developer.lifx.com/) looked like it would be a good middle ground. I signed up for a developer account an generated an API key, and waited for the bulb to arrive.

The bulb I was shipped came with v1 firmware, which it turns out doesn't work with the API. To make things worse, I found my phone wouldn't pair with the bulb, preventing me from controlling it at all (much less updating the firmware). However, my tablet would pair with the bulb, and after a couple (very slow) tries, the firmware updated and I could then see the bulb associated with my account in the API (and it paired happily with my phone, too!)

The next hurdle was programatic control -- IFTTT had built-in integrations with LIFX for turning on at sunset, but had no way to do so conditionally, so I'd have to do that part myself. (IFTTT has since added some features along those lines with Applets.)

The first problem to tackle was calculation of sunset - there are some formulas for that, and a handy Python library called [astral](https://pythonhosted.org/astral/). A quick [wrapper](sunset.py) around that gets me the time of local civil twilight in UNIX time.

Since civil twilight varies throughout the year, we can't just use `cron` to make things happen, but we can use `at`. Unfortunately, it seems that UNIX time isn't something that `at` can easily use a time specification, so some hackery was required. A `cron` job on an external VM runs at 4am on weekdays and runs [a script](setup-lifx.sh) which gets the civil twilight time, subtracts from the current UNIX time, divides by 60, and invokes `at` with an 'now + X minutes' specification. 

The next part is to determine if I'm actually in the office. It's safe to assume that if my laptop is in the office, then so am I, so we'll use that as a proxy. Ordinarily I'd just give the laptop a static DHCP reservation and ping it from Nagios, but my Nagios at home can't see into the office network, so an alternative is required. Here, I set up a cron job to run [a script](light-ping.sh) every couple minutes. Rather than have to learn how to use Apple's Core Location API, I use the wired interface's IP address and MAC address of the default gateway to decide if the laptop is in the office. If the script decides that I am, it makes a simple HTTP `GET` request to a [matching script](heartbeat.php) on my server, which generates a Nagios external host check result with a status of `UP`.

There isn't a great way for an external script to query a hosts's status from Nagios, so the next best thing is to enable host obsession, and write the current status into a per-host file. When `at` fires at sunset, this per-host file is checked for the `UP` string, and if found, calls out to the Lifx API to fade up the bulb. Voila, light!

Turning the light off in the evening is easier: within Nagios, the host definition for my laptop is set for freshness checking to be enabled, with a 3-minute timeout. When the freshness timout expires, an otherwise-disabled active check is run, and the check command for the host will always return a status of `DOWN`. This triggers a Nagios event handler which runs the same [control script](control-lifx.sh), and the API is called to fade the light down.

The Lifx API has been quite stable, but every once in a while the bulb will stop talking to it, so there's also a Nagios host definition for the bulb, with a [check command](check_lifx.php) to make sure the API has heard from the bulb recently. A power cycle of the bulb has (so far) always gotten it to reconnect. 

File summary:

* check_lifx.php: Check for recent bulb checkin to the LIFX API
* commands-local.cfg: Nagios command definitions
  * update-statfile: Write each host's state to a file
  * check-lifx: hook for calling check_lifx.php
  * control-lifx: hook for calling control-lifx.sh
* control-lifx.sh: Script to actually call out to the LIFX API.
* heartheat.php: Recieve pings from cron and submit passive check result to nagios
* light-ping.sh: cron script to determine in-office state and send pings
* nagios.cfg: snippets of required Nagios global config
* setup-lifx.sh: Cron job run at 4am to calcualte sunset time and set `at` job.
* sunset.py: Python wrapper around `astral.py` to compute sunset
* work-lifxbulb.cfg: Nagios config for the bulb itself and checks of the API endpont.
* work-macbook.cfg: Nagios config for my work laptop and associated event handler.

