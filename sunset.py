#!/usr/bin/python
import datetime
from astral import Astral
city_name = 'Minneapolis'
today = datetime.datetime.now()

a = Astral()
a.solar_depression = 'civil'
city = a[city_name]
sun = city.sun(date=today, local=True)
print sun['sunset'].strftime('%s')
