from django.db import models


class Activity(models.Model):
    url = models.TextField()  # relative or full?

    okind = models.TextField()
    oid = models.TextField()
    ekind = models.TextField()

    # these three contain json. not using pg.JSONField() because sqlite
    data = models.TextField()
    trace = models.TextField()
    # elm.js corresponding to site_version should be used for this
    response = models.TextField()

    who = models.TextField(null=True)
    when = models.DateTimeField(auto_now_add=True)

    ip = models.TextField(max_length=39)
    session = models.TextField(null=True)
    # tracker? visit?
    app = models.TextField(blank=True)
    site_version = models.TextField()
    # mobile vs desktop?
    # utm parameters?
