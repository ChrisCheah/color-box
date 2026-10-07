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


def _configured_deployed_base_urls():
    configured = []
    seen = set()
    for label, env_var in (
        ("port-forward", "COLORBOX_BASE_URL"),
        ("external-hostname", "COLORBOX_EXTERNAL_BASE_URL"),
    ):
        url = os.environ.get(env_var)
        if not url:
            continue
        normalized = url.rstrip("/")
        if normalized in seen:
            continue
        seen.add(normalized)
        configured.append(pytest.param(normalized, id=label))
    return configured


def pytest_generate_tests(metafunc):
    if "base_url" not in metafunc.fixturenames:
        return

    params = _configured_deployed_base_urls()
    if not params:
        params = [pytest.param(None, id="no-deployed-url")]
    metafunc.parametrize("base_url", params, scope="session")


@pytest.fixture(scope="session")
def base_url(request):
    """Base URL of a deployed API under test."""
    url = request.param
    if not url:
        pytest.skip(
            "Set COLORBOX_BASE_URL and/or COLORBOX_EXTERNAL_BASE_URL to run deployed-API tests"
        )
    return url
