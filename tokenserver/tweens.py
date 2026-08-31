# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.

import time

from pyramid.httpexceptions import HTTPException

from tokenserver.metrics_context import start_metrics_context, collect_metrics


def set_x_timestamp_header(handler, registry):
    """Tween to set the X-Timestamp header on all responses."""

    def set_x_timestamp_header_tween(request):
        try:
            response = handler(request)
        except HTTPException, response:
            response.headers["X-Timestamp"] = str(int(time.time()))
            raise
        else:
            response.headers["X-Timestamp"] = str(int(time.time()))
            return response

    return set_x_timestamp_header_tween


def metrics_tween_factory(handler, registry):
    def metrics_tween(request):
        start_metrics_context()          # fresh dict for this request
        response = handler(request)
        metrics_dict = collect_metrics()
        for key, value in metrics_dict.items():
            request.metrics[key] = value
        return response
    return metrics_tween


def includeme(config):
    #config.add_tween("tokenserver.tweens.metrics_tween_factory")
    """Include all the TokenServer tweens into the given config."""
    config.add_tween("tokenserver.tweens.set_x_timestamp_header")
