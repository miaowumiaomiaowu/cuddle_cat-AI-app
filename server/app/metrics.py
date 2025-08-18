from datetime import datetime
from threading import Lock
from typing import Dict, Any, List

_start_time = datetime.now()
_counters: Dict[str, int] = {}
_lock = Lock()

# Keep a rolling window of recent latency samples (milliseconds)
_LAT_SAMPLES: List[int] = []
_LAT_CAP = 200


def inc(key: str, by: int = 1) -> None:
    with _lock:
        _counters[key] = _counters.get(key, 0) + by


def add_latency_sample(ms: int) -> None:
    with _lock:
        _LAT_SAMPLES.append(ms)
        if len(_LAT_SAMPLES) > _LAT_CAP:
            # drop oldest
            del _LAT_SAMPLES[0: len(_LAT_SAMPLES) - _LAT_CAP]


def get_latency_p95() -> int | None:
    with _lock:
        if not _LAT_SAMPLES:
            return None
        arr = sorted(_LAT_SAMPLES)
        n = len(arr)
        idx = max(0, min(n - 1, int(0.95 * n) - 1))
        return arr[idx]


def get_counters() -> Dict[str, int]:
    with _lock:
        return dict(_counters)


def uptime_seconds() -> int:
    return int((datetime.now() - _start_time).total_seconds())


def reset() -> None:
    with _lock:
        _counters.clear()
        _LAT_SAMPLES.clear()

