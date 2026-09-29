"""Prints the renderer skeleton of an InnerTube response (renderer keys only, first N list items).

Usage:  python tool/renderer_tree.py test/innertube/fixtures/home.json [items_per_list] [max_depth]
"""
import json, sys

path, max_items = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 1
max_depth = int(sys.argv[3]) if len(sys.argv) > 3 else 40
d = json.load(open(path, encoding="utf-8"))
SKIP = {"menu", "trackingParams", "clickTrackingParams", "loggingContext", "accessibility", "thumbnailOverlay",
        "overlay", "badges", "frameworkUpdates", "responseContext", "serviceTrackingParams", "menuRenderer",
        "toggleMenuServiceItemRenderer", "subscribeButton", "microformat"}


def walk(o, path, depth, out):
    if depth > max_depth:
        return
    if isinstance(o, dict):
        for k, v in o.items():
            if k in SKIP:
                continue
            p = f"{path}.{k}"
            if k.endswith(("Renderer", "ViewModel")) or k in ("continuations", "continuationContents",
                                                                 "onResponseReceivedActions", "header"):
                n = len(v) if isinstance(v, list) else ""
                out.append("  " * depth + f"{k}{f' [{n}]' if n else ''}")
                walk(v, p, depth + 1, out)
            else:
                walk(v, p, depth, out)
    elif isinstance(o, list):
        if len(o) > max_items and any(isinstance(x, dict) for x in o):
            out.append("  " * depth + f"[list of {len(o)}]")
        for x in o[:max_items]:
            walk(x, path, depth, out)


out = []
walk(d, "", 0, out)
print("\n".join(out))
