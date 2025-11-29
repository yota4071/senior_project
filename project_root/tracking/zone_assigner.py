from .zone_definitions import ZONES

def get_zone(x, y):
    for name, ((x1, y1), (x2, y2)) in ZONES.items():
        if x1 <= x <= x2 and y1 <= y <= y2:
            return name
    return "unknown"