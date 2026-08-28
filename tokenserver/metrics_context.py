import contextvars

_metrics_ctx = contextvars.ContextVar('extra_metrics', default=None)

def start_metrics_context():
    _metrics_ctx.set({})

def record_metric(key, value):
    d = _metrics_ctx.get()
    if d is not None:
        d[key] = value

def collect_metrics():
    return _metrics_ctx.get() or {}
