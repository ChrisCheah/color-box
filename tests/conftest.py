"""Shared pytest fixtures for color-box tests."""
import os
import sys

import pytest

# Make the app module importable when tests are run from the repo root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))


@pytest.fixture()
def client():
    """Flask test client with a clean in-memory `boxes` dict per test."""
    import color_boxes

    color_boxes.boxes.clear()
    color_boxes.app.config.update(TESTING=True)
    with color_boxes.app.test_client() as c:
        yield c
    color_boxes.boxes.clear()


@pytest.fixture(scope="session")
def base_url():
    """Base URL of a deployed API. Tests using this fixture are skipped if unset."""
    url = os.environ.get("COLORBOX_BASE_URL")
    if not url:
        pytest.skip("COLORBOX_BASE_URL not set; skipping deployed-API tests")
    return url.rstrip("/")
