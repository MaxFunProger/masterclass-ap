"""Загрузка query_mappings.yaml: фразы пользователя -> параметры GET /mclist."""

from __future__ import annotations

import logging
import os
import re
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

try:
    import yaml
except ImportError as e:  # pragma: no cover
    raise ImportError("Install PyYAML: pip install pyyaml") from e

DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent / "query_mappings.yaml"


def _matches_any_regex(patterns: list[str], text: str) -> bool:
    """Return True if *text* matches any regex in *patterns* (case-insensitive)."""
    for pat in patterns:
        if not isinstance(pat, str):
            continue
        try:
            if re.search(pat, text, re.I):
                return True
        except re.error as e:
            logger.warning("Bad regex pattern %r: %s", pat, e)
    return False


class IntentMappings:
    def __init__(self, data: dict[str, Any]):
        self._raw = data or {}
        self.version = self._raw.get("version", 0)
        self.category_aliases: dict[str, str] = dict(self._raw.get("category_aliases") or {})
        self.intent_mappings: list[dict[str, Any]] = list(self._raw.get("intent_mappings") or [])

        bsm = self._raw.get("broad_search_markers") or {}
        self.broad_search_markers: list[str] = list(bsm.get("patterns") or [])

        odm = self._raw.get("optional_decline_markers") or {}
        self.optional_decline_markers: list[str] = list(odm.get("patterns") or [])
        self.optional_decline_drop: list[str] = list(
            odm.get("drop_params") or ["format", "min_age", "event_date_from", "event_date_to"]
        )

    @classmethod
    def load(cls, path: Path | None = None) -> IntentMappings:
        p = path or DEFAULT_CONFIG_PATH
        if not p.is_file():
            logger.warning("query_mappings.yaml not found at %s - using empty mappings", p)
            return cls({})
        with open(p, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict):
            logger.warning("query_mappings.yaml root must be a mapping")
            return cls({})
        n = len(data.get("intent_mappings") or [])
        logger.info("Loaded query_mappings from %s (%s intents)", p, n)
        return cls(data)

    def normalize_category(self, cat: str) -> str:
        if not cat or not isinstance(cat, str):
            return cat
        c = cat.strip().lower().replace(" ", "_").replace("-", "_")
        if c in self.category_aliases:
            return self.category_aliases[c]
        for key, val in self.category_aliases.items():
            lk = key.lower() if isinstance(key, str) else str(key)
            if lk == c or lk in c or c in lk:
                return val
        return cat

    def _intent_matches(self, intent: dict[str, Any], user_blob: str, blob_lower: str) -> bool:
        if _matches_any_regex(intent.get("patterns") or [], user_blob):
            return True
        for kw in intent.get("keywords") or []:
            if isinstance(kw, str) and kw.lower() in blob_lower:
                return True
        return False

    def infer_from_user_text(self, user_blob: str, args: dict[str, Any]) -> dict[str, Any]:
        out = dict(args)
        if not user_blob or not user_blob.strip():
            return out

        blob_lower = user_blob.lower()
        extra_tag_parts: list[str] = []

        for intent in self.intent_mappings:
            if not self._intent_matches(intent, user_blob, blob_lower):
                continue
            iid = intent.get("id", "?")
            mclist = intent.get("mclist") or {}
            if not isinstance(mclist, dict):
                continue

            for key in ("category", "audience", "format", "company"):
                val = mclist.get(key)
                if val is None:
                    continue
                val = str(val).strip()
                if val and not out.get(key):
                    out[key] = val
                    logger.info("intent %s: set %s=%s", iid, key, val)

            raw_tags = mclist.get("tags")
            if raw_tags:
                extra_tag_parts.extend(
                    p.strip() for p in str(raw_tags).split(",") if p.strip()
                )

        if extra_tag_parts:
            existing = {p.strip() for p in str(out.get("tags", "")).split(",") if p.strip()}
            merged = existing.union(extra_tag_parts)
            out["tags"] = ",".join(sorted(merged))

        return out

    def matches_broad_search_marker(self, text: str) -> bool:
        return bool(text and text.strip() and _matches_any_regex(self.broad_search_markers, text.strip()))

    def apply_broad_search_override(self, last_user_message: str, args: dict[str, Any]) -> dict[str, Any]:
        if not self.matches_broad_search_marker(last_user_message):
            return dict(args)
        out = dict(args)
        had_cat = out.pop("category", None)
        out.pop("tags", None)
        if had_cat:
            logger.info("broad_search: cleared category=%s and tags (user declined theme filter)", had_cat)
        else:
            logger.info("broad_search: cleared tags only (no category in args)")
        return out

    def matches_optional_decline_marker(self, text: str) -> bool:
        return bool(text and text.strip() and _matches_any_regex(self.optional_decline_markers, text.strip()))

    def apply_optional_decline_override(self, last_user_message: str, args: dict[str, Any]) -> dict[str, Any]:
        if not self.matches_optional_decline_marker(last_user_message):
            return dict(args)
        out = dict(args)
        for key in self.optional_decline_drop:
            if isinstance(key, str) and out.pop(key, None) is not None:
                logger.info("optional_decline: dropped %s (user said detail does not matter)", key)
        return out

    def summary(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "intents": len(self.intent_mappings),
            "category_aliases": len(self.category_aliases),
            "broad_search_markers": len(self.broad_search_markers),
            "optional_decline_markers": len(self.optional_decline_markers),
        }


_MAPPINGS: IntentMappings | None = None


def get_mappings() -> IntentMappings:
    global _MAPPINGS
    if _MAPPINGS is None:
        env_path = os.environ.get("QUERY_MAPPINGS_PATH", "").strip()
        _MAPPINGS = IntentMappings.load(Path(env_path) if env_path else None)
    return _MAPPINGS
