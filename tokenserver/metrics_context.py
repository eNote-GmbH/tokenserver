import threading

_local = threading.local()

def start_metrics_context():
    _local.metrics = {}

def record_metric(key, value):
    d = getattr(_local, 'metrics', None)
    if d is not None:
        d[key] = value

def collect_metrics():
    return getattr(_local, 'metrics', None) or {}
