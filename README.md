# xbox-status-api

I hacked this together while waiting for Microsoft to fix Xbox Live logins so I could play Titanfall. It's pretty janky and just scrapes their status site, but it works pretty well so far.

# Usage

This is currently running on Heroku at http://xbox-status-api.herokuapp.com/. *Note that this is not a production deployment, so plan accordingly.* You can give it a spin like this:

`curl -i http://xbox-status-api.herokuapp.com/`

It returns a JSON payload that looks like this:

```json
{
  "services": [{
    "name": "Xbox Live Core Services",
    "status": "unavailable",
    "affected": {
      "platforms": [{
        "name": "Xbox One",
        "icon": "http://support.xbox.com/Content/Images/LiveStatus/xboxone_icon.png"
      }],
      "services": [{
        "description": "Signing into Xbox Live"
      }]
    },
    "details": {
      "last_updated_at": "2014-03-12T02:41:16+00:00",
      "message": "Were you experiencing issues signing in to Xbox Live? We are very happy to say that our team has fixed the problem and the Live service is ready and waiting. If you are experiencing any lingering issues, try a cold reboot of your Xbox by powering down, unplugging, waiting 10 seconds, plugging back in and powering back on. Thanks for all your patience while our team was working. Have fun!"
    }
  }, {
    "name": "Purchase and Content Usage",
    "status": "active",
    "affected": null,
    "details": null
  }, {
    "name": "Website",
    "status": "active",
    "affected": null,
    "details": null
  }, {
    "name": "TV, Music and Video",
    "status": "active",
    "affected": null,
    "details": null
  }, {
    "name": "Social and Gaming",
    "status": "active",
    "affected": null,
    "details": null
  }],
  "metadata": {
    "last_updated_at": "2014-03-12T06:58:30+00:00",
    "services_unavailable": true,
    "service_update_since_last_check": false
  }
}
```

It caches the response from the status site for 5 minutes and will update when a request comes in after that TTL has been exceeded.
