from django.db import models


class Activity(models.Model):
    url = models.TextField(default="")
    method = models.TextField(default="")
    ua = models.TextField(default="")
    ip = models.TextField(max_length=39)

    okind = models.TextField()
    oid = models.TextField()
    ekind = models.TextField()
    data = models.JSONField(default=dict)

    uid = models.TextField(null=True)
    sid = models.TextField(null=True)
    vid = models.TextField(default="")
    vid_created = models.BooleanField(default=False)
    tid = models.TextField(default="")
    tid_created = models.BooleanField(default=False)

    when = models.DateTimeField(auto_now_add=True)
    duration = models.IntegerField(default=-1)

    response = models.JSONField(default=dict)
    outcome = models.TextField(default="")
    code = models.TextField(default="")

    trace = models.JSONField(default=dict)
    hash = models.TextField(default="")
    rust_trace = models.TextField(null=True)

    utm_source = models.TextField(null=True)
    utm_medium = models.TextField(null=True)
    utm_campaign = models.TextField(null=True)
    utm_term = models.TextField(null=True)
    utm_content = models.TextField(null=True)

    site_version = models.TextField()
